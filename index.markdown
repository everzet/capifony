---
layout: home
title: capifony &mdash; symfony and Symfony2 deployment
---

## 1. Install script

First, install `capifony` itself with [RubyGems](http://rubygems.org/):

{% highlight bash %}
$ gem install capifony
{% endhighlight %}

<hr />

## 2. Setup project

Setup initial deployment configuration for your project:

{% highlight bash %}
$ cd path/to/your/project
$ capifony .
{% endhighlight %}

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

{% highlight bash %}
$ gem install capistrano_rsync_with_remote_cache
{% endhighlight %}

Now, change your deployment strategy in `deploy.rb`:

{% highlight ruby %}
set :deploy_via, :rsync_with_remote_cache
{% endhighlight %}

In this case, rsync will create a cache on your production server and will push
**only** files that have changed between deploys.

<hr />

<div class="step">
    <h2 id="setup_server"><a href="#setup_server">4. Setup server</a></h2>
    <p>
        Now, you can start the deployment process! To get your server setup with the directory structure that Capistrano expects,
        `cd` to your local project directory and run:
    </p>
    <pre>
<span class="prompt">$&gt;</span> cap deploy:setup</pre>
    <p>
        (You'll only have to run this once!)
    </p>
    <p>
        This command will create the following approximate directory structure on your server.
        The exact structure will depend on if you're deploying a symfony 1.x or Symfony2 application:
    </p>
    <pre>
`-- /var/www/my-app.com
|-- current → /var/www/my-app.com/releases/20100512131539
|-- releases
|-- 20100512131539
|-- 20100509150741
`-- 20100509145325
`-- shared
|-- log
|-- config
    `-- databases.yml
`-- web
    `-- uploads
    </pre>
    <p>
        The folders in the releases directory will be the actual deployed code, as timestamped directories.
        In a symfony 1.x application, for example, Capistrano symlinks your `log` &amp; `web/uploads` directories from your app
        to the directories in the shared folder so that it doesn’t get erased when you deploy a new version of your code.
    </p>
    <p>
        To quickly setup a new server, you can do:
    </p>
    <pre>
<span class="prompt">$&gt;</span> cap HOSTS=new.server.com deploy:setup</pre>
</div>

<div class="step">
    <h2 id="deploy"><a href="#deploy">5. Deploy!</a></h2>
    <p>
        To deploy your application, simply run:
    </p>
    <pre>
<span class="prompt">$&gt;</span> cap deploy</pre>
    <p>
        Depending on your setup, you may need to ssh onto your server to setup additional, shared files after your first deployment
        (e.g. `app/config/parameters.yml` if you're using Symfony2 with the deployment recipe listed below).
    </p>
    <p>
        Something went wrong???
    </p>
    <pre>
<span class="prompt">$&gt;</span> cap deploy:rollback</pre>
</div>

<div class="step">
    <h2 id="symfony2_deployment"><a href="#symfony2_deployment">Symfony2 Deployment</a></h2>
    <p>
        If you're deploying a Symfony2 application, then this section is probably for you. This section explains how to configure capifony to deploy
        an application that uses the `bin/vendors` file to manage vendor libraries and the `app/config/parameters.yml`
        file for server-specific configuration (like database connection information).
    </p>
    <p>
        First, add the following to your `app/config/deploy.rb` file so that the `parameters.yml` file is shared between all deployments:
    </p>
    <pre>
set :shared_files,      ["app/config/parameters.yml"]</pre>

    <p>
        Next, share the `vendor` directory between all deployments to make deploying faster:
    </p>
    <pre>
set :shared_children,     [app_path + "/logs", web_path + "/uploads", "vendor"]</pre>

    <p>
        To install your vendors, capifony will rely on `bin/vendors` by default.
        But the recommended dependency manager is now <a href="http://getcomposer.org">Composer</a>.
        In order to use it, just add the following configuration:
    </p>
    <pre>
set :use_composer, true</pre>

    <p>
        If you want to update your vendors, add the following parameter:
    </p>
    <pre>
set :update_vendors, true</pre>

    <p>
        It will run `composer.phar update` if you use Composer, `bin/vendors` otherwise.
        Note that the `bin/vendors` can be configured using the `:vendors_mode` parameter to decide which action to run (upgrade, install,
        or reinstall).
    </p>

    <p>
        The final step is to configure your `app/config/parameters.yml` file. The best way to do this is to create this file in shared folder on server manually:
    </p>
    <pre>
<span class="prompt">$&gt;</span> ssh your_deploy_server
<span class="prompt">$&gt;</span> mkdir -p /var/www/my-app.com/shared/app/config
<span class="prompt">$&gt;</span> vim /var/www/my-app.com/shared/app/config/parameters.yml</pre>

    <p>
        Once your `parameters.yml` file is correctly configured, you should be able to test your deployed application.
        On every subsequent deploy, that same `app/config/parameters.yml` file will by symlinked into your application,
        meaning you only need to configure after the initial deploy.
    </p>
</div>

<div class="step">
    <h2 id="configuration_reference"><a href="#configuration_reference">Configuration Reference</a></h2>
    <p>Capifony is highly configurable, and any option that exists for capistrano also exists for capifony</p>

    <p>
        By default, capifony will ssh with your current system user, but you can change this behavior with `set :user` parameter:
    </p>
    <pre>
set :user, "deployer"</pre>
    <p>
        If you’re using your own private keys for git, you might want to tell Capistrano to use agent forwarding (which means that the production server uses your local keys to pull from git):
    </p>
    <pre>
ssh_options[:forward_agent] = true</pre>
    <p>
        You can also tell cap the exact branch to pull from during deployment:
    </p>
    <pre>
set :branch, "v0.2.0"</pre>
    <p>
        If you’re using git submodules, you must tell cap to fetch them:
    </p>
    <pre>
set :git_enable_submodules, 1</pre>
    <p>
        If you connect to your production server using a non-traditional port, set the port manually:
    </p>
    <pre>
ssh_options[:port] = "22123"</pre>
    <p>If you are not allowed sudo ability on your host you can use the following configuration:</p>
    <pre>
set :use_sudo, false</pre>
    <p>If your host complains about the entire project being group-writable, add the following configuration:</p>
    <pre>
set :group_writable, false</pre>
    <p>
        You can use the `cap deploy:cleanup` task to delete old releases on the server. By default, Capifony will keep the last 5 releases.
        You can choose to keep a different number of releases by setting the `keep_releases` parameter:
    </p>
    <pre>
set :keep_releases, 3</pre>
    <p>
        Since capifony 2.1.8, the verbosity has been reduced, and human readable messages are printed, so that you can easily follow
        the deployment process. If you want to change this behavior, configure the logger in your `deploy.rb` file:
    </p>
    <pre>
# IMPORTANT = 0
# INFO      = 1
# DEBUG     = 2
# TRACE     = 3
# MAX_LEVEL = 3
config.logger = Logger::MAX_LEVEL</pre>

    <p></p>

    <h3>Symfony configuration parameters</h3>
    <p>
        All symfony tasks (both **symfony 1.x** and **Symfony2**) run using the default `php`
        binary on the production server. You can change this via:
    </p>
    <pre>
set :php_bin, "/path/to/php"</pre>
    <p>
        All symfony tasks (both **symfony 1.x** and **Symfony2**) also run inside the `prod`
        environment on production server. You can change this via:
    </p>
    <pre>
set :symfony_env_prod, "staging"</pre>
    <p>
        By default, capifony will try to configure your `config/databases.yml` on every **symfony 1.x**
        project deployment (if it's not present) on production. You can turn this behavior off with:
    </p>
    <pre>
set :use_orm, false</pre>
    <p>
        In Symfony2, you can choose the ORM you are using (Doctrine, or Propel). The default ORM is Doctrine.
    </p>
    <pre>
set :model_manager, "propel"</pre>

    <p>
        If you want to use a shared symfony library instead of one bundled inside a **symfony 1.x** project, define the path to it with:
    </p>
    <pre>
set :symfony_lib, "/path/to/symfony"</pre>
    <p>
        If your `app` or `web` paths in **Symfony2** differ from default the default paths, you can specify them with:
    </p>
    <pre>
set :app_path, "my_app"
set :web_path, "my_web"</pre>
    <p>
        If you use **AsseticBundle** with **Symfony2**, then you probably want to dump assets on every deploy:
    </p>
    <pre>
set :dump_assetic_assets, true</pre>

    <p>
        If you are working with a continuous process, you may want to automate everything.
        You can turn off the interactive mode by setting the following parameter to `false`:
    </p>
    <pre>
set :interactive_mode, false</pre>
</div>

<div class="step">
    <h2 id="other_features"><a href="#other_features">Other Features</a></h2>

    <h3>Databases</h3>
    <p>If you need to dump remote database, and download this dump to local `backups/` folder, run:</p>
    <pre>
cap database:dump:remote</pre>
    <p>If you need to dump local database, and put this dump to local `backups/` folder, run:</p>
    <pre>
cap database:dump:local</pre>
    <p>If you need to dump remote database, and populate this dump on local machine, run:</p>
    <pre>
cap database:move:to_local</pre>
    <p>If you need to dump local database, and populate this dump on remote server, run:</p>
    <pre>
cap database:move:to_remote</pre>
    <p></p>

    <h3>Shared folders and symfony 1.x</h3>
    <p>
        If you need to download some shared folders from remote server, run:
    </p>
    <pre>
cap shared:{databases OR log OR uploads]:to_local</pre>
    <p>If you need to upload some shared folders to remote server, run:</p>
    <pre>
cap shared:{databases OR log OR uploads]:to_remote</pre>
    <p></p>

    <h3>Enabling/Disabling applications</h3>
    <p>
        If you want to quickly disable your application, run:
    </p>
    <pre>
cap deploy:web:disable</pre>
    <p>
        It will use the `project:disable` task with symfony 1.x, or will install a `maintenance.html`
        page with Symfony2.
    </p>
    <p>
        To enable the application, just run:
    </p>
    <pre>
cap deploy:web:enable</pre>
    <p>
        Same here, it will use the `project:enable` task with symfony 1.x, and will remove the
        `maintenance.html` page with Symfony2.
    </p>
    <p>
        For Symfony2 users, you can customize the page by specifying the `REASON`,
        and `UNTIL` environment variables:
    </p>
    <pre>
cap deploy:web:disable \
REASON="hardware upgrade" \
UNTIL="12pm Central Time"</pre>
    <p>
        You can use a different template for the maintenance page by setting the
        `:maintenance_template_path` variable in your `deploy.rb` file. The template file
        should either be a plaintext or an erb file.
    </p>

    <h3>Other tasks</h3>
    <p>If you need to deploy and run your migrations you can call:</p>
    <pre>
cap deploy:migrations</pre>
    <p>To run your test suite on the production server, just invoke:</p>
    <pre>
cap deploy:tests:all</pre>
    <p>You can invoke tasks/commands by calling:</p>
    <pre>
cap symfony</pre>
    <p>If you want to see all available tasks, you can run:</p>
    <pre>
cap -T</pre>
</div>

<hr />

## Known Issues

If you get the following error message `sudo : no tty present and no askpass
program specified`, add this parameter:

{% highlight ruby %}
default_run_options[:pty] = true
{% endhighlight %}

<hr />

## Cookbook

To learn more about **capifony**, you can read these recipes:

* [Using the Multistage extension](cookbook/using-the-multistage-extension.html)
