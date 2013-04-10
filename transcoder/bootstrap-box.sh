#!/usr/local/bin/bash

# 1. Add machine name to /etc/hosts
# 2. Add machine to .ssh/config for SSH Agent Forwarding
# 3. Execute script with 'cat bootstrap-box.sh | ssh -t -t ec2-user@HOST'

sudo yum -y install git
git config --global user.name "Tom Daly"
git config --global user.email "tjd@q7.io"
git config --global credential.helper 'cache --timeout=3600'

ssh-keyscan -t rsa,dsa github.com 2>&1 >> ~/.ssh/known_hosts

git clone git@github.com:tomdalynh/fleye.git

exit

