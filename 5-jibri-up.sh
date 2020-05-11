modprobe snd-aloop
# show the module loaded
lsmod | grep snd_aloop
echo "snd-aloop" >> /etc/modules

apt -y install ffmpeg unzip

# install Chrome
curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt update
apt -y install google-chrome-stable
# don't show warnings about chrome being controlled by test software
mkdir -p /etc/opt/chrome/policies/managed
echo '{ "CommandLineFlagSecurityWarningsEnabled": false }' >>/etc/opt/chrome/policies/managed/managed_policies.json

# install Chromdriver
# note - chromedrive is not managed by apt and must be installed manually
CHROME_DRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE`
wget -N http://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip -P ~/
unzip ~/chromedriver_linux64.zip -d /usr/local/bin/
rm ~/chromedriver_linux64.zip
# not sure if changing permissions is required
chown root:root /usr/local/bin/chromedriver
chmod 0755 /usr/local/bin/chromedriver

# install jibri
apt -y install jibri

# add more groups
usermod -aG adm,plugdev jibri
# should already have jibri,audio,video,jitsi


# configure jitsi components

# insert virtual host for Jibri recorder into prosody config
echo '' >> /etc/prosody/conf.avail/videostream.site.cfg.lua
echo 'VirtualHost "recorder.videostream.site"' >> /etc/prosody/conf.avail/videostream.site.cfg.lua
echo '    modules_enabled = {' >> /etc/prosody/conf.avail/videostream.site.cfg.lua
echo '        "ping";' >> /etc/prosody/conf.avail/videostream.site.cfg.lua
echo '    }' >> /etc/prosody/conf.avail/videostream.site.cfg.lua
echo '    authentication = "internal_plain"' >> /etc/prosody/conf.avail/videostream.site.cfg.lua

# register prosody users for jibri to authenticate and record
prosodyctl register jibri auth.videostream.site jibriauthpass
prosodyctl register recorder recorder.videostream.site jibrirecorderpass

# Tell Jicofo to look for Jibri controllers in the MUC created above
echo 'org.jitsi.jicofo.jibri.BREWERY=JibriBrewery@internal.auth.videostream.site' >> /etc/jitsi/jicofo/sip-communicator.properties
echo 'org.jitsi.jicofo.jibri.PENDING_TIMEOUT=90' >> /etc/jitsi/jicofo/sip-communicator.properties

# enable live streaming and file recording features in the client
# and hide the recorder participant
sed -i "s_// fileRecordingsEnabled: false,_fileRecordingsEnabled: true,_g" /etc/jitsi/meet/videostream.site-config.js
sed -i "s_// liveStreamingEnabled: false,_liveStreamingEnabled: true,\n    hiddenDomain:'recorder.videostream.site',_g" /etc/jitsi/meet/videostream.site-config.js


# Configure Jibri
# make a directory to hold recordings
mkdir /recordings
chown jibri:jibri /recordings

# configure directory to record to
sed -i 's|"recording_directory":"/tmp/recordings",|"recording_directory": "/recordings",|g' /etc/jitsi/jibri/config.json
# no script to run after recording. note: this can upload a file to s3, for example
sed -i 's|"finalize_recording_script_path": "/path/to/finalize_recording.sh",|"finalize_recording_script_path": "",|g' /etc/jitsi/jibri/config.json
# set servers and login
sed -i 's|"prod.xmpp.host.net"|"videostream.site"|g' /etc/jitsi/jibri/config.json
sed -i 's|"xmpp_domain": "xmpp.domain",|"xmpp_domain": "videostream.site",|g' /etc/jitsi/jibri/config.json
sed -i 's|"domain": "auth.xmpp.domain",|"domain": "auth.videostream.site",|g' /etc/jitsi/jibri/config.json
# set the first username and password for auth
sed -i '0,/"username": "username",/{s/"username": "username",/"username": "jibri",/g}' /etc/jitsi/jibri/config.json
sed -i '0,/"password": "password"/{s/"password": "password"/"password": "jibriauthpass"/g}' /etc/jitsi/jibri/config.json
sed -i 's|"domain": "internal.auth.xmpp.domain",|"domain": "internal.auth.videostream.site",|g' /etc/jitsi/jibri/config.json
sed -i 's|"nickname": "jibri-nickname"|"nickname": "jibri"|g' /etc/jitsi/jibri/config.json
sed -i 's|"domain": "recorder.xmpp.domain",|"domain": "recorder.videostream.site",|g' /etc/jitsi/jibri/config.json
# set the second username and password for the recorder to join the special room (brewery)
sed -i 's|"username": "username",|"username": "recorder",|g' /etc/jitsi/jibri/config.json
sed -i 's|"password": "password"|"password": "jibrirecorderpass"|g' /etc/jitsi/jibri/config.json


# start Jibri when the server starts
systemctl enable jibri

# Restart services to apply changes
systemctl restart prosody
systemctl restart jicofo
systemctl restart jitsi-videobridge2
systemctl restart jibri
