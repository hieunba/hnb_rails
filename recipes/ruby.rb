#
# Cookbook:: rails
# Recipe:: ruby
# Copyright:: 2018, Nghiem Ba Hieu, All Rights Reserved.
version = node['rails']['ruby']['ruby_version']

global_prefix = node['rbenv']['global_prefix'] || '/opt/rbenv'

rbenv_system_install 'system' do
  global_prefix global_prefix
end

rbenv_ruby version do
  verbose true
end

rbenv_global version

link '/usr/bin/ruby' do
  to "#{global_prefix}/shims/ruby"
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
