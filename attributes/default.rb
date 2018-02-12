default["rails"]["applications_root"] = "/u/apps"
default["rbenv"]["binaries_url"] = "http://binaries.intercityup.com/ruby/ubuntu"
default["rbenv"]["available_binaries"] = %w(1.9.3-p547 2.0.0-p481 2.1.0 2.1.1 2.1.2 2.1.3 2.1.5 2.2.1)
default['rbenv']['group_users'] = %w(deploy)

default['rails']['ruby']['ruby_version'] = '2.1.0'
default['rails']['ruby']['rails_version'] = '4.1.16'
default['rails']['ruby']['timeout'] = 1500
default['rails']['ruby']['bundler_version'] = '1.15.4'

case node["platform_family"]
when "debian"
  if node["platform"] == "ubuntu" && node["platform_version"] == "14.04"
    default["nginx"]["pid"] = "/run/nginx.pid"
  end
end
