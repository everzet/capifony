---
layout: cookbook
title: Automatically set proper permissions
---

As described by the [Symfony2 documentation](
http://symfony.com/doc/current/book/installation.html#configuration-and-setup),
you must set the proper permissions for the `app/cache` and `app/logs` directories, since they need to be writable by your webserver.

> NOTE : This feature is not available for versions prior to 2.1.X

<hr />

## Settings

There are 4 parameters to care about when using this task:

- `:writable_dirs`: This is where you specifiy the relative path of dirs that
  must be writable by your webserver user (i.e. app/cache app/logs for
  Symfony2)
- `:webserver_user`: This is the name of your webserver_user (i.e www-data for
  many Apache distributions)
- `:permission_method`: The method to use for setting permissions (supported
  values are `:acl`, `:chmod` and `:chown`)
- `:use_set_permissions`: This parameter defines whether to run the `set_permissions`
  task. This param is `false` by default (supported values `true`, `false`)

> NOTE : The `:acl` method relies on the `setfacl` command which may not be available by
> default on your system (i.e. Debian).  You'll need to [enable ACL support](
> https://help.ubuntu.com/community/FilePermissionsACLs) before using it.

> NOTE : The `:chown` method must only be used if neither `:acl` nor `:chmod` can
> be used on your system. Please note that to use this method you have to set
> the `:use_sudo` variable to `true`!

Here is a basic example of what these parameters might look like in your `deploy.rb`:

{% highlight ruby %}
set :writable_dirs,       ["app/cache", "app/logs"]
set :webserver_user,      "www-data"
set :permission_method,   :acl
set :use_set_permissions, true
{% endhighlight %}

> NOTE : For multistage usage you just have to override these variables on
> stage specific files if ever needed.
