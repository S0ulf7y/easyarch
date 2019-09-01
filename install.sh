#!/bin/bash
#
# This script is intendet to install a simple and lightweight instance of Arch Linux on Desktop and Notebook systems.
# The installation contains a setup for german language user expirience.
# A working internet connection is required.

# Quit the script if any executed command fails:
set -e

# Set german keyboard layout
loadkeys de

# Select the disk for the installation
echo "On which disk do you want to install Arch Linux?"
echo 'You can just type i.e. "sda"'
lsblk
read -p "Disk:" disk

# Let the user confirm that the disk will be wiped
echo "Attention! This will wipe the selected hard drive! Do you want to continue?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done

# Wipe the disk
sgdisk /dev/"$disk" -o

# Calculate the right size of SWAP and the startpoint of the root partition
ram=$(free -m | awk '/^Mem:/{print $2}')
echo "$ram"
if [[ "$ram" < 2000 ]]; then
  bestswap=$(($ram * 2))
  echo "$bestswap"
fi
if [[ "$ram" > 8000 ]]; then
  bestswap=$(($ram * 0,5))
  echo "$bestswap"
fi

echo "$bestswap"

# Ask the user if the right amount of Swap is calculated
echo "$bestswap" "seems to be a good amount of Swap for your machine. Would you like to keep this value?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) read -p "Enter the Swap size you wish to set:" bestswap;;
    esac
done

# Set the endsector for the Swap partition and the startsector for the root partition
swapsize=$((ram + 514))
rootstart=$((swapsize + 1))

# Create the partition table
echo "Creating GPT table..."
parted /dev/"$disk" mklabel gpt --script
echo "Success!"

# Create the boot partition (always 512MB)
echo "Creating boot partition..."
parted /dev/"$disk" mkpart BOOT fat32 1MiB 513MiB
echo "Success!"

# Create the Swap partition based on the calcula
echo "Creating Swap partition..."
parted /dev/"$disk" mkpart p_swap linux-swap 514MiB "$swapsize"MiB
echo "Success!"

# Create the root partiton dynamically after the Swap partition
echo "Creating root partition..."
parted /dev/"$disk" mkpart p_arch ext4 "$rootstart"MiB 100%
echo "Success!"

# Set the boot disk as an EFI device
echo "Setting /dev/"$disk" as EFI device..."
parted /dev/"$disk" set 1 esp on
echo "Success!"

# Create the file systems for the new partitions
mkfs.ext4 -L p_arch /dev/"$disk"3
mkswap -L p_swap /dev/"$disk"2
mkfs.fat -F 32 -n BOOT /dev/"$disk"1

# Mount the newly created partitons
mount /dev/"$disk"3 /mnt
mkdir /mnt/boot
mount /dev/"$disk"1 /mnt/boot

# Turn Swap on for the swap partiton
swapon -L p_swap

# Update the pacman index
pacman -Sy

# Install the base system
pacstrap /mnt base base-devel intel-ucode wpa_supplicant dialog grub acpid dbus avahi cups cronie xorg xorg-drivers xf86-input-synaptics ttf-dejavu slim xfce4 xfce4-goodies faenza-icon-theme alsa-utils firefox firefox-i18n-de flashplugin icedtea-web ntfs-3g gvfs udisks2 udiskie pulseaudio pulseaudio-alsa wireless_tools networkmanager network-manager-applet gnome-keyring xscreensaver redshift sudo dkms linux-headers dosfstools efibootmgr

# Automatically generate the fstab file from the mount configuration
genfstab -Lp /mnt > /mnt/etc/fstab

# Copy the second file for the advanced config process to the hdd
cp ./install2.sh /mnt

# Switch to the newly installed system and run the second file
arch-chroot /mnt /install2.sh
