# Core tasks for deploying symfony
load File.expand_path("../tasks/symfony.rake", __FILE__)

# Additional tasks
require "capistrano/symfony/console"
require "capistrano/symfony/composer"
require "capistrano/symfony/assets"

namespace :load do
  task :defaults do
    load 'capistrano/symfony/defaults.rb'
  end
end
