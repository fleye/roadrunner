#!/usr/local/bin/bash

cd ~
ssh-keygen -t rsa -b 1024
cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys

exit


