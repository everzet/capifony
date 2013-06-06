require 'capistrano/recipes/deploy/strategy/copy'
require 'fileutils'
require 'capifony_symfony2'

module Capistrano
  module Deploy
    module Strategy
      class CapifonyCopyLocal < Copy
        print "--> Using Copy Local Strategy\n"
        # Deploy
        def deploy!
          copy_cache ? run_copy_cache_strategy : run_copy_strategy
          create_revision_file
          $temp_destination = destination  # Make temp location avaliable globally.
          symfony.composer.install
          symfony.bootstrap.build
          compress_repository
          distribute!
        ensure
          rollback_changes
        end
      end
    end
  end
end