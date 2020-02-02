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

# Verschlüssele /dev/"$disk"2
cryptsetup luksFormat -c aes-xts-plain64 -s 512 /dev/"$disk"2
 
# Öffnet verschlüsselten Cotainer wieder und mapped auf "lvm"
cryptsetup open --type luks /dev/"$disk"2 lvm

# Erstelle Volume Group auf /dev/mapper/lvm mit Namen "main"
vgcreate main /dev/mapper/lvm

# Erstelle 8GB SWAP
lvcreate -L 8G main -n swap

# Erstelle root mit Rest
lvcreate -l 100%FREE main -n root

# Set the boot disk as an EFI device
echo "Setting /dev/"$disk" as EFI device..."
parted /dev/"$disk" set 1 esp on
echo "Success!"

# Create the file systems for the new partitions
mkfs.ext4 -L p_arch /dev/mapper/main-root
mkswap -L p_swap /dev/mapper/main-swap
mkfs.fat -F 32 -n BOOT /dev/"$disk"1

# Mount the newly created partitons
mount /dev/mapper/main-root /mnt
mkdir /mnt/boot
mount /dev/"$disk"1 /mnt/boot
swapon /dev/mapper/main-swap

# Configure and update the pacman index
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
grep -E -A 1 ".*Germany.*$" /etc/pacman.d/mirrorlist.bak | sed '/--/d' > /etc/pacman.d/mirrorlist
pacman -Sy

# Install the base system
pacstrap /mnt base base-devel intel-ucode wpa_supplicant dialog grub acpid dbus avahi cups cronie xorg xorg-drivers xf86-input-synaptics ttf-dejavu slim xfce4 xfce4-goodies faenza-icon-theme alsa-utils ntfs-3g gvfs udisks2 udiskie pulseaudio pulseaudio-alsa wireless_tools networkmanager network-manager-applet gnome-keyring xscreensaver redshift sudo dkms linux-headers dosfstools efibootmgr slock vlc clementine gimp thunderbird thunderbird-i18n-de atom evince firefox firefox-i18n-de flashplugin icedtea-web archlinux-themes-slim gnome-system-monitor

# Automatically generate the fstab file from the mount configuration
genfstab -Lp /mnt > /mnt/etc/fstab

# Copy the correct mkinitcpio.conf file for LUKS to /mnt
cp ./mkinitcpio.conf /mnt/etc/

# Copy the correct grub config file to /mnt
cp ./grub /mnt/etc/default

# Copy the second file for the advanced config process to the hdd
cp ./install2.sh /mnt

# Copy the files for the X11 locale setup to the hdd
cp ./setx11locale.service /mnt/etc/systemd/system
cp ./setx11locale /mnt/usr/bin

# Switch to the newly installed system and run the second file
arch-chroot /mnt /install2.sh
