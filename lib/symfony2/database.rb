require 'fileutils'
require 'zlib'

namespace :database do
  namespace :dump do
    desc "Dumps remote database"
    task :remote, :roles => :db, :only => { :primary => true } do
      application_name = application.gsub(/\s+/, "_") # make application name safe
      env              = fetch(:deploy_env, "remote")
      filename         = "#{application_name}.#{env}_dump.#{Time.now.to_i}.sql.gz"
      latest_filepath  = "backups/#{application_name}.#{env}_dump.latest.sql.gz"
      backup_filepath  = "backups/#{filename}"
      temp_filepath    = "#{remote_tmp_dir}/#{filename}"
      config           = ""

      data = capture("#{try_sudo} cat #{current_path}/#{app_config_path}/#{app_config_file}")
      config = load_database_config data, symfony_env_prod

      case config['database_driver']
      when "pdo_mysql", "mysql"
        data = capture("#{try_sudo} sh -c 'mysqldump -u#{config['database_user']} --host='#{config['database_host']}' --password='#{config['database_password']}' #{config['database_name']} | gzip -c > #{temp_filepath}'")
        puts data
      when "pdo_pgsql", "pgsql"
        data = capture("#{try_sudo} sh -c 'pg_dump -U #{config['database_user']} #{config['database_name']} --clean | gzip -c > #{temp_filepath}'")
        puts data
      end

      FileUtils.mkdir_p("backups")
      get temp_filepath, backup_filepath # copy temporary file to backup path
      begin
        FileUtils.ln_sf(filename, latest_filepath) # symlink newest backup path
      rescue Exception # fallback for file systems that don't support symlinks
        FileUtils.cp_r(backup_filepath, latest_filepath) # copy newest backup
      end
      run "#{try_sudo} rm -f #{temp_filepath}"
    end

    desc "Dumps local database"
    task :local do
      filename         = "#{application_name}.local_dump.#{Time.now.to_i}.sql.gz"
      latest_filepath  = "backups/#{application_name}.local_dump.latest.sql.gz"
      backup_filepath  = "backups/#{filename}"
      temp_filepath    = "backups/#{application_name}_dump_tmp.sql"
      file             = "backups/#{filename}"
      config           = load_database_config IO.read("#{app_config_path}/#{app_config_file}"), symfony_env_local

      FileUtils::mkdir_p("backups")
      case config['database_driver']
      when "pdo_mysql", "mysql"
        `mysqldump -u#{config['database_user']} --password=\"#{config['database_password']}\" #{config['database_name']} > #{temp_filepath}`
      when "pdo_pgsql", "pgsql"
        `pg_dump -U #{config['database_user']} #{config['database_name']} --clean > #{temp_filepath}`
      end

      File.open(temp_filepath, "r+") do |f|
        gz = Zlib::GzipWriter.open(file)
        while (line = f.gets)
          gz << line
        end
        gz.flush
        gz.close
      end

      begin
        FileUtils.ln_sf(filename, latest_filepath)
      rescue Exception # fallback for file systems that don't support symlinks
        FileUtils.cp_r(backup_filepath, latest_filepath)
      end
      FileUtils.rm(temp_filepath)
    end
  end

  namespace :move do
    desc "Dumps remote database, downloads it to local, and populates here"
    task :to_local, :roles => :db, :only => { :primary => true } do
      env       = fetch(:deploy_env, "remote")
      filename  = "#{application_name}.#{env}_dump.latest.sql.gz"
      config    = load_database_config IO.read("#{app_config_path}/#{app_config_file}"), symfony_env_local
      sqlfile   = "#{application_name}_dump.sql"

      database.dump.remote

      f = File.new("backups/#{sqlfile}", "a+")
      gz = Zlib::GzipReader.new(File.open("backups/#{filename}", "r"))
      f << gz.read
      f.close

      case config['database_driver']
      when "pdo_mysql", "mysql"
        `mysql -u#{config['database_user']} --password=\"#{config['database_password']}\" #{config['database_name']} < backups/#{sqlfile}`
      when "pdo_pgsql", "pgsql"
        `psql -U #{config['database_user']} #{config['database_name']} < backups/#{sqlfile}`
      end
      FileUtils.rm("backups/#{sqlfile}")
    end

    desc "Dumps local database, loads it to remote, and populates there"
    task :to_remote, :roles => :db, :only => { :primary => true } do
      filename  = "#{application_name}.local_dump.latest.sql.gz"
      file      = "backups/#{filename}"
      sqlfile   = "#{application_name}_dump.sql"
      config    = ""

      database.dump.local

      upload(file, "#{remote_tmp_dir}/#{filename}", :via => :scp)
      run "#{try_sudo} gunzip -c #{remote_tmp_dir}/#{filename} > #{remote_tmp_dir}/#{sqlfile}"

      data = capture("#{try_sudo} cat #{current_path}/#{app_config_path}/#{app_config_file}")
      config = load_database_config data, symfony_env_prod

      case config['database_driver']
      when "pdo_mysql", "mysql"
        data = capture("#{try_sudo} mysql -u#{config['database_user']} --host='#{config['database_host']}' --password='#{config['database_password']}' #{config['database_name']} < #{remote_tmp_dir}/#{sqlfile}")
        puts data
      when "pdo_pgsql", "pgsql"
        data = capture("#{try_sudo} psql -U #{config['database_user']} #{config['database_name']} < #{remote_tmp_dir}/#{sqlfile}")
        puts data
      end

      run "#{try_sudo} rm -f #{remote_tmp_dir}/#{filename}"
      run "#{try_sudo} rm -f #{remote_tmp_dir}/#{sqlfile}"
    end
  end
end