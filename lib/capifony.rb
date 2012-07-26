# Symfony environment on local
set :symfony_env_local, "dev"

# Symfony environment
set :symfony_env_prod,  "prod"

# PHP binary to execute
set :php_bin,           "php"

set :remote_tmp_dir,    "/tmp"

def prompt_with_default(var, default, &block)
  set(var) do
    Capistrano::CLI.ui.ask("#{var} [#{default}] : ", &block)
  end
  set var, default if eval("#{var.to_s}.empty?")
end

namespace :deploy do
  desc <<-DESC
    Blank task exists as a hook into which to install your own environment \
    specific behaviour.
  DESC
  task :start, :roles => :app, :except => { :no_release => true } do
    # Empty Task to overload with your platform specifics
  end

  desc <<-DESC
    Blank task exists as a hook into which to install your own environment \
    specific behaviour.
  DESC
  task :stop, :roles => :app, :except => { :no_release => true } do
    # Empty Task to overload with your platform specifics
  end

  desc <<-DESC
    Blank task exists as a hook into which to install your own environment \
    specific behaviour.
  DESC
  task :restart, :roles => :app, :except => { :no_release => true } do
    # Empty Task to overload with your platform specifics
  end

  desc <<-DESC
    Prepares one or more servers for deployment. Before you can use any \
    of the Capistrano deployment tasks with your project, you will need to \
    make sure all of your servers have been prepared with `cap deploy:setup'. When \
    you add a new server to your cluster, you can easily run the setup task \
    on just that server by specifying the HOSTS environment variable:

      $ cap HOSTS=new.server.com deploy:setup

    It is safe to run this task on servers that have already been set up; it \
    will not destroy any deployed revisions or data.
  DESC
  task :setup, :roles => :app, :except => { :no_release => true } do
    dirs = [deploy_to, releases_path, shared_path]
    run "mkdir -p #{dirs.join(' ')}"
    run "chmod g+w #{dirs.join(' ')}" if fetch(:group_writable, true)
  end
end
