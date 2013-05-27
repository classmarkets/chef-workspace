# Getting Started

## Getting the Code and Installing Dependencies

Install the rubygems package with your distro's package manager

    apt-get install rubygems
    yum install rubygems
    pacman -S rubygems

Install VirtualBox: https://www.virtualbox.org/wiki/Downloads

Install Vagrant: http://docs.vagrantup.com/v2/installation/index.html
*Note: make sure to remove the vagrant gem if you installed it before. The
gem is outdated and no longer mantained.*

    user@pc:~/src $ gem install bundler --no-rdoc --no-ri

    user@pc:~/src $ git clone gl@gitlab.classmarkets.com:infrastructure/chef-workspace.git chef
    user@pc:~/src $ cd chef
    user@pc:~/src/chef $ bundle install
    user@pc:~/src/chef $ gem install --local gems/knife-spork-1.0.17.gem

## Installing a Local Chef Server

    user@pc:~/src/chef $ vagrant up chefserver
    user@pc:~/src/chef $ vagrant ssh chefserver

    vagrant@localhost:~ $ sudo su -

    root@localhost:~ # vim /etc/chef-server/chef-server.rb

Copy the configuration from http://serverfault.com/questions/483957/chef-connection-refused-for-cookbook-upload/486246#486246

    root@localhost:~ # chef-server-ctl reconfigure

Copy `/etc/chef-server/chef-validator.pem` on chefserver to `.chef/chef-validator-vagrant.pem` on your local machine

    root@localhost:~ # exit
    vagrant@localhost:~ $ exit

Browse to https://192.168.114.11/ and login with admin / p@ssw0rd1.
Browse to https://192.168.114.11/users/new and create your own admin user. Save the private key at `.chef/$USER-vagrant.pem`

    user@pc:~/src/chef $ vim .chef/$USER-vagrant.pem

    user@pc:~/src/chef $ knife block use vagrant
    user@pc:~/src/chef $ knife cookbook upload -a
    user@pc:~/src/chef $ ./update_roles.sh
    user@pc:~/src/chef $ for i in environments/*; do knife environment from file $i; done

## Installing the First Node

    user@pc:~/src/chef $ vagrant up alice
    user@pc:~/src/chef $ ./bootstrap.pl alice

This will install Chef on alice and register alice with the
Chef server. Browse to https://192.168.114.11/nodes/alice.v/edit Now
you can start to play with roles and recipes. For starters, drag the
`classmarkets_linux_server` role into the run list, set the envionment to
`vagrant` and save the node. You have to set the environment every time
you edit a node.

    user@pc:~/src/chef $ vagrant ssh alice
    vagrant@alice:~ $ sudo su -
    root@alice:~ # chef-client

Now watch the magic happen :)

# Migrating from the old repository

Note: If you know that you don't have any local or unpublished changes in
your local repository, you can just delete it and start from scratch. If
you are unsure, keep reading.

First, get the old remote repository out of the way and add the new
one. You can either delete the old remote completely or keep and rename
it. I chose to rename the old remote to `legacy`, just in case.
Then you can add the new remote.

    # either of the following two is fine
    user@pc:~/src/chef git remote remove origin
    user@pc:~/src/chef git remote rename origin legacy

    user@pc:~/src/chef git remote add origin gl@gitlab.classmarkets.com:infrastructure/chef.git

The old `env/vagrant` branch is now the new master branch, so go ahead
and rename it.

    user@pc:~/src/chef git branch -m env/vagrant master

Rebase the master branch of top of the new remote.

    user@pc:~/src/chef git fetch origin
    user@pc:~/src/chef git checkout env/vagrant
    user@pc:~/src/chef git rebase origin/master
    user@pc:~/src/chef git push -u origin master

Install any new gems and the vendor cookbooks with librarian

    user@pc:~/src/chef $ bundle install
    user@pc:~/src/chef $ librarian-chef install

When you rebased your master branch, most of the cookbooks in ./cookbooks
have been deleted, because they will now be managed by librarian. Take a
look in this directory and see if there are any vendor cookbooks left over
(except `fake-dns` and `simple_iptables` &ndash; these two are supposed
to be there). If there are, delete them and add them to the Cheffile
unless they are already installed in ./vendor/cookbooks.

Update your local chefserver

    user@pc:~/src/chef $ knife block use vagrant
    user@pc:~/src/chef $ knife cookbook upload -a
    user@pc:~/src/chef $ ./update_roles.sh

All that's left is a little bit of spring cleaning

    user@pc:~/src/chef $ git remote prune origin
    user@pc:~/src/chef $ git branch | grep chef-vendor | xargs git branch -D
