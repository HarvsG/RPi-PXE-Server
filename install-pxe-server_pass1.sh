#!/bin/bash

######################################################################
#
# v2018-03-23
#
# known issues:
#

#bridge#


######################################################################
echo -e "\e[32msetup variables\e[0m";
SRC_MOUNT=/media/server


######################################################################
## optional
grep mod_install_server /etc/fstab > /dev/null || ( \
echo -e "\e[32madd usb-stick to fstab\e[0m";
[ -d "$SRC_MOUNT/" ] || sudo mkdir -p $SRC_MOUNT;
sudo sh -c "echo '
## mod_install_server
LABEL=PXE-Server  $SRC_MOUNT  auto  noatime,nofail,auto,x-systemd.automount,x-systemd.device-timeout=5,x-systemd.mount-timeout=5  0  0
' >> /etc/fstab"
sudo mount -a;
)


######################################################################
grep -q max_loop /boot/cmdline.txt 2> /dev/null || {
	echo -e "\e[32msetup cmdline.txt for more loop devices\e[0m";
	sudo sed -i '1 s/$/ max_loop=64/' /boot/cmdline.txt;
}


######################################################################
grep -q net.ifnames /boot/cmdline.txt 2> /dev/null || {
	echo -e "\e[32msetup cmdline.txt for old style network interface names\e[0m";
	sudo sed -i '1 s/$/ net.ifnames=0/' /boot/cmdline.txt;
}


######################################################################
sudo sync \
&& echo -e "\e[32mupdate...\e[0m" && sudo apt update -y \
&& echo -e "\e[32mupgrade...\e[0m" && sudo apt upgrade -y \
&& echo -e "\e[32mautoremove...\e[0m" && sudo apt autoremove -y --purge \
&& echo -e "\e[32mautoclean...\e[0m" && sudo apt autoclean \
&& sudo sync \
&& echo -e "\e[32mDone.\e[0m" \
;


######################################################################
echo -e "\e[32minstall nfs-kernel-server for pxe\e[0m";
sudo apt install -y nfs-kernel-server;
sudo systemctl enable nfs-kernel-server.service;
sudo systemctl restart nfs-kernel-server.service;

######################################################################
echo -e "\e[32menable port mapping\e[0m";
sudo systemctl enable rpcbind.service;
sudo systemctl restart rpcbind.service;


######################################################################
echo -e "\e[32minstall dnsmasq for pxe\e[0m";
sudo apt install -y dnsmasq
sudo systemctl enable dnsmasq.service;
sudo systemctl restart dnsmasq.service;


######################################################################
echo -e "\e[32minstall samba\e[0m";
sudo apt install -y samba;


######################################################################
echo -e "\e[32minstall rsync\e[0m";
sudo apt install -y rsync;


######################################################################
echo -e "\e[32minstall uuid\e[0m";
sudo apt install -y uuid;


#####################################################################
echo -e "\e[32minstall lighttpd\e[0m";
sudo apt install -y lighttpd;
sudo sh -c "cat << EOF  >> /etc/lighttpd/lighttpd.conf
########################################
## mod_install_server
dir-listing.activate = \"enable\" 
dir-listing.external-css = \"\"
dir-listing.external-js = \"\"
dir-listing.set-footer = \"&nbsp;<br />\"
dir-listing.exclude = ( \"[.]*\.url\" )
EOF";
sudo rm /var/www/html/index.lighttpd.html


######################################################################
echo -e "\e[32mdisable ntp\e[0m";
sudo systemctl stop ntp.service 1>/dev/null 2>/dev/null;
sudo systemctl disable ntp.service 1>/dev/null 2>/dev/null;

echo -e "\e[32minstall chrony as ntp client and ntp server\e[0m";
sudo apt install -y chrony;
sudo systemctl enable chronyd.service;
sudo systemctl restart chronyd.service;


######################################################################
echo -e "\e[32minstall syslinux-common for pxe\e[0m";
sudo apt install -y pxelinux syslinux-common syslinux-efi;

sudo wget -O /tmp/syslinux-6.04-pre1.tar.xz https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/Testing/6.04/syslinux-6.04-pre1.tar.xz;

echo -e "\e[32m update the 32bit efi file and ldlinux.e32 to 6.04-pre1 due to bugs\e[0m";
sudo tar -x -v -C /usr/lib/SYSLINUX.EFI/efi32/ -f /tmp/syslinux-6.04-pre1.tar.xz --strip-components=3 syslinux-6.04-pre1/efi32/efi/syslinux.efi;
sudo chown root:root /usr/lib/SYSLINUX.EFI/efi32/syslinux.efi;
sudo chmod 644 /usr/lib/SYSLINUX.EFI/efi32/syslinux.efi;
sudo tar -x -v -C /usr/lib/syslinux/modules/efi32/ -f /tmp/syslinux-6.04-pre1.tar.xz --strip-components=5 syslinux-6.04-pre1/efi32/com32/elflink/ldlinux/ldlinux.e32;
sudo chown root:root /usr/lib/syslinux/modules/efi32/ldlinux.e32;
sudo chmod 644 /usr/lib/syslinux/modules/efi32/ldlinux.e32;

echo -e "\e[32m update the 64bit efi file and ldlinux.e64 to 6.04-pre1 due to bugs\e[0m";
sudo tar -x -v -C /usr/lib/SYSLINUX.EFI/efi64/ -f /tmp/syslinux-6.04-pre1.tar.xz --strip-components=3 syslinux-6.04-pre1/efi64/efi/syslinux.efi;
sudo chown root:root /usr/lib/SYSLINUX.EFI/efi64/syslinux.efi;
sudo chmod 644 /usr/lib/SYSLINUX.EFI/efi64/syslinux.efi;
sudo tar -x -v -C /usr/lib/syslinux/modules/efi64/ -f /tmp/syslinux-6.04-pre1.tar.xz --strip-components=5 syslinux-6.04-pre1/efi64/com32/elflink/ldlinux/ldlinux.e64;
sudo chown root:root /usr/lib/syslinux/modules/efi64/ldlinux.e64;
sudo chmod 644 /usr/lib/syslinux/modules/efi64/ldlinux.e64;

sudo rm /tmp/syslinux-6.04-pre1.tar.xz;


######################################################################
#bridge#echo -e "\e[32minstall network bridge\e[0m";
#bridge#sudo apt install -y bridge-utils hostapd dnsmasq iptables iptables-persistent


######################################################################
## optional
#bridge#echo -e "\e[32minstall wireshark\e[0m";
#bridge#sudo apt install -y wireshark
#bridge#sudo usermod -a -G wireshark $USER


######################################################################
sync
echo -e "\e[32mDone.\e[0m";
echo -e "\e[1;31mPlease reboot\e[0m";
