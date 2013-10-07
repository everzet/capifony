### Upgrade to Capistrano v3

#### Overview
* Capistrano v3 offers some new features (but still in beta)
  * Moves to Rake DSL instead of proprietary
  * SSHKit library (command mapping is extremely handy!)
  * Easier testing/speccing
  * Supposedly faster?
* Remove symfony 1 support
* Now composer only for dependency management (remove bin/vendors script support)
* Simplification thanks to capistrano rewrite, and feature set. capifon v2 was
  duplicating some functionality already available in capistrano
* Idempotent tasks - (i.e. no longer need to run "deploy:setup")
* No more magic, all variables have to be fetched: `fetch(:my_variable)`

#### New task execution flow
Tasks in brackets are only run based on specific configurations

```
deploy
  deploy:starting
    [before]
      (deploy:linked_parameters)
    deploy:check
  deploy:started
  deploy:updating
    git:create_release
    deploy:symlink:shared
    deploy:create_cache_dir
    (deploy:set_permissions)
    (deploy:linked_parameters:copy_template)
  deploy:updated
    [before]
      composer:run => composer:get && composer:[install|update]
    [after]
      (deploy:assets:normalize)
      (deploy:clear_controllers)
  deploy:publishing
    deploy:symlink:release
    deploy:restart
  deploy:published
  deploy:finishing
    deploy:cleanup
  deploy:finished
    deploy:log_revision
```

#### New tasks
* `linked_parameters:check` & `linked_parameters:copy_template`  - Helps with
  sharing parameters file between deploys. Can be improved if/when SSHKit gets
  more features

#### Changed tasks
* `deploy:set_permissions` has been re-written, and given some child tasks
  for easier maintainability. Only acl guaranteed to work due to lack of
  `use_sudo`
  - `deploy:set_permissions:acl`
  - `deploy:set_permissions:chown`
  - `deploy:set_permissions:chmod`
* `symfony:project:clear_controllers` renamed -> `deploy:clear_controllers`

#### Removed tasks
* `deploy:cold` - what use was this?
* `deploy:test_all` - Better implemented by end user imo
* `deploy:finalize_update`, split into:
  - `deploy:assets:normalize`
  - `deploy:create_cache_dir`
* `assets:install` - Composer runs this in the symfony standard edition, is it
  needed?
* `bootstrap:build` - Also handled by composer?

#### Tasks yet to be implemented
* `symfony:doctrine` tasks
* `symfony:propel` tasks
* `deploy:web` tasks (maintenence page)
* `deploy:drop` - is this needed?
* `deploy:shared_childs` - capistrano handles this natively with `linked_dirs` and `linked_files`

#### Changed/renamed variables
`shared_files` -> `linked_files`
`shared_children` -> `linked_dirs`

#### Removed variables
`vendors_mode` - irrelevant with composer
`use_composer` - always yes
`clear_controllers` -> not needed, just make `controllers_to_clear` empty array
`symfony_version` -> Not sure if this is needed any more?
`build_bootstrap`

#### New variables
`composer_download_path` - might change due to MITM problems?
`app_config_file_template`
`use_config_file_template`
`app_config_file_path`
`app_config_template_path`

#### Work in progress
* capistrano v3 has not yet figured out what to do with `use_sudo`
* Feature parity with v2 branch
  * Bring back pretty output and progress bar
  * Missing tasks
  * Copy vendors strategy
  * Running composer install locally (not currently possible imo?)
* More composer tasks? (add warnings for deploys without a `composer.lock` file?)
* Test suite (see capistrano v3 for examples)
* Use `lib/capistrnao/templates` by `bin/capifony` for installation
* Not sure if we can put `config.rb` into `app/config` (maybe not needed with
  proposed changes to folder structure for Symfony standard edition)
* Figure out strategies for handling `parameters.yml` file
* Need to work out proper use of `on roles :app`
* Streaming of `symfony:logs:tail`?
* Bring back `no_release` exclusion for some tasks e.g. ` on roles :app, reject: lambda { |h| h.properties.no_release } do`
* Add ruby file wrappers around path variables like capistrano does i.e. `release_path` in capistrano
* More simplification of variables that can be set would be nice

#### Things that are waiting for more features in SSHKit/capistrano
* `shared` tasks - needs more SSHKit features
* `database` (backup) tasks - needs more SSHKit features

#### Some issues may be fixed thanks to capistrano v3 rewrites

Capistrano has changed how it handles multiple hosts, which fixes
some pain points/current github issues for capifony

* https://github.com/everzet/capifony/issues/359
* https://github.com/everzet/capifony/issues/399
* https://github.com/everzet/capifony/issues/365
