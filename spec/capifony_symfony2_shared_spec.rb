require 'spec_helper'

require 'fakefs/safe'

describe "Capifony::Symfony2 - shared" do
  before do
    @configuration = Capistrano::Configuration.new
    @configuration.extend(Capistrano::Spec::ConfigurationExtension)

    @configuration.set :application,          'test-app'
    @configuration.set :latest_release,       '/var/www/releases/20120927'
    @configuration.set :previous_release,     '/var/www/releases/20120920'
    @configuration.set :current_path,         '/var/www/current'
    @configuration.set :shared_path,          '/var/www/shared'
    @configuration.set :remote_tmp_dir,       '/tmp'
    @configuration.set :maintenance_basename, 'maintenance'
    @configuration.set :try_sudo,             ''

    Capifony::Symfony2.load_into(@configuration)
  end

  subject { @configuration }

  it "defines shared folder tasks" do
    @configuration.find_task('shared:folder:download').should_not == nil
  end

  context "when runnning shared:folder:download", fakefs: true do
    before do
      @configuration.find_and_execute_task('shared:folder:download')
      @filename = "test-app.remote_shared.#{Time.now.utc.strftime("%Y%m%d%H%M%S")}.tar.gz"
      @file = "/tmp/#{@filename}"
    end

    it { should have_run(" sh -c \'cd /var/www/shared; tar -zcvf #{@file} --exclude=\'cached-copy\' .\'") }
    it { should have_gotten("#{@file}").to("backups/#{@filename}") }
    it { should have_run(" rm -f #{@file}") }
  end
end
