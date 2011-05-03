load Gem.required_location('capifony', 'capifony.rb')

# Symfony application path
set :app_path,            "app"

# Symfony web path
set :web_path,            "web"

# Use AsseticBundle
set :dump_assetic_assets, false

# Dirs that need to remain the same between deploys (shared dirs)
set :shared_children,     [app_path + "/logs", web_path + "/uploads"]

# Files that need to remain the same between deploys
set :shared_files,        false

# Asset folders (that need to be timestamped)
set :asset_children,      [web_path + "/css", web_path + "/images", web_path + "/js"]

# Symfony2 console file
set :symfony_console,     "console"

namespace :deploy do
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

  desc "Update latest release source path."
  task :finalize_update, :except => { :no_release => true } do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)
    run "if [ -d #{latest_release}/#{app_path}/cache ] ; then rm -rf #{latest_release}/#{app_path}/cache; fi"
    run "mkdir -p #{latest_release}/#{app_path}/cache && chmod -R 0777 #{latest_release}/#{app_path}/cache"

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
  task :testall do
    update_code
    symlink
    run "cd #{latest_release} && phpunit -c #{app_path} src"
  end

  desc "Migrate Symfony2 Doctrine ORM database."
  task :migrate do
    currentVersion = nil
    run "#{php-bin} #{app-path}/#{symfony_console} doctrine:migrations:status" do |ch, stream, out|
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
    puts "Current database version #{currentVersion}"
    
    on_rollback {
      run "#{php-bin} #{app-path}/#{symfony_console} doctrine:migrations:migrate #{currentVersion}" do |ch, stream, out|
        if out =~ /Are you sure you wish to continue/
          ch.send_data("y\r\n")
        end
      end
    }
    
    run "#{php-bin} #{app-path}/#{symfony_console} doctrine:migrations:migrate" do |ch, stream, out|
      if out =~ /Are you sure you wish to continue/
        ch.send_data("y\r\n")
      end
    end
  end
end

namespace :symfony do
  desc "Runs custom symfony task"
  task :default do
    prompt_with_default(:task_arguments, "cache:clear")

    stream "cd #{latest_release} && #{php_bin} #{app_path}/#{symfony_console} #{task_arguments}"
  end

  namespace :assets do
    desc "Install bundle's assets"
    task :install do
      run "cd #{latest_release} && #{php_bin} #{app_path}/#{symfony_console} assets:install #{web_path}"
    end
  end

  namespace :assetic do
    desc "Dumps all assets to the filesystem"
    task :dump do
      run "cd #{latest_release} && #{php_bin} #{app_path}/#{symfony_console} assetic:dump #{web_path} --env=#{symfony_env_prod}"
    end
  end

  namespace :cache do
    desc "Clears project cache."
    task :clear do
      run "cd #{latest_release} && #{php_bin} #{app_path}/#{symfony_console} cache:clear"
    end

    desc "Warms up an empty cache."
    task :warmup do
      run "cd #{latest_release} && #{php_bin} #{app_path}/#{symfony_console} cache:warmup"
    end
  end

  namespace :doctrine do
    namespace :cache do
      desc "Clear all metadata cache for a entity manager."
      task :clear_metadata do
        run "cd #{latest_release} && #{php_bin} #{app_path}/#{symfony_console} doctrine:cache:clear-metadata"
      end

      desc "Clear all query cache for a entity manager."
      task :clear_query do
        run "cd #{latest_release} && #{php_bin} #{app_path}/#{symfony_console} doctrine:cache:clear-query"
      end

      desc "Clear result cache for a entity manager."
      task :clear_result do
        run "cd #{latest_release} && #{php_bin} #{app_path}/#{symfony_console} doctrine:cache:clear-result"
      end
    end

    namespace :database do
      desc "Create the configured databases."
      task :create do
        run "cd #{latest_release} && #{php_bin} #{app_path}/#{symfony_console} doctrine:database:create"
      end

      desc "Drop the configured databases."
      task :drop do
        run "cd #{latest_release} && #{php_bin} #{app_path}/#{symfony_console} doctrine:database:drop"
      end
    end

    namespace :generate do
      desc "Generates proxy classes for entity classes."
      task :hydrators do
        run "cd #{latest_release} && #{php_bin} #{app_path}/#{symfony_console} doctrine:generate:proxies"
      end

      desc "Generate repository classes from your mapping information."
      task :hydrators do
        run "cd #{latest_release} && #{php_bin} #{app_path}/#{symfony_console} doctrine:generate:repositories"
      end
    end

    namespace :schema do
      desc "Processes the schema and either create it directly on EntityManager Storage Connection or generate the SQL output."
      task :create do
        run "cd #{latest_release} && #{php_bin} #{app_path}/#{symfony_console} doctrine:schema:create"
      end

      desc "Drop the complete database schema of EntityManager Storage Connection or generate the corresponding SQL output."
      task :drop do
        run "cd #{latest_release} && #{php_bin} #{app_path}/#{symfony_console} doctrine:schema:drop"
      end
    end

    namespace :migrations do
      desc "Execute a migration to a specified version or the latest available version."
      task :migrate do
        run "cd #{latest_release} && #{php_bin} #{app_path}/#{symfony_console} doctrine:migrations:migrate"
      end

      desc "View the status of a set of migrations."
      task :status do
        run "cd #{latest_release} && #{php_bin} #{app_path}/#{symfony_console} doctrine:migrations:status"
      end
    end

    namespace :mongodb do
      namespace :generate do
        desc "Generates hydrator classes for document classes."
        task :hydrators do
          run "cd #{latest_release} && #{php_bin} #{app_path}/#{symfony_console} doctrine:mongodb:generate:hydrators"
        end

        desc "Generates proxy classes for document classes."
        task :hydrators do
          run "cd #{latest_release} && #{php_bin} #{app_path}/#{symfony_console} doctrine:mongodb:generate:proxies"
        end

        desc "Generates repository classes for document classes."
        task :hydrators do
          run "cd #{latest_release} && #{php_bin} #{app_path}/#{symfony_console} doctrine:mongodb:generate:repositories"
        end
      end

      namespace :schema do
        desc "Allows you to create databases, collections and indexes for your documents."
        task :create do
          run "cd #{latest_release} && #{php_bin} #{app_path}/#{symfony_console} doctrine:mongodb:schema:create"
        end

        desc "Allows you to drop databases, collections and indexes for your documents."
        task :drop do
          run "cd #{latest_release} && #{php_bin} #{app_path}/#{symfony_console} doctrine:mongodb:schema:drop"
        end
      end
    end
  end
end

# After finalizing update:
after "deploy:finalize_update" do
  symfony.cache.warmup                    # 1. Warmup clean cache
  symfony.assets.install                  # 2. Publish bundle assets
  if dump_assetic_assets
    symfony.assetic.dump                  # 3. Dump assetic assets
  end
end
