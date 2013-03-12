require 'spec_helper'

describe "Capifony::Symfony2 - doctrine" do
  before do
    @configuration = Capistrano::Configuration.new
    @configuration.extend(Capistrano::Spec::ConfigurationExtension)

    # Common parameters
    @configuration.set :latest_release,       '/var/www/releases/20120927'
    @configuration.set :shared_path,          '/var/www/shared'
    @configuration.set :maintenance_basename, 'maintenance'
    @configuration.set :try_sudo,             ''

    Capifony::Symfony2.load_into(@configuration)

    @configuration.set :interactive_mode,     false
  end

  subject { @configuration }

  it "defines symfony:doctrine:cache tasks" do
    @configuration.find_task('symfony:doctrine:cache:clear_metadata').should_not == nil
    @configuration.find_task('symfony:doctrine:cache:clear_query').should_not == nil
    @configuration.find_task('symfony:doctrine:cache:clear_result').should_not == nil
  end

  context "when running symfony:doctrine:cache:clear_metadata" do
    before do
      @configuration.find_and_execute_task('symfony:doctrine:cache:clear_metadata')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:cache:clear-metadata --env=prod\'') }
  end

  context "when running symfony:doctrine:cache:clear_query" do
    before do
      @configuration.find_and_execute_task('symfony:doctrine:cache:clear_query')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:cache:clear-query --env=prod\'') }
  end

  context "when running symfony:doctrine:cache:clear_result" do
    before do
      @configuration.find_and_execute_task('symfony:doctrine:cache:clear_result')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:cache:clear-result --env=prod\'') }
  end

  it "defines symfony:doctrine:database tasks" do
    @configuration.find_task('symfony:doctrine:database:create').should_not == nil
    @configuration.find_task('symfony:doctrine:database:drop').should_not == nil
  end

  context "when running symfony:doctrine:database:create" do
    before do
      @configuration.find_and_execute_task('symfony:doctrine:database:create')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:database:create --env=prod\'') }
  end

  context "when running symfony:doctrine:database:drop" do
    before do
      @configuration.find_and_execute_task('symfony:doctrine:database:drop')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:database:drop --force --env=prod\'') }
  end

  it "defines symfony:doctrine:schema tasks" do
    @configuration.find_task('symfony:doctrine:schema:create').should_not == nil
    @configuration.find_task('symfony:doctrine:schema:drop').should_not == nil
    @configuration.find_task('symfony:doctrine:schema:update').should_not == nil
  end

  context "when running symfony:doctrine:schema:create" do
    before do
      @configuration.find_and_execute_task('symfony:doctrine:schema:create')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:schema:create --env=prod\'') }
  end

  context "when running symfony:doctrine:schema:drop" do
    before do
      @configuration.find_and_execute_task('symfony:doctrine:schema:drop')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:schema:drop --force --env=prod\'') }
  end

  context "when running symfony:doctrine:schema:update" do
    before do
      @configuration.find_and_execute_task('symfony:doctrine:schema:update')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:schema:update --force --env=prod\'') }
  end

  it "defines symfony:doctrine:load_fixtures task" do
    @configuration.find_task('symfony:doctrine:load_fixtures').should_not == nil
  end

  context "when running symfony:doctrine:load_fixtures" do
    before do
      @configuration.find_and_execute_task('symfony:doctrine:load_fixtures')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:fixtures:load --env=prod\'') }
  end

  it "defines symfony:doctrine:migrations tasks" do
    @configuration.find_task('symfony:doctrine:migrations:migrate').should_not == nil
    @configuration.find_task('symfony:doctrine:migrations:status').should_not == nil
  end

  context "when running symfony:doctrine:migrations:status" do
    before do
      @configuration.find_and_execute_task('symfony:doctrine:migrations:status')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:migrations:status --env=prod\'') }
  end

  it "defines symfony:doctrine:mongodb tasks" do
    @configuration.find_task('symfony:doctrine:mongodb:schema:create').should_not == nil
    @configuration.find_task('symfony:doctrine:mongodb:schema:update').should_not == nil
    @configuration.find_task('symfony:doctrine:mongodb:schema:drop').should_not == nil
    @configuration.find_task('symfony:doctrine:mongodb:indexes:create').should_not == nil
    @configuration.find_task('symfony:doctrine:mongodb:indexes:drop').should_not == nil
  end

  context "when running symfony:doctrine:mongodb:schema:create" do
    before do
      @configuration.find_and_execute_task('symfony:doctrine:mongodb:schema:create')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:mongodb:schema:create --env=prod\'') }
  end

  context "when running symfony:doctrine:mongodb:schema:update" do
    before do
      @configuration.find_and_execute_task('symfony:doctrine:mongodb:schema:update')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:mongodb:schema:update --env=prod\'') }
  end

  context "when running symfony:doctrine:mongodb:schema:drop" do
    before do
      @configuration.find_and_execute_task('symfony:doctrine:mongodb:schema:drop')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:mongodb:schema:drop --env=prod\'') }
  end

  context "when running symfony:doctrine:mongodb:indexes:create" do
    before do
      @configuration.find_and_execute_task('symfony:doctrine:mongodb:indexes:create')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:mongodb:schema:create --index --env=prod\'') }
  end

  context "when running symfony:doctrine:mongodb:indexes:drop" do
    before do
      @configuration.find_and_execute_task('symfony:doctrine:mongodb:indexes:drop')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:mongodb:schema:drop --index --env=prod\'') }
  end

  it "defines symfony:doctrine:init tasks" do
    @configuration.find_task('symfony:doctrine:init:acl').should_not == nil
  end

  context "when running symfony:doctrine:init:acl" do
    before do
      @configuration.find_and_execute_task('symfony:doctrine:init:acl')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console init:acl --env=prod\'') }
  end

  context "when running symfony:doctrine:* with custom entity manager" do
    before do
      @configuration.set :doctrine_em, 'custom_em'

      @configuration.find_and_execute_task('symfony:doctrine:cache:clear_metadata')
      @configuration.find_and_execute_task('symfony:doctrine:cache:clear_query')
      @configuration.find_and_execute_task('symfony:doctrine:cache:clear_result')
      @configuration.find_and_execute_task('symfony:doctrine:schema:create')
      @configuration.find_and_execute_task('symfony:doctrine:schema:drop')
      @configuration.find_and_execute_task('symfony:doctrine:schema:update')
      @configuration.find_and_execute_task('symfony:doctrine:load_fixtures')
      @configuration.find_and_execute_task('symfony:doctrine:migrations:status')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:cache:clear-metadata --env=prod --em=custom_em\'') }
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:cache:clear-query --env=prod --em=custom_em\'') }
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:cache:clear-result --env=prod --em=custom_em\'') }
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:schema:create --env=prod --em=custom_em\'') }
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:schema:drop --force --env=prod --em=custom_em\'') }
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:schema:update --force --env=prod --em=custom_em\'') }
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:fixtures:load --env=prod --em=custom_em\'') }
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:migrations:status --env=prod --em=custom_em\'') }
  end
  
  context "when running symfony:doctrine:clear_* with flush option" do
    before do
      @configuration.set :doctrine_clear_use_flush_option, true

      @configuration.find_and_execute_task('symfony:doctrine:cache:clear_metadata')
      @configuration.find_and_execute_task('symfony:doctrine:cache:clear_query')
      @configuration.find_and_execute_task('symfony:doctrine:cache:clear_result')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:cache:clear-metadata --env=prod --flush\'') }
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:cache:clear-query --env=prod --flush\'') }
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:cache:clear-result --env=prod --flush\'') }
  end

end
