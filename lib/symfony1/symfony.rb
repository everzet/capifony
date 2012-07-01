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
    run "cd #{latest_release} && #{try_sudo} #{php_bin} ./symfony cache:clear"
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
end
