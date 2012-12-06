namespace :database do
  namespace :dump do
    desc "Dump remote database"
    task :remote, :roles => :db, :only => { :primary => true } do
      filename  = "#{application}.remote_dump.#{Time.now.strftime("%Y-%m-%d_%H-%M-%S")}.sql.gz"
      file      = "#{remote_tmp_dir}/#{filename}"
      sqlfile   = "#{application}_dump.sql"
      config    = ""

      run "#{try_sudo} cat #{shared_path}/config/databases.yml" do |ch, st, data|
        config = load_database_config data, symfony_env_prod
      end

      sql_dump_cmd = generate_sql_command('dump', config)
      logger.debug sql_dump_cmd.gsub(/(--password=)([^ ]+)/, '\1\'********\'')    # Log the command with a masked password
      saved_log_level = logger.level
      logger.level = Capistrano::Logger::IMPORTANT    # Change log level so that the real command (containing a plaintext password) is not displayed
      try_sudo "#{sql_dump_cmd} | gzip -c > #{file}"
      logger.level = saved_log_level

      require "fileutils"
      FileUtils.mkdir_p("backups")
      get file, "backups/#{filename}"
      begin
        FileUtils.ln_sf(filename, "backups/#{application}.remote_dump.latest.sql.gz")
      rescue Exception # fallback for file systems that don't support symlinks
        FileUtils.cp_r("backups/#{filename}", "backups/#{application}.remote_dump.latest.sql.gz")
      end
      run "#{try_sudo} rm #{file}"
    end

    desc "Dump local database"
    task :local do
      filename  = "#{application}.local_dump.#{Time.now.strftime("%Y-%m-%d_%H-%M-%S")}.sql.gz"
      tmpfile   = "backups/#{application}_dump_tmp.sql"
      file      = "backups/#{filename}"
      config    = load_database_config IO.read('config/databases.yml'), symfony_env_local
      sqlfile   = "#{application}_dump.sql"

      require "fileutils"
      FileUtils::mkdir_p("backups")

      sql_dump_cmd = generate_sql_command('dump', config)
      run_locally "#{sql_dump_cmd} > #{tmpfile}"

      File.open(tmpfile, "r+") do |f|
        gz = Zlib::GzipWriter.open(file)
        while (line = f.gets)
          gz << line
        end
        gz.flush
        gz.close
      end

      begin
        FileUtils.ln_sf(filename, "backups/#{application}.local_dump.latest.sql.gz")
      rescue Exception # fallback for file systems that don't support symlinks
        FileUtils.cp_r("backups/#{filename}", "backups/#{application}.local_dump.latest.sql.gz")
      end
      FileUtils.rm(tmpfile)
    end
  end

  namespace :move do
    desc "Dump remote database, download it to local & populate here"
    task :to_local, :roles => :db, :only => { :primary => true } do

      database.dump.remote

      begin
        zipped_file_path  = `readlink -f backups/#{application}.remote_dump.latest.sql.gz`.chop  # gunzip does not work with a symlink
      rescue Exception # fallback for file systems that don't support symlinks
        zipped_file_path  = "backups/#{application}.remote_dump.latest.sql.gz"
      end
      unzipped_file_path   = "backups/#{application}_dump.sql"

      run_locally "gunzip -c #{zipped_file_path} > #{unzipped_file_path}"

      config = load_database_config IO.read('config/databases.yml'), symfony_env_local

      run_locally generate_sql_command('drop', config)
      run_locally generate_sql_command('create', config)

      sql_import_cmd = generate_sql_command('import', config)
      run_locally "#{sql_import_cmd} < #{unzipped_file_path}"

      FileUtils.rm("#{unzipped_file_path}")
    end

    desc "Dump local database, load it to remote & populate there"
    task :to_remote, :roles => :db, :only => { :primary => true } do

      filename  = "#{application}.local_dump.latest.sql.gz"
      file      = "backups/#{filename}"
      sqlfile   = "#{application}_dump.sql"
      config    = ""

      database.dump.local

      upload(file, "#{remote_tmp_dir}/#{filename}", :via => :scp)
      run "#{try_sudo} gunzip -c #{remote_tmp_dir}/#{filename} > #{remote_tmp_dir}/#{sqlfile}"

      run "#{try_sudo} cat #{shared_path}/config/databases.yml" do |ch, st, data|
        config = load_database_config data, symfony_env_prod
      end

      try_sudo generate_sql_command('drop', config)
      try_sudo generate_sql_command('create', config)

      sql_import_cmd = generate_sql_command('import', config)

      try_sudo "#{sql_import_cmd} < #{remote_tmp_dir}/#{sqlfile}"

      run "#{try_sudo} rm #{remote_tmp_dir}/#{filename}"
      run "#{try_sudo} rm #{remote_tmp_dir}/#{sqlfile}"
    end
  end
end
