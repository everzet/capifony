# Map php executable (configurable)
SSHKit.config.command_map[:symfony] = "#{fetch(:php_bin)} #{fetch(:symfony_console)} --env=#{fetch(:symfony_env_prod)} #{fetch(:symfony_debug) ? "" : "--no-debug"}"

namespace :symfony do
  task :default do
    on roles :app do
      within current_path do
        ask(:task_to_execute, "cache:clear")
        execute :symfony, fetch(:task_to_execute)
      end
    end
  end

  namespace :cache do
    task :clear do
      on roles :app do
        within current_path do
          execute :symfony, "cache:clear"
        end
      end
    end
    task :warmup do
      on roles :app do
        within current_path do
          execute :symfony, "cache:warmup"
        end
      end
    end
  end

  namespace :logs do
    task :tail do
      on roles :app do
        within current_path do
          execute :tail, "#{fetch(:log_path)}/#{fetch(:symfony_env_prod)}.log"
        end
      end
    end
  end
end
