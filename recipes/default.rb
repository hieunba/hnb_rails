#
# Cookbook Name:: rails
# Recipe:: default
#
# Copyright 2012, Michiel Sikkes
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

include_recipe "sudo"
include_recipe "nginx"

nginx_site 'default' do
  action :disable
end

include_recipe 'rails::mysql'

include_recipe "rails::setup"

applications_root = node[:rails][:applications_root]

if node[:active_applications]

  # Include library helpers
  ::Chef::Resource.send(:include, Rails::Helpers)

  node[:active_applications].each do |app, app_info|
    rails_env = app_info['rails_env'] || "production"
    deploy_user = app_info['deploy_user'] || "deploy"
    application_root = "#{applications_root}/#{app}"
    app_env = app_info['app_env'] || {}
    app_env['RAILS_ENV'] = rails_env

    rbenv_gem "bundler" do
      version node['rails']['ruby']['bundler_version']
      rbenv_version app_info['ruby_version']
    end

    directory "#{applications_root}/#{app}" do
      recursive true
      group deploy_user
      owner deploy_user
    end

    ["shared/config",
     "shared/bin",
     "shared/vendor",
     "shared/public",
     "shared/assets",
     "shared/bundle",
     "shared/tmp",
     "shared/tmp/sockets",
     "shared/tmp/cache",
     "shared/tmp/sockets",
     "shared/tmp/pids",
     "shared/log",
     "shared/system",
     "releases"].each do |dir|
      directory "#{applications_root}/#{app}/#{dir}" do
        recursive true
        group deploy_user
        owner deploy_user
      end
    end

    template "#{application_root}/shared/.ruby-version" do
      owner deploy_user
      group deploy_user
      mode 0600
      source "ruby-version.erb"
      variables ruby_version: app_info["ruby_version"]
    end

    if app_info['database_info']

      template "#{applications_root}/#{app}/shared/config/database.yml" do
        owner deploy_user
        group deploy_user
        mode 0600
        source "app_database.yml.erb"
        variables :database_info => app_info['database_info'], :rails_env => rails_env
      end

    end

    if app_info['ssl_info']
      template "#{applications_root}/#{app}/shared/config/certificate.crt" do
        owner "deploy"
        group "deploy"
        mode 0644
        source "app_cert.crt.erb"
        variables :app_crt=> app_info['ssl_info']['crt']
      end

      template "#{applications_root}/#{app}/shared/config/certificate.key" do
        owner "deploy"
        group "deploy"
        mode 0644
        source "app_cert.key.erb"
        variables :app_key=> app_info['ssl_info']['key']
      end
    end

    template "/etc/nginx/sites-available/#{app}.conf" do
      source "app_nginx.conf.erb"
      variables(
        name: app,
        domain_names: app_info["domain_names"],
        redirect_domain_names: app_info["redirect_domain_names"],
        client_max_body_size: app_info["client_max_body_size"],
        enable_ssl: File.exists?("#{applications_root}/#{app}/shared/config/certificate.crt"),
        custom_configuration: nginx_custom_configuration(app_info))
      notifies :reload, resources(service: "nginx")
    end

    template "#{applications_root}/#{app}/shared/config/unicorn.rb" do
      mode 0644
      source "app_unicorn.rb.erb"
      variables :name => app, :deploy_user => deploy_user, :number_of_workers => app_info['number_of_workers'] || 2
    end

    if node['platform_version'] == '14.04'
      template "/etc/init/#{app}.conf" do
        mode 0644
        source "unicorn_upstart.erb"
        variables(
          name: app,
          rails_env: rails_env,
          deploy_user: deploy_user,
          application_root: application_root
        )
      end
  
      service "#{app}" do
        provider Chef::Provider::Service::Upstart
        action [ :enable ]
      end
    end

    execute 'systemctl daemon-reload' do
      action :nothing
      user 'root'
    end

    service_command = "#{application_root}/current/bin/unicorn -D -c #{application_root}/shared/config/unicorn.rb"
    service_options = {}
    service_options['auto_reload'] = true
    service_options['reload_signal'] = 'HUP'
    service_options['stop_signal'] = 'TERM'
    service_options['restart_mode'] = 'on-failure'
    service_options['directory'] = "#{application_root}/current"

    template "/etc/systemd/system/#{app}.service" do
      source 'systemd.service.erb'
      notifies :run, 'execute[systemctl daemon-reload]', :immediately if service_options[:auto_reload]
      variables(
        name: app,
        auto_reload: service_options['auto_reload'],
        reload_signal: service_options['reload_signal'],
        stop_signal: service_options['stop_signal'],
        restart_mode: service_options['restart_mode'],
        directory: service_options['directory'],
        command: service_command,
        user: 'deploy',
        environment: { RAILS_ENV: rails_env }
      )
    end

    service app do
      action :enable
    end

    nginx_site "#{app}.conf" do
      action :enable
    end

    logrotate_app "rails-#{app}" do
      cookbook "logrotate"
      path ["#{applications_root}/#{app}/current/log/*.log"]
      frequency "daily"
      rotate 14
      create "644 #{deploy_user} #{deploy_user}"
    end

  end

end
