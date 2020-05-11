apt update && apt -y full-upgrade

echo "$DOMAIN_NAME" > /etc/hostname
sed -i "s/127.0.0.1 localhost/127.0.0.1 $DOMAIN_NAME localhost/g" /etc/hosts
reboot now
