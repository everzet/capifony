namespace :symfony do
  namespace :propel do
    desc "Ensure Propel is correctly configured"
    task :setup do
      conf_files_exists = capture("if test -s #{shared_path}/config/propel.ini -a -s #{shared_path}/config/databases.yml ; then echo 'exists' ; fi").strip

      # share childs again (for propel.ini file)
      shared_files << "config/propel.ini"
      deploy.share_childs

      if (!conf_files_exists.eql?("exists"))
        run "cp #{symfony_lib}/plugins/sfPropelPlugin/config/skeleton/config/propel.ini #{shared_path}/config/propel.ini"
        symfony.configure.database
      end
    end

    desc "Migrates database to current version"
    task :migrate do
      puts "propel doesn't have built-in migration for now"
    end

    desc "Generate model lib form and filters classes based on your schema"
    task :build_classes do
      run "php #{latest_release}/symfony propel:build --model --env=#{symfony_env_prod}"
      run "php #{latest_release}/symfony propel:build --forms --env=#{symfony_env_prod}"
      run "php #{latest_release}/symfony propel:build --filters --env=#{symfony_env_prod}"
    end

    desc "Generate code & database based on your schema"
    task :build_all do
      if Capistrano::CLI.ui.agree("Do you really want to rebuild #{symfony_env_prod}'s database? (y/N)")
        run "cd #{latest_release} && #{php_bin} ./symfony propel:build --sql --db --no-confirmation --env=#{symfony_env_prod}"
      end
    end

    desc "Generate code & database based on your schema & load fixtures"
    task :build_all_and_load do
      if Capistrano::CLI.ui.agree("Do you really want to rebuild #{symfony_env_prod}'s database and load #{symfony_env_prod}'s fixtures? (y/N)")
        run "cd #{latest_release} && #{php_bin} ./symfony propel:build --sql --db --and-load --no-confirmation --env=#{symfony_env_prod}"
      end
    end

    desc "Generate sql & database based on your schema"
    task :build_db do
      if Capistrano::CLI.ui.agree("Do you really want to rebuild #{symfony_env_prod}'s database? (y/N)")
        run "cd #{latest_release} && #{php_bin} ./symfony propel:build --sql --db --no-confirmation --env=#{symfony_env_prod}"
      end
    end

    desc "Generate sql & database based on your schema & load fixtures"
    task :build_db_and_load do
      if Capistrano::CLI.ui.agree("Do you really want to rebuild #{symfony_env_prod}'s database and load #{symfony_env_prod}'s fixtures? (y/N)")
        run "cd #{latest_release} && #{php_bin} ./symfony propel:build --sql --db --and-load --no-confirmation --env=#{symfony_env_prod}"
      end
    end
  end
end
