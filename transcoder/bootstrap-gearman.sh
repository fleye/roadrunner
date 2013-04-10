#!/usr/local/bin/bash

yum -y install perl-CPAN
yum -y install perl-CPANPLUS 

cpanp -i Term::ReadLine::Perl --prereqs

# Install Gearman
yum -y install curl curl-devel gcc uuid-devel libuuid libuuid-devel uuid boost boost-devel libevent libevent-devel gcc-c++
wget https://launchpad.net/gearmand/1.0/1.0.3/+download/gearmand-1.0.3.tar.gz 
tar -zxvf gearmand-1.0.3.tar.gz
cd gearmand-1.0.3
./configure
make all install
cd ..

cpanp -i Time::HiRes --prereqs
cpanp -i Gearman::Client --prereqs
cpanp -i Gearman::Worker --prereqs
cpanp -i Config::General --prereqs
cpanp -i Digest::MD5 --prereqs

