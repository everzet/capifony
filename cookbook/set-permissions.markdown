---
layout: cookbook
title: Automatically set proper permissions
---

As described by the [Symfony2 documentation](
http://symfony.com/doc/current/book/installation.html#configuration-and-setup)
you have to set proper permissions to `app/cache` and `app/logs` folders which
have to be writable by your webserver.

> NOTE : This feature is not available for version prior to 2.1.X

<hr />

## Settings

There are 3 variables to care about when using this task:

- `:writable_dirs`: That's where you specifiy the relative path of dirs that
  must be writable by your webserver user (i.e. app/cache app/logs for
  Symfony2)
- `:webserver_user`: This is the name of your webserver_user (i.e www-data for
  many Apache distributions)
- `:permission_method`: The method to use for setting permissions (supported
  values are `:acl`, `:chmod` and `:chown`)
- `:use_set_permissions`: This parameter defines whether to run the `set_permissions`
  task. This param is `false` by default (supported values `true`, `false`)

> NOTE : `:acl` method rely on the `setfacl` command which may not be available by
> default on your system (i.e. Debian) you may then [enable ACL support](
> https://help.ubuntu.com/community/FilePermissionsACLs) before using it.

> NOTE : `:chown` method must only be used if neither `:acl` nor `:chmod` can
> be used on your system. Please note that to use this method you have to set
> the `:use_sudo` variable to `true`!

Here is a basic exemple of what your `deploy.rb` may look like:

{% highlight ruby %}
set :writable_dirs,     ["app/cache", "app/logs"]
set :webserver_user,    "www-data"
set :permission_method, :acl
set :use_set_permissions, true
{% endhighlight %}

> NOTE : For multistage usage you just have to override these variables on
> stage specific files if ever needed.
