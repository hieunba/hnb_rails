name             "rails"
maintainer       "Nghiem Ba Hieu"
maintainer_email "hi3unb@gmail.com"
license          "MIT"
description      "Installs/Configures rails"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.5.2'

supports 'ubuntu', '>= 16.04'

depends "ruby_rbenv", "~> 2.0.6"
depends "sudo", "~> 4.0.0"
depends "database"
depends "nginx", "~> 7.0.2"
depends "bluepill"
depends "logrotate"
depends 'poise-service', '~> 1.5.2'
depends 'mysql', '~> 8.5.1'
depends 'mysql2_chef_gem', '~> 2.1.0'
