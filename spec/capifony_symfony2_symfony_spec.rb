require 'spec_helper'

describe "Capifony::Symfony2 - symfony" do
  before do
    @configuration = Capistrano::Configuration.new
    @configuration.extend(Capistrano::Spec::ConfigurationExtension)

    # Common parameters
    @configuration.set :latest_release,       '/var/www/releases/20120927'
    @configuration.set :previous_release,     '/var/www/releases/20120920'
    @configuration.set :current_path,         '/var/www/current'
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

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console assets:install web --env=prod --no-debug\'') }
  end

  context "when running symfony:assets:install" do
    before do
      @configuration.set :assets_symlinks, true
      @configuration.find_and_execute_task('symfony:assets:install')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console assets:install web --symlink --env=prod --no-debug\'') }
  end

  context "when running symfony:assets:install" do
    before do
      @configuration.set :assets_relative, true
      @configuration.find_and_execute_task('symfony:assets:install')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console assets:install web --relative --env=prod --no-debug\'') }
  end

  context "when running symfony:assets:install" do
    before do
      @configuration.set :assets_symlinks, true
      @configuration.set :assets_relative, true
      @configuration.find_and_execute_task('symfony:assets:install')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console assets:install web --symlink --relative --env=prod --no-debug\'') }
  end

  context "when running symfony:assets:install with sudo" do
    before do
      @configuration.set :try_sudo, 'sudo'
      @configuration.find_and_execute_task('symfony:assets:install')
    end

    it { should have_run('sudo sh -c \'cd /var/www/releases/20120927 && php app/console assets:install web --env=prod --no-debug\'') }
  end

  context "when running symfony:assets:install with a custom assets_install_path" do
    before do
      @configuration.set :assets_install_path, 'some/where'
      @configuration.find_and_execute_task('symfony:assets:install')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console assets:install some/where --env=prod --no-debug\'') }
  end

  it "defines symfony:assetic tasks" do
    @configuration.find_task('symfony:assetic:dump').should_not == nil
  end

  context "when running symfony:assetic:dump" do
    before do
      @configuration.find_and_execute_task('symfony:assetic:dump')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console assetic:dump --env=prod --no-debug /var/www/releases/20120927/web\'') }
  end

  context "when running symfony:assetic:dump with sudo" do
    before do
      @configuration.set :try_sudo, 'sudo'
      @configuration.find_and_execute_task('symfony:assetic:dump')
    end

    it { should have_run('sudo sh -c \'cd /var/www/releases/20120927 && php app/console assetic:dump --env=prod --no-debug /var/www/releases/20120927/web\'') }
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
    @configuration.find_task('symfony:composer:install').should_not == nil
    @configuration.find_task('symfony:composer:update').should_not == nil
    @configuration.find_task('symfony:composer:dump_autoload').should_not == nil
    @configuration.find_task('symfony:composer:copy_vendors').should_not == nil
  end

  context "when running symfony:composer:update" do
    before do
      @configuration.find_and_execute_task('symfony:composer:update')
    end

    it { should_not have_run('vendorDir=/var/www/current/vendor; if [ -d $vendorDir ] || [ -h $vendorDir ]; then cp -a $vendorDir /var/www/releases/20120927/vendor; fi;') }
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && curl -s http://getcomposer.org/installer | php\'') }
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php composer.phar update --no-dev --verbose --prefer-dist --optimize-autoloader --no-progress\'') }
  end

  context "when running symfony:composer:update with interactive_mode disabled" do
    before do
      @configuration.set :interactive_mode, false
      @configuration.find_and_execute_task('symfony:composer:update')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php composer.phar update --no-dev --verbose --prefer-dist --optimize-autoloader --no-progress --no-interaction\'') }
  end

  context "when running symfony:composer:update with a given composer_bin" do
    before do
      @configuration.set :composer_bin, "my_composer"
      @configuration.find_and_execute_task('symfony:composer:update')
    end

    it { should_not have_run('vendorDir=/var/www/current/vendor; if [ -d $vendorDir ] || [ -h $vendorDir ]; then cp -a $vendorDir /var/www/releases/20120927/vendor; fi;') }
    it { should_not have_run(' sh -c \'cd /var/www/releases/20120927 && curl -s http://getcomposer.org/installer | php\'') }
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && my_composer update --no-dev --verbose --prefer-dist --optimize-autoloader --no-progress\'') }
  end

  context "when running symfony:composer:update with enabled copy_vendors" do
    before do
      @configuration.set :copy_vendors, true
      @configuration.find_and_execute_task('symfony:composer:update')
    end

    it { should have_run('vendorDir=/var/www/current/vendor; if [ -d $vendorDir ] || [ -h $vendorDir ]; then cp -a $vendorDir /var/www/releases/20120927/vendor; fi;') }
  end

  context "when running symfony:composer:install with an existing composer.phar in the previous release" do
    before do
      @configuration.stub(:remote_file_exists?).and_return(true)
      @configuration.find_and_execute_task('symfony:composer:install')
    end

    it { should_not have_run('vendorDir=/var/www/current/vendor; if [ -d $vendorDir ] || [ -h $vendorDir ]; then cp -a $vendorDir /var/www/releases/20120927/vendor; fi;') }
    it { should_not have_run(' sh -c \'cp /var/www/releases/20120920/composer.phar /var/www/releases/20120927/\'') }
    it { should_not have_run(' sh -c \'cd /var/www/releases/20120927 && curl -s http://getcomposer.org/installer | php\'') }
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php composer.phar self-update\'') }
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && SYMFONY_ENV=prod php composer.phar install --no-dev --verbose --prefer-dist --optimize-autoloader --no-progress\'') }
  end

  context "when running symfony:composer:install without any existing composer.phar in the previous release" do
    before do
      @configuration.stub(:remote_file_exists?).and_return(false)
      @configuration.find_and_execute_task('symfony:composer:install')
    end

    it { should_not have_run('vendorDir=/var/www/current/vendor; if [ -d $vendorDir ] || [ -h $vendorDir ]; then cp -a $vendorDir /var/www/releases/20120927/vendor; fi;') }
    it { should_not have_run(' sh -c \'cp /var/www/releases/20120920/composer.phar /var/www/releases/20120927/\'') }
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && curl -s http://getcomposer.org/installer | php\'') }
    it { should_not have_run(' sh -c \'cd /var/www/releases/20120927 && php composer.phar self-update\'') }
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && SYMFONY_ENV=prod php composer.phar install --no-dev --verbose --prefer-dist --optimize-autoloader --no-progress\'') }
  end

  context "when running symfony:composer:install" do
    before do
      @configuration.find_and_execute_task('symfony:composer:install')
    end

    it { should_not have_run('vendorDir=/var/www/current/vendor; if [ -d $vendorDir ] || [ -h $vendorDir ]; then cp -a $vendorDir /var/www/releases/20120927/vendor; fi;') }
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && curl -s http://getcomposer.org/installer | php\'') }
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && SYMFONY_ENV=prod php composer.phar install --no-dev --verbose --prefer-dist --optimize-autoloader --no-progress\'') }
  end

  context "when running symfony:composer:install with interactive mode disabled" do
    before do
      @configuration.set :interactive_mode, false
      @configuration.find_and_execute_task('symfony:composer:install')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && SYMFONY_ENV=prod php composer.phar install --no-dev --verbose --prefer-dist --optimize-autoloader --no-progress --no-interaction\'') }
  end

  context "when running symfony:composer:install with a given composer_bin" do
    before do
      @configuration.set :composer_bin, "my_composer"
      @configuration.find_and_execute_task('symfony:composer:install')
    end

    it { should_not have_run('vendorDir=/var/www/current/vendor; if [ -d $vendorDir ] || [ -h $vendorDir ]; then cp -a $vendorDir /var/www/releases/20120927/vendor; fi;') }
    it { should_not have_run(' sh -c \'cd /var/www/releases/20120927 && curl -s http://getcomposer.org/installer | php\'') }
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && SYMFONY_ENV=prod my_composer install --no-dev --verbose --prefer-dist --optimize-autoloader --no-progress\'') }
  end

  context "when running symfony:composer:install with enabled copy_vendors" do
    before do
      @configuration.set :copy_vendors, true
      @configuration.find_and_execute_task('symfony:composer:install')
    end

    it { should have_run('vendorDir=/var/www/current/vendor; if [ -d $vendorDir ] || [ -h $vendorDir ]; then cp -a $vendorDir /var/www/releases/20120927/vendor; fi;') }
  end

  context "when running symfony:composer:dump_autoload" do
    before do
      @configuration.find_and_execute_task('symfony:composer:dump_autoload')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && curl -s http://getcomposer.org/installer | php\'') }
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php composer.phar dump-autoload --optimize\'') }
  end

  context "when running symfony:composer:dump_autoload with a given composer_bin" do
    before do
      @configuration.set :composer_bin, "my_composer"
      @configuration.find_and_execute_task('symfony:composer:dump_autoload')
    end

    it { should_not have_run(' sh -c \'cd /var/www/releases/20120927 && curl -s http://getcomposer.org/installer | php\'') }
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && my_composer dump-autoload --optimize\'') }
  end

  it "defines symfony:cache tasks" do
    @configuration.find_task('symfony:cache:clear').should_not == nil
    @configuration.find_task('symfony:cache:warmup').should_not == nil
  end

  context "when running symfony:cache:clear" do
    before do
      @configuration.find_and_execute_task('symfony:cache:clear')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console cache:clear --env=prod --no-debug\'') }
    it { should have_run(' chmod -R g+w /var/www/releases/20120927/app/cache') }
  end

  context "when running symfony:cache:warmup" do
    before do
      @configuration.find_and_execute_task('symfony:cache:warmup')
    end

    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && php app/console cache:warmup --env=prod --no-debug\'') }
    it { should have_run(' chmod -R g+w /var/www/releases/20120927/app/cache') }
  end

  it "defines symfony:project tasks" do
    @configuration.fetch(:controllers_to_clear).should == ['app_*.php']
    @configuration.find_task('symfony:project:clear_controllers').should_not == nil
  end

  context "when running symfony:project:clear_controllers" do
    before do
      @configuration.find_and_execute_task('symfony:project:clear_controllers')
    end
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && rm -f web/app_*.php\'') }
  end

  context "when running symfony:project:clear_controllers with a given controllers_to_clear" do
    before do
      @configuration.set :controllers_to_clear,  ['config.php', 'app_dev.php', 'app_test.php']
      @configuration.find_and_execute_task('symfony:project:clear_controllers')
    end
    it { should have_run(' sh -c \'cd /var/www/releases/20120927 && rm -f web/config.php web/app_dev.php web/app_test.php\'') }
  end


end
