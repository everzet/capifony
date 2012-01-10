load Gem.find_files('capifony.rb').last.to_s

# Symfony application path
set :app_path,            "app"

# Symfony web path
set :web_path,            "web"

# Symfony console bin
set :symfony_console,     app_path + "/console"

# Symfony log path
set :log_path,            app_path + "/logs"

# Symfony cache path
set :cache_path,          app_path + "/cache"

# Use AsseticBundle
set :dump_assetic_assets, false

# Whether to run the bin/vendors script to update vendors
set :update_vendors, false

# Whether to use composer to install vendors. This needs :update_vendors to false
set :use_composer, false

# run bin/vendors script in mode (upgrade, install (faster if shared /vendor folder) or reinstall)
set :vendors_mode, "reinstall"

# Whether to run cache warmup 
set :cache_warmup, true 

# Assets install
set :assets_install, true 

# Dirs that need to remain the same between deploys (shared dirs)
set :shared_children,     [log_path, web_path + "/uploads"]

# Files that need to remain the same between deploys
set :shared_files,        false

# Asset folders (that need to be timestamped)
set :asset_children,      [web_path + "/css", web_path + "/images", web_path + "/js"]

set :model_manager, "doctrine"
# Or: `propel`

namespace :deploy do
  desc "Symlink static directories and static files that need to remain between deployments."
  task :share_childs, :roles  => [:app]do
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

  desc "Update latest release source path."
  task :finalize_update, :roles  => [:app], :except => { :no_release => true } do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)
    run "if [ -d #{latest_release}/#{cache_path} ] ; then rm -rf #{latest_release}/#{cache_path}; fi"
    run "mkdir -p #{latest_release}/#{cache_path} && chmod -R 0777 #{latest_release}/#{cache_path}"
    run "chmod -R g+w #{latest_release}/#{cache_path}"

    share_childs

    if fetch(:normalize_asset_timestamps, true)
      stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
      asset_paths = asset_children.map { |p| "#{latest_release}/#{p}" }.join(" ")
      run "find #{asset_paths} -exec touch -t #{stamp} {} ';'; true", :env => { "TZ" => "UTC" }
    end
  end

  desc "Deploy the application and start it."
  task :cold do
    update
    start
  end

  desc "Deploy the application and run the test suite."
  task :testall, :roles  => [:app] do
    update_code
    symlink
    run "cd #{latest_release} && phpunit -c #{app_path} src"
  end

  desc "Migrate Symfony2 Doctrine ORM database."
  task :migrate, :roles  => [:app] do
    currentVersion = nil
    run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:migrations:status --env=#{symfony_env_prod}" do |ch, stream, out|
      if stream == :out and out =~ /Current Version:[^$]+\(([0-9]+)\)/
        currentVersion = Regexp.last_match(1)
      end
      if stream == :out and out =~ /Current Version:\s*0\s*$/
        currentVersion = 0
      end
    end

    if currentVersion == nil
      raise "Could not find current database migration version"
    end
    puts "Current database version: #{currentVersion}"

    on_rollback {
      if Capistrano::CLI.ui.agree("Do you really want to migrate #{symfony_env_prod}'s database back to version #{currentVersion}? (y/N)")
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:migrations:migrate #{currentVersion} --env=#{symfony_env_prod} --no-interaction"
      end
    }

    if Capistrano::CLI.ui.agree("Do you really want to migrate #{symfony_env_prod}'s database? (y/N)")
      run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:migrations:migrate --env=#{symfony_env_prod} --no-interaction"
    end
  end
end

namespace :symfony do
  desc "Runs custom symfony task"
  task :default, :roles  => [:app] do
    prompt_with_default(:task_arguments, "cache:clear")

    stream "cd #{latest_release} && #{php_bin} #{symfony_console} #{task_arguments} --env=#{symfony_env_prod}"
  end

  namespace :assets do
    desc "Install bundle's assets"
    task :install, :roles => [:web] do
      run "cd #{latest_release} && #{php_bin} #{symfony_console} assets:install #{web_path} --env=#{symfony_env_prod}"
    end
  end

  namespace :assetic do
    desc "Dumps all assets to the filesystem"
    task :dump, :roles  => [:web] do
      run "cd #{latest_release} && #{php_bin} #{symfony_console} assetic:dump #{web_path} --env=#{symfony_env_prod} --no-debug"
    end
  end

  namespace :vendors do
    desc "Runs the bin/vendors script to install the vendors (fast if already installed)"
    task :install, :roles  => [:app] do
      run "cd #{latest_release} && #{php_bin} bin/vendors install"
    end

    desc "Runs the bin/vendors script to reinstall the vendors"
    task :reinstall, :roles  => [:app] do
      run "cd #{latest_release} && #{php_bin} bin/vendors install --reinstall"
    end

    desc "Runs the bin/vendors script to upgrade the vendors"
    task :upgrade, :roles  => [:app] do
      run "cd #{latest_release} && #{php_bin} bin/vendors update"
    end
  end

  namespace :composer do
    desc "Runs composer install to install vendors from composer.lock file"
    task :install do
      run "cd #{latest_release} && #{php_bin} composer.phar install"
    end
  end

  namespace :cache do
    desc "Clears project cache."
    task :clear, :roles  => [:app] do
      run "cd #{latest_release} && #{php_bin} #{symfony_console} cache:clear --env=#{symfony_env_prod}"
      run "chmod -R g+w #{latest_release}/#{cache_path}"
    end

    desc "Warms up an empty cache."
    task :warmup, :roles  => [:app] do
      run "cd #{latest_release} && #{php_bin} #{symfony_console} cache:warmup --env=#{symfony_env_prod}"
      run "chmod -R g+w #{latest_release}/#{cache_path}"
    end
  end

  namespace :doctrine do
    namespace :cache do
      desc "Clear all metadata cache for a entity manager."
      task :clear_metadata, :roles  => [:app] do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:cache:clear-metadata --env=#{symfony_env_prod}"
      end

      desc "Clear all query cache for a entity manager."
      task :clear_query, :roles  => [:app] do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:cache:clear-query --env=#{symfony_env_prod}"
      end

      desc "Clear result cache for a entity manager."
      task :clear_result, :roles  => [:app] do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:cache:clear-result --env=#{symfony_env_prod}"
      end
    end

    namespace :database do
      desc "Create the configured databases."
      task :create, :roles  => [:app] do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:database:create --env=#{symfony_env_prod}"
      end

      desc "Drop the configured databases."
      task :drop, :roles  => [:app] do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:database:drop --env=#{symfony_env_prod}"
      end
    end

    namespace :generate do
      desc "Generates proxy classes for entity classes."
      task :hydrators, :roles  => [:app] do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:generate:proxies --env=#{symfony_env_prod}"
      end

      desc "Generate repository classes from your mapping information."
      task :hydrators, :roles  => [:app] do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:generate:repositories --env=#{symfony_env_prod}"
      end
    end

    namespace :schema do
      desc "Processes the schema and either create it directly on EntityManager Storage Connection or generate the SQL output."
      task :create, :roles  => [:app] do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:schema:create --env=#{symfony_env_prod}"
      end

      desc "Drop the complete database schema of EntityManager Storage Connection or generate the corresponding SQL output."
      task :drop, :roles  => [:app] do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:schema:drop --env=#{symfony_env_prod}"
      end
    end

    namespace :migrations do
      desc "Execute a migration to a specified version or the latest available version."
      task :migrate, :roles  => [:app] do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:migrations:migrate --env=#{symfony_env_prod}"
      end

      desc "View the status of a set of migrations."
      task :status, :roles  => [:app] do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:migrations:status --env=#{symfony_env_prod}"
      end
    end

    namespace :mongodb do
      namespace :generate do
        desc "Generates hydrator classes for document classes."
        task :hydrators, :roles  => [:app] do
          run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:mongodb:generate:hydrators --env=#{symfony_env_prod}"
        end

        desc "Generates proxy classes for document classes."
        task :hydrators, :roles  => [:app] do
          run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:mongodb:generate:proxies --env=#{symfony_env_prod}"
        end

        desc "Generates repository classes for document classes."
        task :hydrators, :roles  => [:app] do
          run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:mongodb:generate:repositories --env=#{symfony_env_prod}"
        end
      end

      namespace :schema do
        desc "Allows you to create databases, collections and indexes for your documents."
        task :create, :roles  => [:app] do
          run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:mongodb:schema:create --env=#{symfony_env_prod}"
        end

        desc "Allows you to drop databases, collections and indexes for your documents."
        task :drop, :roles  => [:app] do
          run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:mongodb:schema:drop --env=#{symfony_env_prod}"
        end
      end
    end
  end

  namespace :init do
    desc "Mounts ACL tables in the database"
    task :acl do
      run "cd #{latest_release} && #{php_bin} #{symfony_console} init:acl --env=#{symfony_env_prod}"
    end
  end

    
  namespace :propel do
    namespace :database do
      desc "Create the configured databases."
      task :create, :roles  => [:app] do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} propel:database:create --env=#{symfony_env_prod}"
      end

      desc "Drop the configured databases."
      task :drop, :roles  => [:app] do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} propel:database:drop --env=#{symfony_env_prod}"
      end
    end

    namespace :build do
      desc "Build the Model classes."
      task :model, :roles  => [:app] do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} propel:build-model --env=#{symfony_env_prod}"
      end

      desc "Build SQL statements."
      task :sql, :roles  => [:app] do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} propel:build-sql --env=#{symfony_env_prod}"
      end

      desc "Build the Model classes, SQL statements and insert SQL."
      task :all_and_load, :roles  => [:app] do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} propel:build --insert-sql --env=#{symfony_env_prod}"
      end
    end
  end
end

# After finalizing update:
after "deploy:finalize_update" do
  if update_vendors
    # share the children first (to get the vendor symlink)
    deploy.share_childs
    vendors_mode.chomp # To remove trailing whiteline
    case vendors_mode
     when "upgrade" then symfony.vendors.upgrade
     when "install" then symfony.vendors.install
     when "reinstall" then symfony.vendors.reinstall
    end
  elsif use_composer
    symfony.composer.install
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

  if model_manager == "propel"
    symfony.propel.build.model
  end
end
