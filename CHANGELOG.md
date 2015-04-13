### 2.8.5 / ???

n/a

### 2.8.4 / April 13, 2015

* Fixed: update_assets_version by date of last modified file
* Fixed: replace latest_release with current_path and write tests

*Important:* http://williamdurand.fr/2015/04/11/on-capifony-and-its-future/

### 2.8.3 / December 17, 2014

* Fixed: rollback using the sudo context if available.
* Fixed: support for hosts other then localhost when using `database:copy:to_local`
* Fixed: revert "Recreated composer autoload after `deploy:rollback`

### 2.8.2 / October 7, 2014

* Fixed: set default `:use_composer` to true
* Fixed: Inifile 3.0.0 gem is incompatible with Capifony. Use Inifile version >=
  2.0.2 and < 3.0.0. fixes #523

### 2.8.1 / August 14, 2014

* Fixed: use `--tabular` for `getfacl` instead of `-t` shortcut

### 2.8.0 / August 1, 2014

* Added: alternative way on Linux/Ubuntu to deploy using chmod option: access
  recursively all users write permissions to following directory.
* Added: rename database move commands to copy
* Added: check for possible already existing acl on directory
* Added: make `symfony:composer:install` run in interactive mode, to allow
  `parameters.(ini|yml)` configuration using
  `incenteev/composer-parameter-handle`

### 2.7.0 / May 16, 2014

* Added: support for command `doctrine:mongodb:fixtures:load`

### 2.6.0 / April 9, 2014

* Added: `no_release` for symfony1 `publish_assets`
* Added: allow to skip or not interactive_mode for the task `capifony:doctrine:load:fixtures`
* Added: support composer version specify (install/self-update)
* Removed: unneeded dump of autoload files

### 2.5.0 / February 11, 2014

* Added: more no_release attributes to allow using custom roles
* Fixed: symfony:assets:update_version executed before composer
* Fixed: updated the specified version for the ruby-progressbar to 1.4.1 (the
  latest version).
* Fixed: missing parameter "-p" for "getfacl" on CentOS
* Fixed: moved `cache warmup` task after `assetic dump` task
* Fixed: recreated composer autoload after deploy:rollback

### 2.4.2 / January 7, 2014

* Fixed: add null value(tylda) to regular expression (#447)
* Fixed: move set_permission task after cache warmup (#443, #453)
* Removed: unneeded overwrite of assetic `write_to` parameter when dumping
  assets (#451)

### 2.4.1 / November 19, 2013

* Fixed: Set facl permissions only once
* Fixed: error incompatible character encodings: UTF-8 and ASCII-8BIT
* Added: use SYMFONY_ENV for composer update call

### 2.4.0 / September 17, 2013

* Fixed: copy vendor dir to latest_release, not to latest_release/vendor
* Added: -h option with host into postgresql dump tasks
* Fixed: assets install step disappeared ??
* Added: variable to set options of dump-autoload action
* Added: missing backup_path definition for symfony 1
* Added: new gem dependency on fakefs (specs)
* Added: backup task for the shared folder
* Fixed: changed database backup filename to be human readable
* Added: license to gemspec
* Added: web_path variable
* Fixed: set symfony environment prior calling composer install

### 2.3.0 / July 26, 2013

* Use `symfony_env_*` variables to tail
* Allow more Capistrano version
* Allow custom backup path
* chown deployment is recursive now

### 2.2.10 / June 9, 2013

* "interactive_mode" should also affect composer
* Override copy strategy to allow vendors to be installed locally.
* Add "--no-progress" to composers default options
* Improved #112 password is passed to pg_dump and psql
* Implemented progress bar on "database:dump:remote"
* Implemented wrapper around "ruby-progressbar" gem
* also copy vendors for vendors:install and vendors:upgrade
* Updated composer_options for the upcoming changes in composer.

### 2.2.9 / May 6, 2013

* Change setfacl call to match Symfony2 permission granting instructions
* Fixed default deploy.rb (refs #354)
* Add 'symfony_debug' setting to toggle --no-debug on console commands
* Add test for #362
* Use capistrano-maintenance 0.0.3
* Added custom assets:install path
* update specs
* Dump Assetic files to latest release directory
* add unit test for doctrine_clear_use_flush_option
* remove inline condition
* add use of flush option in doctrine:clear_* task

### 2.2.8 / March 5, 2013

* Remove the ability to copy of Composer
* Use composer optimize autoloader
* BugFix running cap deploy with user_sudo = true
* replace run block for data capturing with capture method + make try_sudo work
* Update assets_version before installing assets
* Add pretty printing to symfony:assets:update_version
* Update capifony.gemspec

### 2.2.7 / February 3, 2013

* Implemented :doctrine_em configuration option (#321)
* Added :doctrine_em symbol with default value of `false`
* Added `before` hooks for relevant symfony:doctrine commands to assemble --em flag
* Added flag variable to commands being run
* Added tests for --em flag in spec file
* Updated specs for doctrine drop tasks
* Added confirmation to doctrine drops tasks
* Fixed symfony:doctrine:database:drop (missed --force argument too).
* Added confirmation for symfony:doctrine:database:drop and symfony:doctrine:schema:drop.
* Compatibility to Capistrano 2.14.1
* Fixed symfony:doctrine:schema:drop - added --force
* Task symfony:doctrine:schema:drop never actually droped schema because of missing --force parameter.

### 2.2.6 / January 17, 2013

* Clear controllers should only run on the app role
* Do not update composer [Closes #309]
* Use trysudo when running a custom symfony command

### 2.2.5 / December 29, 2012

* host specification in mysql remote operations

### 2.2.4 / December 13, 2012

* Fixed a typo
* Fix #294
* extended fallback code when using
* symlinks for file systems that don't support them
* Fix travis config
* Fix symfony:assets:update_version, add sh tests. Fixes #282
* Fix whitespaces
* Use config_path var instead of hardcoded value
* deploy:migrate primary restriction is not cascaded

### 2.2.3 / November 28, 2012

* #273. Create only one run call in the task and Tests
* #273. Make mor flexible clear_controllers
* Ensure the remote database password is not logged in plaintext
* Create a new variable to allow execute set_permissions automatically

### 2.2.2 / November 13, 2012

* test when running symfony:composer:{install,update} with enabled copy_vendors
* Fix missing #{php_bin} variables
* Added optional symfony:composer:copy_vendors

### 2.2.1 / November 2, 2012

* Move warn message to the description. Fix #201
* Update README (tests)
* Updated capistrano-maintenance version
* IMPORTANT: Fix maintenance tasks by adding a new dependency (capistrano-maintenance)
* Fix test, add more tests for the composer copy feature
* fix tests
* Update spec/capifony_symfony2_symfony_spec.rb
* Update lib/symfony2/symfony.rb
* Update lib/symfony2/symfony.rb
* Ignore "No such file or directory" on deploy:web:enable
* Added doctrine:fixtures:load
* [symfony1] Fix bad command with use_sudo = false
* Refactor symfony:vendors and symfony:cache tasks based on @leek work
* Fix composer tasks

### 2.2.0 / October 22, 2012

* Minor fixes
* Clean output in tests
* Fix travis build
* Dump autoloader generation
* Refactor specs
* Update CHANGELOG
* Fix #244
* Correct pretty_print on composer:get based on @simonchrz's patch
* Enable web tasks
* Update gemspec file
* Make version consistent with capistrano
* Add UPGRADE file
* Fix command again
* Fix missing method
* Fix command
* Rename files
* Improve command
* Remove old README.ja.md as it's not maintained anymore
* Add note about tests in README
* Update CHANGELOG
* Minor fixes
* Add tests for propel namespace
* Add tests for doctrine namespace
* Fix travis-ci setup
* Add more tests for the symfony namespace (Symfony2)
* Fix encoding
* Trying to fix dependencies
* Add testing tools to gemfile
* fix gemfile
* Add travis/bundler configs, bump version to 2.2.x-dev
* Introducing a test suite
* Refactored Symfony2 code
* Fix conflict with the pp gem
* cd command not found when composer self-update
* Fix #240
* Fixing spelling mistakes an code
* Fix composer tasks
* Fixing logic in deep_merge method for symfony1
* Fix symfony:doctrine:migrations:migrate when using pty by not using try_sudo. Also log current database version with level info.
* Fixed a problem with case-insensitivity. This worked on OS X, but not on Linux, because the file system is case sensitive.
* Take capistrano/ext/multistage parameter deploy_env into account when using different deploy environments.
* Avoid the unnecessary use of try_sudo to make remote dumps work, as Capifony doesn't seem to check if use_sudo is false.
* Added patch-5 branch modifications from https://github.com/leek/capifony/tree/patch-5 to enable using parameters.ini config files.

### 2.1.16 / September 25, 2012

* Add composer:dump_autoload to the finalize_update after hook
* Add new task to allow composer dump-autoload
* Added back the '#{try_sudo}' option to the command
* Tweaked the way 'assets_version' value is updated
* run "#{try_sudo}"
* Use try_sudo instead of run

### 2.1.15 / September 10, 2012

* Fix #203
* Preliminary testing seems to show that this is generally how try_sudo was meant to be implemented, and is in fact how it is required to be implemented to work with things that depend on the output of run.
* --index is an invalid option when doing an update
* Setup a configurable Composer binary also. Refs #212
* Make the Composer options configurable
* Added symfony:doctrine:schema:update
* Remove unnecessary code.
* Fix regression. 'try_sudo' behaves differently from 'run' regarding the 'do' block.
* Possible fix for #202
* set_permissions: fix for acl method
* Fix this fucking dumb task. #195

### 2.1.14 / August 22, 2012

* Fix escaping in clear controllers #195

### 2.1.13 / August 21, 2012

* check all .php files in stead of only _app.php
* fix clear controllers to also work with try_sudo
* use try_sudo in stead of run to execute commands, refs #189
* Add a symfony:project:clear_controllers
* .first instead of .last as the selected gem for symfony1/symfony2
* Enhance deploy:set_permissions to grant permissions to the shell user
* Fix currentVersion regex always returning nil
* Improve composer path checking
* Fix remote_command_exists
* Fix running doctrine migrations with allocated PTY
* Update lib/symfony1.rb

### 2.1.12 / August 6, 2012

* Enable options for assets:install
* Looked for sf1 settings DB file instead of sf2 one
* Add ability to tail `dev|prod.log`
* Put remote tmp directory in a variable so that it can be overriden

### 2.1.11 / July 20, 2012

* Fix hard-coded "app" references
* Fix hard-coded path to "app"
* Fix set_permissions task. Refs #166
* Try to fix #166
* Setting :roles, etc. for each task (Symfony2 only currently)
* Fix set_permissions task. Refs #166
* Fix documentation link
* Fix #163
* fix elsif synthax

### 2.1.10 / July 16, 2012

* Fix CS
* Add ownership check before changing permissions
* Add pretty output
* Fix normalizing assets
* Fix build bootstrap
* Added set_permissions task
* Fix PR #158
* fix for remote check of composer.phar, File.exist? only checks local files
* Fix capifony script
* Use `--no-scripts` during `composer install/update` to avoid useless/duplicate processing.
* Fixed database tasks for postgresql
* Better pretty output if error raised
* Add task for updating `assets_version` in `config.yml`
* Avoid the use of try_sudo
* More `:no_release`...
* Since `:roles` isn't used in Capifony, these need `:no_release` *at least*.
* Fixing missing `pretty_print`.

### 2.1.9 / July 3, 2012

* fixed regression

### 2.1.8 / July 2, 2012

* bugfixes
* fix database tasks to use role :db
* BC break: capifony now requires Capistrano >= 2.11.0
* added red color for error messages.
* added commented lines in the generated deploy.rb file to set verbosity as
  before.
* BC break: verbose mode is disabled by default (log level = IMPORTANT), so
  that it's more readable.
* added dependency to 'colored'.
* added human readable messages in deploy related tasks.
* removed unexistent Doctrine commands

### 2.1.7 / June 21, 2012

* added maintenance page feature for Symfony2, use symfony 1.4 tasks
  (project:disable, project:enable) to do the same.
* added `interactive_mode` variable. Allows to avoid the need to confirm
  task executions, useful for fully automated deployments.
* fixed propel regression.
* added new `symfony_version` variable automatically guessed.
* the `build_bootstrap` script to use is now configurable thanks to the
  `:build_bootstrap` variable.
* composer can be used with the `update_vendors` parameter, so that you can
  update composer dependencies.
* composer support updated, it downloads the `phar` if not available in the
  working directory.
* bugfixes.

### 2.1.6 / April 12, 2012

* bugfixes

### 2.1.3 / September 27, 2011

* propel support for Symfony2 (by @willdurand)
* cache warmup and assets install configurable (by @gigo6000)
* always use --no-debug with assetic (by @fernanDOTdo)
* fixed assetic bug (by @mbontemps)

### 2.1.2 / August 11, 2011

* fix for vendors install

### 2.1.1 / July 13, 2011

* support for rubygems 1.8

### 2.1.0 / June 24, 2011

* fully support different app path

### 2.0.9 / June 15, 2011

* migrations fixed in Symfony2

### 2.0.8 / June 14, 2011

* update_vendors functionality support (via @weaverryan)

### 2.0.7 / June 9, 2011

* more modular behavior (thanks Alif Rachmawadi)
* cache:clear command fix (thanks Marijn Huizendveld)

### 2.0.6 / May 4, 2011

* add write access to cache folder for deployer's usergroup

### 2.0.5 / May 3, 2011

* made the Symfony2 console command configurable (symfony_console) (thanks @ruudk)
* added --env=#{symfony_env_prod} to every Symfony2 console command (thanks @ruudk)

### 2.0.4 / April 23, 2011

* shared lib support in symfony1 (thanks @jakzal)

### 2.0.3 / April 16, 2011

* windows support for symfony1 database: tasks (thanks @akloboucnik)

### 2.0.2 / April 6, 2011

* db migration task refactoring (thanks @schmittjoh)

### 2.0.1 / March 30, 2011

* fixed wrong assetic command

### 2.0.0 / March 22, 2011

* optimized shared commands in symfony1 scripts
* added symfony2 deployment strategy
* added `use_orm` option to symfony1 recipes. Turn it off if you don't use ORM

### 0.4.2 / September 23, 2010

* added `symfony:doctrine:compile` task

### 0.4.1 / June 17, 2010

* added `symfony_env_local` variable, specifying local symfony environment to work with
* added third parameter (blocks) to `prompt_with_default` (as in `ask`)
* hided password from input & logs in `symfony:configure:database` task
* added confirmation dialogs to destructive ORM tasks
* run `project:clear-controllers` only on `prod` environment

### 0.4.0 / June 16, 2010

* added propel tasks (thanks to http://github.com/arlo)
* added orm abstraction
* added doctrine/symfony tasks
* huge refactoring of mostly everything (thanks to http://github.com/arlo)

### 0.3.3 / June 13, 2010

* added ability to change called php binary (thanks to http://github.com/xgorse)

### 0.3.2 / June 12, 2010

* fixed :finalize_update hooks (clear_controllers task now runs)

### 0.3.1 / June 11, 2010

* fixed deployment bug with new shared link instruction

### 0.3.0 / June 11, 2010

* fixed incorrect links bug (thanks to arlo)
* added database dumpers tasks
* database:move:* now uses database dumpers to actually dump

### 0.2.2 / June 6, 2010

* deployment bug with `mkdir shared/config` fixed

### 0.2.1 / June 5, 2010

* dependency fix

### 0.2.0 / June 5, 2010

* some fixes
* symfony:check_configuration task
* database move tasks
* shared folder tasks (move to_local, move to_remote)

### 0.1.0 / June 3, 2010

First ever working version.
