#!/usr/local/bin/bash

echo "Make sure SSH agent forwarding is enabled to allow Github to work"

sudo yum -y install git
git config --global user.name "Tom Daly"
git config --global user.email "tjd@q7.io"
git config --global credential.helper 'cache --timeout=3600'

ssh-keyscan -t rsa,dsa github.com 2>&1 >> ~/.ssh/known_hosts

git clone git@github.com:tomdalynh/fleye.git

exit

