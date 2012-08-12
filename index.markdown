---
layout: default
title: symfony and Symfony2 deployment
---

## 1. Install script

First, install `capifony` itself with [RubyGems](http://rubygems.org/):

    gem install capifony

<hr />

## 2. Setup project

Setup initial deployment configuration for your project:

    cd path/to/your/project
    capifony .

This will create a `Capfile` in your project root, and a `deploy.rb` config file
in `config/` (for symfony 1.x projects) or in `app/config/` (for Symfony2
projects).

<hr />

## 3. Configure

Fill up your `config/deploy.rb` (or `app/config/deploy.rb`) with your server
connection data. But first, you must choose your deployment strategy.

### a) deployment &rarr; scm &rarr; production

The first strategy involves deployment to a production server via an intermediate
git repository server.
In this case, the production server **must** have access to your Git
repository (remote or not) and be able to issue a "pull" from it.
You **must** have ssh access to the production server from wherever
you're deploying from:

![](/images/strategy_a.png)

{% highlight ruby %}
# deploy.rb

set   :application,   "My App"
set   :deploy_to,     "/var/www/my-app.com"
set   :domain,        "my-app.com"

set   :scm,           :git
set   :repository,    "ssh-gitrepo-domain.com:/path/to/repo.git"

role  :web,           domain
role  :app,           domain
role  :db,            domain, :primary => true

set   :use_sudo,      false
set   :keep_releases, 3
{% endhighlight %}

In this case, on every `cap deploy`, capifony will:

* ssh to production (`my-app.com`)
* create a new release path (`/var/www/my-app.com/releases/...`)
* clone the latest project version from the remote git repo (`ssh-gitrepo-domain.com`)
* copy the source code, pulled from git, into the release path
* run deployment hooks (`cache:warmup`, `cc`, etc.)

If you don't want to clone the whole repository on every deploy, you can set the
`:deploy_via` parameter:

{% highlight ruby %}
set :deploy_via, :remote_cache
{% endhighlight %}

In this case, a git repository will be kept on the server and Capifony will only
fetch the changes since the last deploy.

### b) deployment &rarr; production (via copy)

The second strategy involves deployment to a production server right from your
deployment machine via a copy.
In this case, the deployment server (which may just be your local computer) **must**
have access to the git repository (remote or not), and be able to pull from it.
The deployment server **must** also have ssh access to the production server:

![](/images/strategy_b.png)

{% highlight ruby %}
# deploy.rb

set   :application,   "My App"
set   :deploy_to,     "/var/www/my-app.com"
set   :domain,        "my-app.com"

set   :scm,           :git
set   :repository,    "file:///Users/deployer/sites/my-app"
set   :deploy_via,    :copy

role  :web,           domain
role  :app,           domain
role  :db,            domain, :primary => true

set   :use_sudo,      false
set   :keep_releases, 3
{% endhighlight %}

In this case, on every `cap deploy`, capifony will:

* ssh to production (`my-app.com`)
* create a new release path (`/var/www/my-app.com/releases/...`)
* clone the latest project version from the **local** git repo
* copy the source code, pulled from git, onto the production server via wires
* run deployment hooks (`cache:warmup`, `cc`, etc.)

Of course, copying the whole project on every deploy is very expensive and slow.
Fortunately, you can optimize things with the
`capistrano_rsync_with_remote_cache` gem:

    gem install capistrano_rsync_with_remote_cache

Now, change your deployment strategy in `deploy.rb`:

{% highlight ruby %}
set :deploy_via, :rsync_with_remote_cache
{% endhighlight %}

In this case, rsync will create a cache on your production server and will push
**only** files that have changed between deploys.

<hr />

## 4. Setup server

Now, you can start the deployment process! To get your server setup with the
directory structure that Capistrano expects, `cd` to your local project
directory and run:

    cap deploy:setup

(You'll only have to run this once!)

This command will create the following approximate directory structure on your
server. The exact structure will depend on if you're deploying a symfony 1.x or
Symfony2 application:

    `-- /var/www/my-app.com
    |-- current → /var/www/my-app.com/releases/20100512131539
    |-- releases
    |   `-- 20100512131539
    |   `-- 20100509150741
    |   `-- 20100509145325
    `-- shared
       |-- web
       |    `-- uploads
       |-- log
       `-- config
           `-- databases.yml

The folders in the releases directory will be the actual deployed code, as
timestamped directories. In a symfony 1.x application, for example, Capistrano
symlinks your `log` &amp; `web/uploads` directories from your app to the
directories in the shared folder so that it doesn’t get erased when you deploy a
new version of your code.

To quickly setup a new server, you can do:

    cap HOSTS=new.server.com deploy:setup

<hr />

## 5. Deploy!

To deploy your application, simply run:

    cap deploy

Depending on your setup, you may need to ssh onto your server to setup
additional, shared files after your first deployment (e.g.
`app/config/parameters.yml` if you're using Symfony2 with the deployment recipe
listed below).

Something went wrong???

    cap deploy:rollback

<hr />

## Symfony2 Deployment

If you're deploying a Symfony2 application, then this section is probably for
you. This section explains how to configure capifony to deploy an application
that uses the `bin/vendors` file to manage vendor libraries and the
`app/config/parameters.yml` file for server-specific configuration (like
database connection information).

First, add the following to your `app/config/deploy.rb` file so that the
`parameters.yml` file is shared between all deployments:

{% highlight ruby %}
set :shared_files,      ["app/config/parameters.yml"]
{% endhighlight %}

Next, share the `vendor` directory between all deployments to make deploying
faster:

{% highlight ruby %}
set :shared_children,     [app_path + "/logs", web_path + "/uploads", "vendor"]
{% endhighlight %}

To install your vendors, capifony will rely on `bin/vendors` by default.
But the recommended dependency manager is now
[Composer](http://getcomposer.org). In order to use it, just add the following
configuration:

{% highlight ruby %}
set :use_composer, true
{% endhighlight %}

If you want to update your vendors, add the following parameter:

{% highlight ruby %}
set :update_vendors, true
{% endhighlight %}

It will run `composer.phar update` if you use Composer, `bin/vendors` otherwise.
Note that the `bin/vendors` can be configured using the `:vendors_mode`
parameter to decide which action to run (upgrade, install, or reinstall).

The final step is to configure your `app/config/parameters.yml` file. The best
way to do this is to create this file in shared folder on server manually:

    ssh your_deploy_server
    mkdir -p /var/www/my-app.com/shared/app/config
    vim /var/www/my-app.com/shared/app/config/parameters.yml

Once your `parameters.yml` file is correctly configured, you should be able to
test your deployed application. On every subsequent deploy, that same
`app/config/parameters.yml` file will by symlinked into your application,
meaning you only need to configure after the initial deploy.

<hr />

## Useful Tasks

If you need to deploy and run your migrations you can call:

    cap deploy:migrations

To run your test suite on the production server, just invoke:

    cap deploy:tests:all

You can invoke tasks/commands by calling:

    cap symfony

If you want to see all available tasks, you can run:

    cap -vT

<hr />

## Configuration References

[Capistrano Configuration](reference/capistrano.html)

[Symfony Configuration](reference/symfony.html)

<hr />

## Cookbook

To learn more about **capifony**, you can read these recipes:

[Enabling/Disabling
applications](cookbook/enabling-disabling-applications.html)

[Using the Multistage
extension](cookbook/using-the-multistage-extension.html)

[Shared folders with symfony 1.x](cookbook/shared-folders-with-symfony-1x.html)

[Specifying Deployment Dependencies](cookbook/specifying-deployment-dependencies.html)

[Setup an automatic upload of parameters file](cookbook/upload-parameters-file.html)

[Setup proper permissions](cookbook/set-permissions.html)

[Speeding up deploy](cookbook/speeding-up-deploy.html)

[Working with databases](cookbook/working-with-databases.html)

<hr />

## Known Issues

If you get the following error message `sudo : no tty present and no askpass
program specified`, add this parameter:

{% highlight ruby %}
default_run_options[:pty] = true
{% endhighlight %}
