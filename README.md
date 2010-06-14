Deploying symfony Applications with Capistrano
==============================================

Capistrano is an open source tool for running scripts on multiple servers. It’s primary use is for easily deploying applications. While it was built specifically for deploying Rails apps, it’s pretty simple to customize it to deploy other types of applications. We’ve been working on creating a deployment “recipe” to work with symfony applications to make our job a lot easier.

Prerequisites
-------------

- Must have SSH access to the server you are deploying to.
- Must have Ruby and RubyGems installed on your machine (not required for deployment server)’

Installing Capifony
-------------------

### Through RubyGems.org ###

	sudo gem install capifony

### Through GitHub ###

	git clone git://github.com/everzet/capifony.git
	cd capifony
	gem build capifony.gemspec
	sudo gem install capifony-{version}.gem

Setup your project to use Capifony
----------------------------------

CD to your project directory & run:

	capifony .

This will create `Capfile` in your project root & `deploy.rb` config file in `config` directory

Fill up your `config/deploy.rb` with your server connection data

Server Setup
------------

Now, you can start the deployment process! To get your server setup with the file structure that Capistrano expects, you can run:

	cap deploy:setup

This command will create the following folder structure on your server:

	|-- deploy_to_path
	  |-- current (symlink)
	  |-- releases
	    |-- 20100512131539
	    |-- 20100509150741
	    |-- 20100509145325
	  |-- shared
	    |-- log
	    |-- web
	      |-- uploads

The folders in the releases directory will be the actual deployed code, timestamped. Capistrano symlinks your log & web/uploads directories from your app to the directories in the shared folder so that it doesn’t get erased when you deploy a new version of your code.

To deploy your application, simply run:

	cap deploy

Deployment
----------

To configure database on production environment, run:

	cap symfony:configure:database

To deploy your application for the first time, you can run:

	cap deploy:cold

This will deploy your application, configures databases.yml (will ask you about DSN, user, pass), create the db, models, forms, filters, and run all of your migrations.

Now, whenever you need to deploy a new version of your code, just run:

	cap deploy

Databases
---------

If you need to dump remote database & download this dump to local `backups/` folder, run:

	cap database:dump:remote

If you need to dump local database & put this dump to local `backups/` folder, run:

	cap database:dump:local

If you need to dump remote database & populate this dump on local machine, run:

	cap database:move:to_local

If you need to dump local database & populate this dump on remote server, run:

	cap database:move:to_remote

Shared folders
--------------

If you need to download some shared folders from remote server, run:

	cap shared:{databases OR log OR uploads]:to_local

If you need to upload some shared folders to remote server, run:

	cap shared:{databases OR log OR uploads]:to_remote

Other tasks
-----------

If you need to deploy and run your migrations you can call:

	cap deploy:migrations

We’ve also added a custom task to run your test suite on the production server. You can invoke this by calling:

	cap deploy:tests:all

This will deploy the application, rebuild the test database, then run all of the tests.

Also, you have command to run your custom symfony tasks:

	cap symfony:run_task

If you want to see all of the Capistrano tasks available, you can run:

	cap -T

We’ve been using this setup for a little while now, and it’s saved us a ton of time when we need to push changes for a site to the production server.

Contributors
============

* everzet (owner): [http://github.com/everzet](http://github.com/everzet)
* Travis Roberts (creator of improved version): [http://blog.centresource.com/author/troberts/](http://blog.centresource.com/author/troberts/)
* Arlo (contributor): [http://github.com/arlo](http://github.com/arlo)
* Xavier Gorse (contributor): [http://github.com/xgorse](http://github.com/xgorse)
