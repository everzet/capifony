---
layout: reference
title: Symfony Configuration Reference
---

All symfony tasks (both **symfony 1.x** and **Symfony2**) run using the default
`php` binary on the production server. You can change this via:

{% highlight ruby %}
set :php_bin, "/path/to/php"
{% endhighlight %}

All symfony tasks (both **symfony 1.x** and **Symfony2**) also run inside the
`prod` environment on production server. You can change this via:

{% highlight ruby %}
set :symfony_env_prod, "staging"
{% endhighlight %}

<hr />

## symfony 1.x

By default, capifony will try to configure your `config/databases.yml` on every
**symfony 1.x** project deployment (if it's not present) on production.
You can turn this behavior off with:

{% highlight ruby %}
set :use_orm, false
{% endhighlight %}

If you want to use a shared symfony library instead of one bundled inside a
**symfony 1.x** project, define the path to it with:

{% highlight ruby %}
set :symfony_lib, "/path/to/symfony"
{% endhighlight %}

<hr />

## Symfony2

In Symfony2, you can choose the ORM you are using (Doctrine, or Propel).
The default ORM is Doctrine.

{% highlight ruby %}
set :model_manager, "propel"
{% endhighlight %}

If your `app` or `web` paths in **Symfony2** differ from default the default
paths, you can specify them with:

{% highlight ruby %}
set :app_path, "my_app"
set :web_path, "my_web"
{% endhighlight %}

If you use **AsseticBundle** with **Symfony2**, then you probably want to dump
assets on every deploy:

{% highlight ruby %}
set :dump_assetic_assets, true
{% endhighlight %}

If you are working with a continuous process, you may want to automate everything.
You can turn off the interactive mode by setting the following parameter to `false`:

{% highlight ruby %}
set :interactive_mode, false
{% endhighlight %}
