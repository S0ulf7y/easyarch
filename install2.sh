#!/bin/bash
#
# This script is intendet to install a simple and lightweight instance of Arch Linux on Desktop and Notebook systems.
# The installation contains a setup for german language user expirience.
# A working internet connection is required.
# The installation process is splitted in two scripts. This is script 2/2 for the configuration of the base system.
#
# TODO: Configure a screenlocker
# TODO: Configure GRUB2 Theme and Timeout
# TODO: Setup /home and Swap encryption option

# Quit the script if any executed command fails:
set -e

# Set a new hostname
echo "Please enter the new hostname"
read hostname
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

# Create the initramfs
mkinitcpio -p linux

# Install and configure GRUB2
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg

# Enable all necessary services
systemctl enable acpid avahi-daemon org.cups.cupsd cronie systemd-timesyncd slim NetworkManager wpa_supplicant setx11locale

# Disable the default DHCP service
systemctl disable dhcpcd dhcpcd@

# Make the script for the X11 keyymap executable
chmod +x /usr/bin/setx11locale

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

# Give the "wheel" group sudo permissions
echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers

# Add the user to the wheel group
gpasswd -a "$username" wheel

# Add the user to the network group
gpasswd -a "$username" network

# Load xfce4 on startup
echo '#!/bin/bash' > /home/"$username"/.xinitrc
echo 'exec startxfce4' >> /home/"$username"/.xinitrc
echo 'nm-applet' >> /home/"$username"/.xinitrc

# Install pikaur as the default AUR helper
git clone https://aur.archlinux.org/pikaur.git
cd pikaur/
su $username -c "makepkg -fsri --noconfirm"
cd ..
rm -rf pikaur/

# Autostart Redshift
mv /Redshift.desktop /home/"$username"/.config/autostart

# Configure the default shell
echo "Which shell do you prefer?"
select shell in "Bash" "ZSH" "fish"; do
    case $shell in
        Bash ) break;;
        ZSH ) pacman -S zsh; touch /home/"$username"/.zshrc; sh -c "$(wget -O- https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"; chsh -s /bin/zsh "$username"; break;;
        fish ) pacman -S fish; chsh -s "/usr/bin/fish"; break;;
    esac
done

# Configure username and email for git
read -p "Please enter your username for git:" gitname
read -p "Please enter your email for git:" gitmail
git config --global user.name "$gitname"
git config --global user.email "$gitmail"

echo 'Done! Please restart your machine.'
