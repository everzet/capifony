require 'fileutils'

namespace :shared do
  namespace :folder do
    desc "Downloads a backup of the shared folder"
    task :download do
      env       = fetch(:deploy_env, "remote")
      filename  = "#{application}.#{env}_shared.#{Time.now.utc.strftime("%Y%m%d%H%M%S")}.tar.gz"
      file      = "#{remote_tmp_dir}/#{filename}"

      capifony_pretty_print "--> Making a temporary archive of the shared directory"
      run "#{try_sudo} sh -c 'cd #{shared_path}; tar -zcvf #{file} --exclude='cached-copy' .'"
      capifony_puts_ok

      FileUtils.mkdir_p("backups/")

      capifony_progress_start
      get(file, "backups/#{filename}", :via => :scp) do |channel, name, sent, total|
        capifony_progress_update(sent, total)
      end

      capifony_pretty_print "--> Cleaning up"
      begin
        FileUtils.ln_sf(filename, "backups/#{application}.#{env}_shared.latest.tar.gz")
      rescue Exception # fallback for file systems that don't support symlinks
        FileUtils.cp_r("backups/#{filename}", "backups/#{application}.#{env}_shared.latest.tar.gz")
      end
      run "#{try_sudo} rm -f #{file}"
      capifony_puts_ok
    end
  end
end
