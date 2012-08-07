load Gem.find_files('capifony.rb').last.to_s
load_paths.push File.expand_path('../', __FILE__)

load 'symfony1/database'
load 'symfony1/deploy'
load 'symfony1/doctrine'
load 'symfony1/propel'
load 'symfony1/shared'
load 'symfony1/symfony'
load 'symfony1/web'

require 'yaml'

# Dirs that need to remain the same between deploys (shared dirs)
set :shared_children,   %w(log web/uploads)

# Files that need to remain the same between deploys
set :shared_files,      %w(config/databases.yml)

# Asset folders (that need to be timestamped)
set :asset_children,    %w(web/css web/images web/js)

# Use ORM
set :use_orm,           true

# Symfony default ORM
set(:symfony_orm)       { guess_symfony_orm }

# Default database connection name
set(:connection)        { symfony_orm }

# Symfony lib path
set(:symfony_lib)       { guess_symfony_lib }

# Shared symfony lib
set :use_shared_symfony, false
set :symfony_version,    "1.4.18"

def guess_symfony_orm
  databases = YAML::load(IO.read('config/databases.yml'))

  if databases[symfony_env_local]
    databases[symfony_env_local].keys[0].to_s
  else
    databases['all'].keys[0].to_s
  end
end

def guess_symfony_lib
  symfony_version = capture("cd #{latest_release} && #{php_bin} ./symfony -V")

  /\((.*)\)/.match(symfony_version)[1]
end

def deep_merge(hash1, hash2)

    #There might not be a second has to cascade to 
    if(hash2 == nil)
      return hash1;
    end
    hash1.merge(hash2){|key, subhash1, subhash2|
        if (subhash1.is_a?(Hash) && subhash2.is_a?(Hash))
            next deep_merge(subhash1, subhash2)
        end
        subhash2
    }
end

def load_database_config(data, env)
  db_config = YAML::load(data)

  connections = deep_merge(db_config['all'], db_config[env.to_s])

  db_param = connections[connection]['param']

  dsn = db_param['dsn']
  host = dsn.match(/host=([^;$]+)/)[1] if dsn.match("host")
  port = dsn.match(/port=([0-9]+)/)[1] if dsn.match("port")

  {
    'type'  => /(\w+)\:/.match(db_param['dsn'])[1],
    'user'  => db_param['username'],
    'pass'  => db_param['password'],
    'db'    => dsn.match(/dbname=([^;$]+)/)[1],
    'host'  => host,
    'port'  => port
  }
end

def generate_sql_command(cmd_type, config)
    db_type  = config['type']
    cmd_conf = {
      'mysql' => {
        'create' => "mysqladmin -u #{config['user']} --password='#{config['pass']}' create",
        'dump'   => "mysqldump -u #{config['user']} --password='#{config['pass']}'",
        'drop'   => "mysqladmin -f -u #{config['user']} --password='#{config['pass']}' drop",
        'import' => "mysql -u #{config['user']} --password='#{config['pass']}'"
      },
      'pgsql' => {
        'create' => "createdb -U #{config['user']}",
        'dump'   => "pg_dump -U #{config['user']}",
        'drop'   => "dropdb -U #{config['user']}",
        'import' => "psql -U #{config['user']} --password='#{config['pass']}'"
      }
    }

    cmd = cmd_conf[db_type][cmd_type]
    cmd+= " --host=#{config['host']}" if config['host']
    cmd+= " --port=#{config['port']}" if config['port']
    cmd+= " #{config['db']}"

    cmd
end

# After setup
after "deploy:setup" do
  if use_shared_symfony
    shared.symfony.download
  end
end

# Before finalizing update
before "deploy:finalize_update" do
  if use_shared_symfony
    symfony.create_lib_symlink
  end
end

# After finalizing update:
after "deploy:finalize_update" do
  if use_orm
    symfony.orm.setup                     # 1. Ensure that ORM is configured
    symfony.orm.build_classes             # 2. (Re)build the model
  end
  symfony.cc                              # 3. Clear cache
  symfony.plugin.publish_assets           # 4. Publish plugin assets
  symfony.project.permissions             # 5. Fix project permissions
  if symfony_env_prod.eql?("prod")
    symfony.project.clear_controllers     # 6. Clear controllers in production environment
  end
end
