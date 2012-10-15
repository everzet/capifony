require 'spec_helper'

describe "Capifony::Symfony2 - doctrine" do
  before do
    @configuration = Capistrano::Configuration.new
    @configuration.extend(Capistrano::Spec::ConfigurationExtension)

    # Common parameters
    @configuration.set :latest_release, '/var/www/releases/20120927'
    @configuration.set :shared_path,    '/var/www/shared'

    Capifony::Symfony2.load_into(@configuration)
  end

  subject { @configuration }

  it "defines symfony:doctrine:cache tasks" do
    @configuration.find_task('symfony:doctrine:cache:clear_metadata').should_not == nil
    @configuration.find_task('symfony:doctrine:cache:clear_query').should_not == nil
    @configuration.find_task('symfony:doctrine:cache:clear_result').should_not == nil
  end

  context "symfony:doctrine:cache:clear_metadata" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:doctrine:cache:clear_metadata')
    end

    it "runs the Symfony2 command" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:cache:clear-metadata --env=prod\'')
    end
  end

  context "symfony:doctrine:cache:clear_query" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:doctrine:cache:clear_query')
    end

    it "runs the Symfony2 command" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:cache:clear-query --env=prod\'')
    end
  end

  context "symfony:doctrine:cache:clear_result" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:doctrine:cache:clear_result')
    end

    it "runs the Symfony2 command" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:cache:clear-result --env=prod\'')
    end
  end

  it "defines symfony:doctrine:database tasks" do
    @configuration.find_task('symfony:doctrine:database:create').should_not == nil
    @configuration.find_task('symfony:doctrine:database:drop').should_not == nil
  end

  context "symfony:doctrine:database:create" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:doctrine:database:create')
    end

    it "runs the Symfony2 command" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:database:create --env=prod\'')
    end
  end

  context "symfony:doctrine:database:drop" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:doctrine:database:drop')
    end

    it "runs the Symfony2 command" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:database:drop --env=prod\'')
    end
  end

  it "defines symfony:doctrine:schema tasks" do
    @configuration.find_task('symfony:doctrine:schema:create').should_not == nil
    @configuration.find_task('symfony:doctrine:schema:drop').should_not == nil
    @configuration.find_task('symfony:doctrine:schema:update').should_not == nil
  end

  context "symfony:doctrine:schema:create" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:doctrine:schema:create')
    end

    it "runs the Symfony2 command" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:schema:create --env=prod\'')
    end
  end

  context "symfony:doctrine:schema:drop" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:doctrine:schema:drop')
    end

    it "runs the Symfony2 command" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:schema:drop --env=prod\'')
    end
  end

  context "symfony:doctrine:schema:update" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:doctrine:schema:update')
    end

    it "runs the Symfony2 command" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:schema:update --force --env=prod\'')
    end
  end

  it "defines symfony:doctrine:migrations tasks" do
    @configuration.find_task('symfony:doctrine:migrations:migrate').should_not == nil
    @configuration.find_task('symfony:doctrine:migrations:status').should_not == nil
  end

  context "symfony:doctrine:migrations:status" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:doctrine:migrations:status')
    end

    it "runs the Symfony2 command" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:migrations:status --env=prod\'')
    end
  end

  it "defines symfony:doctrine:mongodb tasks" do
    @configuration.find_task('symfony:doctrine:mongodb:schema:create').should_not == nil
    @configuration.find_task('symfony:doctrine:mongodb:schema:update').should_not == nil
    @configuration.find_task('symfony:doctrine:mongodb:schema:drop').should_not == nil
    @configuration.find_task('symfony:doctrine:mongodb:indexes:create').should_not == nil
    @configuration.find_task('symfony:doctrine:mongodb:indexes:drop').should_not == nil
  end

  context "symfony:doctrine:mongodb:schema:create" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:doctrine:mongodb:schema:create')
    end

    it "runs the Symfony2 command" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:mongodb:schema:create --env=prod\'')
    end
  end

  context "symfony:doctrine:mongodb:schema:update" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:doctrine:mongodb:schema:update')
    end

    it "runs the Symfony2 command" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:mongodb:schema:update --env=prod\'')
    end
  end

  context "symfony:doctrine:mongodb:schema:drop" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:doctrine:mongodb:schema:drop')
    end

    it "runs the Symfony2 command" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:mongodb:schema:drop --env=prod\'')
    end
  end

  context "symfony:doctrine:mongodb:indexes:create" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:doctrine:mongodb:indexes:create')
    end

    it "runs the Symfony2 command" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:mongodb:schema:create --index --env=prod\'')
    end
  end

  context "symfony:doctrine:mongodb:indexes:drop" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:doctrine:mongodb:indexes:drop')
    end

    it "runs the Symfony2 command" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console doctrine:mongodb:schema:drop --index --env=prod\'')
    end
  end

  it "defines symfony:doctrine:init tasks" do
    @configuration.find_task('symfony:doctrine:init:acl').should_not == nil
  end

  context "symfony:doctrine:init:acl" do
    before do
      @configuration.set :try_sudo, ''
      @configuration.find_and_execute_task('symfony:doctrine:init:acl')
    end

    it "runs the Symfony2 command" do
      @configuration.should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console init:acl --env=prod\'')
    end
  end
end
