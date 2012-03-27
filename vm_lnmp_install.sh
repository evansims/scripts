#!/bin/bash

# Install Nginx, MySQL and PHP on Ubuntu (and compatible)

if [[ $EUID -ne 0 ]]; then
	echo "This script should be run as root" 1>&2
	exit 1
fi

apt-get update
apt-get -y install ufw time bc build-essential autoconf2.13 libssl-dev libcurl4-gnutls-dev libjpeg62-dev libpng12-dev libmysql++-dev libfreetype6-dev libt1-dev libc-client-dev mysql-client libevent-dev libxml2-dev libtool libmcrypt-dev php5-dev libbz2-dev python-software-properties mlocate sendmail
apt-get -y upgrade

# Update locate
updatedb

# Set Timezone to Chicago
echo "America/Chicago" | sudo tee /etc/timezone
sudo dpkg-reconfigure --frontend noninteractive tzdata

# Move SSH port off 22 to avoid brute force attacks.
sudo ufw reset
sudo ufw default deny
sed -i 's/Port 22/Port 2008/' /etc/ssh/sshd_config
sed -i 's/IPV6=no/IPV6=yes/' /etc/default/ufw
/etc/init.d/ssh restart
sudo ufw allow 7 # Echo
sudo ufw allow 2008 # SSH
sudo ufw allow 80/tcp # HTTP
sudo ufw allow 443/tcp # HTTPS
sudo ufw enable

# Install Nginx
add-apt-repository ppa:nginx/stable
apt-get update
apt-get -y install nginx

# Install MySQL
apt-get -y install mysql-server

# Install PHP 5.3.9 from source (compile with mysqlnd support)
mkdir ~/src
cd ~/src
wget -O php.tar.gz http://us.php.net/get/php-5.3.9.tar.gz/from/this/mirror
tar -xzf php.tar.gz
rm php.tar.gz
cd php-5.3.9

CFLAGS="-Os -pipe -march=nocona -msse -mmmx -msse2 -msse3 -mfpmath=sse -fomit-frame-pointer -funroll-loops" ./configure --enable-cgi --enable-fpm --with-mcrypt --enable-mbstring --with-openssl --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-gd --enable-gd-native-ttf --with-jpeg-dir=/usr/lib --with-libxml-dir=/usr/lib --with-curl --with-imap --with-imap-ssl --enable-zip --with-bz2 --enable-sockets --with-zlib --enable-exif --enable-ftp --with-iconv --with-gettext --with-t1lib=/usr --with-freetype-dir=/usr --prefix=/usr --with-fpm-user=www-data --with-fpm-group=www-data --enable-inline-optimization --disable-debug --enable-zend-multibyte --with-kerberos

make
make install

cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod 755 /etc/init.d/php-fpm
update-rc.d -f php-fpm defaults

touch /usr/var/run/php-fpm.pid
chmod 755 /usr/var/run/php-fpm.pid

# Fix PEAR bug.
rm -R /usr/lib/php/.channels/
pear update-channels
pear upgrade

# Install APC
cd ~/src
wget -O apc.tgz http://pecl.php.net/get/APC-3.1.9.tgz
tar -zxf apc.tgz
rm apc.tgz
cd APC-3.1.9
phpize
CFLAGS="-Os -pipe -march=nocona -msse -mmmx -msse2 -msse3 -mfpmath=sse -fomit-frame-pointer -funroll-loops" ./configure --enable-apc --enable-apc-mmap

make
make install

# Install Suhosin
cd ~/src
wget http://download.suhosin.org/suhosin-0.9.33.tgz
tar -xzf suhosin-0.9.33.tgz
rm suhosin-0.9.33.tgz
cd suhosin-0.9.33/
phpize

CFLAGS="-Os -pipe -march=nocona -msse -mmmx -msse2 -msse3 -mfpmath=sse -fomit-frame-pointer -funroll-loops" ./configure --enable-suhosin

make
make install

# Install mysqlnd_ms
cd ~/src
wget http://pecl.php.net/get/mysqlnd_ms-1.2.2.tgz
tar -xzf mysqlnd_ms-1.2.2.tgz
rm mysqlnd_ms-1.2.2.tgz
cd mysqlnd_ms-1.2.2/
phpize

CFLAGS="-Os -pipe -march=nocona -msse -mmmx -msse2 -msse3 -mfpmath=sse -fomit-frame-pointer -funroll-loops" ./configure --enable-mysqlnd-ms

make
make install

# Update configurations.
rm /etc/nginx/sites-enabled/default
wget -O /etc/nginx/sites-enabled/default https://raw.github.com/evansims/scripts/master/nginx/default
wget -O /etc/nginx/php_support https://raw.github.com/evansims/scripts/master/nginx/php_support

mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.old
wget -O /etc/nginx/nginx.conf https://raw.github.com/evansims/scripts/master/nginx/nginx.conf

wget -O /usr/lib/php.ini https://raw.github.com/evansims/scripts/master/php/php.ini
wget -O /usr/etc/php-fpm.conf https://raw.github.com/evansims/scripts/master/php/php-fpm.conf
wget -O /usr/etc/mysqlnd_ms_plugin.ini https://raw.github.com/evansims/scripts/master/php/mysqlnd_ms_plugin.ini

echo "<?php phpinfo(); ?>" >> /usr/share/nginx/www/phpinfo.php

# Restart services.
/etc/init.d/php-fpm stop
/etc/init.d/nginx stop
/etc/init.d/php-fpm start
/etc/init.d/nginx start

echo "Setup complete."
echo "  You should run mysql_secure_installation"
