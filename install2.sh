#!/bin/bash
#
# This script is intended to install a simple and lightweight instance of Arch Linux on Desktop and Notebook systems.
# The installation contains a setup for german language user expirience.
# A working internet connection is required.
# The installation process is splitted in two scripts. This is script 2/2 for the configuration of the base system.
#
# TODO: Install an AUR helper
# TODO: Configure a screenlocker
# TODO: Configure GRUB2 Theme and Timeout
# TODO: Setup /home and Swap encryption option

# Quit the script if any executed command fails:
set -e

# Set a new hostname
read -p "Please enter the new hostname: " hostname
echo "$hostname" > /etc/hostname

# Set the locale
echo LANG=de_DE.UTF-8 > /etc/locale.conf
echo de_DE.UTF-8 UTF-8 >> /etc/locale.gen
echo de_DE ISO-8859-1 >> /etc/locale.gen
echo de_DE@euro ISO-8859-15 >> /etc/locale.gen
locale-gen

# Set the german keyboard layout to be loaded automatically
echo KEYMAP=de-latin1 > /etc/vconsole.conf
echo FONT=lat9w-16 >> /etc/vconsole.conf

# Set the timezone to berlin
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

# Update the pacman index
pacman -Sy

# Set a new root password
echo 'Set root password:'
passwd

# Create a new user
echo "Please enter your user name"
read username
useradd -m -g users -s /bin/bash "$username"

# Set the new users password
echo 'Set' "$username"'s' 'password:'
passwd "$username"

# Install and configure GRUB2
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg

# Enable all necessary services
systemctl enable acpid avahi-daemon cups cronie systemd-timesyncd lightdm NetworkManager wpa_supplicant setx11locale

# Disable the default DHCP service
systemctl disable dhcpcd dhcpcd@

# Make the script for the X11 keyymap executable
chmod +x /usr/bin/setx11locale

# Give the "wheel" group sudo permissions
echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers

# Add the user to the wheel group
gpasswd -a "$username" wheel

# Add the user to the network group
gpasswd -a "$username" network

# Load xfce4 on startup
echo '#!/bin/bash' > /home/"$username"/.xinitrc
echo 'nm-applet' >> /home/"$username"/.xinitrc

echo 'Done! Please restart your machine.'
