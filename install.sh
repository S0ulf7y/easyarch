#!/bin/bash
#
# This script is intendet to install a simple and lightweight instance of Arch Linux on Desktop an Notebook systems.
# The installation contains a setup for german language user expirience.
# A working internet connection is required.

# Quit the script if any executed command fails:
set -e

# Set german keyboard layout
loadkeys de

echo "On which disk do you want to install Arch Linux?"
echo 'You can just type i.e. "sda"'
lsblk
read disk

echo "Attention! This will wipe the selected hard drive! Do you want to continue?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done

sgdisk /dev/"$disk" -o

ram=$(free -m | awk '/^Mem:/{print $2}')
ram=$((ram * 2))
swapsize=$((ram + 514))
rootstart=$((swapsize + 1))

echo "Creating GPT table..."
parted /dev/"$disk" mklabel gpt --script
echo "Success!"
echo "Creating boot partition..."
parted /dev/"$disk" mkpart BOOT fat32 1MiB 513MiB
echo "Success!"
echo "Creating Swap partition..."
parted /dev/"$disk" mkpart p_swap linux-swap 514MiB "$swapsize"MiB
echo "Success!"
echo "Creating root partition..."
parted /dev/"$disk" mkpart p_arch ext4 "$rootstart"MiB 100%
echo "Success!"
echo "Setting /dev/"$disk" as EFI device..."
parted /dev/"$disk" set 1 esp on
echo "Success!"

mkfs.ext4 -L p_arch /dev/"$disk"3
mkswap -L p_swap /dev/"$disk"2
mkfs.fat -F 32 -n BOOT /dev/"$disk"1

mount /dev/"$disk"3 /mnt

mkdir /mnt/boot

mount /dev/"$disk"1 /mnt/boot

swapon -L p_swap

pacman -Sy

pacstrap /mnt base base-devel intel-ucode wpa_supplicant dialog grub acpid dbus avahi cups cronie xorg xorg-drivers xf86-input-synaptics ttf-dejavu slim xfce4 xfce4-goodies faenza-icon-theme alsa-utils firefox firefox-i18n-de flashplugin icedtea-web ntfs-3g gvfs udisks2 udiskie pulseaudio pulseaudio-alsa wireless_tools networkmanager network-manager-applet gnome-keyring xscreensaver redshift sudo dkms linux-headers dosfstools efibootmgr

genfstab -Lp /mnt > /mnt/etc/fstab

cp ./install2.sh /mnt

arch-chroot /mnt /install2.sh
