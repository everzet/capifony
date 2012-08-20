namespace :deploy do
  desc "Runs the symfony migrations"
  task :migrate do
    symfony.orm.migrate
  end

  desc "Symlink static directories and static files that need to remain between deployments."
  task :share_childs do
    if shared_children
      shared_children.each do |link|
        try_sudo "mkdir -p #{shared_path}/#{link}"
        try_sudo "sh -c 'if [ -d #{release_path}/#{link} ] ; then rm -rf #{release_path}/#{link}; fi'"
        try_sudo "ln -nfs #{shared_path}/#{link} #{release_path}/#{link}"
      end
    end
    if shared_files
      shared_files.each do |link|
        link_dir = File.dirname("#{shared_path}/#{link}")
        try_sudo "mkdir -p #{link_dir}"
        try_sudo "touch #{shared_path}/#{link}"
        try_sudo "ln -nfs #{shared_path}/#{link} #{release_path}/#{link}"
      end
    end
  end

  desc "Customize the finalize_update task to work with symfony."
  task :finalize_update, :except => { :no_release => true } do
    try_sudo "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)
    try_sudo "mkdir -p #{latest_release}/cache"
    try_sudo "chmod -R g+w #{latest_release}/cache"

    # Share common files & folders
    share_childs

    if fetch(:normalize_asset_timestamps, true)
      stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
      asset_paths = asset_children.map { |p| "#{latest_release}/#{p}" }.join(" ")
      try_sudo "find #{asset_paths} -exec touch -t #{stamp} {} ';'; true", :env => { "TZ" => "UTC" }
    end
  end

  desc "Need to overwrite the deploy:cold task so it doesn't try to run the migrations."
  task :cold do
    update
    symfony.orm.build_db_and_load
    start
  end

  desc "Deploy the application and run the test suite."
  task :testall do
    update_code
    create_symlink
    symfony.orm.build_db_and_load
    symfony.tests.all
  end
end
