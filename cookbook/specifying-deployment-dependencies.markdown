---
layout: cookbook
title: Specifying Deployment Dependencies
---

Capistrano comes with a `deploy:check` task. You may wonder what the aim of this
task is, because most of the time when you run this task, everything is ok.
Actually, this task is configurable, and this recipe will explain you how to
configure it in order to make this task useful.

<hr />

Capistrano provides a `depend` method you can use in your `deploy.rb` file. This
method adds rules to the `deploy:check` process:

    depend :local,  :command, "git"
    depend :remote, :directory, "/path/to/dir/"

You can either add `:local` rules, or `:remote` rules.

<hr />

## Remote Dependencies

Locally, you can check if a command is available or not, but remotely,
Capistrano offers more checkers like:

* `:directory`: check the presence of a directory;
* `:file`: check the presence of a file;
* `:writable`: check whether a directory/file is writable;
* `:command`: check if a command is available;
* `:deb`: check if a package is installed;
