require 'spec_helper'

describe "Capifony::Symfony2 - symfony" do
  before do
    @configuration = Capistrano::Configuration.new
    @configuration.extend(Capistrano::Spec::ConfigurationExtension)

    # Common parameters
    @configuration.set :latest_release, '/var/www/releases/20120927'
    @configuration.set :shared_path,    '/var/www/shared'

    Capifony::Symfony2.load_into(@configuration)
  end

  subject { @configuration }

  it "defines a symfony namespace" do
    @configuration.find_task('symfony').should_not == nil
  end

  it "defines symfony:logs tasks" do
    @configuration.find_task('symfony:logs:tail').should_not == nil
    @configuration.find_task('symfony:logs:tail_dev').should_not == nil
  end

  context "symfony:logs:tail" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:logs:tail')
    end

    it "runs the tail command with default parameters" do
      @configuration.should have_run(' tail -n 50 -f /var/www/shared/app/logs/prod.log')
    end
  end

  context "symfony:logs:tail_dev" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:logs:tail_dev')
    end

    it "runs the tail command with default parameters" do
      @configuration.should have_run(' tail -n 50 -f /var/www/shared/app/logs/dev.log')
    end
  end

  it "defines symfony:assets tasks" do
    @configuration.find_task('symfony:assets:update_version').should_not == nil
    @configuration.find_task('symfony:assets:install').should_not == nil
  end

  context "symfony:assets:install" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:assets:install')
    end

    it "runs the Symfony2 command without options" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console assets:install web --env=prod\'')
    end
  end

  context "symfony:assets:install" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.set :assets_symlinks, true
      @configuration.find_and_execute_task('symfony:assets:install')
    end

    it "runs the Symfony2 command with symlink option" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console assets:install web --symlink --env=prod\'')
    end
  end

  context "symfony:assets:install" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.set :assets_relative, true
      @configuration.find_and_execute_task('symfony:assets:install')
    end

    it "runs the Symfony2 command with relative option" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console assets:install web --relative --env=prod\'')
    end
  end

  context "symfony:assets:install" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.set :assets_symlinks, true
      @configuration.set :assets_relative, true
      @configuration.find_and_execute_task('symfony:assets:install')
    end

    it "runs the Symfony2 command with both symlink and relative options" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console assets:install web --symlink --relative --env=prod\'')
    end
  end

  context "symfony:assets:install with sudo" do
    before do
      @configuration.set :try_sudo, 'sudo'
      @configuration.find_and_execute_task('symfony:assets:install')
    end

    it "runs the Symfony2 command with sudo" do
      @configuration.should have_run('sudo sh -c \'cd /var/www/releases/20120927 && php app/console assets:install web --env=prod\'')
    end
  end

  it "defines symfony:assetic tasks" do
    @configuration.find_task('symfony:assetic:dump').should_not == nil
  end

  context "symfony:assetic:dump" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:assetic:dump')
    end

    it "runs the Symfony2 command" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console assetic:dump --env=prod --no-debug\'')
    end
  end

  context "symfony:assetic:dump with sudo" do
    before do
      @configuration.set :try_sudo, 'sudo'
      @configuration.find_and_execute_task('symfony:assetic:dump')
    end

    it "runs the Symfony2 command" do
      @configuration.should have_run('sudo sh -c \'cd /var/www/releases/20120927 && php app/console assetic:dump --env=prod --no-debug\'')
    end
  end

  it "defines symfony:vendors tasks" do
    @configuration.find_task('symfony:vendors:install').should_not == nil
    @configuration.find_task('symfony:vendors:reinstall').should_not == nil
    @configuration.find_task('symfony:vendors:upgrade').should_not == nil
  end

  context "symfony:vendors:install" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:vendors:install')
    end

    it "runs the Symfony2 command" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php bin/vendors install\'')
    end
  end

  context "symfony:vendors:reinstall" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:vendors:reinstall')
    end

    it "runs the Symfony2 command" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php bin/vendors install --reinstall\'')
    end
  end

  context "symfony:vendors:upgrade" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:vendors:upgrade')
    end

    it "runs the Symfony2 command" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php bin/vendors update\'')
    end
  end

  it "defines symfony:bootstrap tasks" do
    @configuration.find_task('symfony:bootstrap:build').should_not == nil
  end

  it "defines symfony:composer tasks" do
    @configuration.find_task('symfony:composer:self_update').should_not == nil
    @configuration.find_task('symfony:composer:install').should_not == nil
    @configuration.find_task('symfony:composer:update').should_not == nil
    @configuration.find_task('symfony:composer:dump_autoload').should_not == nil
  end

  it "defines symfony:cache tasks" do
    @configuration.find_task('symfony:cache:clear').should_not == nil
    @configuration.find_task('symfony:cache:warmup').should_not == nil
  end

  context "symfony:cache:clear" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:cache:clear')
    end

    it "runs the Symfony2 command successfully and sets permissions to the cache directory" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console cache:clear --env=prod\'')
      @configuration.should have_run(' chmod -R g+w /var/www/releases/20120927/app/cache')
    end
  end

  it "defines symfony:project tasks" do
    @configuration.find_task('symfony:project:clear_controllers').should_not == nil
  end
end
