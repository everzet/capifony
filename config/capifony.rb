# setting symfony paths:
set :shared_children,   %w(config log cache web/uploads)
set :release_children,  shared_children
set :assets_children,   %s(css images js)

namespace :deploy do
  task :finalize_update, :except => { :no_release => true } do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

    # getting paths
    shared_paths  = shared_children.map { |d| File.join(shared_path, d) }
    release_paths = release_children.map { |d| File.join(latest_release, d) }

    # removing unnecessary paths
    run "rm -rf #{release_paths.join(' ')}"

    # creating symlinks
    shared_paths.each_index do |i|
      run "ln -s #{shared_path.at(i)} #{release_paths.at(i)}"
    end

    if fetch(:normalize_asset_timestamps, true)
      stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
      asset_paths = assets_children.map { |p| "#{latest_release}/web/#{p}" }.join(" ")
      run "find #{asset_paths} -exec touch -t #{stamp} {} ';'; true", :env => { "TZ" => "UTC" }
    end
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    # clearing symfony cache
    try_runner "#{current_path}symfony cc"
  end
end