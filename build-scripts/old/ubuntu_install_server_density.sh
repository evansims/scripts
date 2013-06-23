wget -q https://www.serverdensity.com/downloads/boxedice-public.key -O- | sudo apt-key add -
sudo nano -w /etc/apt/sources.list.d/sd-agent.list
deb http://www.serverdensity.com/downloads/linux/deb all main
apt-get update
apt-get install sd-agent
sudo nano -w /etc/sd-agent/config.php
