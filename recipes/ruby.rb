#
# Cookbook:: rails
# Recipe:: ruby
# Copyright:: 2018, Nghiem Ba Hieu, All Rights Reserved.
version = node['rails']['ruby']['ruby_version']

rbenv_system_install 'system'

rbenv_ruby version do
  verbose true
end

rbenv_global version

rbenv_gem 'rails' do
  version node['rails']['ruby']['rails_version']
  rbenv_version version
  timeout node['rails']['ruby']['timeout']
end

rbenv_gem 'bundler' do
  version node['rails']['ruby']['bundler_version']
  rbenv_version version
end

applications_root = node['rails']['applications_root']

if node['active_applications']
  node['active_applications'].each do |app, app_info|
    if app_info[:ruby_version]
      rbenv_ruby app_info[:ruby_version] do
        verbose true
      end
    end
  end
end
