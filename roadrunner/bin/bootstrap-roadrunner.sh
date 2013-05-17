#!/usr/bin/bash

# From Yum
yum -y install mysql



# Perl Modules

cpanp -i File::Util --prereqs
cpanp -i Config::General --prereqs
cpanp -i DBI --prereqs
cpanp -i DBD::mysql --prereqs
cpanp -i Digest::MD5 --prereqs
cpanp -i Log::Report --prereqs
cpanp -i Any::Daemon --prereqs





cpanp -i  --prereqs
