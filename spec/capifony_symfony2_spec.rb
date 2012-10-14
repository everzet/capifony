require 'spec_helper'
require 'symfony2'

describe Capifony::Symfony2, "loaded into a configuration" do
  before do
    @configuration = Capistrano::Configuration.new
    @configuration.extend(Capistrano::Spec::ConfigurationExtension)

    Capifony::Symfony2.load_into(@configuration)
  end

  subject { @configuration }

  it "defines global variables" do
    @configuration.fetch(:symfony_env_local).should == 'dev'
    @configuration.fetch(:symfony_env_prod).should == 'prod'
    @configuration.fetch(:php_bin).should == 'php'
    @configuration.fetch(:remote_tmp_dir).should == '/tmp'
  end

  it "defines Symfony2 related variables" do
    @configuration.fetch(:app_path).should == 'app'
    @configuration.fetch(:web_path).should == 'web'
    @configuration.fetch(:symfony_console).should == 'app/console'
    @configuration.fetch(:log_path).should == 'app/logs'
    @configuration.fetch(:cache_path).should == 'app/cache'
    @configuration.fetch(:shared_children).should == ['app/logs', 'web/uploads']
    @configuration.fetch(:asset_children).should == ['web/css', 'web/images', 'web/js']
    @configuration.fetch(:writable_dirs).should == ['app/logs', 'app/cache']
  end

  it "defines a symfony namespace" do
    @configuration.find_task('symfony:cache:clear').should_not == nil
  end

  context "symfony:cache:clear" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.set :latest_release, '/var/www/releases/20120927'

      @configuration.find_and_execute_task('symfony:cache:clear')
    end

    it "runs the Symfony2 command successfully and sets permissions to the cache directory" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console cache:clear --env=prod\'')
      @configuration.should have_run(' chmod -R g+w /var/www/releases/20120927/app/cache')
    end
  end
end
