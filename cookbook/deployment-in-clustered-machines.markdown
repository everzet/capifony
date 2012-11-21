---
layout: cookbook
title: Deployment in clustered machines
---

When you need to perform the same deploy in more than one machine at the same time,
you can use the `HOSTS` parameter as follows:

### Setup the machines

Before you can use any of the Capistrano deployment tasks with your project, you will need to
make sure all of your servers have been prepared, for that run:

	cap HOSTS="machine1.domain, machine2.domain" deploy:setup


### Deploy

 The rest of the task must run same as a normal deploy, but always using the `HOSTS` parameter

	cap HOSTS="machine1.domain, machine2.domain" deploy


### Multistage deploy

	cap HOSTS="machine1.domain, machine2.domain" stage_name deploy
