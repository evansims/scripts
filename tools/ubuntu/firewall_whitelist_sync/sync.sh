#!/bin/bash

# This script syncs a UFW firewall installation using a few plain text files. The idea is that you might keep these files in a git repo that syncs with a remote origin every so often for new instructions. It's obviously not the most secure of ideas, but it's convenient.
#
# Expected files:
# allow_ipv4.txt
# allow_ipv6.txt
# allow_ports.txt
# deny_ipv4.txt
# deny_ipv6.txt

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sed -i 's/IPV6=no/IPV6=yes/' /etc/default/ufw

ufw disable
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

cat $DIR"/allow_ports.txt" | while read LINE
do
  if [ ! -z "$LINE" ] && [ ${LINE:0:1} != '#' ]; then
    ufw allow $LINE
  fi
done

cat $DIR"/allow_ipv4.txt" | while read LINE
do
  if [ ! -z "$LINE" ] && [ ${LINE:0:1} != '#' ]; then
    ufw allow from $LINE
  fi
done

cat $DIR"/allow_ipv6.txt" | while read LINE
do
  if [ ! -z "$LINE" ] && [ ${LINE:0:1} != '#' ]; then
    ufw allow from $LINE proto ipv6
  fi
done

cat $DIR"/deny_ipv4.txt" | while read LINE
do
  if [ ! -z "$LINE" ] && [ ${LINE:0:1} != '#' ]; then
    ufw deny from $LINE
  fi
done

cat $DIR"/deny_ipv6.txt" | while read LINE
do
  if [ ! -z "$LINE" ] && [ ${LINE:0:1} != '#' ]; then
    ufw deny from $LINE proto ipv6
  fi
done

ufw --force enable
