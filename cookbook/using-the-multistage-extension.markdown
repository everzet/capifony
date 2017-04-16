---
layout: cookbook
title: Using the multistage extension
---

Capistrano provides a [Multistage
extension](https://github.com/capistrano/capistrano/wiki/2.x-Multistage-Extension)
which allows to use a different deployment strategy for different scenarios. For
instance, for your application, you might have two servers: one for production,
where the "live" code is, and one for staging, where you can test features out
without risk of affecting anything critical.

<hr />

## Installation

In order to use the **Multistage extension**, you need to add the following
lines to your `deploy.rb` file:

{% highlight ruby %}
set :stages,        %w(production staging)
set :default_stage, "staging"
set :stage_dir,     "app/config"
require 'capistrano/ext/multistage'
{% endhighlight %}

The first parameter `:stages` configures your different stages. In that case, we
just have two stages `production`, and `staging` which is also the _default
stage_.
The `:stage_dir` parameter allows to configure the path to your configuration
files for each stage.

<hr />

## Configuration

In order to configure each stage, you must create a configuration file per
stage. In that case, you have to create both `app/config/production.rb` and
`app/config/staging.rb` files.

The `production.rb` file contains your **production** settings:

{% highlight ruby %}
server 'production.server.com', :app, :web, :primary => true
{% endhighlight %}

The `staging.rb` file contains your **staging** settings:

{% highlight ruby %}
server 'staging.server.com', :app, :web, :primary => true
{% endhighlight %}

That's it!

<hr />

## Usage

As you configured the `:default_stage` parameter with `staging`, all tasks will
be run with your `staging` settings.

But now, you can run `cap production deploy` to deploy your application to your
production server, and it's the same pattern for all tasks:

    cap staging taskname

Where _stage_ can be either `staging`, or `production` in our example.
