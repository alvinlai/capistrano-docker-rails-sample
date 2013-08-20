capistrano-docker-rails-sample
==============================

Rails sample app for demonstrating capistrano-docker integration

Summary:
--------
This is an example Rails 4.0.0 project to show how https://github.com/juwalter/capistrano-docker works.
The fun stuff is in juwalter/capistrano-docker-rails-sample/blob/master/config/deploy.rb#L14 and
juwalter/capistrano-docker-rails-sample/tree/master/config/deploy/cap_docker_rails_example

The configuration and control.sh assumes http://nginx.org/ as your web server. The included
[Dockerfile](http://docs.docker.io/en/latest/use/builder/ "Dockerfile") configures an image with nginx and
rvm and ruby 2.0.

Zero downtime deploys leverage nginx' reverse-proxy feature with multiple upstream servers, see
juwalter/capistrano-docker-rails-sample/blob/master/config/deploy/cap_docker_rails_example/host_nginx/sites-enabled/cap-docker-rails-example.conf#L1

Prerequisites:
--------------
Have
 * http://www.docker.io/gettingstarted/#h_installation
 * nginx
installed and working on your server

Quick start:
------------
 * git clone git@github.com:juwalter/capistrano-docker-rails-sample.git
 * cd capistrano-docker-rails-sample
 * rvm use 2.0@capistrano-docker-rails-sample --rvmrc --create
 * bundle
 * (optional) adjust files at config/deploy/cap_docker_rails_example
 * cap docker:prepare (read the info at the end carefully; you need to prepare the Dockerfile with deploy keys and such)
 * before the next steps, make sure you have a docker repository for this app on your server
 * cap deploy:setup
 * cap deploy:migrations

Contribute:
-----------
 * Fork
 * Create a topic branch - git checkout -b my_branch
 * Rebase your branch so that all your changes are reflected in one commit
 * Push to your branch - git push origin my_branch
 * Create a Pull Request from your branch, include as much documentation as you can in the commit message/pull request, following these guidelines on writing a good commit message
 * Thanks :)
