load Gem.find_files('capifony.rb').last.to_s
load_paths.push File.expand_path('../', __FILE__)

load 'symfony2/database'
load 'symfony2/doctrine'
load 'symfony2/propel'
load 'symfony2/symfony'
load 'symfony2/web'

require 'colored'

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

# Symfony bin vendors
set :symfony_vendors,       "bin/vendors"

# Symfony build_bootstrap script
set :build_bootstrap,       "bin/build_bootstrap"

# Whether to use composer to install vendors.
# If set to false, it will use the bin/vendors script
set :use_composer,          false

# Whether to update vendors using the configured dependency manager (composer or bin/vendors)
set :update_vendors,        false

# run bin/vendors script in mode (upgrade, install (faster if shared /vendor folder) or reinstall)
set :vendors_mode,          "reinstall"

# Whether to run cache warmup
set :cache_warmup,          true

# Use AsseticBundle
set :dump_assetic_assets,   false

# Assets install
set :assets_install,        true

# Files that need to remain the same between deploys
set :shared_files,          false

# Dirs that need to remain the same between deploys (shared dirs)
set :shared_children,       [log_path, web_path + "/uploads"]

# Asset folders (that need to be timestamped)
set :asset_children,        [web_path + "/css", web_path + "/images", web_path + "/js"]

# Model manager: (doctrine, propel)
set :model_manager,         "doctrine"

# Symfony2 version
set(:symfony_version)       { guess_symfony_version }

# If set to false, it will never ask for confirmations (migrations task for instance)
# Use it carefully, really!
set :interactive_mode,      true

def load_database_config(data, env)
  parameters = YAML::load(data)

  parameters['parameters']
end

def guess_symfony_version
  capture("cd #{latest_release} && #{php_bin} #{symfony_console} --version |cut -d \" \" -f 3")
end

# Be less verbose by default
logger.level = Logger::IMPORTANT

# Overrided Capistrano tasks
namespace :deploy do
  desc "Symlinks static directories and static files that need to remain between deployments"
  task :share_childs do
    if shared_children
      puts "--> Creating symlinks for shared directories".green

      shared_children.each do |link|
        run "mkdir -p #{shared_path}/#{link}"
        run "if [ -d #{release_path}/#{link} ] ; then rm -rf #{release_path}/#{link}; fi"
        run "ln -nfs #{shared_path}/#{link} #{release_path}/#{link}"
      end
    end

    if shared_files
      puts "--> Creating symlinks for shared files".green

      shared_files.each do |link|
        link_dir = File.dirname("#{shared_path}/#{link}")
        run "mkdir -p #{link_dir}"
        run "touch #{shared_path}/#{link}"
        run "ln -nfs #{shared_path}/#{link} #{release_path}/#{link}"
      end
    end
  end

  desc "Updates latest release source path"
  task :finalize_update, :except => { :no_release => true } do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

    puts "--> Creating cache directory".green

    run "if [ -d #{latest_release}/#{cache_path} ] ; then rm -rf #{latest_release}/#{cache_path}; fi"
    run "mkdir -p #{latest_release}/#{cache_path} && chmod -R 0777 #{latest_release}/#{cache_path}"
    run "chmod -R g+w #{latest_release}/#{cache_path}"

    share_childs

    if fetch(:normalize_asset_timestamps, true)
      stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
      asset_paths = asset_children.map { |p| "#{latest_release}/#{p}" }.join(" ")

      puts "--> Normalizing asset timestamps".green

      if asset_paths.chomp.empty?
        puts "    No asset paths found, skipped".yellow
      else
        run "find #{asset_paths} -exec touch -t #{stamp} {} ';'; true", :env => { "TZ" => "UTC" }
      end
    end
  end

  desc "Deploys the application and starts it"
  task :cold do
    update
    start
  end

  desc "Deploys the application and runs the test suite"
  task :testall do
    update_code
    symlink
    run "cd #{latest_release} && phpunit -c #{app_path} src"
  end

  desc "Runs the Symfony2 migrations"
  task :migrate do
    if model_manager == "doctrine"
      symfony.doctrine.migrations.migrate
    else
      if model_manager == "propel"
        puts "    Propel doesn't have built-in migration for now".yellow
      end
    end
  end
end

# After finalizing update:
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
    else
      symfony.bootstrap.build
    end
  end

  if model_manager == "propel"
    symfony.propel.build.model
  end

  if assets_install
    symfony.assets.install  # 2. Publish bundle assets
  end

  if cache_warmup
    symfony.cache.warmup    # 3. Warmup clean cache
  end

  if dump_assetic_assets
    symfony.assetic.dump    # 4. Dump assetic assets
  end
end

before "deploy:update_code" do
  puts "--> Updating code base with #{deploy_via} strategy".green
end

after "deploy:create_symlink" do
  puts "--> Deployed!".green
end
