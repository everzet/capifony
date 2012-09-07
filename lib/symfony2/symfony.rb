namespace :symfony do
  desc "Runs custom symfony command"
  task :default, :roles => :app, :except => { :no_release => true } do
    prompt_with_default(:task_arguments, "cache:clear")

    stream "cd #{latest_release} && #{php_bin} #{symfony_console} #{task_arguments} --env=#{symfony_env_prod}"
  end

  namespace :logs do
    [:tail, :tail_dev].each do |action|
      lines = ENV['lines'].nil? ? '50' : ENV['lines']
      log   = action.to_s == 'tail' ? 'prod.log' : 'dev.log'
      desc "Tail #{log}"
      task action, :roles => :app, :except => { :no_release => true } do
        try_sudo "tail -n #{lines} -f #{shared_path}/#{log_path}/#{log}" do |channel, stream, data|
          trap("INT") { puts 'Interupted'; exit 0; }
          puts
          puts "#{channel[:host]}: #{data}"
          break if stream == :err
        end
      end
    end
  end

  namespace :assets do
    desc "Updates assets version (in config.yml)"
    task :update_version, :roles => :app, :except => { :no_release => true } do
       try_sudo "sed -i 's/\\(assets_version: \\)\\(.*\\)$/\\1 #{real_revision}/g' #{latest_release}/#{app_path}/config/config.yml"
    end

    desc "Installs bundle's assets"
    task :install, :roles => :app, :except => { :no_release => true } do
      pretty_print "--> Installing bundle's assets"

      install_options = ''

      if true == assets_symlinks then
          install_options += " --symlink"
      end

      if true == assets_relative then
          install_options += " --relative"
      end

      try_sudo "sh -c 'cd #{latest_release} && #{php_bin} #{symfony_console} assets:install #{web_path} #{install_options} --env=#{symfony_env_prod}'"
      puts_ok
    end
  end

  namespace :assetic do
    desc "Dumps all assets to the filesystem"
    task :dump, :roles => :app,  :except => { :no_release => true } do
      pretty_print "--> Dumping all assets to the filesystem"

      try_sudo "sh -c 'cd #{latest_release} && #{php_bin} #{symfony_console} assetic:dump --env=#{symfony_env_prod} --no-debug'"
      puts_ok
    end
  end

  namespace :vendors do
    [:install, :reinstall, :upgrade].each do |action|
      desc "Runs the bin/vendors script to #{action.to_s} the vendors"
      task action, :roles => :app, :except => { :no_release => true } do
        pretty_print "--> #{action.to_s.capitalize}ing vendors"

        cmd = action.to_s
        case action
        when :reinstall
          cmd = "install --reinstall"
        when :upgrade
          cmd = "update"
        end
        try_sudo "sh -c 'cd #{latest_release} && #{php_bin} #{symfony_vendors} #{cmd}'"
        puts_ok
      end
    end
  end

  namespace :bootstrap do
    desc "Runs the bin/build_bootstrap script"
    task :build, :roles => :app, :except => { :no_release => true } do
      pretty_print "--> Building bootstrap file"

      if !remote_file_exists?("#{latest_release}/#{build_bootstrap}") && true == use_composer then
        set :build_bootstrap, "vendor/sensio/distribution-bundle/Sensio/Bundle/DistributionBundle/Resources/bin/build_bootstrap.php"
        try_sudo "sh -c 'cd #{latest_release} && test -f #{build_bootstrap} && #{php_bin} #{build_bootstrap} #{app_path} || echo '#{build_bootstrap} not found, skipped''"
      else
        try_sudo "sh -c 'cd #{latest_release} && test -f #{build_bootstrap} && #{php_bin} #{build_bootstrap} || echo '#{build_bootstrap} not found, skipped''"
      end

      puts_ok
    end
  end

  namespace :composer do
    desc "Gets composer and installs it"
    task :get, :roles => :app, :except => { :no_release => true } do
      if remote_command_exists?('composer')
        pretty_print "--> Updating Composer in PATH"

        try_sudo "composer self-update"
      else
        pretty_print "--> Downloading Composer"

        try_sudo "sh -c 'cd #{latest_release} && curl -s http://getcomposer.org/installer | #{php_bin}'"
      end

      puts_ok
    end

    desc "Runs composer to install vendors from composer.lock file"
    task :install, :roles => :app, :except => { :no_release => true } do
      composer_bin = "#{php_bin} composer.phar"
      if remote_command_exists?('composer')
        composer_bin = "composer"
      elsif !remote_file_exists?("#{latest_release}/composer.phar")
        symfony.composer.get
      end

      pretty_print "--> Installing Composer dependencies"

      try_sudo "sh -c 'cd #{latest_release} && #{composer_bin} install --no-scripts --verbose'"
      puts_ok
    end

    desc "Runs composer to update vendors, and composer.lock file"
    task :update, :roles => :app, :except => { :no_release => true } do
      composer_bin = "#{php_bin} composer.phar"
      if remote_command_exists?('composer')
        composer_bin = "composer"
      elsif !remote_file_exists?("#{latest_release}/composer.phar")
        symfony.composer.get
      end

      pretty_print "--> Updating Composer dependencies"

      try_sudo "sh -c 'cd #{latest_release} && #{composer_bin} update --no-scripts --verbose'"
      puts_ok
    end
  end

  namespace :cache do
    [:clear, :warmup].each do |action|
      desc "Cache #{action.to_s}"
      task action, :roles => :app, :except => { :no_release => true } do
        case action
        when :clear
          pretty_print "--> Clearing cache"
        when :warmup
          pretty_print "--> Warming up cache"
        end

        try_sudo "sh -c 'cd #{latest_release} && #{php_bin} #{symfony_console} cache:#{action.to_s} --env=#{symfony_env_prod}'"
        try_sudo "chmod -R g+w #{latest_release}/#{cache_path}"
        puts_ok
      end
    end
  end

  namespace :project do
    desc "Clears all non production environment controllers"
    task :clear_controllers do
      pretty_print "--> Clear controllers"

      try_sudo "sh -c 'cd #{latest_release} && rm -f #{web_path}/app_*.php'"
      puts_ok
    end
  end
end
