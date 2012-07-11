---
layout: reference
title: Capistrano Configuration Reference
---

Capistrano is highly configurable, and any option that exists for Capistrano
also exists for capifony.

<hr />

By default, capifony will ssh with your current system user, but you can change
this behavior with `set :user` parameter:

{% highlight ruby %}
set :user, "deployer"
{% endhighlight %}

If you’re using your own private keys for git, you might want to tell Capistrano
to use agent forwarding (which means that the production server uses your local
keys to pull from git):

{% highlight ruby %}
ssh_options[:forward_agent] = true
{% endhighlight %}

You can also tell cap the exact branch to pull from during deployment:

{% highlight ruby %}
set :branch, "v0.2.0"
{% endhighlight %}

If you’re using git submodules, you must tell cap to fetch them:

{% highlight ruby %}
set :git_enable_submodules, 1
{% endhighlight %}

If you connect to your production server using a non-traditional port,
set the port manually:

{% highlight ruby %}
ssh_options[:port] = "22123"
{% endhighlight %}

If you are not allowed sudo ability on your host you can use the following
configuration:

{% highlight ruby %}
set :use_sudo, false
{% endhighlight %}

If your host complains about the entire project being group-writable, add the
following configuration:

{% highlight ruby %}
set :group_writable, false
{% endhighlight %}

You can use the `cap deploy:cleanup` task to delete old releases on the server.
By default, Capifony will keep the last 5 releases.
You can choose to keep a different number of releases by setting the
`keep_releases` parameter:

{% highlight ruby %}
set :keep_releases, 3
{% endhighlight %}

Since capifony 2.1.8, the verbosity has been reduced, and human readable
messages are printed, so that you can easily follow the deployment process.
If you want to change this behavior, configure the logger in your `deploy.rb`
file:

{% highlight ruby %}
# IMPORTANT = 0
# INFO      = 1
# DEBUG     = 2
# TRACE     = 3
# MAX_LEVEL = 3
logger.level = Logger::MAX_LEVEL
{% endhighlight %}
