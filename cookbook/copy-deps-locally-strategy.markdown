---
layout: cookbook
title: Deployment &rarr; production (with deps via local copy)
---

This third strategy involves deployment to a production server with dependencies
right from your deployment machine via a local copy.

This strategy is similar to strategy two, with the exception that the production server
does not need access to your git repository to be able to install dependencies.

As with case two the deployment server (which may just be your local computer) **must**
have access to the git repository (remote or not), and be able to pull from it.

The deployment server **must** also have ssh access to the production server:

This method currently works only with Symfony2 and Composer.

{% highlight ruby %}
# deploy.rb

set   :application,   "My App"
set   :deploy_to,     "/var/www/my-app.com"
set   :domain,        "my-app.com"

set   :scm,              :git
set   :repository,       "file:///Users/deployer/sites/my-app"
set   :deploy_via,       :capifony_copy_local
set   :use_composer,     true
set   :use_composer_tmp, true

role  :web,           domain
role  :app,           domain, :primary => true

set   :use_sudo,      false
set   :keep_releases, 3
{% endhighlight %}

In this case, on every `cap deploy`, capifony will:

* create a local tmp directory
* clone the latest project version from the **local** git repo into the **tmp** repo
* run a composer install to install dependencies in the **tmp** repo
* ssh to production (`my-app.com`)
* copy the **tmp** repo with dependencies onto the production server
* create a new release path (`/var/www/my-app.com/releases/...`)
* run deployment hooks (`cache:warmup`, `cc`, etc.) 

For more detail run with the following in your deploy.rb:

{% highlight ruby %}
# deploy.rb

# Be more verbose by uncommenting the following line
logger.level = Logger::MAX_LEVEL
{% endhighlight %}

Copying the whole project and its dependencies on every deploy is very expensive and slow, but will give you
the advantage of production servers not requiring access to private github repositories.

> NOTE: This method uses a custom strategy located in `lib/capistrano/recipes/deploy/strategy/capifony_copy_local.rb`
> that extends the default capistrano copy strategy.
> The test suite does not currently support testing of the ruby `run_locally` method, therefore this deployment
> strategy may break if the capistrano copy strategy is changed.
