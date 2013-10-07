namespace :deploy do
  namespace :assets do
    desc "Normalize asset timestamps"
    task :normalize do
      next unless fetch :normalize_asset_timestamps
      on roles :app, reject: lambda { |h| h.properties.no_release } do
        asset_timestamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
        assets = fetch(:asset_children).join(" ")
        within release_path do
          execute :find, "#{assets} -exec touch -t #{asset_timestamp} {} ';'; true"
        end
      end
    end
  end
  after "deploy:updated", "deploy:assets:normalize"
end
