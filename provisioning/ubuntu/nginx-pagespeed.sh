#!/bin/bash

# Build Nginx from source w/ Pagespeed, Google Performance Tools, More Headers, Fair Upstream and Upload Progress modules.

# Customize your build flags here.
export CFLAGS="-pipe -march=nocona -mtune=i686 -O2 -msse -mmmx -msse2 -msse3 -mfpmath=sse"

# Determine the number of processors available to us for configuring scripts.
CORES=`grep processor /proc/cpuinfo | wc -l`
if ! [[ "$CORES" =~ ^[0-9]+$ ]] || [[ "$CORES" -lt 1 ]]; then
        CORES=1
fi

sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get autoremove
sudo apt-get autoclean
sudo apt-get -y install htop unzip git build-essential libpcre3 libpcre3-dev libssl-dev checkinstall automake
mkdir ~/src

# Grab upload progress module.
cd ~/src
git clone https://github.com/masterzen/nginx-upload-progress-module

# Grab more-headers module.
git clone https://github.com/agentzh/headers-more-nginx-module

# Grab the uptsream fair module.
git clone https://github.com/gnosek/nginx-upstream-fair

# Grab libunwind
wget http://download.savannah.gnu.org/releases/libunwind/libunwind-0.99-beta.tar.gz
tar -xzvf libunwind-0.99-beta.tar.gz
rm libunwind-0.99-beta.tar.gz
cd libunwind-0.99-beta
sudo ./configure
sudo make
sudo checkinstall --pkgversion=0.99 --default

# Grab Google's Performance Tools library.
cd ~/src
wget https://gperftools.googlecode.com/files/gperftools-2.0.tar.gz
tar -xzvf gperftools-2.0.tar.gz
rm gperftools-2.0.tar.gz
cd gperftools-2.0
sudo ./configure --enable-frame-pointers
sudo make
sudo checkinstall --default

# Grab Google's Pagespeed module.
cd ~/src
wget https://github.com/pagespeed/ngx_pagespeed/archive/release-1.5.27.3-beta.zip
unzip release-1.5.27.3-beta.zip
rm release-1.5.27.3-beta.zip
cd ngx_pagespeed-release-1.5.27.3-beta/
wget https://dl.google.com/dl/page-speed/psol/1.5.27.3.tar.gz
tar -xzvf 1.5.27.3.tar.gz
rm 1.5.27.3.tar.gz

# Compile Nginx.
cd ~/src
wget http://nginx.org/download/nginx-1.4.1.tar.gz
tar -xzvf nginx-1.4.1.tar.gz
rm nginx-1.4.1.tar.gz
cd nginx-1.4.1

sudo ./configure \
--prefix=/usr/share/nginx \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--pid-path=/run/nginx.pid \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--http-client-body-temp-path=/var/lib/nginx/body \
--http-proxy-temp-path=/var/lib/nginx/proxy \
--http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
--lock-path=/var/lock/nginx.lock \
--with-rtsig_module \
--without-select_module \
--without-poll_module \
--with-file-aio \
--with-ipv6 \
--with-http_ssl_module \
--with-http_spdy_module \
--with-http_realip_module \
--with-http_mp4_module \
--with-http_gunzip_module \
--without-http_ssi_module \
--without-http_userid_module \
--without-http_geo_module \
--without-http_referer_module \
--without-http_uwsgi_module \
--without-http_scgi_module \
--without-http_memcached_module \
--without-http_empty_gif_module \
--without-http_browser_module \
--with-google_perftools_module \
--with-pcre-jit \
--add-module=$HOME/src/nginx-upload-progress-module \
--add-module=$HOME/src/headers-more-nginx-module/ \
--add-module=$HOME/src/nginx-upstream-fair/ \
--add-module=$HOME/src/ngx_pagespeed-release-1.5.27.3-beta
sudo make
sudo checkinstall --default

sudo /sbin/ldconfig

# Configure nginx
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.custom.conf
sudo sed -i "s/worker_processes  1;/worker_processes $CORES;/" /etc/nginx/nginx.custom.conf

# Install init.d script
sudo wget https://raw.github.com/JasonGiedymin/nginx-init-ubuntu/master/nginx -O /etc/init.d/nginx
sudo chmod +x /etc/init.d/nginx
sudo sed -i 's/DAEMON=\/usr\/local\/nginx\/sbin\/nginx/DAEMON=\/usr\/sbin\/nginx/' /etc/init.d/nginx
sudo sed -i 's/lockfile=\/var\/lock\/subsys\/nginx/lockfile=\/var\/lock\/nginx.lock/' /etc/init.d/nginx
sudo sed -i 's/PIDSPATH=\/usr\/local\/nginx\/logs/PIDSPATH=\/run/' /etc/init.d/nginx
sudo sed -i 's/NGINX_CONF_FILE="\/usr\/local\/nginx\/conf\/nginx.conf"/NGINX_CONF_FILE="\/etc\/nginx\/nginx.custom.conf"/' /etc/init.d/nginx
sudo update-rc.d -f nginx defaults

sudo mkdir /var/lib/nginx
sudo mkdir /var/lib/nginx/body
sudo mkdir /etc/nginx/conf.d
sudo mkdir /var/cache/nginx
sudo mkdir /var/cache/nginx/ngx_pagespeed_cache

sudo service nginx start
