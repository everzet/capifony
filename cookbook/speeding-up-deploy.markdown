---
layout: cookbook
title: Speeding up deploy
---

> As of
> [2.2.2](https://github.com/everzet/capifony/blob/master/CHANGELOG.md#222--november-13-2012),
> capifony provides this task. To use it, add `set :copy_vendors, true` to your deploy.rb file

With default configuration, capifony will reinstall all your vendors for each deploy.
If you feel that is inefficient, you can manage to have your vendors just updated, not
reinstalled.

Add these lines to your `deploy.rb` file:

{% highlight ruby %}
set :shared_children, [app_path + "/logs", web_path + "/uploads"]

# Symfony2 2.0.x
before "symfony:vendors:install", "symfony:copy_vendors"

# Symfony2 2.1
before 'symfony:composer:update', 'symfony:copy_vendors'

namespace :symfony do
  desc "Copy vendors from previous release"
  task :copy_vendors, :except => { :no_release => true } do
    if Capistrano::CLI.ui.agree("Do you want to copy last release vendor dir then do composer install ?: (y/N)")
      capifony_pretty_print "--> Copying vendors from previous release"

      run "cp -a #{previous_release}/vendor #{latest_release}/"
      capifony_puts_ok
    end
  end
end
{% endhighlight %}

Now, each time you deploy, your vendors will be copied from your previous release,
and then vendors will be updated, not reinstalled from scratch. This means that, in
case you did not change your vendors, deploy will be faster.

Please notice that is not the same as putting your vendors folder in shared.
A shared vendor folder does not allow for real independent releases, and also causes
a downtime on your current release while deploying.

If you don't need a prompt asking you if you want to copy vendors, you can use
the following code:

{% highlight ruby %}
before 'symfony:composer:install', 'composer:copy_vendors'
before 'symfony:composer:update', 'composer:copy_vendors'

namespace :composer do
  task :copy_vendors, :except => { :no_release => true } do
    capifony_pretty_print "--> Copy vendor file from previous release"

    run "vendorDir=#{current_path}/vendor; if [ -d $vendorDir ] || [ -h $vendorDir ]; then cp -a $vendorDir #{latest_release}/vendor; fi;"
    capifony_puts_ok
  end
end
{% endhighlight %}
