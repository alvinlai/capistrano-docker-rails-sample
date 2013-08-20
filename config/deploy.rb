# -*- encoding : utf-8 -*-
require 'bundler/capistrano'
require 'capistrano/docker'

server 'cap_docker_server', :web, :app, :db, :primary => true
set :application, 'CapistranoDockerRailsExample'
set :deploy_to, '/var/www/rails_app'
set :use_sudo, false

set :scm, :git
set :repository, 'git@github.com:juwalter/capistrano-docker-rails-sample.git'
set :branch, 'master'

set :docker_repository, 'cap_docker_example/rails'
set :docker_app_root, '$HOME/APPS/cap_docker_rails_example'
set :docker_shell, "#{docker_app_root}/bin/docker-shell.sh"
set :docker_revisions_file, "#{docker_app_root}/REVISIONS"
set :app_control_script, "#{docker_app_root}/bin/control.sh"

namespace :docker do
  task :prepare do
    run "mkdir -p #{docker_app_root}"
    local_app_config_dir = File.expand_path('../deploy/cap_docker_rails_example', __FILE__)
    remote_app_root = capture("cd #{docker_app_root} && pwd").chomp
    upload "#{local_app_config_dir}/bin", "#{remote_app_root}", via: :scp, recursive: true
    upload "#{local_app_config_dir}/run", "#{remote_app_root}", via: :scp, recursive: true
    upload "#{local_app_config_dir}/host_nginx", "#{remote_app_root}", via: :scp, recursive: true
    upload "#{local_app_config_dir}/docker", "#{remote_app_root}", via: :scp, recursive: true
    upload "#{local_app_config_dir}/REVISIONS", "#{remote_app_root}", via: :scp, recursive: true
    upload "#{local_app_config_dir}/CONFIG", "#{remote_app_root}", via: :scp, recursive: true

    host_ip = capture(%q{ifconfig eth0 | sed -n 's/.*inet addr:\([0-9.]\+\)\s.*/\1/p'}).chomp
    run %Q{. #{docker_app_root}/CONFIG && sed -i "s/UPSTREAM_RAILS_HOST_AND_PORT_A/#{host_ip}:$GROUP_A_RAILS_PORT/"
             #{docker_app_root}/docker/web/web_conf/rails_app_group_a.conf}, shell: 'bash -l'
    run %Q{. #{docker_app_root}/CONFIG && sed -i "s/UPSTREAM_RAILS_HOST_AND_PORT_B/#{host_ip}:$GROUP_B_RAILS_PORT/"
             #{docker_app_root}/docker/web/web_conf/rails_app_group_b.conf}, shell: 'bash -l'
    puts %Q{
      ****************************************************************************************************************
      On the server:
        - (optional) Make additional modifications to the Dockerfile at "#{remote_app_root}/docker/web/Dockerfile"
                    (esp. MAINTAINER, possibly additional database libraries, etc.)
        - Add your deploy key "id_rsa" to "#{remote_app_root}/docker/web/dot_ssh" (necessary for github repo cloning)
        - Add known hosts (e.g. github) to "#{remote_app_root}/docker/web/dot_ssh/known_hosts"
        - Create docker repository: run "docker build -t #{docker_repository} #{remote_app_root}/docker/web"
        - Review #{remote_app_root}/host_nginx/sites-enabled/cap-docker-rails-example.conf
        - Copy #{remote_app_root}/host_nginx/sites-enabled/cap-docker-rails-example.conf to /etc/nginx/sites-enabled
        - Reload nginx: "sudo nginx -s reload"
      On your local machine again:
        - Ready for your first deployment: "cap deploy:setup" and "cap deploy:migrations"
      ****************************************************************************************************************
    }
  end
end

namespace :deploy do
  task :start do
    run "DOCKER_REPOSITORY=#{docker_repository} #{app_control_script} start", shell: 'bash -l'
  end
  task :stop do
    run "DOCKER_REPOSITORY=#{docker_repository} #{app_control_script} stop", shell: 'bash -l'
  end
  task :restart do
    run "DOCKER_REPOSITORY=#{docker_repository} #{app_control_script} restart", shell: 'bash -l'
  end
end
