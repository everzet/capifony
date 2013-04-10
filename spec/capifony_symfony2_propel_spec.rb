require 'spec_helper'

describe "Capifony::Symfony2 - propel" do
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

  it "defines symfony:propel:database tasks" do
    @configuration.find_task('symfony:propel:database:create').should_not == nil
    @configuration.find_task('symfony:propel:database:drop').should_not == nil
  end

  context "when running symfony:propel:database:create" do
    before do
      @configuration.find_and_execute_task('symfony:propel:database:create')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console propel:database:create --env=prod --no-debug\'') }
  end

  context "when running symfony:propel:database:drop" do
    before do
      @configuration.find_and_execute_task('symfony:propel:database:drop')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console propel:database:drop --env=prod --no-debug\'') }
  end

  it "defines symfony:propel:build tasks" do
    @configuration.find_task('symfony:propel:build:model').should_not == nil
    @configuration.find_task('symfony:propel:build:sql').should_not == nil
    @configuration.find_task('symfony:propel:build:sql_load').should_not == nil
    @configuration.find_task('symfony:propel:build:all_and_load').should_not == nil
    @configuration.find_task('symfony:propel:build:acl').should_not == nil
    @configuration.find_task('symfony:propel:build:acl_load').should_not == nil
  end

  context "when running symfony:propel:build:model" do
    before do
      @configuration.find_and_execute_task('symfony:propel:build:model')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console propel:model:build --env=prod --no-debug\'') }
  end

  context "when running symfony:propel:build:model with old Symfony2 version" do
    before do
      @configuration.set :symfony_version, '2.0.1'
      @configuration.find_and_execute_task('symfony:propel:build:model')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console propel:build-model --env=prod --no-debug\'') }
  end

  context "when running symfony:propel:build:model with old dev Symfony2 version" do
    before do
      @configuration.set :symfony_version, '2.0.1-dev'
      @configuration.find_and_execute_task('symfony:propel:build:model')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console propel:build-model --env=prod --no-debug\'') }
  end

  context "when running symfony:propel:build:sql" do
    before do
      @configuration.find_and_execute_task('symfony:propel:build:sql')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console propel:sql:build --env=prod --no-debug\'') }
  end

  context "when running symfony:propel:build:sql with old Symfony2 version" do
    before do
      @configuration.set :symfony_version, '2.0.1'
      @configuration.find_and_execute_task('symfony:propel:build:sql')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console propel:build-sql --env=prod --no-debug\'') }
  end

  context "when running symfony:propel:build:sql with old dev Symfony2 version" do
    before do
      @configuration.set :symfony_version, '2.0.1-dev'
      @configuration.find_and_execute_task('symfony:propel:build:sql')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console propel:build-sql --env=prod --no-debug\'') }
  end

  context "when running symfony:propel:build:sql_load" do
    before do
      @configuration.find_and_execute_task('symfony:propel:build:sql_load')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console propel:sql:insert --force --env=prod --no-debug\'') }
  end

  context "when running symfony:propel:build:sql_load with old Symfony2 version" do
    before do
      @configuration.set :symfony_version, '2.0.1'
      @configuration.find_and_execute_task('symfony:propel:build:sql_load')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console propel:insert-sql --force --env=prod --no-debug\'') }
  end

  context "when running symfony:propel:build:sql_load with old dev Symfony2 version" do
    before do
      @configuration.set :symfony_version, '2.0.1-dev'
      @configuration.find_and_execute_task('symfony:propel:build:sql_load')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console propel:insert-sql --force --env=prod --no-debug\'') }
  end

  context "when running symfony:propel:build:all_and_load" do
    before do
      @configuration.find_and_execute_task('symfony:propel:build:all_and_load')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console propel:build --insert-sql --env=prod --no-debug\'') }
  end

  context "when running symfony:propel:build:acl" do
    before do
      @configuration.find_and_execute_task('symfony:propel:build:acl')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console propel:acl:init --env=prod --no-debug\'') }
  end

  context "when running symfony:propel:build:acl_load" do
    before do
      @configuration.find_and_execute_task('symfony:propel:build:acl_load')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console propel:acl:init --env=prod --no-debug --force\'') }
  end
end
