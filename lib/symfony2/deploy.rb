# Overrided Capistrano tasks
namespace :deploy do
  desc "Symlinks static directories and static files that need to remain between deployments"
  task :share_childs, :except => { :no_release => true } do
    if shared_children
      pretty_print "--> Creating symlinks for shared directories"

      shared_children.each do |link|
        run "mkdir -p #{shared_path}/#{link}"
        run "if [ -d #{release_path}/#{link} ] ; then rm -rf #{release_path}/#{link}; fi"
        run "ln -nfs #{shared_path}/#{link} #{release_path}/#{link}"
      end

      puts_ok
    end

    if shared_files
      pretty_print "--> Creating symlinks for shared files"

      shared_files.each do |link|
        link_dir = File.dirname("#{shared_path}/#{link}")
        run "mkdir -p #{link_dir}"
        run "touch #{shared_path}/#{link}"
        run "ln -nfs #{shared_path}/#{link} #{release_path}/#{link}"
      end

      puts_ok
    end
  end

  desc "Updates latest release source path"
  task :finalize_update, :except => { :no_release => true } do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

    pretty_print "--> Creating cache directory"

    run "if [ -d #{latest_release}/#{cache_path} ] ; then rm -rf #{latest_release}/#{cache_path}; fi"
    run "mkdir -p #{latest_release}/#{cache_path} && chmod -R 0777 #{latest_release}/#{cache_path}"
    run "chmod -R g+w #{latest_release}/#{cache_path}"

    puts_ok

    share_childs

    if fetch(:normalize_asset_timestamps, true)
      stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
      asset_paths = asset_children.map { |p| "#{latest_release}/#{p}" }.join(" ")

      if asset_paths.chomp.empty?
        puts "    No asset paths found, skipped".yellow
      else
        pretty_print "--> Normalizing asset timestamps"

        run "find #{asset_paths} -exec touch -t #{stamp} {} ';'; true", :env => { "TZ" => "UTC" }
        puts_ok
      end
    end
  end

  desc <<-DESC
    Deploys and starts a `cold' application. This is useful if you have not \
    deployed your application before.
  DESC
  task :cold do
    update
    start
  end

  desc "Deploys the application and runs the test suite"
  task :testall, :except => { :no_release => true } do
    update_code
    create_symlink
    run "cd #{latest_release} && phpunit -c #{app_path} src"
  end

  desc "Runs the Symfony2 migrations"
  task :migrate do
    if model_manager == "doctrine"
      symfony.doctrine.migrations.migrate
    else
      if model_manager == "propel"
        puts "    Propel doesn't have built-in migration for now".yellow
      end
    end
  end
end
