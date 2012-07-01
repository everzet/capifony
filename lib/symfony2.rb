load Gem.find_files('capifony.rb').last.to_s
load_paths.push File.expand_path('../', __FILE__)

load 'symfony2/output'
load 'symfony2/database'
load 'symfony2/deploy'
load 'symfony2/doctrine'
load 'symfony2/propel'
load 'symfony2/symfony'
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
  msg = "--> Updating code base with #{deploy_via} strategy"

  if logger.level == Logger::IMPORTANT
    pretty_errors
    puts msg
  else
    puts msg.green
  end
end

after "deploy:create_symlink" do
  puts "--> Successfully deployed!".green
end
