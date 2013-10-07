load File.expand_path("../symfony/defaults.rb", __FILE__)
# Core tasks for deploying symfony
load File.expand_path("../tasks/symfony.rake", __FILE__)

# Additional tasks
require "capistrano/symfony/console"
require "capistrano/symfony/composer"
require "capistrano/symfony/assets"
