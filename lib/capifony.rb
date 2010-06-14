require 'yaml'

# Dirs that need to remain the same between deploys (shared dirs)
set :shared_children, %w(log web/uploads)
# PHP binary to execute
set :php_bin,         "php"

def prompt_with_default(var, default)
  set(var) do
    Capistrano::CLI.ui.ask "#{var} [#{default}] : "
  end
  set var, default if eval("#{var.to_s}.empty?")
end

def load_database_config(data, env = 'prod')
  databases = YAML::load(data)

  if databases[env]
    db_param = databases[env]['doctrine']['param']
  else
    db_param = databases['all']['doctrine']['param']
  end

  {
    'type'  => /(\w+)\:/.match(db_param['dsn'])[1],
    'user'  => db_param['username'],
    'pass'  => db_param['password'],
    'db'    => /dbname=([^;$]+)/.match(db_param['dsn'])[1]
  }
end

namespace :deploy do
  desc "Overwrite the start task to set the permissions on the project."
  task :start do
    symfony.configure.database
    symfony.project.permissions
    doctrine.build_all_and_load
  end

  desc "Overwrite the restart task because symfony doesn't need it."
  task :restart do ; end

  desc "Overwrite the stop task because symfony doesn't need it."
  task :stop do ; end

  desc "Customize migrate task because symfony doesn't need it."
  task :migrate do
    doctrine.migrate
  end

  desc "Symlink static directories that need to remain between deployments."
  task :create_dirs do
    if shared_children
      shared_children.each do |link|
        run "if [ -d #{release_path}/#{link} ] ; then rm -rf #{release_path}/#{link}; fi"
        run "mkdir -p #{shared_path}/#{link}"
        run "ln -nfs #{shared_path}/#{link} #{release_path}/#{link}"
      end
    end

    run "mkdir -p #{shared_path}/config"
    run "touch #{shared_path}/config/databases.yml"
  end

  desc "Customize the finalize_update task to work with symfony."
  task :finalize_update, :except => { :no_release => true } do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)
    run "mkdir -p #{latest_release}/cache"
    create_dirs

    if fetch(:normalize_asset_timestamps, true)
      stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
      asset_paths = %w(css images js).map { |p| "#{latest_release}/web/#{p}" }.join(" ")
      run "find #{asset_paths} -exec touch -t #{stamp} {} ';'; true", :env => { "TZ" => "UTC" }
    end
  end

  desc "Need to overwrite the deploy:cold task so it doesn't try to run the migrations."
  task :cold do
    update
    start
  end

  desc "Deploy the application and run the test suite."
  task :testall do
    update_code
    symlink
    doctrine.build_all_and_load_test
    symfony.tests.all
  end
end

namespace :symlink do
  desc "Symlink the database"
  task :db do
    run "ln -nfs #{shared_path}/config/databases.yml #{latest_release}/config/databases.yml"
  end
end

namespace :symfony do
  desc "Downloads & runs check_configuration.php on remote"
  task :check_configuration do
    prompt_with_default(:version, "1.4")

    run "wget  http://sf-to.org/#{version}/check.php -O /tmp/check_configuration.php"
    run "#{php_bin} /tmp/check_configuration.php"
    run "rm /tmp/check_configuration.php"
  end

  desc "Clears the cache"
  task :cc do
    run "#{php_bin} #{latest_release}/symfony cache:clear"
  end

  desc "Runs custom symfony task"
  task :run_task do
    prompt_with_default(:task_arguments, "cache:clear")

    run "#{php_bin} #{latest_release}/symfony #{task_arguments}"
  end

  namespace :configure do
    desc "Configure database DSN"
    task :database do
      prompt_with_default(:dsn, "mysql:host=localhost;dbname=example_dev")
      prompt_with_default(:user, "root")
      prompt_with_default(:pass, "")
      dbclass = "sfDoctrineDatabase"

      run "#{php_bin} #{latest_release}/symfony configure:database --class=#{dbclass} '#{dsn}' '#{user}' '#{pass}'"
    end
  end

  namespace :project do
    desc "Fixes symfony directory permissions"
    task :permissions do
      run "#{php_bin} #{latest_release}/symfony project:permissions"
    end

    desc "Optimizes a project for better performance"
    task :optimize do
      prompt_with_default(:application, "frontend")

      run "#{php_bin} #{latest_release}/symfony project:optimize #{application}"
    end

    desc "Clears all non production environment controllers"
    task :clear_controllers do
      run "#{php_bin} #{latest_release}/symfony project:clear-controllers"
    end
  end

  namespace :plugin do
    desc "Publishes web assets for all plugins"
    task :publish_assets do
      run "#{php_bin} #{latest_release}/symfony plugin:publish-assets"
    end
  end

  namespace :log do
    desc "Clears log files"
    task :clear do
      run "#{php_bin} #{latest_release}/symfony log:clear"
    end

    desc "Rotates an application's log files"
    task :rotate do
      prompt_with_default(:application, "frontend")
      prompt_with_default(:env, "prod")

      run "#{php_bin} #{latest_release}/symfony log:rotate #{application} #{env}"
    end
  end

  namespace :tests do
    desc "Task to run all the tests for the application."
    task :all do
      run "#{php_bin} #{latest_release}/symfony test:all"
    end
  end
end

namespace :doctrine do
  desc "Migrates database to current version"
  task :migrate do
    run "#{php_bin} #{latest_release}/symfony doctrine:migrate --env=prod"
  end

  desc "Generate code & database based on your schema"
  task :build_all do
    run "#{php_bin} #{latest_release}/symfony doctrine:build --all --no-confirmation --env=prod"
  end

  desc "Generate code & database based on your schema & load fixtures"
  task :build_all_and_load do
    run "#{php_bin} #{latest_release}/symfony doctrine:build --all --and-load --no-confirmation --env=prod"
  end

  desc "Generate code & database based on your schema & load fixtures for test environment"
  task :build_all_and_load_test do
    run "#{php_bin} #{latest_release}/symfony doctrine:build --all --and-load --no-confirmation --env=test"
  end
end

namespace :database do
  namespace :dump do
    desc "Dump remote database"
    task :remote do
      filename  = "#{application}.remote_dump.#{Time.now.to_i}.sql.bz2"
      file      = "/tmp/#{filename}"
      sqlfile   = "#{application}_dump.sql"
      config    = ""

      run "cat #{shared_path}/config/databases.yml" do |ch, st, data|
        config = load_database_config data, 'prod'
      end

      case config['type']
      when 'mysql'
        run "mysqldump -u#{config['user']} --password='#{config['pass']}' #{config['db']} | bzip2 -c > #{file}" do |ch, stream, data|
          puts data
        end
      when 'pgsql'
        run "pg_dump -U #{config['user']} --password='#{config['pass']}' #{config['db']} | bzip2 -c > #{file}" do |ch, stream, data|
          puts data
        end
      end

      `mkdir -p backups`
      get file, "backups/#{filename}"
      `cd backups && ln -nfs #{filename} #{application}.remote_dump.latest.sql.bz2`
      run "rm #{file}"
    end

    desc "Dump local database"
    task :local do
      filename  = "#{application}.local_dump.#{Time.now.to_i}.sql.bz2"
      file      = "backups/#{filename}"
      config    = load_database_config IO.read('config/databases.yml'), 'dev'
      sqlfile   = "#{application}_dump.sql"

      `mkdir -p backups`
      case config['type']
      when 'mysql'
        `mysqldump -u#{config['user']} --password='#{config['pass']}' #{config['db']} | bzip2 -c > #{file}`
      when 'pgsql'
        `pg_dump -U #{config['user']} --password='#{config['pass']}' #{config['db']} | bzip2 -c > #{file}`
      end

      `cd backups && ln -nfs #{filename} #{application}.local_dump.latest.sql.bz2`
    end
  end

  namespace :move do
    desc "Dump remote database, download it to local & populate here"
    task :to_local do
      filename  = "#{application}.remote_dump.latest.sql.bz2"
      config    = load_database_config IO.read('config/databases.yml'), 'dev'
      sqlfile   = "#{application}_dump.sql"

      database.dump.remote

      `bunzip2 -kc backups/#{filename} > backups/#{sqlfile}`
      case config['type']
      when 'mysql'
        `mysql -u#{config['user']} --password='#{config['pass']}' #{config['db']} < backups/#{sqlfile}`
      when 'pgsql'
        `psql -U #{config['user']} --password='#{config['pass']}' #{config['db']} < backups/#{sqlfile}`
      end
      `rm backups/#{sqlfile}`
    end

    desc "Dump local database, load it to remote & populate there"
    task :to_remote do
      filename  = "#{application}.local_dump.latest.sql.bz2"
      file      = "backups/#{filename}"
      sqlfile   = "#{application}_dump.sql"
      config    = ""

      database.dump.local

      upload(file, "/tmp/#{filename}", :via => :scp)
      run "bunzip2 -kc /tmp/#{filename} > /tmp/#{sqlfile}"

      run "cat #{shared_path}/config/databases.yml" do |ch, st, data|
        config = load_database_config data, 'prod'
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
end

after "deploy:finalize_update", # After finalizing update:
  "symlink:db",                       # 1. Symlink database
  "symfony:cc",                       # 2. Clear cache
  "symfony:plugin:publish_assets",    # 3. Publish plugin assets
  "symfony:project:permissions",      # 4. Fix project permissions
  "symfony:project:clear_controllers" # 5. Clear controllers
