namespace :symfony do
  namespace :doctrine do
    namespace :cache do
      desc "Clears all metadata cache for a entity manager"
      task :clear_metadata, :roles => :app, :except => { :no_release => true } do
        pretty_print "--> Clearing Doctrine metadata cache"

        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:cache:clear-metadata --env=#{symfony_env_prod}"
        puts_ok
      end

      desc "Clears all query cache for a entity manager"
      task :clear_query, :roles => :app, :except => { :no_release => true } do
        pretty_print "--> Clearing Doctrine query cache"

        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:cache:clear-query --env=#{symfony_env_prod}"
        puts_ok
      end

      desc "Clears result cache for a entity manager"
      task :clear_result, :roles => :app, :except => { :no_release => true } do
        pretty_print "--> Clearing Doctrine result cache"

        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:cache:clear-result --env=#{symfony_env_prod}"
        puts_ok
      end
    end

    namespace :database do
      [:create, :drop].each do |action|
        desc "#{action.to_s.capitalize}s the configured databases"
        task action, :roles => :app, :except => { :no_release => true } do
          case action.to_s
          when "create"
            pretty_print "--> Creating databases"
          when "drop"
            pretty_print "--> Dropping databases"
          end

          run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:database:#{action.to_s} --env=#{symfony_env_prod}", :once => true
          puts_ok
        end
      end
    end

    namespace :schema do
      desc "Processes the schema and either create it directly on EntityManager Storage Connection or generate the SQL output"
      task :create, :roles => :app, :except => { :no_release => true } do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:schema:create --env=#{symfony_env_prod}", :once => true
      end

      desc "Drops the complete database schema of EntityManager Storage Connection or generate the corresponding SQL output"
      task :drop, :roles => :app, :except => { :no_release => true } do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:schema:drop --env=#{symfony_env_prod}", :once => true
      end
    end

    namespace :migrations do
      desc "Executes a migration to a specified version or the latest available version"
      task :migrate, :roles => :app, :except => { :no_release => true } do
        currentVersion = nil
        run "cd #{latest_release} && #{php_bin} #{symfony_console} --no-ansi doctrine:migrations:status --env=#{symfony_env_prod}", :once => true do |ch, stream, out|
          if stream == :out and out =~ /Current Version:.+\(([\w]+)\)/
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
            run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:migrations:migrate #{currentVersion} --env=#{symfony_env_prod} --no-interaction", :once => true
          end
        }

        if !interactive_mode || Capistrano::CLI.ui.agree("Do you really want to migrate #{symfony_env_prod}'s database? (y/N)")
          run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:migrations:migrate --env=#{symfony_env_prod} --no-interaction", :once => true
        end
      end

      desc "Views the status of a set of migrations"
      task :status, :roles => :app, :except => { :no_release => true } do
        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:migrations:status --env=#{symfony_env_prod}", :once => true
      end
    end

    namespace :mongodb do
      [:create, :update, :drop].each do |action|
        namespace :schema do
          desc "Allows you to #{action.to_s} databases, collections and indexes for your documents"
          task action, :roles => :app, :except => { :no_release => true } do
            pretty_print "--> Executing MongoDB schema #{action.to_s}"

            run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:mongodb:schema:#{action.to_s} --env=#{symfony_env_prod}", :once => true
            puts_ok
          end
        end

        namespace :indexes do
          desc "Allows you to #{action.to_s} indexes *only* for your documents"
          task action, :roles => :app do
            pretty_print "--> Executing MongoDB indexes #{action.to_s}"

            run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:mongodb:schema:#{action.to_s} --index --env=#{symfony_env_prod}", :once => true
            puts_ok
          end
        end
      end
    end
  end

  namespace :init do
    desc "Mounts ACL tables in the database"
    task :acl, :roles => :app, :except => { :no_release => true } do
      pretty_print "--> Mounting Doctrine ACL tables"

      run "cd #{latest_release} && #{php_bin} #{symfony_console} init:acl --env=#{symfony_env_prod}", :once => true
      puts_ok
    end
  end
end
