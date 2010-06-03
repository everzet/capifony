# =============================================================================
# REQUIRED VARIABLES
# =============================================================================
set :application,   "my_app"
set :domain,        "#{application}.com"
set :deploy_to,     "/var/www/#{domain}"

# =============================================================================
# SCM OPTIONS
# =============================================================================
set :scm,           :git        # or :subversion
set :repository,    "#{domain}:/reps/#{application}.git"
#set :scm_user,      "username"  # optional
#set :scm_password,  "password"  # optional

# =============================================================================
# ROLES
# =============================================================================
# Modify these values to execute tasks on a different server.
role :web,          domain
role :app,          domain
role :db,           domain, :primary => true

# =============================================================================
# CAPISTRANO OPTIONS
# =============================================================================
set :keep_releases, 3
set :deploy_via,    :remote_cache

# =============================================================================
# SSH OPTIONS (if hasn't got ssh-key for server)
# =============================================================================
#set :user,          "username"
#set :use_sudo,      false       # optional