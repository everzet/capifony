Deploying symfony Applications with Capistrano
----------------------------------------------

Capistrano is an open source tool for running scripts on multiple servers. It’s primary use is for easily deploying applications. While it was built specifically for deploying Rails apps, it’s pretty simple to customize it to deploy other types of applications. We’ve been working on creating a deployment “recipe” to work with symfony applications to make our job a lot easier.

### Prerequisites ###

- Must have SSH access to the server you are deploying to.
- Must have Ruby and RubyGems installed on your machine (not required for deployment server)’

### Installing Capistrano ###

	sudo gem install capistrano

### Setup your project to use Capistrano ###

	cd path/to/your/app
	capify .

This will create a few files for you. It will create a Capfile in the root of your project. It will also create a directory named config (if it doesn’t exist already) and place a file named deploy.rb in the config folder. That’s where you will add/change any application-specific settings for your deployment recipe.

Now replace your Capfile & deploy.rb with repo's one & add application specific options to new deploy.rb.

### Server Setup ###

Now, you can start the deployment process! To get your server setup with the file structure that Capistrano expects, you can run

	cap deploy:setup

This command will create the following folder structure on your server:

	|-- deploy_to_path
	  |-- current (symlink)
	  |-- releases
	    |-- 20100512131539
	    |-- 20100509150741
	    |-- 20100509145325
	  |-- shared
	    |-- cached-copy
	    |-- log
	    |-- pids
	    |-- system

The folders in the releases directory will be the actual deployed code, timestamped. The pids folder in the shared directory is only used for Rails applications, so you can ignore it completely. Capistrano symlinks your log directory from your app to the log directory in the shared folder so that it doesn’t get erased when you deploy a new version of your code.

This is an important step! Before you deploy the application for the first time, it’s really a good idea to scp your databases.yml file up to your server so you can set the proper credentials for your production server and keep it out of your repository. Make sure you put the databases.yml file into the shared/system directory, because we already have a task that will symlink it when each new code version is deployed.

Now, to deploy your application for the first time, you can run:

	cap deploy:cold

This will deploy your application, create the db, models, forms, filters, and run all of your migrations.

Now, whenever you need to deploy a new version of your code, you can just run:

	cap deploy

If you need to deploy and run your migrations you can call:

	cap deploy:migrations

We’ve also added a custom task to run your test suite on the production server. You can invoke this by calling:

	cap deploy:testall

This will deploy the application, rebuild the test database, then run all of the tests.

If you want to see all of the Capistrano tasks available, you can run:

	cap -T

We’ve been using this setup for a little while now, and it’s saved us a ton of time when we need to push changes for a site to the production server.

Contributors
============

* everzet (creator): [http://github.com/everzet](http://github.com/everzet)
* Travis Roberts (creator of improved version): [http://blog.centresource.com/author/troberts/](http://blog.centresource.com/author/troberts/)