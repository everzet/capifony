# Overrided Capistrano tasks
namespace :deploy do
  desc <<-DESC
    Sets permissions for writable_dirs folders as described in the Symfony documentation
    (http://symfony.com/doc/master/book/installation.html#configuration-and-setup)
  DESC
  task :set_permissions, :roles => :app, :except => { :no_release => true } do
    if writable_dirs && permission_method
      dirs = []

      writable_dirs.each do |link|
        if shared_children && shared_children.include?(link)
          absolute_link = shared_path + "/" + link
        else
          absolute_link = latest_release + "/" + link
        end

        dirs << absolute_link
      end

      methods = {
        :chmod => [
          "chmod +a \"#{user} allow delete,write,append,file_inherit,directory_inherit\" %s",
          "chmod +a \"#{webserver_user} allow delete,write,append,file_inherit,directory_inherit\" %s"
        ],
        :acl   => [
          "setfacl -R -m u:#{user}:rwx -m u:#{webserver_user}:rwx %s",
          "setfacl -dR -m u:#{user}:rwx -m u:#{webserver_user}:rwx %s"
        ],
        :chown => ["chown #{webserver_user} %s"]
      }

      if methods[permission_method]
        capifony_pretty_print "--> Setting permissions"

        if fetch(:use_sudo, false)
          methods[permission_method].each do |cmd|
            sudo sprintf(cmd, dirs.join(' '))
          end
        elsif permission_method == :chown
          puts "    You can't use chown method without sudoing"
        else
          dirs.each do |dir|
            is_owner = (capture "`echo stat #{dir} -c %U`").chomp == user
            if is_owner && permission_method != :chown
              methods[permission_method].each do |cmd|
                try_sudo sprintf(cmd, dir)
              end
            else
              puts "    #{dir} is not owned by #{user} or you are using 'chown' method without ':use_sudo'"
            end
          end
        end
        capifony_puts_ok
      else
        puts "    Permission method '#{permission_method}' does not exist.".yellow
      end
    end
  end

  desc "Symlinks static directories and static files that need to remain between deployments"
  task :share_childs, :roles => :app, :except => { :no_release => true } do
    if shared_children
      capifony_pretty_print "--> Creating symlinks for shared directories"

      shared_children.each do |link|
        run "#{try_sudo} mkdir -p #{shared_path}/#{link}"
        run "#{try_sudo} sh -c 'if [ -d #{release_path}/#{link} ] ; then rm -rf #{release_path}/#{link}; fi'"
        run "#{try_sudo} ln -nfs #{shared_path}/#{link} #{release_path}/#{link}"
      end

      capifony_puts_ok
    end

    if shared_files
      capifony_pretty_print "--> Creating symlinks for shared files"

      shared_files.each do |link|
        link_dir = File.dirname("#{shared_path}/#{link}")
        run "#{try_sudo} mkdir -p #{link_dir}"
        run "#{try_sudo} touch #{shared_path}/#{link}"
        run "#{try_sudo} ln -nfs #{shared_path}/#{link} #{release_path}/#{link}"
      end

      capifony_puts_ok
    end
  end

  desc "Updates latest release source path"
  task :finalize_update, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

    capifony_pretty_print "--> Creating cache directory"

    run "#{try_sudo} sh -c 'if [ -d #{latest_release}/#{cache_path} ] ; then rm -rf #{latest_release}/#{cache_path}; fi'"
    run "#{try_sudo} sh -c 'mkdir -p #{latest_release}/#{cache_path} && chmod -R 0777 #{latest_release}/#{cache_path}'"
    run "#{try_sudo} chmod -R g+w #{latest_release}/#{cache_path}"

    capifony_puts_ok

    share_childs

    if fetch(:normalize_asset_timestamps, true)
      stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
      asset_paths = asset_children.map { |p| "#{latest_release}/#{p}" }.join(" ")

      if asset_paths.chomp.empty?
        puts "    No asset paths found, skipped".yellow
      else
        capifony_pretty_print "--> Normalizing asset timestamps"

        run "#{try_sudo} find #{asset_paths} -exec touch -t #{stamp} {} ';' &> /dev/null || true", :env => { "TZ" => "UTC" }
        capifony_puts_ok
      end
    end
  end

  desc <<-DESC
    Deploys and starts a `cold' application. This is useful if you have not \
    deployed your application before.
  DESC
  task :cold, :roles => :app, :except => { :no_release => true } do
    update
    start
  end

  desc "Deploys the application and runs the test suite"
  task :test_all, :roles => :app, :except => { :no_release => true } do
    update_code
    create_symlink
    run "#{try_sudo} sh -c 'cd #{latest_release} && phpunit -c #{app_path} src'"
  end

  desc "Runs the Symfony2 migrations"
  task :migrate, :roles => :app, :except => { :no_release => true }, :only => { :primary => true } do
    if model_manager == "doctrine"
      symfony.doctrine.migrations.migrate
    else
      if model_manager == "propel"
        puts "    Propel doesn't have built-in migration for now".yellow
      end
    end
  end

  desc "Drops :deploy_to directory"
  task :drop do
    if Capistrano::CLI.ui.ask("Are you sure remove #{deploy_to} (y/n)") == 'y'
      run "#{try_sudo} rm -rf #{deploy_to}"
    end
  end
end
