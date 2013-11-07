namespace :symfony do
  desc "Exceute a provided symfony command"
  task :default, :arg_1 do |t, args|
    ask(:cmd, "cache:clear")
    command_to_run = args[:arg_1] || fetch(:cmd)

    on roles :app do
      within current_path do
        execute :php, fetch(:symfony_console_path), command_to_run, command_args, fetch(:symfony_console_flags)
      end
    end
  end

  namespace :cache do
    desc "Run app/console cache:clear for the #{fetch(:symfony_env_prod)} environment"
    task :clear do
      Rake::Task["symfony:default"].invoke("cache:clear")
    end

    desc "Run app/console cache:warmup for the #{fetch(:symfony_env_prod)} environment"
    task :warmup do
      Rake::Task["symfony:default"].invoke("cache:warmup")
    end
  end

  namespace :logs do
    desc "tails #{fetch(:log_path)}/#{fetch(:symfony_env_prod)}.log"
    task :tail do
      on roles :app do
        within current_path do
          execute :tail, "#{fetch(:log_path)}/#{fetch(:symfony_env_prod)}.log"
        end
      end
    end
  end
end
