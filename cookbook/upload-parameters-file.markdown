---
layout: cookbook
title: Automatically upload your parameters.yml file
---

As recommanded by the [Symfony2 documentation](
http://symfony.com/doc/master/cookbook/workflow/new_project_git.html#initial-project-setup)
you shoud not put "parameters.ini" or "parameters.yml" file under version
control. This cookbook will show you a way to automatically upload your
parameters file during your deployment process.

<hr />

## The easy way

### Single stage

You can just copy and paste the snippet code below inside your `deploy.rb` file
replacing the origin_file value with yours (i.e. for Symfony 2.0.* replace
parameters.yml by parameters.ini).

#### Unshared parameters files:

{% highlight ruby %}
task :upload_parameters do
  origin_file = "app/config/parameters.yml"
  destination_file = latest_release + "/app/config/parameters.yml" # Notice the
  latest_release

  run "#{try_sudo} mkdir -p #{File.dirname(destination_file)}"
  top.upload(origin_file, destination_file)
end

before "deploy:share_childs", "upload_parameters"
{% endhighlight %}


####  Shared parameters files:

{% highlight ruby %}
task :upload_parameters do
  origin_file = "app/config/parameters.yml"
  destination_file = shared_path + "/app/config/parameters.yml" # Notice the
  shared_path

  run "#{try_sudo} mkdir -p #{File.dirname(destination_file)}"
  top.upload(origin_file, destination_file)
end

after "deploy:setup", "upload_parameters"
{% endhighlight %}

<hr />

### Multistage

You can also have multiple stages each having their own parameters file. To
accomplish this task you can also setup an automatic upload of parameters
files. For this exemple we are assuming that all your parameters files are
located on an `app/config/parameters` folder which contains `parameters_prod.yml`
and `parameters_staging.yml` files.

You can then use the same snippets as described in the previous part and past
it on you `staging.rb` and `prod.rb` files replacing the `origin_file` variable
if needed.

#### In case of a shared parameters file:

{% highlight ruby %}
# app/config/deploy/prod.rb - Shared parameters file.

task :upload_parameters do
  origin_file = "app/config/parameters/parameters_prod.yml"
  destination_file = shared_path + "/app/config/parameters.yml" # Notice the
  shared_path

  run "#{try_sudo} mkdir -p #{File.dirname(destination_file)}"
  top.upload(origin_file, destination_file)
end

after "deploy:setup", "upload_parameters"
{% endhighlight %}


#### In case of an unshared parameters file:

{% highlight ruby %}
# app/config/deploy/staging.rb - Unshared parameters file.

task :upload_parameters do
  origin_file = "app/config/parameters/parameters_staging.yml"
  destination_file = latest_release + "/app/config/parameters.yml" # Notice the
  latest_release.

  run "#{try_sudo} mkdir -p #{File.dirname(destination_file)}"
  top.upload(origin_file, destination_file)
end

before "deploy:share_childs", "upload_parameters"
{% endhighlight %}

<hr />

## The cleaner way

In the previous section we saw how to process this task easily but it needs
a lot of copy and paste in case of multistage usage. This second method is
a simple implementation that you can simply throw in your `deploy.rb` then you'll
just need to override variables in each of your stage specific \*.rb files.

{% highlight ruby %}
# app/config/deploy.rb

set :parameters_dir, "app/config/parameters"
set :parameters_file, false

task :upload_parameters do
  origin_file = parameters_dir + "/" + parameters_file if parameters_dir && parameters_file
  if origin_file && File.exists?(origin_file)
    ext = File.extname(parameters_file)
    relative_path = "app/config/parameters" + ext

    if shared_files && shared_files.include?(relative_path)
      destination_file = shared_path + "/" + relative_path
    else
      destination_file = latest_release + "/" + relative_path
    end
    run "#{try_sudo} mkdir -p #{File.dirname(destination_file)}"

    top.upload(origin_file, destination_file)
  end
end
{% endhighlight %}

Then you have to choose when to trigger this task. For that you'll copy the
corresponding line right after the previous task.

- For a **shared** parameters file: `after 'deploy:setup', 'upload_parameters'`
- For an **unshared** parameters file: `before 'deploy:share_childs', 'upload_parameters'`

> NOTE: In case of a shared parameters file, the upload of the file will occur
> during the deployement setup phase, while for an unshared parameters file the
> upload will occur every time you run your deploy task.

Then you can specify the right parameters file for each stage.

#### For the prod.rb file:

{% highlight ruby %}
# app/config/deploy/prod.rb

set :parameters_file, "parameters_prod.yml"
{% endhighlight %}

#### For the staging.rb file:

{% highlight ruby %}
# app/config/deploy/staging.rb

set :parameters_file, "parameters_staging.yml"
{% endhighlight %}
