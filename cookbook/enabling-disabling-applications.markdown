---
layout: cookbook
title: Enabling/Disabling applications
---

If you want to quickly disable your application, run:

    cap deploy:web:disable

It will use the `project:disable` task with symfony 1.x, or will install a
`maintenance.html` page with Symfony2.

To enable the application, just run:

    cap deploy:web:enable

Same here, it will use the `project:enable` task with symfony 1.x, and will
remove the `maintenance.html` page with Symfony2.

For Symfony2 users, you can customize the page by specifying the `REASON`,
and `UNTIL` environment variables:

    cap deploy:web:disable \
    REASON="hardware upgrade" \
    UNTIL="12pm Central Time"

You can use a different template for the maintenance page by setting the
`:maintenance_template_path` variable in your `deploy.rb` file. The template
file should either be a plaintext or an erb file.
