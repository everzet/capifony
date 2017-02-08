---
layout: cookbook
title: Generate autoload class map
---

By default capifony does not take advantage of composer's generate class map feature. In order to autogenerate the class map after deployment add these lines to your `deploy.rb` file:

{% highlight ruby %}
after 'symfony:composer:install', 'composer:class_map_generation'
after 'symfony:composer:update', 'composer:class_map_generation'

namespace :composer do
  task :class_map_generation do
    capifony_pretty_print "--> Generating class map with composer"

    run "#{try_sudo} sh -c 'cd #{latest_release} && #{composer_bin} dump-autoload --optimize'"
    capifony_puts_ok
  end
end
{% endhighlight %}

For more information on composer's autoload generate class map feature check out
http://getcomposer.org/doc/03-cli.md#dump-autoload