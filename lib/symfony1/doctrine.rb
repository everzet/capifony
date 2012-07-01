namespace :symfony do
  namespace :doctrine do
    desc "Compile doctrine"
    task :compile do
      run "cd #{latest_release} && #{php_bin} ./symfony doctrine:compile"
    end

    desc "Ensure Doctrine is correctly configured"
    task :setup do
      conf_files_exists = capture("if test -s #{shared_path}/config/databases.yml ; then echo 'exists' ; fi").strip
      if (!conf_files_exists.eql?("exists"))
        symfony.configure.database
      end
    end

    desc "Execute a DQL query and view the results"
    task :dql do
      prompt_with_default(:query, "")

      stream "cd #{latest_release} && #{php_bin} ./symfony doctrine:dql #{query} --env=#{symfony_env_prod}"
    end

    desc "Dumps data to the fixtures directory"
    task :data_dump do
      run "cd #{latest_release} && #{php_bin} ./symfony doctrine:data-dump --env=#{symfony_env_prod}"
    end

    desc "Loads YAML fixture data"
    task :data_load do
      run "cd #{latest_release} && #{php_bin} ./symfony doctrine:data-load --env=#{symfony_env_prod}"
    end

    desc "Loads YAML fixture data without remove"
    task :data_load_append do
      run "cd #{latest_release} && #{php_bin} ./symfony doctrine:data-load --append --env=#{symfony_env_prod}"
    end

    desc "Migrates database to current version"
    task :migrate do
      run "cd #{latest_release} && #{php_bin} ./symfony doctrine:migrate --env=#{symfony_env_prod}"
    end

    desc "Generate model lib form and filters classes based on your schema"
    task :build_classes do
      run "cd #{latest_release} && #{php_bin} ./symfony doctrine:build --all-classes --env=#{symfony_env_prod}"
    end

    desc "Generate code & database based on your schema"
    task :build_all do
      if Capistrano::CLI.ui.agree("Do you really want to rebuild #{symfony_env_prod}'s database? (y/N)")
        run "cd #{latest_release} && #{php_bin} ./symfony doctrine:build --all --no-confirmation --env=#{symfony_env_prod}"
      end
    end

    desc "Generate code & database based on your schema & load fixtures"
    task :build_all_and_load do
      if Capistrano::CLI.ui.agree("Do you really want to rebuild #{symfony_env_prod}'s database and load #{symfony_env_prod}'s fixtures? (y/N)")
        run "cd #{latest_release} && #{php_bin} ./symfony doctrine:build --all --and-load --no-confirmation --env=#{symfony_env_prod}"
      end
    end

    desc "Generate sql & database based on your schema"
    task :build_db do
      if Capistrano::CLI.ui.agree("Do you really want to rebuild #{symfony_env_prod}'s database? (y/N)")
        run "cd #{latest_release} && #{php_bin} ./symfony doctrine:build --sql --db --no-confirmation --env=#{symfony_env_prod}"
      end
    end

    desc "Generate sql & database based on your schema & load fixtures"
    task :build_db_and_load do
      if Capistrano::CLI.ui.agree("Do you really want to rebuild #{symfony_env_prod}'s database and load #{symfony_env_prod}'s fixtures? (y/N)")
        run "cd #{latest_release} && #{php_bin} ./symfony doctrine:build --sql --db --and-load --no-confirmation --env=#{symfony_env_prod}"
      end
    end
  end
end
