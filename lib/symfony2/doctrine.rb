namespace :symfony do
  namespace :doctrine do
    namespace :cache do
      desc "Clears all metadata cache for a entity manager"
      task :clear_metadata do
        pretty_print "--> Clearing Doctrine metadata cache"

        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:cache:clear-metadata --env=#{symfony_env_prod}"
        puts_ok
      end

      desc "Clears all query cache for a entity manager"
      task :clear_query do
        pretty_print "--> Clearing Doctrine query cache"

        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:cache:clear-query --env=#{symfony_env_prod}"
        puts_ok
      end

      desc "Clears result cache for a entity manager"
      task :clear_result do
        pretty_print "--> Clearing Doctrine result cache"

        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:cache:clear-result --env=#{symfony_env_prod}"
        puts_ok
      end
    end

    namespace :database do
      desc "Creates the configured databases"
      task :create do
        pretty_print "--> Creating databases"

        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:database:create --env=#{symfony_env_prod}"
        puts_ok
      end

      desc "Drops the configured databases"
      task :drop do
        pretty_print "--> Dropping databases"

        run "cd #{latest_release} && #{php_bin} #{symfony_console} doctrine:database:drop --env=#{symfony_env_prod}"
        puts_ok
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
      pretty_print "--> Mounting Doctrine ACL tables"

      run "cd #{latest_release} && #{php_bin} #{symfony_console} init:acl --env=#{symfony_env_prod}"
      puts_ok
    end
  end
end
