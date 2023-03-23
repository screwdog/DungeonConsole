# Give Up GitHub

This project has given up GitHub.  ([See Software Freedom Conservancy's *Give Up  GitHub* site for details](https://GiveUpGitHub.org).)

You can now find this project at [Codeberg](https://codeberg.org/screw_dog/DungeonConsole) instead.

Any use of this project's code by GitHub Copilot, past or present, is done without our permission.  We do not consent to GitHub's use of this project's code in Copilot.

Join us; you can [give up GitHub](https://GiveUpGitHub.org) too!

![Logo of the GiveUpGitHub campaign](https://sfconservancy.org/img/GiveUpGitHub.png)

DungeonConsole.jl
=================

A command line client for interacting with Dungeons bot (@dungeons@mastodon.social). Allows for viewing the current status of the adventure and voting for the current action.

NOT affiliated with Dungeons bot (which is developed/maintained/run by @astrelion@mastodon.social), this is simply for interacting with its public posts from my own personal account without using Mastodon directly.

## Caveats

This has been developed solely for my personal use and for personal development. Source code shared in case anyone is interested. This will likely not work well (or at all) for you.

## How to use

1. make sure you have a functioning [Julia](https://julialang.org) installation. I'm using v1.8.3, no idea what other version(s) this will work with.

2. obtain this package (or just the source). It's not in any registry so probably best to simply download the files in the "src" directory.

3. register the app to your Mastodon account. Go to "https://your.masto.server/settings/applications" and create a new application. Keep a record of:
    * client key
    * client secret
    * access token

4. create a configuration file "../dungeons_config.toml" and store the three pieces of information as "client_id", "client_secret", and "token".

5. start Julia in the correct directory (use `pwd()` to check, `cd("dir")` to change) and issue the commands:
    * `include("DungeonConsole.jl")`
    * `DungeonConsole.run()`

Copyright (C) 2023 Harry Ray. All rights reserved. Licensed under GPLv3
