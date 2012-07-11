---
layout: cookbook
title: "Shared folders and symfony 1.x"
---

If you need to download some shared folders from remote server, run:

    cap shared:{databases OR log OR uploads]:to_local

If you need to upload some shared folders to remote server, run:

    cap shared:{databases OR log OR uploads]:to_remote

