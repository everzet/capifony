load Gem.find_files('capifony.rb').last.to_s

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

namespace :database do
  namespace :dump do
    desc "Dumps remote database"
    task :remote do
      filename  = "#{application}.remote_dump.#{Time.now.to_i}.sql.gz"
      file      = "/tmp/#{filename}"
      sqlfile   = "#{application}_dump.sql"
      config    = ""

      run "cat #{current_path}/app/config/parameters.yml" do |ch, st, data|
        config = load_database_config data, symfony_env_prod
      end

      case config['database_driver']
      when "pdo_mysql", "mysql"
        run "mysqldump -u#{config['database_user']} --password='#{config['database_password']}' #{config['database_name']} | gzip -c > #{file}" do |ch, stream, data|
          puts data
        end
      when "pdo_pgsql", "pgsql"
        run "pg_dump -U #{config['database_user']} #{config['database_name']} | gzip -c > #{file}" do |ch, stream, data|
          puts data
        end
      end

      require "fileutils"
      FileUtils.mkdir_p("backups")
      get file, "backups/#{filename}"
      begin
        FileUtils.ln_sf(filename, "backups/#{application}.remote_dump.latest.sql.gz")
      rescue NotImplementedError # hack for windows which doesnt support symlinks
        FileUtils.cp_r("backups/#{filename}", "backups/#{application}.remote_dump.latest.sql.gz")
      end
      run "rm #{file}"
    end

    desc "Dumps local database"
    task :local do
      filename  = "#{application}.local_dump.#{Time.now.to_i}.sql.gz"
      tmpfile   = "backups/#{application}_dump_tmp.sql"
      file      = "backups/#{filename}"
      config    = load_database_config IO.read('app/config/parameters.yml'), symfony_env_local
      sqlfile   = "#{application}_dump.sql"

      require "fileutils"
      FileUtils::mkdir_p("backups")
      case config['database_driver']
      when "pdo_mysql", "mysql"
        `mysqldump -u#{config['database_user']} --password=\"#{config['database_password']}\" #{config['database_name']} > #{tmpfile}`
      when "pdo_pgsql", "pgsql"
        `pg_dump -U #{config['database_user']} #{config['database_name']} > #{tmpfile}`
      end

      File.open(tmpfile, "r+") do |f|
        gz = Zlib::GzipWriter.open(file)
        while (line = f.gets)
          gz << line
        end
        gz.flush
        gz.close
      end

      begin
        FileUtils.ln_sf(filename, "backups/#{application}.local_dump.latest.sql.gz")
      rescue NotImplementedError # hack for windows which doesnt support symlinks
        FileUtils.cp_r("backups/#{filename}", "backups/#{application}.local_dump.latest.sql.gz")
      end
      FileUtils.rm(tmpfile)
    end
  end

  namespace :move do
    desc "Dumps remote database, downloads it to local, and populates here"
    task :to_local do
      filename  = "#{application}.remote_dump.latest.sql.gz"
      config    = load_database_config IO.read('app/config/parameters.yml'), symfony_env_local
      sqlfile   = "#{application}_dump.sql"

      database.dump.remote

      require "fileutils"
      f = File.new("backups/#{sqlfile}", "a+")
      require "zlib"
      gz = Zlib::GzipReader.new(File.open("backups/#{filename}", "r"))
      f << gz.read
      f.close

      case config['database_driver']
      when "pdo_mysql", "mysql"
        `mysql -u#{config['database_user']} --password=\"#{config['database_password']}\" #{config['database_name']} < backups/#{sqlfile}`
      when "pdo_pgsql", "pgsql"
        `psql -U #{config['database_user']} --password=\"#{config['database_password']}\" #{config['database_name']} < backups/#{sqlfile}`
      end
      FileUtils.rm("backups/#{sqlfile}")
    end

    desc "Dumps local database, loads it to remote, and populates there"
    task :to_remote do
      filename  = "#{application}.local_dump.latest.sql.gz"
      file      = "backups/#{filename}"
      sqlfile   = "#{application}_dump.sql"
      config    = ""

      database.dump.local

      upload(file, "/tmp/#{filename}", :via => :scp)
      run "gunzip -c /tmp/#{filename} > /tmp/#{sqlfile}"

      run "cat #{shared_path}/config/databases.yml" do |ch, st, data|
        config = load_database_config data, symfony_env_prod
      end

      case config['database_driver']
      when "pdo_mysql", "mysql"
        run "mysql -u#{config['database_user']} --password='#{config['database_password']}' #{config['database_name']} < /tmp/#{sqlfile}" do |ch, stream, data|
          puts data
        end
      when "pdo_pgsql", "pgsql"
        run "psql -U #{config['database_user']} --password='#{config['database_password']}' #{config['database_name']} < /tmp/#{sqlfile}" do |ch, stream, data|
          puts data
        end
      end

      run "rm /tmp/#{filename}"
      run "rm /tmp/#{sqlfile}"
    end
  end
end

namespace :deploy do
  desc "Symlinks static directories and static files that need to remain between deployments"
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

  desc "Updates latest release source path"
  task :finalize_update, :except => { :no_release => true } do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)
    run "if [ -d #{latest_release}/#{cache_path} ] ; then rm -rf #{latest_release}/#{cache_path}; fi"
    run "mkdir -p #{latest_release}/#{cache_path} && chmod -R 0777 #{latest_release}/#{cache_path}"
    run "chmod -R g+w #{latest_release}/#{cache_path}"

    share_childs

    if fetch(:normalize_asset_timestamps, true)
      stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
      asset_paths = asset_children.map { |p| "#{latest_release}/#{p}" }.join(" ")

      if asset_paths.chomp.empty?
        puts "    No asset paths found, skipped"
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
        puts "    Propel doesn't have built-in migration for now"
      end
    end
  end
end

namespace :symfony do
  desc "Runs custom symfony command"
  task :default do
    prompt_with_default(:task_arguments, "cache:clear")

    stream "cd #{latest_release} && #{php_bin} #{symfony_console} #{task_arguments} --env=#{symfony_env_prod}"
  end

  namespace :assets do
    desc "Installs bundle's assets"
    task :install do
      run "cd #{latest_release} && #{php_bin} #{symfony_console} assets:install #{web_path} --env=#{symfony_env_prod}"
    end
  end

  namespace :assetic do
    desc "Dumps all assets to the filesystem"
    task :dump do
      run "cd #{latest_release} && #{php_bin} #{symfony_console} assetic:dump --env=#{symfony_env_prod} --no-debug"
    end
  end

  namespace :vendors do
    desc "Runs the bin/vendors script to install the vendors (fast if already installed)"
    task :install do
      run "cd #{latest_release} && #{php_bin} #{symfony_vendors} install"
    end

    desc "Runs the bin/vendors script to reinstall the vendors"
    task :reinstall do
      run "cd #{latest_release} && #{php_bin} #{symfony_vendors} install --reinstall"
    end

    desc "Runs the bin/vendors script to upgrade the vendors"
    task :upgrade do
      run "cd #{latest_release} && #{php_bin} #{symfony_vendors} update"
    end
  end

  namespace :bootstrap do
    desc "Runs the bin/build_bootstrap script"
    task :build do
      run "cd #{latest_release} && test -f #{build_bootstrap} && #{php_bin} #{build_bootstrap} || echo '#{build_bootstrap} not found, skipped'"
    end
  end

  namespace :composer do
    desc "Gets composer and installs it"
    task :get do
        run "cd #{latest_release} && curl -s http://getcomposer.org/installer | #{php_bin}"
    end

    desc "Runs composer to install vendors from composer.lock file"
    task :install do
      if !File.exist?("#{latest_release}/composer.phar")
        symfony.composer.get
      end

      run "cd #{latest_release} && #{php_bin} composer.phar install"
    end

    desc "Runs composer to update vendors, and composer.lock file"
    task :update do
      if !File.exist?("#{latest_release}/composer.phar")
        symfony.composer.get
      end

      run "cd #{latest_release} && #{php_bin} composer.phar update"
    end
  end

  namespace :cache do
    desc "Clears project cache"
    task :clear do
      run "cd #{latest_release} && #{php_bin} #{symfony_console} cache:clear --env=#{symfony_env_prod}"
      run "chmod -R g+w #{latest_release}/#{cache_path}"
    end

    desc "Warms up an empty cache"
    task :warmup do
      run "cd #{latest_release} && #{php_bin} #{symfony_console} cache:warmup --env=#{symfony_env_prod}"
      run "chmod -R g+w #{latest_release}/#{cache_path}"
    end
  end

  namespace :doctrine do
    namespace :cache do
      desc "Clears all metadata cache for a entity manager"
      task :clear_metadata do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:cache:clear-metadata --env=#{symfony_env_prod}"
      end

      desc "Clears all query cache for a entity manager"
      task :clear_query do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:cache:clear-query --env=#{symfony_env_prod}"
      end

      desc "Clears result cache for a entity manager"
      task :clear_result do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:cache:clear-result --env=#{symfony_env_prod}"
      end
    end

    namespace :database do
      desc "Creates the configured databases"
      task :create do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:database:create --env=#{symfony_env_prod}"
      end

      desc "Drops the configured databases"
      task :drop do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:database:drop --env=#{symfony_env_prod}"
      end
    end

    namespace :generate do
      desc "Generates proxy classes for entity classes"
      task :hydrators do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:generate:proxies --env=#{symfony_env_prod}"
      end

      desc "Generates repository classes from your mapping information"
      task :hydrators do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:generate:repositories --env=#{symfony_env_prod}"
      end
    end

    namespace :schema do
      desc "Processes the schema and either create it directly on EntityManager Storage Connection or generate the SQL output"
      task :create do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:schema:create --env=#{symfony_env_prod}"
      end

      desc "Drops the complete database schema of EntityManager Storage Connection or generate the corresponding SQL output"
      task :drop do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:schema:drop --env=#{symfony_env_prod}"
      end
    end

    namespace :migrations do
      desc "Executes a migration to a specified version or the latest available version"
      task :migrate do
        currentVersion = nil
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:migrations:status --env=#{symfony_env_prod}" do |ch, stream, out|
          if stream == :out and out =~ /Current Version:[^$]+\(([\w]+)\)/
            currentVersion = Regexp.last_match(1)
          end
          if stream == :out and out =~ /Current Version:\s*0\s*$/
            currentVersion = 0
          end
        end

        if currentVersion == nil
          raise "Could not find current database migration version"
        end
        puts "    Current database version: #{currentVersion}"

        on_rollback {
          if !interactive_mode || Capistrano::CLI.ui.agree("Do you really want to migrate #{symfony_env_prod}'s database back to version #{currentVersion}? (y/N)")
            run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:migrations:migrate #{currentVersion} --env=#{symfony_env_prod} --no-interaction"
          end
        }

        if !interactive_mode || Capistrano::CLI.ui.agree("Do you really want to migrate #{symfony_env_prod}'s database? (y/N)")
          run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:migrations:migrate --env=#{symfony_env_prod} --no-interaction"
        end
      end

      desc "Views the status of a set of migrations"
      task :status do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:migrations:status --env=#{symfony_env_prod}"
      end
    end

    namespace :mongodb do
      namespace :generate do
        desc "Generates hydrator classes for document classes"
        task :hydrators do
          run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:mongodb:generate:hydrators --env=#{symfony_env_prod}"
        end

        desc "Generates proxy classes for document classes"
        task :hydrators do
          run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:mongodb:generate:proxies --env=#{symfony_env_prod}"
        end

        desc "Generates repository classes for document classes"
        task :hydrators do
          run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:mongodb:generate:repositories --env=#{symfony_env_prod}"
        end
      end

      namespace :schema do
        desc "Allows you to create databases, collections and indexes for your documents"
        task :create do
          run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:mongodb:schema:create --env=#{symfony_env_prod}"
        end

        desc "Allows you to drop databases, collections and indexes for your documents"
        task :drop do
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
      desc "Creates the configured databases"
      task :create do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} propel:database:create --env=#{symfony_env_prod}"
      end

      desc "Drops the configured databases"
      task :drop do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} propel:database:drop --env=#{symfony_env_prod}"
      end
    end

    namespace :build do
      desc "Builds the Model classes"
      task :model do
        command = "propel:model:build"
        if /2\.0\.[0-9]+.*/ =~ symfony_version
          command = "propel:build-model"
        end

        run "cd #{latest_release} && #{php_bin} #{symfony_console} #{command} --env=#{symfony_env_prod}"
      end

      desc "Builds SQL statements"
      task :sql do
        command = "propel:sql:build"
        if /2\.0\.[0-9]+.*/ =~ symfony_version
          command = "propel:build-sql"
        end

        run "cd #{latest_release} && #{php_bin} #{symfony_console} #{command} --env=#{symfony_env_prod}"
      end

      desc "Builds the Model classes, SQL statements and insert SQL"
      task :all_and_load do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} propel:build --insert-sql --env=#{symfony_env_prod}"
      end

      desc "Generates ACLs models"
      task :acl do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} propel:acl:init --env=#{symfony_env_prod}"
      end

      desc "Inserts propel ACL tables"
      task :acl_load do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} propel:acl:init --env=#{symfony_env_prod} --force"
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
