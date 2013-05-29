---
layout: cookbook
title: How to keep Symfony2 sessions after deploy
---

> NOTE : This feature is not available for versions prior to 2.1.X

You may have noticed that after deploying your Symfony2 application all sessions
are vanishing. Basically, the reason behind it is a cache removal. 

According to the best practices you should not add cache directory into shared folders
(and CVS repository as well). Therefore Capifony creates new cache directory for each
deploy which results in creating new empty sessions directory. 

> NOTE: In Symfony2 **standard edition** sessions are stored in the cache directory.

In order to change sessions save path change the `save_path` parameter under a `framework`
node in your application's `config.yml`

{% highlight yaml %}
framework:
    session:
        save_path: "%kernel.root_dir%/sessions/"
{% endhighlight %}

You have to add also your sessions directory to Capifony's `:shared_children`

{% highlight ruby %}
# deploy.rb
set :shared_children, [log_path, ..., app_path + "/sessions"]
{% endhighlight %}
