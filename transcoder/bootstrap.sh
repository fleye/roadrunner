#!/usr/local/bin/bash


yum -y install git
yum -y install perl-CPAN
yum -y install perl-CPANPLUS 

cpanp -i Term::ReadLine::Perl --prereqs

# Install Gearman
yum -y install gcc
yum -y install boost
yum -y install boost-devel
yum -y install memcached
yum install curl curl-devel uuid-devel libuuid libuuid-devel uuid boost-devel libevent libevent-devel
https://launchpad.net/gearmand/1.0/1.0.3/+download/gearmand-1.0.3.tar.gz
cd gearmand-1.0.3 
./configure
make
make install
cd ..

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

yum install ffmpeg ffmpeg-devel

