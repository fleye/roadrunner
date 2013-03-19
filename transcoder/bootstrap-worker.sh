#!/usr/local/bin/bash

yum -y install perl-CPAN
yum -y install perl-CPANPLUS 

cpanp -i Term::ReadLine::Perl --prereqs

# Install Gearman
yum -y install curl curl-devel gcc uuid-devel libuuid libuuid-devel uuid boot boost-devel libevent libevent-devel
wget https://launchpad.net/gearmand/1.0/1.0.3/+download/gearmand-1.0.3.tar.gz 
tar -zxvf gearmand-1.0.3.tar.gz
cd gearmand-1.0.3
./configure
make all install
cd ..

cpanp -i Time::HiRes --prereqs
cpanp -i Gearman::Client --prereqs
cpanp -i Gearman::Worker --prereqs

# Install FFMPEG
cat << 'EOF' > /etc/yum.repos.d/dag.repo
[dag]
name=Dag RPM Repository for Red Hat Enterprise Linux
baseurl=http://apt.sw.be/redhat/el$releasever/en/$basearch/dag
gpgcheck=1
enabled=1
EOF

yum -y install ffmpeg ffmpeg-devel

