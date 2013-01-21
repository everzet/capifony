require 'rubygems'
require 'bundler/setup'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'capistrano-spec'
require 'capistrano/cli'
require 'rspec'
require 'rspec/autorun'

RSpec.configure do |config|
  config.include Capistrano::Spec::Matchers
  config.include Capistrano::Spec::Helpers
end

require 'capifony_symfony2'

# Overriding these methods avoids a dirty console output
def capifony_pretty_print(msg)
end

def capifony_puts_ok
end
