set :composer_download_path, "http://getcomposer.org/installer"

# Whether to use composer to install vendors to a local temp directory.
set :use_composer_tmp, false

# Path to composer binary
# If set to false, Capifony will download/install composer
set :composer_bin, false

# Options to pass to composer when installing/updating
set :composer_options, "--no-dev --verbose --prefer-dist --optimize-autoloader --no-progress"

# Options to pass to composer when dumping the autoloader (dump-autoloader)
set :composer_dump_autoload_options, "--optimize"

# Whether to update vendors using the configured dependency manager (composer or bin/vendors)
set :update_vendors, false

# Copy vendors from previous release
set :copy_vendors, false

load File.expand_path("../../tasks/composer.rake", __FILE__)
