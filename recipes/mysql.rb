#
# Author:: Nghiem Ba Hieu
# Cookbook:: rails
# Recipe:: mysql
#
# Copyright:: 2018, Nghiem Ba Hieu, All Rights Reserved
mysql2_chef_gem 'default' do
  action :install
end

bind_address = node['mysql']['bind_address'] || '127.0.0.1'

mysql_service 'default' do
  port '3306'
  version '5.7'
  bind_address bind_address
  initial_root_password node['mysql']['server_root_password'] || 'change me'
  action [:create, :start]
end
