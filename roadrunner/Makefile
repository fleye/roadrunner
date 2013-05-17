all:
	echo "There is no default target for all"

prereq:
	# From Yum
	yum -y install mysql
	yum -y install ganglia ganglia-gmond
	yum -y install perl-CPAN
	yum -y install perl-CPANPLUS 
	
	# Perl Modules
	# cpanp -i Term::ReadLine::Perl --prereqs
	# cpanp -i Config::General --prereqs
	# cpanp -i DBI --prereqs
	# cpanp -i DBD::mysql --prereqs
	# cpanp -i Digest::MD5 --prereqs
	# cpanp -i File::Util --prereqs
	# cpanp -i Proc::Daemon --prereqs
	
	# FFmpeg from source
	cd src && tar -zxvf ffmpeg-linux64-20130404.tar.gz

install:
	/bin/mkdir -p /usr/local/fleye
	/bin/mkdir -p /usr/local/fleye/roadrunner
	
	/bin/mkdir -p /usr/local/fleye/roadrunner/bin
	/usr/bin/install -m 0755 -o root -g root bin/go-roadrunner.pl /usr/local/fleye/roadrunner/bin/go-roadrunner.pl
	/usr/bin/install -m 0755 -o root -g root bin/worker-copy-lrv.pl /usr/local/fleye/roadrunner/bin/worker-copy-lrv.pl
	/usr/bin/install -m 0755 -o root -g root bin/worker-transcode-mp4.pl /usr/local/fleye/roadrunner/bin/transcode-mp4.pl

	/bin/mkdir -p /usr/local/fleye/roadrunner/etc
	/usr/bin/install -m 0755 -o root -g root etc/db.conf /usr/local/fleye/roadrunner/etc/db.conf
	
	/bin/mkdir -p /usr/local/fleye/roadrunner/www
	/usr/bin/install -m 0755 -o root -g root www/index.html /usr/local/fleye/roadrunner/www/index.html

	/bin/mkdir -p /usr/local/fleye/roadrunner/www/cgi-bin
	/usr/bin/install -m 0755 -o root -g root www/cgi-bin/config.cgi /usr/local/fleye/roadrunner/www/cgi-bin/config.cgi
	/usr/bin/install -m 0755 -o root -g root www/cgi-bin/jobs.cgi /usr/local/fleye/roadrunner/www/cgi-bin/jobs.cgi

	# FFmpeg
	/usr/bin/install -m 0755 -o root -g root src/ffmpeg-linux64-20130404/ffmpeg /usr/bin/ffmpeg
	
	# Apache Configuration
	/usr/bin/install -m 0755 -o root -g root www/web-roadrunner.conf /etc/httpd/conf.d/web-roadrunner.conf

clean:
	/bin/rm -rf src/ffmpeg-linux64-20130404

directions:


