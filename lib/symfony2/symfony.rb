namespace :symfony do
  desc "Runs custom symfony command"
  task :default do
    prompt_with_default(:task_arguments, "cache:clear")

    stream "cd #{latest_release} && #{php_bin} #{symfony_console} #{task_arguments} --env=#{symfony_env_prod}"
  end

  namespace :assets do
    desc "Installs bundle's assets"
    task :install do
      pretty_print "--> Installing bundle's assets"

      run "cd #{latest_release} && #{php_bin} #{symfony_console} assets:install #{web_path} --env=#{symfony_env_prod}"
      puts_ok
    end
  end

  namespace :assetic do
    desc "Dumps all assets to the filesystem"
    task :dump do
      puts "--> Dumping all assets to the filesystem"

      run "cd #{latest_release} && #{php_bin} #{symfony_console} assetic:dump --env=#{symfony_env_prod} --no-debug"
      puts_ok
    end
  end

  namespace :vendors do
    desc "Runs the bin/vendors script to install the vendors (fast if already installed)"
    task :install do
      pretty_print "--> Installing vendors"

      run "cd #{latest_release} && #{php_bin} #{symfony_vendors} install"
      puts_ok
    end

    desc "Runs the bin/vendors script to reinstall the vendors"
    task :reinstall do
      pretty_print "--> Reinstalling vendors"

      run "cd #{latest_release} && #{php_bin} #{symfony_vendors} install --reinstall"
      puts_ok
    end

    desc "Runs the bin/vendors script to upgrade the vendors"
    task :upgrade do
      pretty_print "--> Upgrading vendors"

      run "cd #{latest_release} && #{php_bin} #{symfony_vendors} update"
      puts_ok
    end
  end

  namespace :bootstrap do
    desc "Runs the bin/build_bootstrap script"
    task :build do
      pretty_print "--> Building bootstrap file"

      run "cd #{latest_release} && test -f #{build_bootstrap} && #{php_bin} #{build_bootstrap} || echo '#{build_bootstrap} not found, skipped'"
      puts_ok
    end
  end

  namespace :composer do
    desc "Gets composer and installs it"
    task :get do
        pretty_print "--> Downloading Composer"

        run "cd #{latest_release} && curl -s http://getcomposer.org/installer | #{php_bin}"
        puts_ok
    end

    desc "Runs composer to install vendors from composer.lock file"
    task :install do
      if !File.exist?("#{latest_release}/composer.phar")
        symfony.composer.get
      end

      pretty_print "--> Installing Composer dependencies"

      run "cd #{latest_release} && #{php_bin} composer.phar install -v"
      puts_ok
    end

    desc "Runs composer to update vendors, and composer.lock file"
    task :update do
      if !File.exist?("#{latest_release}/composer.phar")
        symfony.composer.get
      end

      pretty_print "--> Updating Composer dependencies"

      run "cd #{latest_release} && #{php_bin} composer.phar update -v"
      puts_ok
    end
  end

  namespace :cache do
    desc "Clears cache"
    task :clear do
      pretty_print "--> Clearing cache"

      run "cd #{latest_release} && #{php_bin} #{symfony_console} cache:clear --env=#{symfony_env_prod}"
      run "chmod -R g+w #{latest_release}/#{cache_path}"
      puts_ok
    end

    desc "Warms up an empty cache"
    task :warmup do
      pretty_print "--> Warming up cache"

      run "cd #{latest_release} && #{php_bin} #{symfony_console} cache:warmup --env=#{symfony_env_prod}"
      run "chmod -R g+w #{latest_release}/#{cache_path}"
      puts_ok
    end
  end
end
