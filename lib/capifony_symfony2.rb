# encoding: utf-8
require 'capistrano'
require 'capistrano/maintenance'
require 'colored'
require 'fileutils'
require 'inifile'
require 'yaml'
require 'zlib'

module Capifony
  module Symfony2
    def self.load_into(configuration)
      configuration.load do

        load_paths.push File.expand_path('../', __FILE__)
        load 'capifony'
        load 'symfony2/symfony'
        load 'symfony2/database'
        load 'symfony2/deploy'
        load 'symfony2/doctrine'
        load 'symfony2/propel'
        load 'symfony2/web'

        # Symfony application path
        set :app_path,              "app"

        # Symfony web path
        set :web_path,              "web"

        # Symfony console bin
        set :symfony_console,       app_path + "/console"

        # Symfony log path
        set :log_path,              app_path + "/logs"

        # Symfony cache path
        set :cache_path,            app_path + "/cache"

        # Symfony config file path
        set :app_config_path,       app_path + "/config"

        # Symfony config file (parameters.(ini|yml|etc...)
        set :app_config_file,       "parameters.yml"

        # Symfony bin vendors
        set :symfony_vendors,       "bin/vendors"

        # Symfony build_bootstrap script
        set :build_bootstrap,       "bin/build_bootstrap"

        # Whether to use composer to install vendors.
        # If set to false, it will use the bin/vendors script
        set :use_composer,          false

        # Path to composer binary
        # If set to false, Capifony will download/install composer
        set :composer_bin,          false

        # Options to pass to composer when installing/updating
        set :composer_options,      "--no-scripts --verbose --prefer-dist"

        # Whether to update vendors using the configured dependency manager (composer or bin/vendors)
        set :update_vendors,        false

        # run bin/vendors script in mode (upgrade, install (faster if shared /vendor folder) or reinstall)
        set :vendors_mode,          "reinstall"

        # Copy vendors from previous release
        set :copy_vendors,          false

        # Whether to run cache warmup
        set :cache_warmup,          true

        # Use AsseticBundle
        set :dump_assetic_assets,   false

        # Assets install
        set :assets_install,        true
        set :assets_symlinks,       false
        set :assets_relative,       false

        # Whether to update `assets_version` in `config.yml`
        set :update_assets_version, false

        # Need to clear *_dev controllers
        set :clear_controllers,     true

        # Controllers to clear
        set :controllers_to_clear, ['app_*.php']

        # Files that need to remain the same between deploys
        set :shared_files,          false

        # Dirs that need to remain the same between deploys (shared dirs)
        set :shared_children,       [log_path, web_path + "/uploads"]

        # Asset folders (that need to be timestamped)
        set :asset_children,        [web_path + "/css", web_path + "/images", web_path + "/js"]

        # Dirs that need to be writable by the HTTP Server (i.e. cache, log dirs)
        set :writable_dirs,         [log_path, cache_path]

        # Name used by the Web Server (i.e. www-data for Apache)
        set :webserver_user,        "www-data"

        # Method used to set permissions (:chmod, :acl, or :chown)
        set :permission_method,     false

        # Execute set permissions
        set :use_set_permissions,   false

        # Model manager: (doctrine, propel)
        set :model_manager,         "doctrine"

        # Symfony2 version
        set(:symfony_version)       { guess_symfony_version }

        # If set to false, it will never ask for confirmations (migrations task for instance)
        # Use it carefully, really!
        set :interactive_mode,      true

        def load_database_config(data, env)
          read_parameters(data)['parameters']
        end

        def read_parameters(data)
          if '.ini' === File.extname(app_config_file) then
            File.readable?(data) ? IniFile::load(data) : IniFile.new(data)
          else
            YAML::load(data)
          end
        end

        def guess_symfony_version
          capture("cd #{latest_release} && #{php_bin} #{symfony_console} --version |cut -d \" \" -f 3")
        end

        def remote_file_exists?(full_path)
          'true' == capture("if [ -e #{full_path} ]; then echo 'true'; fi").strip
        end

        def remote_command_exists?(command)
          'true' == capture("if [ -x \"$(which #{command})\" ]; then echo 'true'; fi").strip
        end

        STDOUT.sync
        $error = false
        $pretty_errors_defined = false

        # Be less verbose by default
        logger.level = Capistrano::Logger::IMPORTANT

        def capifony_pretty_print(msg)
          if logger.level == Capistrano::Logger::IMPORTANT
            pretty_errors

            msg = msg.slice(0, 57)
            msg << '.' * (60 - msg.size)
            print msg
          else
            puts msg.green
          end
        end

        def capifony_puts_ok
          if logger.level == Capistrano::Logger::IMPORTANT && !$error
            puts '✔'.green
          end

          $error = false
        end

        def pretty_errors
          if !$pretty_errors_defined
            $pretty_errors_defined = true

            class << $stderr
              @@firstLine = true
              alias _write write

              def write(s)
                if @@firstLine
                  s = '✘' << "\n" << s
                  @@firstLine = false
                end

                _write(s.red)
                $error = true
              end
            end
          end
        end

        ["symfony:composer:install", "symfony:composer:update"].each do |action|
          before action do
            if copy_vendors
              symfony.composer.copy_vendors
            end
          end
        end

        after "deploy:finalize_update" do
          if use_composer
            if update_vendors
              symfony.composer.update
            else
              symfony.composer.install
            end
          else
            if update_vendors
              vendors_mode.chomp # To remove trailing whiteline
              case vendors_mode
              when "upgrade" then symfony.vendors.upgrade
              when "install" then symfony.vendors.install
              when "reinstall" then symfony.vendors.reinstall
              end
            end
          end

          symfony.bootstrap.build

          if use_set_permissions
            symfony.deploy.set_permissions
          end

          if model_manager == "propel"
            symfony.propel.build.model
          end

          if use_composer
            symfony.composer.dump_autoload
          end

          if assets_install
            symfony.assets.install          # Publish bundle assets
          end

          if update_assets_version
            symfony.assets.update_version   # Update `assets_version`
          end

          if cache_warmup
            symfony.cache.warmup            # Warmup clean cache
          end

          if dump_assetic_assets
            symfony.assetic.dump            # Dump assetic assets
          end

          if clear_controllers
            # If clear_controllers is an array set controllers_to_clear,
            # else use the default value 'app_*.php'
            if clear_controllers.is_a? Array
              set(:controllers_to_clear) { clear_controllers }
            end
            symfony.project.clear_controllers
          end
        end

        before "deploy:update_code" do
          msg = "--> Updating code base with #{deploy_via} strategy"

          if logger.level == Capistrano::Logger::IMPORTANT
            pretty_errors
            puts msg
          else
            puts msg.green
          end
        end

        after "deploy:create_symlink" do
          puts "--> Successfully deployed!".green
        end
      end

    end
  end
end

if Capistrano::Configuration.instance
  Capifony::Symfony2.load_into(Capistrano::Configuration.instance)
end
