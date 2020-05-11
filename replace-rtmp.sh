# copy the script to replace the argument of ffmpeg
mkdir /opt/util
cp /home/ubuntu/opt-util-ffmpeg.sh /opt/util/ffmpeg
chmod +x /opt/util/ffmpeg

# put the helper ffmpeg into the path for Jbri only
sed -i 's|Type=simple|Type=simple\nEnvironment="PATH=/opt/util:'"$PATH"'"|g' /etc/systemd/system/jibri.service

systemctl daemon-reload
systemctl restart jibri
