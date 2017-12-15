Distilli Ruby Demo
==================

This document describes how to set up a simple Ruby web application deployed
by Distelli to a virtual machine configured by Puppet.

This guide assumes the following resources are available:

  - A GitHub account.

  - A Distelli account.

  - A local development environment with Git and Ruby v2.4 installed
    along with the bundler gem.

  - A server running CentOS 7 where the Ruby application will be deployed.


Step 1: Creating the Ruby App
-----------------------------

The Ruby application used in this exercise will be extremely simple in order
to keep focus on using Distelli for deployment and Puppet for configuration.

A simple Ruby application can be created using the Sinatra framework. The first
step in doing so is to create a `Gemfile` in the local development environment
that lists the Sinatra dependency:


```ruby
# Gemfile
source 'https://rubygems.org'

gem 'sinatra',               '~> 2.0'
```

Once the `Gemfile` has been created, run `bundle install --path=vendor/bundle`
to download and install the latest version of Sinatra 2. Using the `--path`
option keeps the Ruby packages used in this exercise sandboxed to the
`vendor/bundle` directory instead of installing them system-wide where they
could interfere with other Ruby exercises.

Once Sinatra has been installed by Bundler, the next step is to create two
additional files, `app.rb` and `config.ru`, which respectively contain the
application code and the instructions for running the app under a webserver:


```ruby
# app.rb
require 'sinatra/base'

module DistelliDemo; end

class DistelliDemo::App < Sinatra::Base
  get '/' do
    'Hello, world!'
  end
end
```

```ruby
# config.ru
require_relative 'app'
run DistelliDemo::App
```

Once the above files have been created, the app can be tested locally by
running:

    bundle exec rackup

This will launch a webserver that serves the app on localhost port 9292, output
should look similar to:

    [2017-12-15 09:28:30] INFO  WEBrick 1.3.1
    [2017-12-15 09:28:30] INFO  ruby 2.2.7 (2017-03-28) [x86_64-darwin16]
    [2017-12-15 09:28:30] INFO  WEBrick::HTTPServer#start: pid=8214 port=9292

Visiting http://localhost:9292 in a browser should display the "Hello, world!"
message. The development webserver may be shut down by sending CTRL-C to the
shell used to launch it.

Initialize a new git repository and commit the three files, `Gemfile`,
`app.rb`, and `config.ru`, then push that commit to a new project on GitHub.

Alternately, the result of this step can be found as the `step1-create-app`
branch of the following GitHub project:

  https://github.com/Sharpie/distelli-ruby-demo

In the next step, we will prepare the server to which this application will
be deployed.


Step 2: Preparing the Server
----------------------------

Connect to the CentOS 7 server via SSH and run the following commands to
install the Distelli agent:

```sh
curl -sSL https://www.distelli.com/download/client | sh
# This step will ask for your Distelli username and password.
sudo /usr/local/bin/distelli agent install
```

Detailed instructions on the Distelli installation process can be found here
along with steps for verifying a successful installation:

  https://www.distelli.com/docs/user-guides/adding-a-new-server/

The later parts of this exercise will also use Puppet to configure the
server. The Puppet agent may be installed using the following commands:

```
sudo rpm -Uvh http://yum.puppetlabs.com/puppet5/puppet5-release-el-7.noarch.rpm
sudo yum install -y puppet-agent
```

Successful installation of the Puppet agent package can be confirmed by running
the following command:

    /opt/puppetlabs/bin/puppet --version

More information on the Puppet agent installation process can be found here:

  https://puppet.com/docs/puppet/5.3/install_linux.html

Note that this exercise will only be using `puppet apply`, so any instructions
around starting the `puppet agent` daemon or connecting the agent to a Puppet
server can be skipped.


Step 3: Set Up a Distelli Application
-------------------------------------

Once the required agent packages have been installed on the CentOS 7 server, we
can proceed to configuring Distelli to deploy the Ruby code created in Step 1
as a Distelli application.

To create a new application, log into distelli.com and execute the following
steps:

  - Choose "pipelines for applications" from the menu in the upper left.

  - Select the "Applications" tab in the upper left and then click the
    "New App" button in the upper right.

  - Select GitHub as the source control option.

  - Enter the name of the GitHub project where the application code was pushed
    in Step 1.

  - Select the branch where the code was pushed. If a fork of
    `Sharpie/distelli-ruby-demo` was used, then the `step1-create-app` branch
    will be available. Click the "I'm Done" button after selecting a branch.

  - Select "Build Distelli Release" as the build step configuration, ensure
    a `*` character has been entered in the `pkgInclude` field and click
    "I'm Done".

  - Ensure the "I allow Distelli to post a webhook for auto builds" option
    is selected and pick a name for the application, such as `ruby-demo`.
    Make note of the name used as the combination of
    `<distelli account name>/<app name>` will become important later. Select
    "Distelli Ruby" as the build image, enable "Auto Build" and finish
    with "Looks good. Start Build!"

Additional information on the process of setting up a new Distelli application
can be found here:

  https://www.distelli.com/docs/user-guides/creating-an-application/

Once the application build is configured, the final step in setting up Distelli
to manage delivery is to configure a deployment to the CentOS 7 server set up
in Step 2. The steps for doing so are:

  - Select the "Builds" tab in the upper left and then click the
    "New Deployment" button in the upper right.

  - Choose "Deploy a Release" as the Deployment Type.

  - Select the `<app name>` that was assigned to the application.

  - Create a new deployment environment by entering "demo-app" and clicking
    the "Create".

  - Select "Configure Environment" and pick the hostname of the CentOS 7
    server that was configured in Step 2. Click "Add Servers" and close
    the server selection pane.

  - Click "Deploy".

Additional information on the process of setting up a new Distelli deployment
can be found here:

  https://www.distelli.com/docs/user-guides/deploying-an-application-1/

Once the deployment finishes, connect to the CentOS 7 server via SSH. The
results of the deployment, containing the `Gemfile`, `app.rb` and `config.ru`
files created in Step 1, should appear in a directory under:

    /distelli/_apps/

Additionally, Distelli can be configured to build and deploy changes
automatically whenever new commits are pushed to the GitHub repository. This
can be accomplished by the following steps:

  - Select the "Applications" tab in the upper left and then select
    the `<app name>` that was assigned to the application.

  - In the "App Pipeline" pane on the right hand side, choose the "Add Step"
    option. Select "Existing Environment" as the target and select "demo-app".

  - Select the "Auto Deploy" option in the App Pipeline pane.

  - Select the "Manifest" tab and ensure the "Use this manifest for builds and deployments"
    option is not selected.

Additional information on configuring automatic deployments can be found
here:

  https://www.distelli.com/docs/user-guides/enabling-auto-deploy/


Step 4: Configure Distelli to Package App Dependencies
------------------------------------------------------

At this point we've got Distelli automatically deploying content from GitHub
to the CentOS 7 server. However, to get the Ruby app up and running we need
to bring in additional assets to configure and provision with each deployment.

This step describes how to configure Distelli to handle packaging these assets
during its build phase.

The first set of assets we need to package is the Sinatra web framework and
its dependencies. Running `bundle install` in Step 1 created a `Gemfile.lock`
that lists these assets. Add it to the next git commit:

    git add Gemfile.lock

Next, create a `Puppetfile` which lists Puppet modules that will be used to
configure the server:

```ruby
# Puppetfile
forge 'https://forge.puppetlabs.com'


mod 'puppetlabs/stdlib',           '4.24.0'
mod 'puppetlabs/concat',           '4.1.1'

mod 'puppetlabs/firewall',         '1.11.0'
mod 'puppet/selinux',              '1.4.0'
mod 'puppet/nginx',                '0.9.0'
```

The Puppetfile above brings in modules for managing a NGINX webserver to run in
front of the Ruby app server along with firewall rules and SELinux policies.

Finally, add a `distelli-manifest.yml` that configures the build step to
download and package the Ruby gems and Puppet modules:

```yaml
# distelli-manifest.yml
<distelli account name>/<app name>:
  Build:
    - 'source ~/.rvm/scripts/rvm'
    - 'rvm install ruby-2.4.1 || true'
    - 'rvm use 2.4.1'
    - 'gem install r10k'
    - 'gem install bundler'
    - 'r10k puppetfile install --verbose'
    - 'bundle package --all'
  PkgInclude:
    - '*'
  PkgExclude:
    - '.bundle/'
```

The above manifest uses `r10k puppetfile install` and `bundle package` to
add assets during the Distelli build. Make sure to replace
`<distelli account name>` and `<app name>` with values from Step 3.

Additional information on configuring the Distilli manifest can be found
here:

  https://www.distelli.com/docs/manifest/distelli-manifest/

Add `Gemfile.lock`, `Puppetfile`, and `distelli-manifest.yml`, make a git
commit and push the result to GitHub. This will trigger a new build and
deployment of the project.


Step 5: Automate Server Configuration with Puppet
-------------------------------------------------

In this step we will add a Puppet manifest that will ensure the CentOS 7 server
is configured with items necessary to support the deployed application:

  - A Ruby 2.4 installation that has the contents of Gemfile.lock installed.

  - A user account and systemd service for running the Ruby application server.

  - A NGINX webserver for handling the privilages required to bind port 80 for
    HTTP traffic.

  - Firewall configuration that allows external traffic to reach NGINX.

  - SELinux configuration that allows NGINX to relay traffic to the Ruby
    application server.

The following `config.pp` Puppet manifest accomplishes the above on CentOS 7:

```puppet
# config.pp
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
```

The Puppet manifest above makes use of some environment variables set by
the Distelli agent. These are described in detail at:

  https://www.distelli.com/docs/reference/environment-variables/

Finally, the `distelli-manifest.yml` must be updated to run `puppet apply`
as part of the deployment and to control the `demo-app` service:

```yaml
# distelli-manifest.yml
<distelli account name>/<app name>:
  Build:
    - 'source ~/.rvm/scripts/rvm'
    - 'rvm install ruby-2.4.1 || true'
    - 'rvm use 2.4.1'
    - 'gem install r10k'
    - 'gem install bundler'
    - 'r10k puppetfile install --verbose'
    - 'bundle package --all'
  PkgInclude:
    - '*'
  PkgExclude:
    - '.bundle/'
  PostInstall:
    - 'sudo -E /opt/puppetlabs/bin/puppet apply --verbose --modulepath modules config.pp'
  Start:
    - sudo systemctl restart demo-app
  Terminate:
    - sudo systemctl stop demo-app
```

Commit `config.pp` along with the updated `distelli-manifest.yml` and push the
result to GitHub. After the deployment finishes the CentOS 7 server should
respond to a HTTP request on port 80 with "Hello, world!"
