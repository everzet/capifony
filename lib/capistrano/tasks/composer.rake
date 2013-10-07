# Map :composer to give configured arguments
def get_composer_arguments()
  args = ""
  args += fetch(:composer_options, "")
  args += fetch(:interactive_mode, false) ? "" : " --no-interaction"
end
SSHKit.config.command_map[:composer] = "SYMFONY_ENV=#{fetch(:symfony_env_prod)} #{fetch(:php_bin)} composer.phar #{get_composer_arguments}"

namespace :composer do
  before "deploy:updated", :run do
    method = fetch(:update_vendors) ? "update" : "install"
    invoke "composer:#{method}"
  end

  desc "Download and install composer"
  task :get do
    on roles :app do
      next if test "[ -e #{release_path.join("composer.phar")} ]"
      # TODO: figure out composer tmp here?
      within release_path do
        # ssh kit doesnt seem to map the piped command :(
        execute :curl, "-s", fetch(:composer_download_path), "|", :php
      end
    end
  end

  desc "Run composer install"
  task install: :"composer:get" do
    on roles :app do
      within release_path do
        execute :composer, "install"
      end
    end
  end

  desc "Run composer update"
  task update: :"composer:get" do
    within release_path do
      on roles :app do
        execute :composer, "update"
      end
    end
  end
end
