# add jitsi to package manager
echo 'deb https://download.jitsi.org stable/' >> /etc/apt/sources.list.d/jitsi-stable.list
wget -qO - https://download.jitsi.org/jitsi-key.gpg.key | apt-key add -
apt update

# install jitsi
apt -y install jitsi-meet
# Enter site name
# Choose generate own certificate

# create SSL certificates
/usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh
# enter an email address

# Don't listen for Bosh on HTTPS
# Must be placed in main prosody config file to remove errors
echo '' >> /etc/prosody/prosody.cfg.lua
echo '-- BOSH connection is proxyed, do not liste for BOSH over HTTPS' >> /etc/prosody/prosody.cfg.lua
echo 'https_ports = { }' >> /etc/prosody/prosody.cfg.lua

# Add security for creating rooms
# tell Prosody to require authentication
sed -i 's/authentication = "anonymous"/authentication = "internal_plain"/g' /etc/prosody/conf.avail/videostream.site.cfg.lua
# tell jicofo to use the XMPP server for authentication
echo 'org.jitsi.jicofo.auth.URL=XMPP:videostream.site' >> /etc/jitsi/jicofo/sip-communicator.properties


# Configuring

# Allow anonymous users to join existing conferences with a guest VirtualHost
echo '' >> /etc/prosody/conf.avail/videostream.site.cfg.lua
echo 'VirtualHost "guest.videostream.site"' >> /etc/prosody/conf.avail/videostream.site.cfg.lua
echo '    authentication = "anonymous"' >> /etc/prosody/conf.avail/videostream.site.cfg.lua
echo '    c2s_require_encryption = false' >> /etc/prosody/conf.avail/videostream.site.cfg.lua
# add anonyomous domain for guests to client
sed -i "s_// anonymousdomain: 'guest.example.com',_anonymousdomain: 'guest.videostream.site',_g" /etc/jitsi/meet/videostream.site-config.js

# Configuring the interface of the client
# turn off audio levels to speed up rendering on client and clean up interface
sed -i "s_// disableAudioLevels: false,_disableAudioLevels: true,_g" /etc/jitsi/meet/videostream.site-config.js
# disable noisy mic detection to clean up interface
sed -i "s_enableNoisyMicDetection: true,_enableNoisyMicDetection: false,_g" /etc/jitsi/meet/videostream.site-config.js

# removed blurred video background
sed -i "s/DISABLE_VIDEO_BACKGROUND: false,/DISABLE_VIDEO_BACKGROUND: true,/g" /usr/share/jitsi-meet/interface_config.js
# removed default display name
sed -i "s/DEFAULT_REMOTE_DISPLAY_NAME: 'Fellow Jitster',/DEFAULT_REMOTE_DISPLAY_NAME: '',/g" /usr/share/jitsi-meet/interface_config.js
# removed my default display name
sed -i "s/DEFAULT_LOCAL_DISPLAY_NAME: 'me',/DEFAULT_LOCAL_DISPLAY_NAME: '',/g" /usr/share/jitsi-meet/interface_config.js
# remove jitsi watermark
sed -i "s/SHOW_JITSI_WATERMARK: true,/SHOW_JITSI_WATERMARK: false,/g" /usr/share/jitsi-meet/interface_config.js
sed -i "s-JITSI_WATERMARK_LINK: 'https://jitsi.org',-JITSI_WATERMARK_LINK: '',-g" /usr/share/jitsi-meet/interface_config.js
sed -i "s/SHOW_WATERMARK_FOR_GUESTS: true,/SHOW_WATERMARK_FOR_GUESTS: false,/g" /usr/share/jitsi-meet/interface_config.js
# remove generated room name
sed -i "s/GENERATE_ROOMNAMES_ON_WELCOME_PAGE: true,/GENERATE_ROOMNAMES_ON_WELCOME_PAGE: false,/g" /usr/share/jitsi-meet/interface_config.js
# cleaner welcome page
sed -i "s/DISPLAY_WELCOME_PAGE_CONTENT: true,/DISPLAY_WELCOME_PAGE_CONTENT: false,/g" /usr/share/jitsi-meet/interface_config.js
# remove option for resource intensive background blurring (comment out)
sed -i "s_'videobackgroundblur', _\n        //'videobackgroundblur',\n        _g" /usr/share/jitsi-meet/interface_config.js
# remove sounds for call overlay
sed -i "s/DISABLE_RINGING: false,/DISABLE_RINGING: true,/g" /usr/share/jitsi-meet/interface_config.js
# remove the connection indicator for a cleaner interface
sed -i "s/CONNECTION_INDICATOR_DISABLED: false,/CONNECTION_INDICATOR_DISABLED: true,/g" /usr/share/jitsi-meet/interface_config.js
# remove the video quality for a cleaner interface
sed -i "s/VIDEO_QUALITY_LABEL_DISABLED: false,/VIDEO_QUALITY_LABEL_DISABLED: true,/g" /usr/share/jitsi-meet/interface_config.js
# hirde recent list of meetings
sed -i "s/ RECENT_LIST_ENABLED: true,/ RECENT_LIST_ENABLED: false,/g" /usr/share/jitsi-meet/interface_config.js
sed -i "s/DISABLE_VIDEO_BACKGROUND: false,/DISABLE_VIDEO_BACKGROUND: true,/g" /usr/share/jitsi-meet/interface_config.js
sed -i "s/DISABLE_VIDEO_BACKGROUND: false,/DISABLE_VIDEO_BACKGROUND: true,/g" /usr/share/jitsi-meet/interface_config.js
sed -i "s/DISABLE_VIDEO_BACKGROUND: false,/DISABLE_VIDEO_BACKGROUND: true,/g" /usr/share/jitsi-meet/interface_config.js

# change the app title bar to app title
sed -i "s/APP_NAME: 'Jitsi Meet',/APP_NAME: 'Videostream',/g" /usr/share/jitsi-meet/interface_config.js
# note there is a native app name as well

# example - create account
prosodyctl register guest videostream.site password123

# Restart services to apply changes
systemctl restart prosody
systemctl restart jicofo
systemctl restart jitsi-videobridge2
