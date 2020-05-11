# add higher limits to /etc/systemd/system.conf
echo 'DefaultLimitNOFILE=65000' >> /etc/systemd/system.conf
echo 'DefaultLimitNPROC=65000' >> /etc/systemd/system.conf
echo 'DefaultTasksMax=65000' >> /etc/systemd/system.conf
systemctl daemon-reload
