Deploying symfony Applications with Capistrano
----------------------------------------------

Capistrano is an open source tool for running scripts on multiple servers. It’s primary use is for easily deploying applications. While it was built specifically for deploying Rails apps, it’s pretty simple to customize it to deploy other types of applications. We’ve been working on creating a deployment “recipe” to work with symfony applications to make our job a lot easier.

### Prerequisites ###

- Must have SSH access to the server you are deploying to.
- Must have Ruby and RubyGems installed on your machine (not required for deployment server)’

### Installing Capistrano ###

	sudo gem install capistrano

### Setup your project to use Capistrano ###

Place files & folders from this repository into appropriate folders in your project:

- `Capfile` &rarr; `/sf/proj/Capfile`
- `config/capifony.rb` &rarr; `/sf/proj/config/capifony.rb`
- `config/deploy.rb` &rarr; `/sf/proj/config/deploy.rb`

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
	    |-- log
	    |-- web
	      |-- uploads

The folders in the releases directory will be the actual deployed code, timestamped. Capistrano symlinks your log & web/uploads directories from your app to the directories in the shared folder so that it doesn’t get erased when you deploy a new version of your code.

To deploy your application, simply run:

	cap deploy

To configure database on production environment, run:

	cap symfony:configure:database

To deploy your application for the first time, you can run:

	cap deploy:cold

This will deploy your application, configures databases.yml (will ask you about DSN, user, pass), create the db, models, forms, filters, and run all of your migrations.

Now, whenever you need to deploy a new version of your code, just run:

	cap deploy

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
