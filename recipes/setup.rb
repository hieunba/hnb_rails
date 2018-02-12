deploy_group = 'deploy'

group deploy_group

user 'deploy' do
  comment 'Deploy User'
  group deploy_group
  home '/home/deploy'
  shell '/bin/bash'
  manage_home true
end

if node[:deploy_users]
  node[:deploy_users].each do |deploy_user|
    user deploy_user do
      comment "Deploy User #{deploy_user}"
      group deploy_user
      home "/home/#{deploy_user}"
      shell '/bin/bash'
      manage_home true
    end
  end
end

package 'libffi-dev'

include_recipe 'rails::dependencies'

include_recipe 'rails::ruby'
