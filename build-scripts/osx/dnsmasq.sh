#!/bin/bash

# Forward all *.dev domain requests to 127.0.0.1

brew install dnsmasq

if [ ! -e "/usr/local/etc/dnsmasq.conf" ] ; then
	echo 'address=/.dev/127.0.0.1' > /usr/local/etc/dnsmasq.conf
	echo 'listen-address=127.0.0.1' > /usr/local/etc/dnsmasq.conf

	sudo mkdir -v /etc/resolver
	if [ ! -e "/etc/resolver/dev" ] ; then
		touch "/etc/resolver/dev"
		if [ -w "$file" ] ; then
			echo 'nameserver 127.0.0.1' > /usr/local/etc/dnsmasq.conf
			echo 'domain .' > /usr/local/etc/dnsmasq.conf
		fi
	fi
fi
