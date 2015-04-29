namespace :symfony do
  desc "Runs custom symfony command"
  task :default, :roles => :app, :except => { :no_release => true } do
    prompt_with_default(:task_arguments, "cache:clear")

    stream "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{symfony_console} #{task_arguments} #{console_options}'"
  end


  namespace :logs do
    [:tail, :tail_dev].each do |action|
      lines = ENV['lines'].nil? ? '50' : ENV['lines']
      log   = action.to_s == 'tail' ? 'prod.log' : 'dev.log'
      desc "Tail #{log}"
      task action, :roles => :app, :except => { :no_release => true } do
        log   = action.to_s == 'tail' ? "#{symfony_env_prod}.log" : "#{symfony_env_local}.log"
        run "#{try_sudo} tail -n #{lines} -f #{shared_path}/#{log_path}/#{log}" do |channel, stream, data|
          trap("INT") { puts 'Interupted'; exit 0; }
          puts
          puts "#{channel[:host]}: #{data}"
          break if stream == :err
        end
      end
    end
  end

  namespace :assets do
    desc "Creates a config file (assets_version.yml) withe latest asset version"
    task :update_version, :roles => :app, :except => { :no_release => true } do
      capifony_pretty_print "--> Updating `assets_version`"
      asset_paths = asset_children.map { |p| "#{latest_release}/#{p}" }.join(" ")

      if asset_paths.chomp.empty?
        puts "    No asset paths found, skipped".yellow
      else
        assets_version = capture("find #{asset_paths} -type f -printf '%Ts\\n' | sort -n | tail -1")
        assets_version = assets_version.to_i.to_s(36)
        puts "    Latest assets version: (#{assets_version})"

        file_path = "#{latest_release}/#{app_config_path}/assets_version.yml"
        file_content = "parameters:\n    assets_version: #{assets_version}"
        run "echo '#{file_content}' | #{try_sudo} tee #{file_path}"
        capifony_puts_ok
      end
    end

    desc "Normalizes assets timestamps"
    task :normalize_timestamps, :roles => :app, :except => { :no_release => true } do
      stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
      asset_paths = asset_children.map { |p| "#{latest_release}/#{p}" }.join(" ")

      if asset_paths.chomp.empty?
        puts "    No asset paths found, skipped".yellow
      else
        capifony_pretty_print "--> Normalizing asset timestamps"

        run "#{try_sudo} find #{asset_paths} -exec touch -t #{stamp} {} ';' &> /dev/null || true", :env => { "TZ" => "UTC" }
        capifony_puts_ok
      end
    end

    desc "Installs bundle's assets"
    task :install, :roles => :app, :except => { :no_release => true } do
      capifony_pretty_print "--> Installing bundle's assets"

      install_options = ''

      if true == assets_symlinks then
        install_options += " --symlink"
      end

      if true == assets_relative then
        install_options += " --relative"
      end

      run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{symfony_console} assets:install #{assets_install_path}#{install_options} #{console_options}'"
      capifony_puts_ok
    end
  end

  namespace :assetic do
    desc "Dumps all assets to the filesystem"
    task :dump, :roles => :app,  :except => { :no_release => true } do
      capifony_pretty_print "--> Dumping all assets to the filesystem"

      run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{symfony_console} assetic:dump #{console_options}'"
      capifony_puts_ok
    end
  end

  namespace :vendors do
    [:install, :reinstall, :upgrade].each do |action|
      desc "Runs the bin/vendors script to #{action.to_s} the vendors"
      task action, :roles => :app, :except => { :no_release => true } do
        capifony_pretty_print "--> #{action.to_s.capitalize}ing vendors"

        cmd = action.to_s
        case action
        when :reinstall
          cmd = "install --reinstall"
        when :upgrade
          cmd = "update"
        end

        run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{symfony_vendors} #{cmd}'"
        capifony_puts_ok
      end
    end
  end

  namespace :bootstrap do
    desc "Runs the bin/build_bootstrap script"
    task :build, :roles => :app, :except => { :no_release => true } do
      if use_composer_tmp
        logger.debug "Building bootstrap file in #{$temp_destination}"
        capifony_pretty_print "--> Building bootstrap file in temp location"

        if !File.exists?("#{$temp_destination}/#{build_bootstrap}") && true == use_composer then
          set :build_bootstrap, "vendor/sensio/distribution-bundle/Sensio/Bundle/DistributionBundle/Resources/bin/build_bootstrap.php"
          run_locally "cd #{$temp_destination} && test -f #{build_bootstrap} && #{php_bin} #{build_bootstrap} #{app_path} || echo '#{build_bootstrap} not found, skipped'"
        else
          run_locally "cd #{$temp_destination} && test -f #{build_bootstrap} && #{php_bin} #{build_bootstrap} || echo '#{build_bootstrap} not found, skipped'"
        end
      else
        capifony_pretty_print "--> Building bootstrap file"

        if !remote_file_exists?("#{latest_release}/#{build_bootstrap}") && true == use_composer then
          set :build_bootstrap, "vendor/sensio/distribution-bundle/Sensio/Bundle/DistributionBundle/Resources/bin/build_bootstrap.php"
          run "#{try_sudo} sh -c 'cd #{latest_release} && test -f #{build_bootstrap} && #{php_bin} #{build_bootstrap} #{app_path} || echo '#{build_bootstrap} not found, skipped''"
        else
          run "#{try_sudo} sh -c 'cd #{latest_release} && test -f #{build_bootstrap} && #{php_bin} #{build_bootstrap} || echo '#{build_bootstrap} not found, skipped''"
        end
      end
      capifony_puts_ok
    end
  end

  namespace :composer do
    desc "Gets composer and installs it"
    task :get, :roles => :app, :except => { :no_release => true } do
      install_options = ''
      unless composer_version.empty?
        install_options += " -- --version=#{composer_version}"
      end

      if use_composer_tmp
        # Because we always install to temp location we assume that we download composer every time.
        logger.debug "Downloading composer to #{$temp_destination}"
        capifony_pretty_print "--> Downloading Composer to temp location"
        run_locally "cd #{$temp_destination} && curl -sS https://getcomposer.org/installer | #{php_bin}#{install_options}"
      else
        if !remote_file_exists?("#{latest_release}/composer.phar")
          capifony_pretty_print "--> Downloading Composer"

          run "#{try_sudo} sh -c 'cd #{latest_release} && curl -sS https://getcomposer.org/installer | #{php_bin}#{install_options}'"
        else
          capifony_pretty_print "--> Updating Composer"

          run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} composer.phar self-update #{composer_version}'" \
        end
      end
      capifony_puts_ok
    end

    desc "Updates composer"

    desc "Runs composer to install vendors from composer.lock file"
    task :install, :roles => :app, :except => { :no_release => true } do

      if !composer_bin
        symfony.composer.get
        set :composer_bin, "#{php_bin} composer.phar"
      end

      options = "#{composer_options}"
      if !interactive_mode
        options += " --no-interaction"
      end

      if use_composer_tmp
        logger.debug "Installing composer dependencies to #{$temp_destination}"
        capifony_pretty_print "--> Installing Composer dependencies in temp location"

        tmp_options = options

        if deploy_via == :capifony_copy_local
          # do not run scripts locally: they must be executed on the target server
          tmp_options += " --no-scripts"
        end

        run_locally "cd #{$temp_destination} && SYMFONY_ENV=#{symfony_env_prod} #{composer_bin} install #{tmp_options}"
        capifony_puts_ok
      else
        capifony_pretty_print "--> Installing Composer dependencies"

        command = "#{try_sudo} sh -c 'cd #{latest_release} && SYMFONY_ENV=#{symfony_env_prod} #{composer_bin} install #{options}'"

        if interactive_mode

            input = ''
            print_wizard = false
            close_header = true
            run(command, { :pty => true, :eof => false }) do |channel, stream, data|

                # on normal output
                channel.on_data do |ch, data|

                    # check if composer is waiting for user input
                    print_wizard = data =~ /:[[:space:]]*$/

                    # avoid echoing the user input
                    if input.strip != data.strip and not print_wizard
                        logger.debug data
                    end

                    # if input has been requested
                    if print_wizard

                        if close_header

                            # finalize the info string
                            capifony_puts_ok

                            # and open a new section
                            capifony_pretty_print "--> Updating parameters"
                            puts if logger.level == Logger::IMPORTANT

                            close_header = false
                        end

                        print data

                        # capture the user input
                        input = $stdin.gets

                        # send it to the remote process
                        channel.send_data(input)
                    end
                end

                # on error
                channel.on_extended_data do |ch, data|
                    warn "[err :: #{ch[:server]}] #{data}"
                end
            end

            capifony_pretty_print "--> Parameters updated" if not close_header

        else
            run command
        end

        capifony_puts_ok
      end
    end

    desc "Runs composer to update vendors, and composer.lock file"
    task :update, :roles => :app, :except => { :no_release => true } do
      if !composer_bin
        symfony.composer.get
        set :composer_bin, "#{php_bin} composer.phar"
      end

      options = "#{composer_options}"
      if !interactive_mode
        options += " --no-interaction"
      end

      capifony_pretty_print "--> Updating Composer dependencies"

      command = "#{try_sudo} sh -c 'cd #{latest_release} && SYMFONY_ENV=#{symfony_env_prod} #{composer_bin} update #{options}'"

        if interactive_mode

            input = ''
            print_wizard = false
            close_header = true
            run(command, { :pty => true, :eof => false }) do |channel, stream, data|

                # on normal output
                channel.on_data do |ch, data|

                    # check if composer is waiting for user input
                    print_wizard = data =~ /:[[:space:]]*$/

                    # avoid echoing the user input
                    if input.strip != data.strip and not print_wizard
                        logger.debug data
                    end

                    # if input has been requested
                    if print_wizard

                        if close_header

                            # finalize the info string
                            capifony_puts_ok

                            # and open a new section
                            capifony_pretty_print "--> Updating parameters"
                            puts if logger.level == Logger::IMPORTANT

                            close_header = false
                        end

                        print data

                        # capture the user input
                        input = $stdin.gets

                        # send it to the remote process
                        channel.send_data(input)
                    end
                end

                # on error
                channel.on_extended_data do |ch, data|
                    warn "[err :: #{ch[:server]}] #{data}"
                end
            end

            capifony_pretty_print "--> Parameters updated" if not close_header

        else
            run command
        end

      capifony_puts_ok
    end

    desc "Dumps an optimized autoloader"
    task :dump_autoload, :roles => :app, :except => { :no_release => true } do
      if !composer_bin
        symfony.composer.get
        set :composer_bin, "#{php_bin} composer.phar"
      end

      capifony_pretty_print "--> Dumping an optimized autoloader"
      run "#{try_sudo} sh -c 'cd #{latest_release} && #{composer_bin} dump-autoload #{composer_dump_autoload_options}'"
      capifony_puts_ok
    end

    task :copy_vendors, :except => { :no_release => true } do
      capifony_pretty_print "--> Copying vendors from previous release"

      run "vendorDir=#{current_path}/vendor; if [ -d $vendorDir ] || [ -h $vendorDir ]; then cp -a $vendorDir #{latest_release}; fi;"
      capifony_puts_ok
    end

    # Install composer to temp directory.
    # Not sure if this is required yet.
    desc "Dumps an optimized autoloader"
    task :dump_autoload_temp, :roles => :app, :except => { :no_release => true } do
      if !composer_bin
        symfony.composer.get_temp
        set :composer_bin, "#{php_bin} composer.phar"
      end

      logger.debug "Dumping an optimised autoloader to #{$temp_destination}"
      capifony_pretty_print "--> Dumping an optimized autoloader to temp location"
      run_locally cd "#{$temp_destination} && #{composer_bin} dump-autoload --optimize"
      capifony_puts_ok
    end

  end

  namespace :cache do
    [:clear, :warmup].each do |action|
      desc "Cache #{action.to_s}"
      task action, :roles => :app, :except => { :no_release => true } do
        case action
        when :clear
          capifony_pretty_print "--> Clearing cache"
        when :warmup
          capifony_pretty_print "--> Warming up cache"
        end

        run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{symfony_console} cache:#{action.to_s} #{console_options}'"
        run "#{try_sudo} chmod -R g+w #{latest_release}/#{cache_path}"
        capifony_puts_ok
      end
    end
  end

  namespace :project do
    desc "Clears all non production environment controllers"
    task :clear_controllers, :roles => :app, :except => { :no_release => true } do
      capifony_pretty_print "--> Clear controllers"

      command = "#{try_sudo} sh -c 'cd #{latest_release} && rm -f"
      controllers_to_clear.each do |link|
        command += " #{web_path}/" + link
      end
      run command + "'"

      capifony_puts_ok
    end
  end
end
