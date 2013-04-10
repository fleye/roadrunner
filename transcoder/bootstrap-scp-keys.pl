#!/usr/local/bin/bash

cd ~
ssh-keygen -t rsa -b 1024
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

exit


