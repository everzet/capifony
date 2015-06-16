require 'spec_helper'

describe "Capifony::Symfony2 - web" do
  before do
    @configuration = Capistrano::Configuration.new
    @configuration.extend(Capistrano::Spec::ConfigurationExtension)

    @configuration.set :latest_release,               '/var/www/releases/20120927'
    @configuration.set :previous_release,             '/var/www/releases/20120920'
    @configuration.set :current_path,                 '/var/www/current'
    @configuration.set :maintenance_template_path,    'maintenance.template.html'
    @configuration.set :maintenance_basename,         'maintenance'
    @configuration.set :try_sudo,                     ''

    Capifony::Symfony2.load_into(@configuration)
  end

  subject { @configuration }

  it "defines deploy web enable and disable tasks" do
    @configuration.find_task('deploy:web:enable').should_not == nil
    @configuration.find_task('deploy:web:disable').should_not == nil
  end
end
