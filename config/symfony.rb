_cset(:host) { abort "Please specify the hostname, set :host, 'localhost'" }

_cset(:db_orm) { abort "Please specify the DB ORM, set :db_orm, 'Doctrine'" }
_cset(:db_dsn) { abort "Please specify the DB DSN, set :db_dsn, 'mysql:host=localhost;dbname=example'" }
_cset(:db_user) { abort "Please specify the DB User, set :db_user, 'root'" }
_cset(:db_pass) { abort "Please specify the DB Pass, set :db_orm, '$ecr3t'" }

role :app, host

namespace :git do
  task :ignore do
    File.open('.gitignore', 'w') do |file|
      file.puts <<-IGNORE
Capfile
config/symfony.rb
config/ProjectConfiguration.class.php
config/databases.yml
web/sf*
cache/*
plugins/.*
log/*
      IGNORE
    end
  end

  task :init do
    run_locally 'git init'
    self.ignore
  end

  task :setup_remote, :roles => :app do
    rep = "#{repository}#{application}.git"
    run <<-CMD
      mkdir -p #{releases_path} &&
      mkdir -p #{rep} &&
      cd #{rep} &&
      git --bare init
    CMD

    run_locally "git remote add origin ssh://#{host}/#{rep}"
    run_locally "git push origin master:refs/heads/master"
    run_locally "git config branch.master.remote origin"
    run_locally "git config branch.master.merge master"
    run_locally "git config push.default current"

    run <<-CMD
      mkdir -p #{releases_path} &&
      cd #{releases_path} &&
      git clone #{rep}
    CMD
  end
end

namespace :symfony do
  def get_rem_path
    "#{releases_path}#{application}"
  end

  def get_sf_orm
    case db_orm
      when 'Propel'   then 'sfDoctrine'
      when 'Doctrine' then 'sfPropel'
      else 'sfPropel'
    end
  end

  def get_sf_project_configuration sf_lib_path
    <<-CODE
<?php

require_once '#{sf_lib_path}/autoload/sfCoreAutoload.class.php';
sfCoreAutoload::register();

class ProjectConfiguration extends sfProjectConfiguration
{
public function setup()
{
  // for compatibility / remove and enable only the plugins you want
  \$this->enableAllPluginsExcept(array('#{self.get_sf_orm}Plugin', 'sfCompat10Plugin'));
}
}
    CODE
  end

  def get_sf_setup_cmds
    Array[
      'mkdir -p cache',
      'mkdir -p log',
      'symfony plugin:publish-assets',
      'symfony project:permissions',
      'symfony cache:clear'
    ]
  end

  task :test_remote, :roles => :app do
    upload('config/check_configuration.php', "#{symfony.get_rem_path}/check_configuration.php")
    output = capture("php #{symfony.get_rem_path}/check_configuration.php")
    run "rm #{symfony.get_rem_path}/check_configuration.php"
    puts output
  end

  task :setup do
    sf_version  = `cd config && symfony -V && cd ..`
    sf_lib_path = /.*\((.*)\).*/.match(sf_version)[1]

    File.open('config/ProjectConfiguration.class.php', 'w') do |file|
      file.puts self.get_sf_project_configuration(sf_lib_path)
    end

    self.get_sf_setup_cmds.each do |cmd|
      run_locally cmd
    end
  end

  task :setup_remote, :roles => :app do
    sf_version  = capture('symfony -V')
    sf_lib_path = /.*\((.*)\).*/.match(sf_version)[1]

    put(self.get_sf_project_configuration(sf_lib_path), "#{symfony.get_rem_path}/config/ProjectConfiguration.class.php")

    run <<-CMD
      cd #{symfony.get_rem_path}/ &&
      #{self.get_sf_setup_cmds.join(' && ')}
    CMD
  end
end

namespace :db do
  task :get_dump, :roles => :app do
    run "#{symfony.get_rem_path}/symfony doctrine:data-dump"
    run "cd #{symfony.get_rem_path}/ && git commit -am 'dump from #{Time.now.utc.strftime("%Y%m%d%H%M.%S")}' && git push"
    run_locally 'git pull'
    run_locally 'symfony doctrine:data-load'
  end

  task :push, :roles => :app do
    run_locally 'symfony doctrine:data-dump'
    run_locally "git commit -am 'dump from #{Time.now.utc.strftime("%Y%m%d%H%M.%S")}' && git push"
    run "cd #{symfony.get_rem_path}/ && git pull"
    run "#{symfony.get_rem_path}/symfony doctrine:data-load"
  end

  task :setup_remote, :roles => :app do
    run <<-CODE
      cd #{symfony.get_rem_path}/ && symfony configure:database --name=#{db_orm} --class=#{symfony.get_sf_orm}Database '#{db_dsn}' #{db_user} #{db_pass}
    CODE
  end
end

namespace :deploy do
  task :setup do
    git.setup_remote
    symfony.setup_remote
    db.setup_remote
  end

  task :default, :roles => :app do
    run "cd #{symfony.get_rem_path}/ && git pull && symfony cache:clear"
  end
end
