#!/bin/bash
set -e

# Interactive User Input
echo "Enter hostname: "
read hostname
echo "Enter username: "
read username
echo "Enter root password: "
read -s root_password
echo "Enter user password: "
read -s user_password
echo "Enter your region (e.g., America/New_York): "
read timezone
echo "Do you want to change the locale? (y/n): "
read change_locale
if [ "$change_locale" == "y" ]; then
    echo "Enter your locale (e.g., en_US.UTF-8): "
    read locale
else
    locale="en_US.UTF-8"
fi

echo "Enter the disk to install on (e.g., /dev/mmcblk0, /dev/sda): "
read disk

# Partitioning
echo "Partitioning Disk..."
parted $disk mklabel gpt
parted $disk mkpart ESP fat32 1MiB 513MiB
parted $disk set 1 esp on
parted $disk mkpart primary ext4 513MiB 100%

# Formatting
mkfs.fat -F32 ${disk}p1
mkfs.ext4 ${disk}p2

# Mounting
mount ${disk}p2 /mnt
mkdir -p /mnt/boot
mount ${disk}p1 /mnt/boot

# Install base system
pacstrap /mnt base linux linux-firmware nano networkmanager

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot and configure system
arch-chroot /mnt /bin/bash <<EOF
set -e

ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc
sed -i 's/#$locale UTF-8/$locale UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=$locale" > /etc/locale.conf
echo "$hostname" > /etc/hostname

# Set up /etc/hosts
echo "127.0.0.1   localhost" >> /etc/hosts
echo "::1         localhost" >> /etc/hosts
echo "127.0.1.1   $hostname.localdomain $hostname" >> /etc/hosts

# Set root password
echo "root:$root_password" | chpasswd

# Install bootloader
mkdir -p /boot/efi
mount ${disk}p1 /boot/efi
pacman -S grub efibootmgr --noconfirm
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Enable NetworkManager
systemctl enable NetworkManager
EOF

# Install Desktop Environment and Essential Packages
arch-chroot /mnt /bin/bash <<EOF
pacman -S xorg cinnamon lightdm lightdm-gtk-greeter conky fastfetch htop kitty tlp firefox zsh rhythmbox timeshift pulseaudio pavucontrol git base-devel --noconfirm
systemctl enable lightdm
echo "$username ALL=(ALL) ALL" > /etc/sudoers.d/$username
useradd -m -G wheel -s /bin/zsh $username
echo "$username:$user_password" | chpasswd
EOF

# Install Yay as user
arch-chroot /mnt /bin/bash -c "sudo -u $username bash -c 'cd ~ && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si --noconfirm'"

# Remove Yay build folder
arch-chroot /mnt /bin/bash -c "sudo -u $username rm -rf /home/$username/yay-bin"

# Install AUR packages as user
arch-chroot /mnt /bin/bash -c "sudo -u $username yay -S albert oh-my-zsh-git zsh-theme-powerlevel10k-git --noconfirm"

# Remove build files for AUR packages
arch-chroot /mnt /bin/bash -c "sudo -u $username rm -rf /home/$username/.cache/yay/*"

# Unmount and Reboot
umount -R /mnt
echo "Installation complete! Rebooting..."
reboot
