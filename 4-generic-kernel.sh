apt -y install linux-image-extra-virtual
# install the package version of grub

# this part is fragile because it assums there are exactly 3 versions
# of the kernel installed: the aws version that comes with the server,
# the upgraded aws version, and the generic version we want
sed -i 's/GRUB_DEFAULT=0/GRUB_DEFAULT="1>4"/g' /etc/default/grub
update-grub
reboot now
