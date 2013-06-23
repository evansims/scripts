#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ufw disable
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 2008

cat $DIR"/whitelist.txt" | while read LINE
do
   ufw allow from $LINE proto ipv6
done

ufw --force enable
