---
layout: cookbook
title: Managing External Vendors with Composer
---

By default Capifony will install vendors using `bin/vendors`. Since Symfony 2.1
[Composer](http://getcomposer.org) has become the default package manager. To
use Composer you must add the following to your configuration:

{% highlight ruby %}
set :use_composer, true
{% endhighlight %}

<hr />

## Update Vendors

When using Composer it will run `composer.phar install` by default. If you want
to update your vendors, add the following parameter:

{% highlight ruby %}
set :update_vendors, true
{% endhighlight %}

<hr />

## Shared Vendors

If you want to share the vendor folders between deployments you can add the following
to your configuration:

{% highlight ruby %}
set :copy_vendors, true
{% endhighlight %}

<hr />

## Composer Options

You can control command line options passed to composer like so:

{% highlight ruby %}
set :composer_options,  "--no-dev --verbose --prefer-dist --optimize-autoloader --no-progress"
{% endhighlight %}

This means that by default, any post-install/post-update hooks that are defined in your `composer.json` file will run. You can disable that behavior by passing `--no-scripts` as one of the options above, and perhaps tell Capifony to run separate scripts in your `deploy.rb` file.
