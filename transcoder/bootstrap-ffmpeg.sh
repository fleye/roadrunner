#!/usr/local/bin/bash

# Install FFMPEG
sudo cat << 'EOF' > /etc/yum.repos.d/dag.repo
[dag]
name=Dag RPM Repository for Red Hat Enterprise Linux
baseurl=http://apt.sw.be/redhat/el$releasever/en/$basearch/dag
gpgcheck=1
enabled=1
EOF

sudo yum -y install ffmpeg ffmpeg-devel


