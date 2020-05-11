apt update && apt -y full-upgrade

echo 'videostream.site' > /etc/hostname
sed -i 's/127.0.0.1 localhost/127.0.0.1 videostream.site localhost/g' /etc/hosts
reboot now
