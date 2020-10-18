#!/bin/bash
#
# This script is intendet to install a simple and lightweight instance of Arch Linux on Desktop and Notebook systems.
# The installation contains a setup for german language user expirience.
# A working internet connection is required.
# The installation process is splitted in two scripts. This is script 1/2 for the installation of the base system. Script 2/2 will be copied to the hard drive and executed automatically.
# TODO: Setup Full Disk Encryption option

# Quit the script if any executed command fails:
set -e

# Set german keyboard layout
loadkeys de

# Select the disk for the installation
echo "On which disk do you want to install Arch Linux?"
echo 'You can just type i.e. "sda"'
lsblk
read -p "Disk:" disk

# Wipe the disk
sgdisk /dev/"$disk" -o
# Create the partition table
echo "Creating GPT table..."
parted /dev/"$disk" mklabel gpt --script
echo "Success!"

# Create the boot partition (always 512MB)
echo "Creating boot partition..."
parted /dev/"$disk" mkpart BOOT fat32 1MiB 513MiB
echo "Success!"

# Create the root partiton dynamically after the Swap partition
echo "Creating root partition..."
parted /dev/"$disk" mkpart p_arch ext4 514MiB 100%
echo "Success!"

# Set the boot disk as an EFI device
echo "Setting /dev/"$disk" as EFI device..."
parted /dev/"$disk" set 1 esp on
echo "Success!"

# Create the file systems for the new partitions
mkfs.ext4 -L p_arch /dev/"$disk"2
mkfs.fat -F 32 -n BOOT /dev/"$disk"1

# Mount the newly created partitons
mount /dev/"$disk"2 /mnt
mkdir /mnt/boot
mount /dev/"$disk"1 /mnt/boot

# Configure and update the pacman index
pacman -Sy

# Install the base system
pacstrap /mnt base base-devel intel-ucode linux linux-firmware wpa_supplicant dialog grub acpid dbus avahi cups cronie xorg xorg-drivers xf86-input-synaptics ttf-dejavu slim xfce4 xfce4-goodies faenza-icon-theme alsa-utils ntfs-3g gvfs udisks2 udiskie pulseaudio pulseaudio-alsa wireless_tools networkmanager network-manager-applet gnome-keyring xscreensaver redshift sudo dkms linux-headers dosfstools efibootmgr slock vlc clementine gimp thunderbird thunderbird-i18n-de atom evince firefox firefox-i18n-de flashplugin icedtea-web archlinux-themes-slim gnome-system-monitor

# Automatically generate the fstab file from the mount configuration
genfstab -Lp /mnt > /mnt/etc/fstab

############## Start of install2.sh
echo 'set -e' > install2.sh

# Set a new hostname
echo 'read -p "Please enter the new hostname: " hostname' >> install2.sh
echo 'echo "$hostname" > /etc/hostname' >> install2.sh

# Set the locale
echo 'echo LANG=de_DE.UTF-8 > /etc/locale.conf' >> install2.sh
echo 'echo de_DE.UTF-8 UTF-8 >> /etc/locale.gen' >> install2.sh
echo 'echo de_DE ISO-8859-1 >> /etc/locale.gen' >> install2.sh
echo 'echo de_DE@euro ISO-8859-15 >> /etc/locale.gen' >> install2.sh
echo 'locale-gen' >> install2.sh

# Set the german keyboard layout to be loaded automatically
echo 'echo KEYMAP=de-latin1 > /etc/vconsole.conf' >> install2.sh
echo 'echo FONT=lat9w-16 >> /etc/vconsole.conf' >> install2.sh

# Set the timezone to berlin
echo 'ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime' >> install2.sh

# Update the pacman index
echo 'pacman -Sy' >> install2.sh

# Create the initramfs
echo 'mkinitcpio -p linux' >> install2.sh

# Set a new root password
echo 'echo "Set root password:"' >> install2.sh
echo 'passwd' >> install2.sh

# Install and configure GRUB2
echo 'grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub' >> install2.sh
echo 'grub-mkconfig -o /boot/grub/grub.cfg' >> install2.sh

# Enable all necessary services
echo 'systemctl enable acpid avahi-daemon org.cups.cupsd cronie systemd-timesyncd slim NetworkManager wpa_supplicant setx11locale' >> install2.sh

# Disable the default DHCP service
echo 'systemctl disable dhcpcd dhcpcd@' >> install2.sh

# Make the script for the X11 keyymap executable
echo 'chmod +x /usr/bin/setx11locale' >> install2.sh

# Create a new user
echo 'echo "Please enter your user name"' >> install2.sh
echo 'read username' >> install2.sh
echo 'useradd -m -g users -s /bin/bash "$username"'>> install2.sh

# Set the new users password
echo 'echo "Set" "$username""s" "password:"' >> install2.sh
echo 'passwd "$username"' >> install2.sh

# Give the "wheel" group sudo permissions
echo 'echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers' >> install2.sh

# Add the user to the wheel group
echo 'gpasswd -a "$username" wheel' >> install2.sh

# Add the user to the network group
echo 'gpasswd -a "$username" network' >> install2.sh

# Load xfce4 on startup
echo 'echo "#!/bin/bash" > /home/"$username"/.xinitrc' >> install2.sh
echo 'echo "exec startxfce4" >> /home/"$username"/.xinitrc' >> install2.sh
echo 'echo "nm-applet" >> /home/"$username"/.xinitrc' >> install2.sh

echo 'echo "Done! Please restart your machine."' >> install2.sh
############## End of install2.sh

# Copy the second file for the advanced config process to the hdd
chmod +x install2.sh
cp ./install2.sh /mnt

############## Start of setx11locale.service
echo '[Unit]' > setx11locale.service
echo 'Description=Set the X11 keyboard layout to german' >> setx11locale.service

echo '[Service]' >> setx11locale.service
echo 'ExecStart=/usr/bin/setx11locale' >> setx11locale.service

echo '[Install]' >> setx11locale.service
echo 'WantedBy=multi-user.target' >> setx11locale.service
############## End of setx11locale.service

############## Start of setx11locale
echo '#!/bin/bash' > setx11locale

# Quit the script if any executed command fails:
echo 'set -e' >> setx11locale

# Set the X11 keymap to german
echo 'localectl set-x11-keymap de' >> setx11locale

# Disable the service
echo 'systemctl disable setx11locale' >> setx11locale

# Delete the service
echo 'rm /etc/systemd/system/setx11locale.service' >> setx11locale
############## End of setx11locale

# Copy the files for the X11 locale setup to the hdd
cp ./setx11locale.service /mnt/etc/systemd/system
cp ./setx11locale /mnt/usr/bin

# Switch to the newly installed system and run the second file
arch-chroot /mnt /install2.sh
