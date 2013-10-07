# Symfony console bin
set :symfony_console, fetch(:app_path) + "/console"

load File.expand_path("../../tasks/symfony_console.rake", __FILE__)
