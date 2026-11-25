#!/usr/bin/env bash
set -Eeuo pipefail

DISK="/dev/vda"
TIMEZONE="$${TIMEZONE:-America/Chicago}"

echo "Available block devices:"
lsblk

echo "Selected installation disk: $DISK"
sleep 5

timedatectl set-ntp true

echo "Wiping and partitioning $DISK..."

swapoff --all 2>/dev/null || true
umount -R /mnt 2>/dev/null || true

wipefs --all --force "$DISK"

parted --script "$DISK" mklabel gpt
parted --script "$DISK" mkpart ESP fat32 1MiB 513MiB
parted --script "$DISK" set 1 esp on
parted --script "$DISK" mkpart primary ext4 513MiB 100%

partprobe "$DISK"
udevadm settle

EFI_PARTITION="$${DISK}1"
ROOT_PARTITION="$${DISK}2"

echo "Formatting partitions..."

mkfs.fat -F 32 -n EFI "$EFI_PARTITION"
mkfs.ext4 -F -L arch-root "$ROOT_PARTITION"

echo "Mounting filesystems..."

mount "$ROOT_PARTITION" /mnt
mkdir -p /mnt/boot
mount "$EFI_PARTITION" /mnt/boot

echo "Refreshing installation mirror list..."

reflector \
  --country US \
  --protocol https \
  --latest 20 \
  --sort rate \
  --save /etc/pacman.d/mirrorlist

pacman -Syy

echo "Installing Arch Linux packages..."

pacstrap -K /mnt \
  base \
  linux \
  linux-firmware \
  grub \
  efibootmgr \
  networkmanager \
  openssh \
  sudo \
  cloud-init \
  qemu-guest-agent \
  python \
  ca-certificates \
  vim \
  gnupg \
  curl \
  wget \
  git \
  jq \
  htop \
  tcpdump \
  lsof \
  unzip \
  tar \
  bash-completion \
  cloud-guest-utils \
  nfs-utils \
  reflector \
  firewalld

echo "Generating fstab..."

genfstab -U /mnt > /mnt/etc/fstab

echo "Configuring installed system..."

arch-chroot /mnt /usr/bin/env TIMEZONE="$TIMEZONE" /bin/bash <<'CHROOT_EOF'
set -Eeuo pipefail

ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf

cat > /etc/hosts <<'EOF'
127.0.0.1 localhost
::1       localhost
EOF

echo "Creating temporary Packer account..."

useradd \
  --create-home \
  --shell /bin/bash \
  --groups wheel \
  packer

echo "packer:packer" | chpasswd

install -d -m 0750 /etc/sudoers.d

cat > /etc/sudoers.d/zz-packer <<'EOF'
packer ALL=(ALL:ALL) NOPASSWD: ALL
EOF

chmod 0440 /etc/sudoers.d/zz-packer

cat > /etc/sudoers.d/wheel <<'EOF'
%wheel ALL=(ALL:ALL) ALL
EOF

chmod 0440 /etc/sudoers.d/wheel

echo "Configuring temporary SSH access for Packer..."

install -d -m 0755 /etc/ssh/sshd_config.d

cat > /etc/ssh/sshd_config.d/10-packer.conf <<'EOF'
PasswordAuthentication yes
EOF

chmod 0600 /etc/ssh/sshd_config.d/10-packer.conf

install -d -m 0755 /etc/sysctl.d

cat > /etc/sysctl.d/zz-base.conf <<'EOF'
net.ipv4.ip_forward = 1
net.ipv4.tcp_syncookies = 1
vm.swappiness = 10
fs.file-max = 100000
EOF

install -d -m 0755 /etc/security/limits.d

cat > /etc/security/limits.d/zz-base.conf <<'EOF'
* soft nofile 65536
* hard nofile 65536
EOF

mkdir -p /var/log/journal
chmod 2755 /var/log/journal

echo "Installing GRUB fallback UEFI bootloader..."

grub-install \
  --target=x86_64-efi \
  --efi-directory=/boot \
  --bootloader-id=GRUB \
  --removable \
  --no-nvram \
  --recheck

grub-mkconfig -o /boot/grub/grub.cfg

echo "Configuring cloud-init..."

install -d -m 0755 /etc/cloud/cloud.cfg.d

cat > /etc/cloud/cloud.cfg.d/zz-pve.cfg <<'EOF'
datasource_list: [ConfigDrive, NoCloud]

growpart:
  mode: auto
  devices:
    - /
  ignore_growroot_disabled: false

resize_rootfs: true
EOF

echo "Enabling services..."

systemctl enable NetworkManager.service
systemctl enable qemu-guest-agent.service
systemctl enable systemd-timesyncd.service

systemctl enable sshdgenkeys.service
systemctl enable sshd.service

systemctl enable cloud-init-local.service

if systemctl list-unit-files cloud-init-main.service >/dev/null 2>&1; then
  systemctl enable cloud-init-main.service
elif systemctl list-unit-files cloud-init.service >/dev/null 2>&1; then
  systemctl enable cloud-init.service
fi

systemctl enable cloud-config.service
systemctl enable cloud-final.service

pacman -Scc --noconfirm || true

rm -f /var/log/pacman.log
rm -f /root/.bash_history

find /tmp -mindepth 1 -delete
find /var/tmp -mindepth 1 -delete
CHROOT_EOF

sync
umount -R /mnt

echo "Arch Linux installation completed successfully."
echo "Rebooting into the installed system for Packer SSH provisioning..."

reboot