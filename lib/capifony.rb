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
    run "#{try_sudo} mkdir -p #{dirs.join(' ')}"
    run "#{try_sudo} chmod g+w #{dirs.join(' ')}" if fetch(:group_writable, true)
  end

  desc <<-DESC
    Copies your project to the remote servers. This is the first stage \
    of any deployment; moving your updated code and assets to the deployment \
    servers. You will rarely call this task directly, however; instead, you \
    should call the `deploy' task (to do a complete deploy) or the `update' \
    task (if you want to perform the `restart' task separately).
    You will need to make sure you set the :scm variable to the source \
    control software you are using (it defaults to :subversion), and the \
    :deploy_via variable to the strategy you want to use to deploy (it \
    defaults to :checkout).
  DESC
  task :update_code, :except => { :no_release => true } do
    on_rollback { run "#{try_sudo} rm -rf #{release_path}; true" }
    strategy.deploy!
    finalize_update
  end
end
