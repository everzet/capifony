---
layout: cookbook
title: Working with databases
---

If you need to dump remote database, and download this dump to local `backups/`
folder, run:

    cap database:dump:remote

If you need to dump local database, and put this dump to local `backups/` folder,
run:

    cap database:dump:local

If you need to dump remote database, and populate this dump on local machine,
run:

    cap database:move:to_local

If you need to dump local database, and populate this dump on remote server,
run:

    cap database:move:to_remote

