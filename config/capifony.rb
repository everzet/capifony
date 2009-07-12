# setting symfony paths:
set :shared_children,   %w(log web/uploads)
set :release_children,  shared_children
set :assets_children,   %w(css images js)

namespace :deploy do
  task :setup, :except => { :no_release => true } do
    dirs = [deploy_to, releases_path, shared_path]
    dirs += shared_children.map { |d| File.join(shared_path, d) }
    run "mkdir -p #{dirs.join(' ')} && chmod g+w #{dirs.join(' ')}"
  end

  task :finalize_update, :except => { :no_release => true } do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

    # getting paths
    shared_paths  = shared_children.map { |d| File.join(shared_path, d) }
    release_paths = release_children.map { |d| File.join(latest_release + '/', d) }

    # removing unnecessary paths
    run "rm -rf #{release_paths.join(' ')}"

    # creating symlinks
    shared_paths.each_index { |i| run "ln -s #{shared_paths.at(i)} #{release_paths.at(i)}" }

    # cache directory
    run "mkdir -p #{latest_release}/cache"

    # publishing plugin assets
    run "cd #{latest_release} && symfony plugin:publish-assets"

    # permission
    run "cd #{latest_release} && symfony project:permissions"

    if fetch(:normalize_asset_timestamps, true)
      stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
      asset_paths = assets_children.map { |p| "#{latest_release}/web/#{p}" }.join(" ")
      run "find #{asset_paths} -exec touch -t #{stamp} {} ';'; true", :env => { "TZ" => "UTC" }
    end
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    # doing nothing. Overload this method if you need some custom actions
  end
end

namespace :symfony do
  def run_task task
    run "cd #{current_path} && symfony #{task}"
  end
end