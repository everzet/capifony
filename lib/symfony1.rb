require 'yaml'
load Gem.find_files('capifony.rb').last.to_s

# Dirs that need to remain the same between deploys (shared dirs)
set :shared_children,   %w(log web/uploads)

# Files that need to remain the same between deploys
set :shared_files,      %w(config/databases.yml)

# Asset folders (that need to be timestamped)
set :asset_children,    %w(web/css web/images web/js)

# Use ORM
set :use_orm,           true

# Symfony default ORM
set(:symfony_orm)     { guess_symfony_orm }

# Symfony lib path
set(:symfony_lib)     { guess_symfony_lib }

# Shared symfony lib
set :use_shared_symfony, false
set :symfony_version, "1.4.11"

def guess_symfony_orm
  databases = YAML::load(IO.read('config/databases.yml'))

  if databases[symfony_env_local]
    databases[symfony_env_local].keys[0].to_s
  else
    databases['all'].keys[0].to_s
  end
end

def guess_symfony_lib
  symfony_version = capture("cd #{latest_release} && #{php_bin} ./symfony -V")

  /\((.*)\)/.match(symfony_version)[1]
end

def load_database_config(data, env)
  databases = YAML::load(data)

  if databases[env]
    db_param = databases[env][symfony_orm]['param']
  else
    db_param = databases['all'][symfony_orm]['param']
  end

  {
    'type'  => /(\w+)\:/.match(db_param['dsn'])[1],
    'user'  => db_param['username'],
    'pass'  => db_param['password'],
    'db'    => /dbname=([^;$]+)/.match(db_param['dsn'])[1]
  }
end

namespace :deploy do
  desc "Customize migrate task because symfony doesn't need it."
  task :migrate do
    symfony.orm.migrate
  end

  desc "Symlink static directories and static files that need to remain between deployments."
  task :share_childs do
    if shared_children
      shared_children.each do |link|
        run "mkdir -p #{shared_path}/#{link}"
        run "if [ -d #{release_path}/#{link} ] ; then rm -rf #{release_path}/#{link}; fi"
        run "ln -nfs #{shared_path}/#{link} #{release_path}/#{link}"
      end
    end
    if shared_files
      shared_files.each do |link|
        link_dir = File.dirname("#{shared_path}/#{link}")
        run "mkdir -p #{link_dir}"
        run "touch #{shared_path}/#{link}"
        run "ln -nfs #{shared_path}/#{link} #{release_path}/#{link}"
      end
    end
  end

  desc "Customize the finalize_update task to work with symfony."
  task :finalize_update, :except => { :no_release => true } do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)
    run "mkdir -p #{latest_release}/cache"
    run "chmod -R g+w #{latest_release}/cache"

    # Share common files & folders
    share_childs

    if fetch(:normalize_asset_timestamps, true)
      stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
      asset_paths = asset_children.map { |p| "#{latest_release}/#{p}" }.join(" ")
      run "find #{asset_paths} -exec touch -t #{stamp} {} ';'; true", :env => { "TZ" => "UTC" }
    end
  end

  desc "Need to overwrite the deploy:cold task so it doesn't try to run the migrations."
  task :cold do
    update
    symfony.orm.build_db_and_load
    start
  end

  desc "Deploy the application and run the test suite."
  task :testall do
    update_code
    symlink
    symfony.orm.build_db_and_load
    symfony.tests.all
  end
end

namespace :symfony do
  desc "Runs custom symfony task"
  task :default do
    prompt_with_default(:task_arguments, "cache:clear")

    stream "cd #{latest_release} && #{php_bin} ./symfony #{task_arguments}"
  end

  desc "Downloads & runs check_configuration.php on remote"
  task :check_configuration do
    prompt_with_default(:version, "1.4")

    run "wget  http://sf-to.org/#{version}/check.php -O /tmp/check_configuration.php"
    stream "#{php_bin} /tmp/check_configuration.php"
    run "rm /tmp/check_configuration.php"
  end

  desc "Clears the cache"
  task :cc do
    run "cd #{latest_release} && #{php_bin} ./symfony cache:clear"
    run "chmod -R g+w #{latest_release}/cache"
  end

  desc "Creates symbolic link to symfony lib in shared"
  task :create_lib_symlink do 
    prompt_with_default(:version, symfony_version)
    symlink_path = "#{latest_release}/lib/vendor/symfony"

    run "if [ ! -d #{shared_path}/symfony-#{version} ]; then exit 1; fi;"
    run "ln -nfs #{shared_path}/symfony-#{version} #{symlink_path};"
  end

  namespace :configure do
    desc "Configure database DSN"
    task :database do
      prompt_with_default(:dsn,         "mysql:host=localhost;dbname=#{application}")
      prompt_with_default(:db_username, "root")
      db_password = Capistrano::CLI.password_prompt("db_password : ")

      # surpress debug log output to hide the password
      current_logger_level = self.logger.level
      if current_logger_level >= Capistrano::Logger::DEBUG
        logger.debug %(executing "cd #{latest_release} && #{php_bin} ./symfony configure:database '#{dsn}' '#{db_username}' ***")
        self.logger.level = Capistrano::Logger::INFO 
      end

      stream "cd #{latest_release} && #{php_bin} ./symfony configure:database '#{dsn}' '#{db_username}' '#{db_password}'"

      # restore logger level
      self.logger.level = current_logger_level
    end
  end

  namespace :project do
    desc "Disables an application in a given environment"
    task :disable do
      run "cd #{latest_release} && #{php_bin} ./symfony project:disable #{symfony_env_prod}"
    end

    desc "Enables an application in a given environment"
    task :enable do
      run "cd #{latest_release} && #{php_bin} ./symfony project:enable #{symfony_env_prod}"
    end

    desc "Fixes symfony directory permissions"
    task :permissions do
      run "cd #{latest_release} && #{php_bin} ./symfony project:permissions"
    end

    desc "Optimizes a project for better performance"
    task :optimize do
      prompt_with_default(:application, "frontend")

      run "cd #{latest_release} && #{php_bin} ./symfony project:optimize #{application}"
    end

    desc "Clears all non production environment controllers"
    task :clear_controllers do
      run "cd #{latest_release} && #{php_bin} ./symfony project:clear-controllers"
    end

    desc "Sends emails stored in a queue"
    task :send_emails do
      prompt_with_default(:message_limit, 10)
      prompt_with_default(:time_limit,    10)

      stream "cd #{latest_release} && #{php_bin} ./symfony project:send-emails --message-limit=#{message_limit} --time-limit=#{time_limit} --env=#{symfony_env_prod}"
    end
    
    desc 'Task to set all front controllers to a specific environment'
    task :set_environment do
      if (env = fetch(:symfony_env_prod, nil)) && env != 'prod'
        cmd   = []
        apps  = fetch(:symfony_apps, ['frontend'])

        # First application listed becomes index.php
        if app = apps.shift
          cmd << "cp #{release_path}/web/#{app}_#{env}.php #{release_path}/web/index.php"
        end
        
        # All other apps are copied to their default controllers
        for app in apps
          cmd << "cp #{release_path}/web/#{app}_#{env}.php #{release_path}/web/#{app}.php"
        end
    
        run cmd.join(';') if cmd.join(';')
      end
    end
  end

  namespace :plugin do
    desc "Publishes web assets for all plugins"
    task :publish_assets do
      run "cd #{latest_release} && #{php_bin} ./symfony plugin:publish-assets"
    end
  end

  namespace :log do
    desc "Clears log files"
    task :clear do
      run "cd #{latest_release} && #{php_bin} ./symfony log:clear"
    end

    desc "Rotates an application's log files"
    task :rotate do
      prompt_with_default(:application, "frontend")

      run "cd #{latest_release} && #{php_bin} ./symfony log:rotate #{application} #{symfony_env_prod}"
    end
  end

  namespace :tests do
    desc "Launches all tests"
    task :all do
      run "cd #{latest_release} && #{php_bin} ./symfony test:all"
    end

    desc "Launches functional tests"
    task :functional do
      prompt_with_default(:application, "frontend")

      run "cd #{latest_release} && #{php_bin} ./symfony test:functional #{application}"
    end

    desc "Launches unit tests"
    task :unit do
      run "cd #{latest_release} && #{php_bin} ./symfony test:unit"
    end
  end

  namespace :orm do
    desc "Ensure symfony ORM is properly configured"
    task :setup do
      find_and_execute_task("symfony:#{symfony_orm}:setup")
    end
  
    desc "Migrates database to current version"
    task :migrate do
      find_and_execute_task("symfony:#{symfony_orm}:migrate")
    end

    desc "Generate model lib form and filters classes based on your schema"
    task :build_classes do
      find_and_execute_task("symfony:#{symfony_orm}:build_classes")
    end

    desc "Generate code & database based on your schema"
    task :build_all do
      find_and_execute_task("symfony:#{symfony_orm}:build_all")
    end

    desc "Generate code & database based on your schema & load fixtures"
    task :build_all_and_load do
      find_and_execute_task("symfony:#{symfony_orm}:build_all_and_load")
    end

    desc "Generate sql & database based on your schema"
    task :build_db do
      find_and_execute_task("symfony:#{symfony_orm}:build_db")
    end

    desc "Generate sql & database based on your schema & load fixtures"
    task :build_db_and_load do
      find_and_execute_task("symfony:#{symfony_orm}:build_db_and_load")
    end
  end

  namespace :doctrine do
    desc "Compile doctrine"
    task :compile do
      run "cd #{latest_release} && #{php_bin} ./symfony doctrine:compile"
    end

    desc "Ensure Doctrine is correctly configured"
    task :setup do 
      conf_files_exists = capture("if test -s #{shared_path}/config/databases.yml ; then echo 'exists' ; fi").strip
      if (!conf_files_exists.eql?("exists"))
        symfony.configure.database
      end
    end

    desc "Execute a DQL query and view the results"
    task :dql do
      prompt_with_default(:query, "")

      stream "cd #{latest_release} && #{php_bin} ./symfony doctrine:dql #{query} --env=#{symfony_env_prod}"
    end

    desc "Dumps data to the fixtures directory"
    task :data_dump do
      run "cd #{latest_release} && #{php_bin} ./symfony doctrine:data-dump --env=#{symfony_env_prod}"
    end

    desc "Loads YAML fixture data"
    task :data_load do
      run "cd #{latest_release} && #{php_bin} ./symfony doctrine:data-load --env=#{symfony_env_prod}"
    end

    desc "Loads YAML fixture data without remove"
    task :data_load_append do
      run "cd #{latest_release} && #{php_bin} ./symfony doctrine:data-load --append --env=#{symfony_env_prod}"
    end

    desc "Migrates database to current version"
    task :migrate do
      run "cd #{latest_release} && #{php_bin} ./symfony doctrine:migrate --env=#{symfony_env_prod}"
    end

    desc "Generate model lib form and filters classes based on your schema"
    task :build_classes do
      run "cd #{latest_release} && #{php_bin} ./symfony doctrine:build --all-classes --env=#{symfony_env_prod}"
    end

    desc "Generate code & database based on your schema"
    task :build_all do
      if Capistrano::CLI.ui.agree("Do you really want to rebuild #{symfony_env_prod}'s database? (y/N)")
        run "cd #{latest_release} && #{php_bin} ./symfony doctrine:build --all --no-confirmation --env=#{symfony_env_prod}"
      end
    end

    desc "Generate code & database based on your schema & load fixtures"
    task :build_all_and_load do
      if Capistrano::CLI.ui.agree("Do you really want to rebuild #{symfony_env_prod}'s database and load #{symfony_env_prod}'s fixtures? (y/N)")
        run "cd #{latest_release} && #{php_bin} ./symfony doctrine:build --all --and-load --no-confirmation --env=#{symfony_env_prod}"
      end
    end

    desc "Generate sql & database based on your schema"
    task :build_db do
      if Capistrano::CLI.ui.agree("Do you really want to rebuild #{symfony_env_prod}'s database? (y/N)")
        run "cd #{latest_release} && #{php_bin} ./symfony doctrine:build --sql --db --no-confirmation --env=#{symfony_env_prod}"
      end
    end

    desc "Generate sql & database based on your schema & load fixtures"
    task :build_db_and_load do
      if Capistrano::CLI.ui.agree("Do you really want to rebuild #{symfony_env_prod}'s database and load #{symfony_env_prod}'s fixtures? (y/N)")
        run "cd #{latest_release} && #{php_bin} ./symfony doctrine:build --sql --db --and-load --no-confirmation --env=#{symfony_env_prod}"
      end
    end
  end

  namespace :propel do
    desc "Ensure Propel is correctly configured"
    task :setup do
      conf_files_exists = capture("if test -s #{shared_path}/config/propel.ini -a -s #{shared_path}/config/databases.yml ; then echo 'exists' ; fi").strip

      # share childs again (for propel.ini file)
      shared_files << "config/propel.ini"
      deploy.share_childs

      if (!conf_files_exists.eql?("exists"))
        run "cp #{symfony_lib}/plugins/sfPropelPlugin/config/skeleton/config/propel.ini #{shared_path}/config/propel.ini"
        symfony.configure.database
      end
    end

    desc "Migrates database to current version"
    task :migrate do
      puts "propel doesn't have built-in migration for now"
    end

    desc "Generate model lib form and filters classes based on your schema"
    task :build_classes do
      run "php #{latest_release}/symfony propel:build --model --env=#{symfony_env_prod}"
      run "php #{latest_release}/symfony propel:build --forms --env=#{symfony_env_prod}"
      run "php #{latest_release}/symfony propel:build --filter --env=#{symfony_env_prod}"
    end

    desc "Generate code & database based on your schema"
    task :build_all do
      if Capistrano::CLI.ui.agree("Do you really want to rebuild #{symfony_env_prod}'s database? (y/N)")
        run "cd #{latest_release} && #{php_bin} ./symfony propel:build --sql --db --no-confirmation --env=#{symfony_env_prod}"
      end
    end

    desc "Generate code & database based on your schema & load fixtures"
    task :build_all_and_load do
      if Capistrano::CLI.ui.agree("Do you really want to rebuild #{symfony_env_prod}'s database and load #{symfony_env_prod}'s fixtures? (y/N)")
        run "cd #{latest_release} && #{php_bin} ./symfony propel:build --sql --db --and-load --no-confirmation --env=#{symfony_env_prod}"
      end
    end

    desc "Generate sql & database based on your schema"
    task :build_db do
      if Capistrano::CLI.ui.agree("Do you really want to rebuild #{symfony_env_prod}'s database? (y/N)")
        run "cd #{latest_release} && #{php_bin} ./symfony propel:build --sql --db --no-confirmation --env=#{symfony_env_prod}"
      end
    end

    desc "Generate sql & database based on your schema & load fixtures"
    task :build_db_and_load do
      if Capistrano::CLI.ui.agree("Do you really want to rebuild #{symfony_env_prod}'s database and load #{symfony_env_prod}'s fixtures? (y/N)")
        run "cd #{latest_release} && #{php_bin} ./symfony propel:build --sql --db --and-load --no-confirmation --env=#{symfony_env_prod}"
      end
    end
  end
end

namespace :database do
  namespace :dump do
    desc "Dump remote database"
    task :remote do
      filename  = "#{application}.remote_dump.#{Time.now.to_i}.sql.gz"
      file      = "/tmp/#{filename}"
      sqlfile   = "#{application}_dump.sql"
      config    = ""

      run "cat #{shared_path}/config/databases.yml" do |ch, st, data|
        config = load_database_config data, symfony_env_prod
      end

      case config['type']
      when 'mysql'
        run "mysqldump -u#{config['user']} --password='#{config['pass']}' #{config['db']} | gzip -c > #{file}" do |ch, stream, data|
          puts data
        end
      when 'pgsql'
        run "pg_dump -U #{config['user']} --password='#{config['pass']}' #{config['db']} | gzip -c > #{file}" do |ch, stream, data|
          puts data
        end
      end

      require "FileUtils"
      FileUtils.mkdir_p("backups")
      get file, "backups/#{filename}"
      begin
        FileUtils.ln_sf(filename, "backups/#{application}.remote_dump.latest.sql.gz")
      rescue NotImplementedError # hack for windows which doesnt support symlinks
        FileUtils.cp_r("backups/#{filename}", "backups/#{application}.remote_dump.latest.sql.gz")
      end
      run "rm #{file}"
    end

    desc "Dump local database"
    task :local do
      filename  = "#{application}.local_dump.#{Time.now.to_i}.sql.gz"
      tmpfile   = "backups/#{application}_dump_tmp.sql"
      file      = "backups/#{filename}"
      config    = load_database_config IO.read('config/databases.yml'), symfony_env_local
      sqlfile   = "#{application}_dump.sql"

      require "FileUtils"
      FileUtils::mkdir_p("backups")
      case config['type']
      when 'mysql'
        `mysqldump -u#{config['user']} --password=\"#{config['pass']}\" #{config['db']} > #{tmpfile}`
      when 'pgsql'
        `pg_dump -U #{config['user']} --password=\"#{config['pass']}\" #{config['db']} > #{tmpfile}`
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
        FileUtils.ln_sf(filename, "backups/#{application}.local_dump.latest.sql.gz")
      rescue NotImplementedError # hack for windows which doesnt support symlinks
        FileUtils.cp_r("backups/#{filename}", "backups/#{application}.local_dump.latest.sql.gz")
      end
      FileUtils.rm(tmpfile)
    end
  end

  namespace :move do
    desc "Dump remote database, download it to local & populate here"
    task :to_local do
      filename  = "#{application}.remote_dump.latest.sql.gz"
      config    = load_database_config IO.read('config/databases.yml'), symfony_env_local
      sqlfile   = "#{application}_dump.sql"

      database.dump.remote

      require "FileUtils"
      f = File.new("backups/#{sqlfile}", "a+")
      require "zlib"
      gz = Zlib::GzipReader.new(File.open("backups/#{filename}", "r"))
      f << gz.read
      f.close
      
      case config['type']
      when 'mysql'
        `mysql -u#{config['user']} --password=\"#{config['pass']}\" #{config['db']} < backups/#{sqlfile}`
      when 'pgsql'
        `psql -U #{config['user']} --password=\"#{config['pass']}\" #{config['db']} < backups/#{sqlfile}`
      end
      FileUtils.rm("backups/#{sqlfile}")
    end

    desc "Dump local database, load it to remote & populate there"
    task :to_remote do
      filename  = "#{application}.local_dump.latest.sql.gz"
      file      = "backups/#{filename}"
      sqlfile   = "#{application}_dump.sql"
      config    = ""

      database.dump.local

      upload(file, "/tmp/#{filename}", :via => :scp)
      run "gunzip -c /tmp/#{filename} > /tmp/#{sqlfile}"

      run "cat #{shared_path}/config/databases.yml" do |ch, st, data|
        config = load_database_config data, symfony_env_prod
      end

      case config['type']
      when 'mysql'
        run "mysql -u#{config['user']} --password='#{config['pass']}' #{config['db']} < /tmp/#{sqlfile}" do |ch, stream, data|
          puts data
        end
      when 'pgsql'
        run "psql -U #{config['user']} --password='#{config['pass']}' #{config['db']} < /tmp/#{sqlfile}" do |ch, stream, data|
          puts data
        end
      end

      run "rm /tmp/#{filename}"
      run "rm /tmp/#{sqlfile}"
    end
  end
end

namespace :shared do
  namespace :databases do
    desc "Download config/databases.yml from remote server"
    task :to_local do
      download("#{shared_path}/config/databases.yml", "config/databases.yml", :via => :scp)
    end

    desc "Upload config/databases.yml to remote server"
    task :to_remote do
      upload("config/databases.yml", "#{shared_path}/config/databases.yml", :via => :scp)
    end
  end

  namespace :log do
    desc "Download all logs from remote folder to local one"
    task :to_local do
      download("#{shared_path}/log", "./", :via => :scp, :recursive => true)
    end

    desc "Upload all logs from local folder to remote one"
    task :to_remote do
      upload("log", "#{shared_path}/", :via => :scp, :recursive => true)
    end
  end

  namespace :uploads do
    desc "Download all files from remote web/uploads folder to local one"
    task :to_local do
      download("#{shared_path}/web/uploads", "web", :via => :scp, :recursive => true)
    end

    desc "Upload all files from local web/uploads folder to remote one"
    task :to_remote do
      upload("web/uploads", "#{shared_path}/web", :via => :scp, :recursive => true)
    end
  end

  namespace :symfony do
    desc "Downloads symfony framework to shared directory"
    task :download do 
      prompt_with_default(:version, symfony_version)
  
      run <<-CMD
        if [ ! -d #{shared_path}/symfony-#{version} ]; then
          wget -q http://www.symfony-project.org/get/symfony-#{version}.tgz -O- | tar -zxf - -C #{shared_path};
        fi
      CMD
    end
  end
end

# After setup
after "deploy:setup" do
  if use_shared_symfony
    shared.symfony.download
  end
end

# Before finalizing update
before "deploy:finalize_update" do
  if use_shared_symfony
    symfony.create_lib_symlink
  end
end

# After finalizing update:
after "deploy:finalize_update" do
  if use_orm
    symfony.orm.setup                     # 1. Ensure that ORM is configured
    symfony.orm.build_classes             # 2. (Re)build the model
  end
  symfony.cc                              # 3. Clear cache
  symfony.plugin.publish_assets           # 4. Publish plugin assets
  symfony.project.permissions             # 5. Fix project permissions
  if symfony_env_prod.eql?("prod")
    symfony.project.clear_controllers     # 6. Clear controllers in production environment
  end
end
