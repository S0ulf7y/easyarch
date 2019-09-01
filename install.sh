#!/bin/bash
#
# This script is intendet to install a simple and lightweight instance of Arch Linux on Desktop an Notebook systems.
# A working internet connection is required.

loadkeys de

sgdisk /dev/sda -o

parted /dev/sda mklabel gpt --script
parted /dev/sda mkpart BOOT fat32 1MiB 513MiB
parted /dev/sda mkpart p_swap linux-swap 514MiB 4610MiB
parted /dev/sda mkpart p_arch ext4 4611MiB 100%
parted /dev/sda set 1 esp on

mkfs.ext4 -L p_arch /dev/sda3
mkswap -L p_swap /dev/sda2
mkfs.fat -F 32 -n BOOT /dev/sda1

mount /dev/sda3 /mnt

mkdir /mnt/boot

mount /dev/sda1 /mnt/boot

swapon -L p_swap

pacman -Sy

pacstrap /mnt base base-devel intel-ucode wpa_supplicant dialog grub acpid dbus avahi cups cronie xorg xorg-drivers xf86-input-synaptics ttf-dejavu slim xfce4 xfce4-goodies faenza-icon-theme alsa-utils firefox firefox-i18n-de flashplugin icedtea-web vlc clementine gimp ntfs-3g gvfs udisks2 udiskie pulseaudio pulseaudio-alsa wireless_tools networkmanager network-manager-applet gnome-keyring thunderbird thunderbird-i18n-de xscreensaver atom evince redshift sudo dkms linux-headers dosfstools efibootmgr

genfstab -Lp /mnt > /mnt/etc/fstab

cp ./install2.sh /mnt

arch-chroot /mnt /install2.sh
