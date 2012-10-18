require 'spec_helper'

describe "Capifony::Symfony2 - symfony" do
  before do
    @configuration = Capistrano::Configuration.new
    @configuration.extend(Capistrano::Spec::ConfigurationExtension)

    # Common parameters
    @configuration.set :latest_release,       '/var/www/releases/20120927'
    @configuration.set :shared_path,          '/var/www/shared'
    @configuration.set :maintenance_basename, 'maintenance'
    @configuration.set :try_sudo,             ''

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

  context "when running symfony:logs:tail" do
    before do
      @configuration.find_and_execute_task('symfony:logs:tail')
    end

    it { should have_run(' tail -n 50 -f /var/www/shared/app/logs/prod.log') }
  end

  context "when running symfony:logs:tail_dev" do
    before do
      @configuration.find_and_execute_task('symfony:logs:tail_dev')
    end

    it { should have_run(' tail -n 50 -f /var/www/shared/app/logs/dev.log') }
  end

  it "defines symfony:assets tasks" do
    @configuration.find_task('symfony:assets:update_version').should_not == nil
    @configuration.find_task('symfony:assets:install').should_not == nil
  end

  context "when running symfony:assets:install" do
    before do
      @configuration.find_and_execute_task('symfony:assets:install')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console assets:install web --env=prod\'') }
  end

  context "when running symfony:assets:install" do
    before do
      @configuration.set :assets_symlinks, true
      @configuration.find_and_execute_task('symfony:assets:install')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console assets:install web --symlink --env=prod\'') }
  end

  context "when running symfony:assets:install" do
    before do
      @configuration.set :assets_relative, true
      @configuration.find_and_execute_task('symfony:assets:install')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console assets:install web --relative --env=prod\'') }
  end

  context "when running symfony:assets:install" do
    before do
      @configuration.set :assets_symlinks, true
      @configuration.set :assets_relative, true
      @configuration.find_and_execute_task('symfony:assets:install')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console assets:install web --symlink --relative --env=prod\'') }
  end

  context "when running symfony:assets:install with sudo" do
    before do
      @configuration.set :try_sudo, 'sudo'
      @configuration.find_and_execute_task('symfony:assets:install')
    end

    it { should have_run('sudo sh -c \'cd /var/www/releases/20120927 && php app/console assets:install web --env=prod\'') }
  end

  it "defines symfony:assetic tasks" do
    @configuration.find_task('symfony:assetic:dump').should_not == nil
  end

  context "when running symfony:assetic:dump" do
    before do
      @configuration.find_and_execute_task('symfony:assetic:dump')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console assetic:dump --env=prod --no-debug\'') }
  end

  context "when running symfony:assetic:dump with sudo" do
    before do
      @configuration.set :try_sudo, 'sudo'
      @configuration.find_and_execute_task('symfony:assetic:dump')
    end

    it { should have_run('sudo sh -c \'cd /var/www/releases/20120927 && php app/console assetic:dump --env=prod --no-debug\'') }
  end

  it "defines symfony:vendors tasks" do
    @configuration.find_task('symfony:vendors:install').should_not == nil
    @configuration.find_task('symfony:vendors:reinstall').should_not == nil
    @configuration.find_task('symfony:vendors:upgrade').should_not == nil
  end

  context "when running symfony:vendors:install" do
    before do
      @configuration.find_and_execute_task('symfony:vendors:install')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php bin/vendors install\'') }
  end

  context "when running symfony:vendors:reinstall" do
    before do
      @configuration.find_and_execute_task('symfony:vendors:reinstall')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php bin/vendors install --reinstall\'') }
  end

  context "when running symfony:vendors:upgrade" do
    before do
      @configuration.find_and_execute_task('symfony:vendors:upgrade')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php bin/vendors update\'') }
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

  context "when running symfony:cache:clear" do
    before do
      @configuration.find_and_execute_task('symfony:cache:clear')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console cache:clear --env=prod\'') }
    it { should have_run(' chmod -R g+w /var/www/releases/20120927/app/cache') }
  end

  it "defines symfony:project tasks" do
    @configuration.find_task('symfony:project:clear_controllers').should_not == nil
  end
end
