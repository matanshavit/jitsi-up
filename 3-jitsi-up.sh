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
# note the rate limits for Let's Encrypt,
# especially 5 duplicate certificates per week
# https://letsencrypt.org/docs/rate-limits/

# Don't listen for Bosh on HTTPS
# Must be placed in main prosody config file to remove errors
echo ''                                        >> $PROSODY_GLOBAL_CONFIG
echo '-- BOSH connection is proxyed,'          >> $PROSODY_GLOBAL_CONFIG
echo '-- so do not listen for BOSH over HTTPS' >> $PROSODY_GLOBAL_CONFIG
echo 'https_ports = { }'                       >> $PROSODY_GLOBAL_CONFIG

# Add security for creating rooms
# tell Prosody to require authentication
sed -i 's/authentication = "anonymous"/authentication = "internal_plain"/g' $PROSODY_CONFIG
# tell jicofo to use the XMPP server for authentication
echo "org.jitsi.jicofo.auth.URL=XMPP:$DOMAIN_NAME" >> $JICOFO_SIP_PROPS


# Configuring

# Allow anonymous users to join existing conferences with a guest VirtualHost
echo ''                                       >> $PROSODY_CONFIG
echo 'VirtualHost "'"guest.$DOMAIN_NAME"'"'   >> $PROSODY_CONFIG
echo '    authentication = "anonymous"'       >> $PROSODY_CONFIG
echo '    c2s_require_encryption = false'     >> $PROSODY_CONFIG
# add anonyomous domain for guests to client
sed -i "s_// anonymousdomain: 'guest.example.com',_anonymousdomain: 'guest.$DOMAIN_NAME',_g" $JITSI_MEET_CONFIG

# Configuring the interface of the client
# turn off audio levels to speed up rendering on client and clean up interface
sed -i "s_// disableAudioLevels: false,_disableAudioLevels: true,_g"        $JITSI_MEET_CONFIG
# disable noisy mic detection to clean up interface
sed -i "s_enableNoisyMicDetection: true,_enableNoisyMicDetection: false,_g" $JITSI_MEET_CONFIG

# removed blurred video background
sed -i "s/DISABLE_VIDEO_BACKGROUND: false,/DISABLE_VIDEO_BACKGROUND: true,/g"                     $JITSI_MEET_INTERFACE_CONFIG
# removed default display name
sed -i "s/DEFAULT_REMOTE_DISPLAY_NAME: 'Fellow Jitster',/DEFAULT_REMOTE_DISPLAY_NAME: '',/g"      $JITSI_MEET_INTERFACE_CONFIG
# removed my default display name
sed -i "s/DEFAULT_LOCAL_DISPLAY_NAME: 'me',/DEFAULT_LOCAL_DISPLAY_NAME: '',/g"                    $JITSI_MEET_INTERFACE_CONFIG
# remove jitsi watermark
sed -i "s/SHOW_JITSI_WATERMARK: true,/SHOW_JITSI_WATERMARK: false,/g"                             $JITSI_MEET_INTERFACE_CONFIG
sed -i "s-JITSI_WATERMARK_LINK: 'https://jitsi.org',-JITSI_WATERMARK_LINK: '',-g"                 $JITSI_MEET_INTERFACE_CONFIG
sed -i "s/SHOW_WATERMARK_FOR_GUESTS: true,/SHOW_WATERMARK_FOR_GUESTS: false,/g"                   $JITSI_MEET_INTERFACE_CONFIG
# remove generated room name
sed -i "s/GENERATE_ROOMNAMES_ON_WELCOME_PAGE: true,/GENERATE_ROOMNAMES_ON_WELCOME_PAGE: false,/g" $JITSI_MEET_INTERFACE_CONFIG
# cleaner welcome page
sed -i "s/DISPLAY_WELCOME_PAGE_CONTENT: true,/DISPLAY_WELCOME_PAGE_CONTENT: false,/g"             $JITSI_MEET_INTERFACE_CONFIG
# remove option for resource intensive background blurring (comment out)
sed -i "s_'videobackgroundblur', _\n        //'videobackgroundblur',\n        _g"                 $JITSI_MEET_INTERFACE_CONFIG
# remove option for raising hand to clean up interface
sed -i "s_'raisehand',_\n        //'raisehand',\n        _g"                                      $JITSI_MEET_INTERFACE_CONFIG
# remove sounds for call overlay
sed -i "s/DISABLE_RINGING: false,/DISABLE_RINGING: true,/g"                                       $JITSI_MEET_INTERFACE_CONFIG
# remove the connection indicator for a cleaner interface
sed -i "s/CONNECTION_INDICATOR_DISABLED: false,/CONNECTION_INDICATOR_DISABLED: true,/g"           $JITSI_MEET_INTERFACE_CONFIG
# remove the video quality for a cleaner interface
sed -i "s/VIDEO_QUALITY_LABEL_DISABLED: false,/VIDEO_QUALITY_LABEL_DISABLED: true,/g"             $JITSI_MEET_INTERFACE_CONFIG
# hide recent list of meetings
sed -i "s/ RECENT_LIST_ENABLED: true,/ RECENT_LIST_ENABLED: false,/g"                             $JITSI_MEET_INTERFACE_CONFIG

# change the app title bar to app title
sed -i "s/ APP_NAME: 'Jitsi Meet',/ APP_NAME: '$APP_NAME',/g"                                     $JITSI_MEET_INTERFACE_CONFIG
# note there is a native app name as well

# example - create account
prosodyctl register $JITSI_USER $DOMAIN_NAME $JITSI_PASSWORD

# Restart services to apply changes
systemctl restart prosody
systemctl restart jicofo
systemctl restart jitsi-videobridge2
