# =============================================================================
# REQUIRED VARIABLES
# =============================================================================
set :application,   "my_app"
set :domain,        "mydomain.com"
set :deploy_to,     "/var/www/#{domain}"
set :user,          "username"

# =============================================================================
# SCM OPTIONS
# =============================================================================
set :scm, :git                  # or :subversion
set :scm_user,      "username"  # optional
set :scm_password,  "password"  # optional
set :repository,    "http://svn.myrepo.com/#{application}/trunk/"

# =============================================================================
# SSH OPTIONS
# =============================================================================
set :user,          "username"
set :use_sudo,      false       # optional

# =============================================================================
# ROLES
# =============================================================================
# Modify these values to execute tasks on a different server.
role :web, domain
role :app, domain
role :db,  domain,  :primary => true

# =============================================================================
# CAPISTRANO OPTIONS
# =============================================================================
set :keep_releases, 3
set :deploy_via,    :remote_cache