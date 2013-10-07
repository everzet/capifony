set :application, "your application name"
set :repo_url, "git@github.com:org/your_repository.git"
# set :deploy_to, "/var/www/app_path"

# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# set :scm, :git

# set :format, :pretty
# set :log_level, :debug
# set :pty, true

# set :linked_files, %w{app/config/parameters.yml}
# set :linked_dirs, %w{app/logs web/uploads}
# set :writable_dirs %w{app/logs app/cache}
# set :permission_method, :acl

# set :keep_releases, 5

namespace :deploy do
  after :finishing, 'deploy:cleanup'
end
