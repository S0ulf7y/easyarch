echo "Please anter the new hostname"
read hostname
echo "$hostname" > /etc/hostname

echo LANG=de_DE.UTF-8 > /etc/locale.conf

echo de_DE.UTF-8 UTF-8 >> /etc/locale.gen
echo de_DE ISO-8859-1 >> /etc/locale.gen
echo de_DE@euro ISO-8859-15 >> /etc/locale.gen

locale-gen

echo KEYMAP=de-latin1 > /etc/vconsole.conf
echo FONT=lat9w-16 >> /etc/vconsole.conf

ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

pacman -Sy

mkinitcpio -p linux

echo 'Set root passwort:'
passwd

grub-mkconfig -o /boot/grub/grub.cfg

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub

systemctl enable acpid avahi-daemon org.cups.cupsd cronie systemd-timesyncd slim

echo "Please enter your user name"
read username
useradd -m -g users -s /bin/bash "$username"

echo 'Set' "$username"'s' 'password:'
passwd "$username"

echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers

gpasswd -a "$username" wheel

echo '#!/bin/bash' > /home/"$username"/.xinitrc
echo 'exec startxfce4' >> /home/"$username"/.xinitrc
echo 'nm-applet' >> /home/"$username"/.xinitrc

reboot
