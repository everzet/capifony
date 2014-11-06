require 'fileutils'
require 'zlib'

namespace :database do
  namespace :dump do
    desc "Dumps remote database"
    task :remote, :roles => :db, :only => { :primary => true } do
      env       = fetch(:deploy_env, "remote")
      filename  = "#{application}.#{env}_dump.#{Time.now.utc.strftime("%Y%m%d%H%M%S")}.sql.gz"
      file      = "#{remote_tmp_dir}/#{filename}"
      sqlfile   = "#{application}_dump.sql"
      config    = ""

      data = capture("#{try_sudo} cat #{current_path}/#{app_config_path}/#{app_config_file}")
      config = load_database_config data, symfony_env_prod

      case config['database_driver']
      when "pdo_mysql", "mysql"
        data = capture("#{try_sudo} sh -c 'mysqldump -u#{config['database_user']} --host='#{config['database_host']}' --password='#{config['database_password']}' #{config['database_name']} | gzip -c > #{file}'")
        puts data
      when "pdo_pgsql", "pgsql"
        data = capture("#{try_sudo} sh -c 'PGPASSWORD=\"#{config['database_password']}\" pg_dump -U #{config['database_user']} #{config['database_name']} -h#{config['database_host']} --clean | gzip -c > #{file}'")
        puts data
      end

      FileUtils.mkdir_p("#{backup_path}")

      capifony_progress_start
      get(file, "#{backup_path}/#{filename}", :via => :scp) do |channel, name, sent, total|
        capifony_progress_update(sent, total)
      end

      begin
        FileUtils.ln_sf(filename, "#{backup_path}/#{application}.#{env}_dump.latest.sql.gz")
      rescue Exception # fallback for file systems that don't support symlinks
        FileUtils.cp_r("#{backup_path}/#{filename}", "#{backup_path}/#{application}.#{env}_dump.latest.sql.gz")
      end
      run "#{try_sudo} rm -f #{file}"
    end

    desc "Dumps local database"
    task :local do
      filename  = "#{application}.local_dump.#{Time.now.utc.strftime("%Y%m%d%H%M%S")}.sql.gz"
      tmpfile   = "#{backup_path}/#{application}_dump_tmp.sql"
      file      = "#{backup_path}/#{filename}"
      config    = load_database_config IO.read("#{app_config_path}/#{app_config_file}"), symfony_env_local
      sqlfile   = "#{application}_dump.sql"

      FileUtils::mkdir_p("#{backup_path}")
      case config['database_driver']
      when "pdo_mysql", "mysql"
        `mysqldump -u#{config['database_user']} --password=\"#{config['database_password']}\" #{config['database_name']} > #{tmpfile}`
      when "pdo_pgsql", "pgsql"
        `PGPASSWORD=\"#{config['database_password']}\" pg_dump -U #{config['database_user']} #{config['database_name']} --clean > #{tmpfile}`
      end

      File.open(tmpfile, "r+") do |f|
        gz = Zlib::GzipWriter.open(file)
        while (line = f.gets)
          gz << line
        end
        gz.flush
        gz.close
      end

      begin
        FileUtils.ln_sf(filename, "#{backup_path}/#{application}.local_dump.latest.sql.gz")
      rescue Exception # fallback for file systems that don't support symlinks
        FileUtils.cp_r("#{backup_path}/#{filename}", "#{backup_path}/#{application}.local_dump.latest.sql.gz")
      end
      FileUtils.rm(tmpfile)
    end
  end

  namespace :copy do
    desc "Dumps remote database, downloads it to local, and populates here"
    task :to_local, :roles => :db, :only => { :primary => true } do
      env       = fetch(:deploy_env, "remote")
      filename  = "#{application}.#{env}_dump.latest.sql.gz"
      config    = load_database_config IO.read("#{app_config_path}/#{app_config_file}"), symfony_env_local
      sqlfile   = "#{application}_dump.sql"

      database.dump.remote

      f = File.new("#{backup_path}/#{sqlfile}", "a+")
      gz = Zlib::GzipReader.new(File.open("#{backup_path}/#{filename}", "r"))
      f << gz.read
      f.close

      case config['database_driver']
      when "pdo_mysql", "mysql"
        `mysql -u#{config['database_user']} --host=\"#{config['database_host']}\" --password=\"#{config['database_password']}\" #{config['database_name']} < #{backup_path}/#{sqlfile}`
      when "pdo_pgsql", "pgsql"
        `PGPASSWORD=\"#{config['database_password']}\" psql -U #{config['database_user']} #{config['database_name']} -h#{config['database_host']}< #{backup_path}/#{sqlfile}`
      end
      FileUtils.rm("#{backup_path}/#{sqlfile}")
    end

    desc "Dumps local database, loads it to remote, and populates there"
    task :to_remote, :roles => :db, :only => { :primary => true } do
      filename  = "#{application}.local_dump.latest.sql.gz"
      file      = "#{backup_path}/#{filename}"
      sqlfile   = "#{application}_dump.sql"
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
        data = capture("#{try_sudo} PGPASSWORD=\"#{config['database_password']}\" psql -U #{config['database_user']} #{config['database_name']} -h#{config['database_host']} < #{remote_tmp_dir}/#{sqlfile}")
        puts data
      end

      run "#{try_sudo} rm -f #{remote_tmp_dir}/#{filename}"
      run "#{try_sudo} rm -f #{remote_tmp_dir}/#{sqlfile}"
    end
  end
end
