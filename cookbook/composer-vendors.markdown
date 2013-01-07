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
set :copy_vendors, false
{% endhighlight %}

<hr />

## Scripts

By default Composer does not run the `post-install` or `post-update` scripts 
specified within the `composer.json` file. This is because the `composer_options`
default is `--no-scripts --verbose --prefer-dist`

Some extenal bundles may require a script to run with deployment. If you require
composer to run scripts you can use the `composer_options` variable to specifiy
what is included when the composer command is called. For example to run the scripts
update the parameter:

{% highlight ruby %}
set :composer_options,  "--verbose --prefer-dist"
{% endhighlight %}
