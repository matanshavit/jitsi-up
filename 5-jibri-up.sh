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
echo ''                                        >> $PROSODY_CONFIG
echo 'VirtualHost "'"recorder.$DOMAIN_NAME"'"' >> $PROSODY_CONFIG
echo '    modules_enabled = {'                 >> $PROSODY_CONFIG
echo '        "ping";'                         >> $PROSODY_CONFIG
echo '    }'                                   >> $PROSODY_CONFIG
echo '    authentication = "internal_plain"'   >> $PROSODY_CONFIG

# register prosody users for jibri to authenticate and record
prosodyctl register jibri    auth."$DOMAIN_NAME"     $JIBRI_PASSWORD
prosodyctl register recorder recorder."$DOMAIN_NAME" $RECORDER_PASSWORD

# Tell Jicofo to look for Jibri controllers in the MUC created above
echo "org.jitsi.jicofo.jibri.BREWERY=JibriBrewery@internal.auth.$DOMAIN_NAME" >> $JICOFO_SIP_PROPS
echo 'org.jitsi.jicofo.jibri.PENDING_TIMEOUT=90'                              >> $JICOFO_SIP_PROPS

# enable live streaming and file recording features in the client
# and hide the recorder participant
sed -i "s_// fileRecordingsEnabled: false,_fileRecordingsEnabled: true,_g"                                          $JITSI_MEET_CONFIG
sed -i "s_// liveStreamingEnabled: false,_liveStreamingEnabled: true,\n    hiddenDomain:'recorder.$DOMAIN_NAME',_g" $JITSI_MEET_CONFIG


# Configure Jibri
# make a directory to hold recordings
mkdir $RECORDINGS_DIR
chown jibri:jibri $RECORDINGS_DIR

# configure directory to record to
sed -i 's|"recording_directory":"/tmp/recordings",|"recording_directory": "'"$RECORDINGS_DIR"'",|g'                    $JIBRI_CONFIG
# no script to run after recording. note: this can upload a file to s3, for example
sed -i 's|"finalize_recording_script_path": "/path/to/finalize_recording.sh",|"finalize_recording_script_path": "",|g' $JIBRI_CONFIG
# set servers and login
sed -i 's|"prod.xmpp.host.net"|"'"$DOMAIN_NAME"'"|g'                                                                   $JIBRI_CONFIG
sed -i 's|"xmpp_domain": "xmpp.domain",|"xmpp_domain": "'"$DOMAIN_NAME"'",|g'                                          $JIBRI_CONFIG
sed -i 's|"domain": "auth.xmpp.domain",|"domain": "auth.'"$DOMAIN_NAME"'",|g'                                          $JIBRI_CONFIG
# set the first username and password for auth
sed -i '0,/"username": "username",/{s/"username": "username",/"username": "jibri",/g}'                                 $JIBRI_CONFIG
sed -i '0,/"password": "password"/{s/"password": "password"/"password": "'"$JIBRI_PASSWORD"'"/g}'                      $JIBRI_CONFIG
sed -i 's|"domain": "internal.auth.xmpp.domain",|"domain": "internal.auth.'"$DOMAIN_NAME"'",|g'                        $JIBRI_CONFIG
sed -i 's|"nickname": "jibri-nickname"|"nickname": "jibri"|g'                                                          $JIBRI_CONFIG
sed -i 's|"domain": "recorder.xmpp.domain",|"domain": "recorder.'"$DOMAIN_NAME"'",|g'                                  $JIBRI_CONFIG
# set the second username and password for the recorder to join the special room (brewery)
sed -i 's|"username": "username",|"username": "recorder",|g'                                                           $JIBRI_CONFIG
sed -i 's|"password": "password"|"password": "'"$RECORDER_PASSWORD"'"|g'                                               $JIBRI_CONFIG


# start Jibri when the server starts
systemctl enable jibri

# Restart services to apply changes
systemctl restart prosody
systemctl restart jicofo
systemctl restart jitsi-videobridge2
systemctl restart jibri
