#!/usr/bin/env php
<?php

if (count($argv) < 3)
{
  die('USAGE: ./setup db_user db_password' . "\n");
}

$version = exec('symfony -V');
$matches = array();

preg_match('/.*\((.*)\).*/', $version, &$matches);

file_put_contents('config/ProjectConfiguration.class.php', "<?php

require_once '" . $matches[1] . "/autoload/sfCoreAutoload.class.php';
sfCoreAutoload::register();

class ProjectConfiguration extends sfProjectConfiguration
{
  public function setup()
  {
    // for compatibility / remove and enable only the plugins you want
    \$this->enableAllPluginsExcept(array('sfPropelPlugin', 'sfCompat10Plugin'));
  }
}
");
file_put_contents('config/databases.yml', "all:
  doctrine:
    class: sfDoctrineDatabase
    param:
      dsn: 'mysql:host=localhost;dbname=everzet'
      username: " . $argv[1] . "
      password: " . $argv[2] . "
");

exec('mkdir cache');
exec('mkdir log');
exec('./symfony plugin:publish-assets');
exec('./symfony project:permissions');
exec('./symfony cache:clear');
