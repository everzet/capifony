# Use AsseticBundle
set :dump_assetic_assets,   false

# Assets install
set :assets_install,        false
set :assets_symlinks,       false
set :assets_relative,       false
set :assets_install_path,   fetch(:web_path)

# Whether to update `assets_version` in `config.yml`
set :update_assets_version, false

set :normalize_asset_timestamps, true
# Asset folders (that need to be timestamped)
set :asset_children,        [fetch(:web_path) + "/css", fetch(:web_path) + "/images", fetch(:web_path) + "/js"]

load File.expand_path("../../tasks/assets.rake", __FILE__)
