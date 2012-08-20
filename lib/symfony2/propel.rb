namespace :symfony do
  namespace :propel do
    namespace :database do
      [:create, :drop].each do |action|
        desc "#{action.to_s.capitalize}s the configured databases"
        task action, :roles => :app, :except => { :no_release => true } do
          case action.to_s
          when "create"
            pretty_print "--> Creating databases"
          when "drop"
            pretty_print "--> Dropping databases"
          end

          try_sudo "sh -c 'cd #{latest_release} && #{php_bin} #{symfony_console} propel:database:#{action.to_s} --env=#{symfony_env_prod}'", :once => true
          puts_ok
        end
      end
    end

    namespace :build do
      desc "Builds the Model classes"
      task :model, :roles => :app, :except => { :no_release => true } do
        command = "propel:model:build"
        if /2\.0\.[0-9]+.*/ =~ symfony_version
          command = "propel:build-model"
        end

        pretty_print "--> Generating Propel classes"

        try_sudo "sh -c 'cd #{latest_release} && #{php_bin} #{symfony_console} #{command} --env=#{symfony_env_prod}'"
        puts_ok
      end

      desc "Builds SQL statements"
      task :sql, :roles => :app, :except => { :no_release => true } do
        command = "propel:sql:build"
        if /2\.0\.[0-9]+.*/ =~ symfony_version
          command = "propel:build-sql"
        end

        pretty_print "--> Generating Propel SQL"

        try_sudo "sh -c 'cd #{latest_release} && #{php_bin} #{symfony_console} #{command} --env=#{symfony_env_prod}'"
        puts_ok
      end

      desc "Inserts SQL statements"
      task :sql_load, :roles => :app, :except => { :no_release => true } do
        command = "propel:sql:insert"
        if /2\.0\.[0-9]+.*/ =~ symfony_version
          command = "propel:insert-sql"
        end

        pretty_print "--> Inserting Propel SQL"

        try_sudo "sh -c 'cd #{latest_release} && #{php_bin} #{symfony_console} #{command} --force --env=#{symfony_env_prod}'", :once => true
        puts_ok
      end

      desc "Builds the Model classes, SQL statements and insert SQL"
      task :all_and_load, :roles => :app, :except => { :no_release => true } do
        pretty_print "--> Setting up Propel (classes, SQL)"

        try_sudo "sh -c 'cd #{latest_release} && #{php_bin} #{symfony_console} propel:build --insert-sql --env=#{symfony_env_prod}'"
        puts_ok
      end

      desc "Generates ACLs models"
      task :acl, :roles => :app, :except => { :no_release => true } do
        try_sudo "sh -c 'cd #{latest_release} && #{php_bin} #{symfony_console} propel:acl:init --env=#{symfony_env_prod}'"
      end

      desc "Inserts propel ACL tables"
      task :acl_load, :roles => :app, :except => { :no_release => true } do
        try_sudo "sh -c 'cd #{latest_release} && #{php_bin} #{symfony_console} propel:acl:init --env=#{symfony_env_prod} --force'", :once => true
      end
    end
  end
end
