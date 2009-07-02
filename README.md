# Capifony

Capistrano is a utility and framework for executing commands in parallel on multiple remote machines, via SSH.
Capifony is a batch of Capistrano reciepts, writed for symfony framework.

## DEPENDENCIES

* Capistrano (http://github.com/capistrano/capistrano/tree/master);
* git (http://git-scm.com/) on development & production. For now, only git supported, working on SVN integration;
* symfony framework 1.2+, installed on development & production servers;
* SSH connection to production server.

## WORKFLOW

![Diagram](http://everzet.com/images/capifony.png)

* There is your symfony project on development server (your PC/Notebook), that stored inside git repository;
* There is production server. Your VPS or server with connection over SSH. Main git repository stored on it and production version of project is pulled from it.
* You make changes in your development project, commit them and push to the remote repository on the production server. 'cap deploy' task connects to the production server over SSH and pull all your changes from remote repository to remote project.

## USAGE

In general, you'll use Capifony as follows:

1. Go into new project directory on your development server/machine, generate symfony project;

2. Run <code>capify .</code>;

3. Download or clone capifony, replace "Capfile" in symfony project root directory with downloaded one & place symfony.rb in config subdirectory;

4. Edit <code>config/deploy.rb</code> to match this:
<pre>
    set :application,   "example-app"
    set :repository,    "/path/to/your/production/repos/"
    set :releases_path, "/path/to/your/www/"
    set :host,          "hostname"
    set :db_orm,        "Propel"
    set :db_dsn,        "mysql:host=localhost;dbname=example-app"
    set :db_user,       "root"
    set :db_pass,       "$secr3t"
</pre>
5. Run <code>cap git:init</code>. This will generates <code>.gitignore</code> file & inits empty repository in project directory. <code>.gitignore</code> by defaults ignoring <code>config/ProjectConfiguration.class.php</code> & <code>config/databases.yml</code>, because them is server dependent. You can autogenerate them later on production by calling <code>cap symfony:setup_remote</code> & <code>cap db:setup_remote</code>;

6. Run <code>git add . && git commit -am 'initial commit'</code>. You done initial commit;

7. Run <code>cap symfony:test_remote</code> task. It will download <code>check_configuration.php</code> to your production server, runs it, removes it from production & show it's output;

8. If everything in previous step goes fine, run <code>cap deploy:setup</code> task. This task is wrapper to call <code>git:setup_remote</code>, <code>symfony:setup_remote</code>, <code>db:setup_remote</code> tasks.
    * <code>cap git:setup_remote</code> creates 'bare' repository on production server, pushes local commits into it, and clones production project from it;
    * <code>cap symfony:setup_remote</code> generates <code>config/ProjectConfiguration.class.php</code> with right path for symfony installation;
    * <code>cap db:setup_remote</code> runs <code>symfony configure:database</code> with data from <code>deploy.rb</code>.

9. You're done. Now you can:
    1. Make changes;
    2. Commit changes, by calling <code>git commit -am 'done something'</code>;
    3. When you're done with changes & ready to deploy - run <code>git push && cap deploy</code>.

## ADDITIONAL TASKS:

* <code>cap db:get_dump</code> runs <code>symfony doctrine:data-dump</code> on the production server, commit fixtures in repo, pull them locally & run <code>symfony doctrine:data-load</code>;
* <code>cap db:push</code> same as <code>get_dump</code>, but in another direction;
* <code>cap git:ignore</code> only creates <code>.gitignore</code> file.

## LICENSE:

(The MIT License)

Copyright (c) 2009 Konstantin Kudryashov <ever.zet@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
