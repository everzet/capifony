---
layout: cookbook
title: Speeding up deploy
---

With default configuration, capifony will reinstall all your vendors for each deploy.
If you feel that is inefficient, you can manage to have your vendors just updated, not
reinstalled.

Add these lines to your `deploy.rb` file:

    set :vendors_mode, "install"
    set :update_vendors, true
    before "symfony:vendors:install", "symfony:copy_vendors"
     
    namespace :symfony do
      desc "Copy vendors from previous release"
      task :copy_vendors, :except => { :no_release => true } do
        pretty_print "--> Copying vendors from previous release"
        run "cp -a #{previous_release}/vendor/* #{latest_release}/vendor/"
        puts_ok
      end
    end

Now, each time you deploy, your vendors will be copied from your previous release,
and then vendors will be updated, not reinstalled from scratch. This means that, in
case you did not change your vendors, deploy will be faster.

Please notice that is not the same as putting your vendors folder in shared.
A shared vendor folder does not allow for real independent releases, and also causes
a downtime on your current release while deploying.
