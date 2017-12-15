$ruby_scl = '/usr/bin/scl enable rh-ruby24 --'
$install_root = inline_template('<%= ENV["DISTELLI_INSTALLHOME"] %>')
$app_root = inline_template('<%= ENV["DISTELLI_APPHOME"] %>')

# Configure Ruby 2.4
package {'centos-release-scl': ensure => present}
package {'rh-ruby24': ensure => present}

exec {'ensure bundler':
  command => "${ruby_scl} gem install bundler"
}


# Configure Demo App
exec {'install app':
  command => "${ruby_scl} bundle install --deployment",
  cwd     => $install_root,
}

user {'demo-app':
  ensure     => present,
  managehome => true,
}

file {'/lib/systemd/system/demo-app.service':
  ensure  => file,
  owner   => root,
  mode    => '0644',
  content => @("EOF")
    [Unit]
    Description=Demo Ruby App Deployed by Distelli and Puppet
    After=network.target

    [Service]
    Type=simple
    User=demo-app
    WorkingDirectory=${app_root}
    ExecStart=${ruby_scl} bundle exec rackup --host 127.0.0.1 --port 9000
    | EOF
}

exec {'reload systemd':
  command     => '/bin/systemctl daemon-reload',
  refreshonly => true,
  subscribe   => [
    File['/lib/systemd/system/demo-app.service'],
  ],
}


# Configure NGINX Reverse Proxy
include nginx

nginx::resource::server {fact('fqdn'):
  listen_port    => 80,
  listen_options => 'default_server',
  proxy          => 'http://127.0.0.1:9000',
}

# Exercise for the reader: configure SELinux to allow NGINX to proxy traffic
# to port 9000 and configure the firewall to allow traffic to port 80 along
# with SSH, ICMP, Distelli agent, etc.
class {selinux: mode => permissive}
class {firewall: ensure => stopped}
