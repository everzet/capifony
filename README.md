Deploying symfony Applications with Capistrano
==============================================

[![Build Status](https://secure.travis-ci.org/everzet/capifony.png?branch=master)](http://travis-ci.org/everzet/capifony)

Capistrano is an open source tool for running scripts on multiple servers.
Its primary use is for easily deploying applications. While it was built
specifically for deploying Rails apps, it’s pretty simple to customize it
to deploy other types of applications. We’ve been working on creating a
deployment “recipe” to work with symfony applications to make our job a
lot easier.


## Prerequisites ##

- Symfony 1.4+ OR Symfony2
- Must have SSH access to the server you are deploying to.
- Must have Ruby and RubyGems installed on your machine (not required
  for deployment server)


## Installing Capifony ##

### Through RubyGems.org ###

	sudo gem install capifony

### Through GitHub ###

	git clone git://github.com/everzet/capifony.git
	cd capifony
	gem build capifony.gemspec
	sudo gem install capifony-{version}.gem


## What's next? ##

Read the [capifony documentation](http://capifony.org/)

## Running the test suite ##

You need a set of dependencies in order to run the capifony's test suite.
You can use **Bundler** to install these dependencies:

    bundle install --gemfile=.gemfile

Then, run the tests using **Rake**:

    rake spec

For more information, see the `.travis.yml` file.


## Contributors ##

* everzet (owner): [http://github.com/everzet](http://github.com/everzet)
* Arlo Borras (contributor): [http://github.com/arlo](http://github.com/arlo)
* Xavier Gorse (contributor): [http://github.com/xgorse](http://github.com/xgorse)
* Travis Roberts (creator of improved version): [http://blog.centresource.com/author/troberts/](http://blog.centresource.com/author/troberts/)
* Brent Shaffer (contributor): [http://github.com/bshaffer](http://github.com/bshaffer)
* William Durand (maintainer): [http://github.com/willdurand](http://github.com/willdurand)
* And, [All contributors](https://github.com/everzet/capifony/contributors)


## License ##

Capifony is released under the MIT License. See the bundled LICENSE file for details.
