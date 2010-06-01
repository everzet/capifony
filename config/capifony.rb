set :app_symlinks, %w{uploads} # dirs that need to remain the same between deploys

# =============================================================================
# OVERWRITE CAPISTRANO TASKS
# =============================================================================
namespace :deploy do
  desc "Overwrite the start task to set the permissions on the project."
  task :start do
    run "php #{release_path}/symfony project:permissions"
    run "php #{release_path}/symfony doctrine:build --all --and-load --no-confirmation"
  end
  
  desc "Overwrite the restart task because symfony doesn't need it."
  task :restart do ; end
  
  desc "Overwrite the stop task because symfony doesn't need it."
  task :stop do ; end
  
  desc "Customize migrate task to work with symfony."
  task :migrate do
    run "php #{latest_release}/symfony doctrine:migrate --env=prod"
  end
  
  desc "Symlink static directories that need to remain between deployments."
  task :create_dirs do
    if app_symlinks
      app_symlinks.each do |link|
        run "mkdir -p #{shared_path}/system/#{link}"
        run "ln -nfs #{shared_path}/system/#{link} #{release_path}/web/#{link}"
      end
    end
  end
  
  desc "Customize the finalize_update task to work with symfony."
  task :finalize_update, :except => { :no_release => true } do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

    run <<-CMD
      rm -rf #{latest_release}/log #{latest_release}/cache &&
      mkdir -p #{shared_path}/cache &&
      ln -s #{shared_path}/log #{latest_release}/log &&
      ln -s #{shared_path}/cache #{latest_release}/cache
    CMD

    if fetch(:normalize_asset_timestamps, true)
      stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
      asset_paths = %w(css images js).map { |p| "#{latest_release}/web/#{p}" }.join(" ")
      run "find #{asset_paths} -exec touch -t #{stamp} {} ';'; true", :env => { "TZ" => "UTC" }
    end
  end

  desc "Need to overwrite the deploy:cold task so it doesn't try to run the migrations."
  task :cold do
    update
    start
  end
  
  desc "Task to run all the tests for the application."
  task :symfony_test do
    run "php #{latest_release}/symfony test:all"
  end

  desc "Task used in conjunction with the symfony_test task to rebuild the database."
  task :rebuild do
    run "php #{latest_release}/symfony doctrine:build --all --and-load --env=test --no-confirmation"
  end
  
  desc "Deploy the application and run the test suite."
  task :testall do
    update_code
    symlink
    rebuild
    symfony_test
  end
end

namespace :symlink do
  desc "Symlink the database"
  task :db do
    run "ln -nfs #{shared_path}/databases.yml #{release_path}/config/databases.yml"
  end
end

namespace :symfony do
  desc "Task to clear the cache on deploy."
  task :clear_cache do
    run "php #{release_path}/symfony cache:clear"
  end
end

after "deploy:finalize_update", "symlink:db", "deploy:create_dirs", "symfony:clear_cache"