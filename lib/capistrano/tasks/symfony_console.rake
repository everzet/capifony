namespace :symfony do
  desc "Exceute a provided symfony command"
  task :command, :command_name do |t, args|
    # ask only runs if argument is not provided
    ask(:cmd, "cache:clear")
    command = args[:command_name] || fetch(:cmd)
    command_args = args.extras

    on roles :app do
      within current_path do
        execute :php, fetch(:symfony_console_path), command, *command_args, fetch(:symfony_console_flags)
      end
    end
  end

  namespace :cache do
    desc "Run app/console cache:clear for the #{fetch(:symfony_env_prod)} environment"
    task :clear do
      invoke "symfony:command", "cache:clear"
    end

    desc "Run app/console cache:warmup for the #{fetch(:symfony_env_prod)} environment"
    task :warmup do
      invoke "symfony:command", "cache:warmup"
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

task :symfony => ["symfony:command"]
