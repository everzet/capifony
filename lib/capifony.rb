# Dirs that need to remain the same between deploys (shared dirs)
set :shared_children, %w(log web/uploads)

def prompt_with_default(var, default)
  set(var) do
    Capistrano::CLI.ui.ask "#{var} [#{default}] : "
  end
  set var, default if eval("#{var.to_s}.empty?")
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
        run "mkdir -p #{shared_path}/#{link}"
        run "ln -nfs #{shared_path}/#{link} #{release_path}/#{link}"
      end
    end

    run "touch #{shared_path}/databases.yml"
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
    run "ln -nfs #{shared_path}/databases.yml #{latest_release}/config/databases.yml"
  end
end

namespace :symfony do
  desc "Clears the cache"
  task :cc do
    run "php #{latest_release}/symfony cache:clear"
  end

  desc "Runs custom symfony task"
  task :run_task do
    prompt_with_default(:task_arguments, "cache:clear")

    run "php #{latest_release}/symfony #{task_arguments}"
  end

  namespace :configure do
    desc "Configure database DSN"
    task :database do
      prompt_with_default(:dsn, "mysql:host=localhost;dbname=example_dev")
      prompt_with_default(:user, "root")
      prompt_with_default(:pass, "")
      dbclass = "sfDoctrineDatabase"

      run "php #{latest_release}/symfony configure:database --class=#{dbclass} '#{dsn}' '#{user}' '#{pass}'"
    end
  end

  namespace :project do
    desc "Fixes symfony directory permissions"
    task :permissions do
      run "php #{latest_release}/symfony project:permissions"
    end

    desc "Optimizes a project for better performance"
    task :optimize do
      prompt_with_default(:application, "frontend")

      run "php #{latest_release}/symfony project:optimize #{application}"
    end

    desc "Clears all non production environment controllers"
    task :clear_controllers do
      run "php #{latest_release}/symfony project:clear-controllers"
    end
  end

  namespace :plugin do
    desc "Publishes web assets for all plugins"
    task :publish_assets do
      run "php #{latest_release}/symfony plugin:publish-assets"
    end
  end

  namespace :log do
    desc "Clears log files"
    task :clear do
      run "php #{latest_release}/symfony log:clear"
    end

    desc "Rotates an application's log files"
    task :rotate do
      prompt_with_default(:application, "frontend")
      prompt_with_default(:env, "prod")

      run "php #{latest_release}/symfony log:rotate #{application} #{env}"
    end
  end

  namespace :tests do
    desc "Task to run all the tests for the application."
    task :all do
      run "php #{latest_release}/symfony test:all"
    end
  end
end

namespace :doctrine do
  desc "Migrates database to current version"
  task :migrate do
    run "php #{latest_release}/symfony doctrine:migrate --env=prod"
  end

  desc "Generate code & database based on your schema"
  task :build_all do
    run "php #{latest_release}/symfony doctrine:build --all --no-confirmation --env=prod"
  end

  desc "Generate code & database based on your schema & load fixtures"
  task :build_all_and_load do
    run "php #{latest_release}/symfony doctrine:build --all --and-load --no-confirmation --env=prod"
  end

  desc "Generate code & database based on your schema & load fixtures for test environment"
  task :build_all_and_load_test do
    run "php #{latest_release}/symfony doctrine:build --all --and-load --no-confirmation --env=test"
  end
end

namespace :shared do
  namespace :database do
    desc "Download config/databases.yml from remote server"
    task :download do
      download("#{shared_path}/databases.yml", "config/databases.yml", :via => :scp, :recursive => true)
    end

    desc "Upload config/databases.yml to remote server"
    task :upload do
      upload("config/databases.yml", "#{shared_path}/databases.yml", :via => :scp, :recursive => true)
    end
  end

  namespace :logs do
    desc "Download all logs from remote folder to local one"
    task :download do
      download("#{shared_path}/log", "log", :via => :scp, :recursive => true)
    end

    desc "Upload all logs from local folder to remote one"
    task :upload do
      upload("log", "#{shared_path}/log", :via => :scp, :recursive => true)
    end
  end

  namespace :uploads do
    desc "Download all files from remote web/uploads folder to local one"
    task :download do
      download("#{shared_path}/web/uploads", "web/uploads", :via => :scp, :recursive => true)
    end

    desc "Upload all files from local web/uploads folder to remote one"
    task :upload do
      upload("web/uploads", "#{shared_path}/web/uploads", :via => :scp, :recursive => true)
    end
  end
end

after "deploy:finalize_update", # After finalizing update:
  "symlink:db",                       # 1. Symlink database
  "symfony:cc",                       # 2. Clear cache
  "symfony:plugin:publish_assets",    # 3. Publish plugin assets
  "symfony:project:permissions"       # 4. Fix project permissions
  "symfony:project:clear_controllers" # 5. Clear controllers
