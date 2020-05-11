# Jitsi Up
start a new Jitsi server with Jibri

## Making a Jitsi server

### Create an EC2 instance
I've created an instance template that sets up a
t3.large instance with Ubuntu 18.04 LTS on AMD64 chips,
my security key, security groups for public access,
and only my ssh access (using my laptop IP).

For new developers, launch a new instance with these settings:
- Ubuntu Server 18.04 LTS (64-bit x86)
- t3.xlarge 4 CPUs & 16 Gb RAM
- New security group. Pick a name like Jitsi-Security-Group.
  - For security, change the SSH rule Source to "My IP" to restrict access.
  - Add rule - Type: HTTP, Source: Anywhere
  - Add rule - Type: HTTPS, Source: Anywhere
  - Add rule - Type: Custom TCP, Port: 4443, Source Anywhere
  - Add rule - Type: Custom UDP, Port 10000, Source Anywhere

When you launch, save the settings as a new template to make creating new instances easier.

For launching from template:
- Launch a new instance from the template.
  Make sure to have the security key (pem file)
  and the access group has the IP address of the laptop being used/

Finally, for everyone:
- Associate an Elastic IP address with the instance
  (can be reused for preserving DNS lookup).

### Set up DNS
To issue security ceritficates, Let's Encrypt (the free one),
seems not to allow AWS namesapce domains. I set up videostream.site
to point to the Elastic IP address we have in AWS
- Point a DNS lookup to the Elastic IP address of the EC2 instance
In this example, I'll use live.videostream.site as the domain.

### Edit 0-export-variable.sh
- Change DOMAIN_NAME to the domain set up above.
- Change JITSI_USER and JITSI_PASSWORD to set up a user that will have permission to create meetings
- Change APP_NAME to the name of you app.

### Copy files and SSH into EC2 instance
- If you are reusing the IP address and have SSH'd to the old servers, remove
 that line from known hosts.
- SSH to the instance, and enter super user mode.
  For example (replace with your own key and EC2 DNS address for the instance)
  ```
  scp -i ~/.ssh/jitsi-1.pem *.sh ubuntu@live.videostream.site:~
  ssh -i ~/.ssh/jitsi-1.pem ubuntu@live.videostream.site
  sudo su -
  ```

### Prepare variables for scripts
```
echo "source /home/ubuntu/0-export-variables.sh" >> ~/.bashrc
source  ~/.bashrc
```

### Change the host name to the domain name
```
source /home/ubuntu/1-change-host.sh
```
Install the package maintainer's version of the boot grub.
This will reboot the instance, kicking you off the SSH connection.
Reconnect to SSH after a few seconds.
```
ssh -i ~/.ssh/jitsi-1.pem ubuntu@live.videostream.site
sudo su -
```

### Optional - increase task count
According to the docs, the task count may go higher than the default limits
for conferences with over 100 participants.
https://github.com/jitsi/jitsi-meet/blob/master/doc/quick-install.md#advanced-configuration
```
source /home/ubuntu/2-increase-task-limit.sh
```
### Install Jitsi
```
source /home/ubuntu/3-jitsi-up.sh
```

### Visit your domain, Jitsi should be up!


## Installing Jibri

## Use generic Linux kernel
The AWS Linux kernel does not have the ALSA sound module.
The generic kernel has it.
```
source /home/ubuntu/4-generic-kernel.sh
```

This will reboot the instance, kicking you off the SSH connection.
Reconnect to SSH after a few seconds.
```
ssh -i ~/.ssh/jitsi-1.pem ubuntu@live.videostream.site
sudo su -
```
The Linux name should now be generic.
```
uname -r
```

### Install and configure Jibri
```
source /home/ubuntu/5-jibri-up.sh
```

## That's it
 You should be able to record and livestream with Jibri now
