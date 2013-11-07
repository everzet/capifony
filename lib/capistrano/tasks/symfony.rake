module Capistrano
  class FileNotFound < StandardError
  end
end

def writable_absolute_paths()
  linked_dirs = fetch(:linked_dirs)
  fetch(:writable_dirs).map do |d|
    linked_dirs.include?(d) ? shared_path.join(d) : release_path.join(d)
  end
end

namespace :deploy do
  desc "Create the cache directory"
  task :create_cache_dir do
    on roles :app do
      cache_path = fetch(:cache_path)
      within release_path do
        if test "[ -d #{release_path.join(cache_path)} ]"
          execute :rm, "-rf", cache_path
        end
        execute :mkdir, "-pv", cache_path
      end
    end
  end

  desc "Clear non production controllers"
  task :clear_controllers do
    next unless any? :controllers_to_clear
    on roles :app do
      within release_path.join(fetch(:web_path)) do
        execute :rm, "-f", *fetch(:controllers_to_clear)
      end
    end
  end

  desc <<-DESC
    Sets permissions for writable_dirs folders as described in the Symfony documentation
    (http://symfony.com/doc/master/book/installation.html#configuration-and-setup)
  DESC
  task :set_permissions do
    # next unless fetch :use_set_permissions
    on roles :app do
      writable_absolute_paths().each do |path|
        unless test "[ -d #{path} ]" or test "[ -e #{path} ]"
          msg = "Cannot change permissions: #{path} is not a file or directory"
          warn msg
          fail Capistrano::FileNotFound, msg
        end
      end
    end
    invoke "deploy:set_permissions:#{fetch(:permission_method)}"
  end

  namespace :set_permissions do
    task :chmod do
      next unless any? :writable_dirs
      # check for sudo test
      on roles :app, reject: lambda { |h| h.properties.no_release } do
        writable_dirs = writable_absolute_paths()
        permission = "allow delete,write,append,file_inherit,directory_inherit"

        execute :chmod, "+a", fetch(:user), permissions, *writable_dirs
        execute :chmod, "+a", fetch(:webserver_user), permissions, *writable_dirs
      end
    end
    task :acl do
      next unless any? :writable_dirs
      on roles :app, reject: lambda { |h| h.properties.no_release } do |host|
        writable_dirs = writable_absolute_paths()
        webserver_user = fetch(:webserver_user)
        execute :setfacl, "-R", "-m u:#{host.user}:rwX", "-m u:#{webserver_user}:rwX", *writable_dirs
        execute :setfacl, "-dR", "-m u:#{host.user}:rwx -m u:#{webserver_user}:rwx", *writable_dirs
      end
    end
    task :chown do
      next unless any? :writable_dirs
      next unless fetch :use_sudo, false
      on roles :app, reject: lambda { |h| h.properties.no_release } do
        writable_dirs = writable_absolute_paths()
        execute :chown, "-R", fetch(:webserver_user), *writable_dirs
      end
    end
  end

  namespace :linked_parameters do
    desc "Check if parameters file is linked in shared directory"
    task :check do
      config_file_path = fetch(:app_config_file_path)
      next unless fetch(:linked_files).include?(config_file_path)
      on roles :app do
        # if the file is already in the shared path, we can skip
        if test "[ -f #{shared_path.join(config_file_path)} ]"
          info "Linked parameters file found"
        else
          warn "Linked parameters file is not present"
          # hack, otherwise capistrano errors out for linked files
          # that do not exist
          within shared_path do
            execute :touch, config_file_path
            info "Created empty parameters file: #{shared_path.join(config_file_path)}"
          end
        end
      end
    end

    desc "If using linked parameters and the linked parameters file is empty, copy from the template"
    task :copy_template do
      next unless fetch :use_config_file_template
      config_file_path = fetch(:app_config_file_path)
      next unless fetch(:linked_files).include?(config_file_path)
      on roles :app do
        shared_config_path = shared_path.join(config_file_path)
        template_path = release_path.join(fetch(:app_config_template_path))

        unless test "[ -f #{template_path} ]"
          msg = "Could not find config file template #{template_path}"
          warn msg
          fail Capistrano::FileNotFound, msg
        end

        # only copy template if file is not empty
        unless test "[ -s #{shared_config_path} ]"
          info "Parameters file is empty! Copying parameters file from template"
          execute :cp, template_path, shared_config_path
        end
      end
    end
  end

  # Capistrano will fail without this empty task
  desc "Restart application"
  task :restart do
  end

  task :updating do
    invoke "deploy:create_cache_dir"
    invoke "deploy:set_permissions"
    invoke "deploy:linked_parameters:copy_template"
  end

  before "deploy:starting", "deploy:linked_parameters:check"
  after "deploy:updated", "deploy:clear_controllers"
end
