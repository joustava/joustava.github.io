---
layout: post
title:  "Welcome to joostoostdijk.com running on Jekyll!"
date:   2020-02-16 12:48:26 +0100
categories: jekyll update migration
---

This blog is build with [Jekyll](https://github.com/jekyll/jekyll)
Following are the steps I took to get a workflow up and running.

```bash
$ gem install jekyll bundler
$ jekyll new joostoostdijk.com
$ cd joostoostdijk.com
$ git init
$ bundle exec jekyll
A subcommand is required.
jekyll 4.0.0 -- Jekyll is a blog-aware, static site generator in Ruby

Usage:

  jekyll <subcommand> [options]

Options:
        -s, --source [DIR]  Source directory (defaults to ./)
        -d, --destination [DIR]  Destination directory (defaults to ./_site)
            --safe         Safe mode (defaults to false)
        -p, --plugins PLUGINS_DIR1[,PLUGINS_DIR2[,...]]  Plugins directory (defaults to ./_plugins)
            --layouts DIR  Layouts directory (defaults to ./_layouts)
            --profile      Generate a Liquid rendering profile
        -h, --help         Show this message
        -v, --version      Print the name and version
        -t, --trace        Show the full backtrace when an error occurs

Subcommands:
  compose
  docs
  import
  build, b              Build your site
  clean                 Clean the site (removes site output and metadata file) without building.
  doctor, hyde          Search site and print specific deprecation warnings
  help                  Show the help message, optionally for a given subcommand.
  new                   Creates a new Jekyll site scaffold in PATH
  new-theme             Creates a new Jekyll theme scaffold
  serve, server, s      Serve your site locally

~/Workspace/own/joostoostdijk.com · (master)
⟩ bundle exec jekyll compose
You must install the 'jekyll-compose' gem version > 0 to use the 'jekyll compose' command.

~/Workspace/own/joostoostdijk.com · (master)
⟩ bundle exec jekyll compose
You must install the 'jekyll-compose' gem version > 0 to use the 'jekyll compose' command.
```

Head over to [jekyll-compose on GitHub](https://github.com/jekyll/jekyll-compose) for installation instructions.
```bash
~/Workspace/own/joostoostdijk.com · (master)
⟩ bundle install
Fetching gem metadata from https://rubygems.org/...........
Fetching gem metadata from https://rubygems.org/.
Resolving dependencies...
Using public_suffix 4.0.3
Using addressable 2.7.0
Using bundler 2.1.4
Using colorator 1.1.0
Using concurrent-ruby 1.1.6
Using eventmachine 1.2.7
Using http_parser.rb 0.6.0
Using em-websocket 0.5.1
Using ffi 1.12.2
Using forwardable-extended 2.6.0
Using i18n 1.8.2
Using sassc 2.2.1
Using jekyll-sass-converter 2.1.0
Using rb-fsevent 0.10.3
Using rb-inotify 0.10.1
Using listen 3.2.1
Using jekyll-watch 2.2.1
Using kramdown 2.1.0
Using kramdown-parser-gfm 1.1.0
Using liquid 4.0.3
Using mercenary 0.3.6
Using pathutil 0.16.2
Using rouge 3.16.0
Using safe_yaml 1.0.5
Using unicode-display_width 1.6.1
Using terminal-table 1.8.0
Using jekyll 4.0.0
Fetching jekyll-compose 0.12.0
Installing jekyll-compose 0.12.0
Using jekyll-feed 0.13.0
Using jekyll-seo-tag 2.6.1
Using minima 2.5.1
Bundle complete! 7 Gemfile dependencies, 31 gems now installed.
Use `bundle info [gemname]` to see where a bundled gem is installed.
```
Update `_config.yml` with preferred settings.

IMPORTANT:

- prepend `JEKYLL_ENV=production` to serve command when wanting to check commenting as it is disabled in delvopment.
- use `bundle info minimal-mistakes-jekyll` to find the original templates. To override copy to project root and edit.


