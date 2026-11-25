eula --agreed
lang en_US
keyboard --xlayouts='us'
timezone America/Chicago --utc
rootpw --lock

text
firstboot --disabled

bootloader --append="rhgb quiet crashkernel=1G-4G:192M,4G-64G:256M,64G-:512M"
zerombr
clearpart --all --initlabel
autopart

network --bootproto=dhcp

repo --name="BaseOS" --baseurl=https://repo.almalinux.org/almalinux/10/BaseOS/x86_64/os/
repo --name="AppStream" --baseurl=https://repo.almalinux.org/almalinux/10/AppStream/x86_64/os/

skipx

%packages
@^minimal-environment
-amd-gpu-firmware
kexec-tools
cloud-init
ca-certificates
qemu-guest-agent
vim
gnupg
curl
wget
git
jq
tcpdump
lsof
unzip
tar
bash-completion
cloud-utils-growpart
nfs-utils
chrony
audit
%end

%post --interpreter=/bin/bash
set -uxo pipefail

setenforce 0 || true
sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

useradd -m -s /bin/bash packer
echo 'packer:packer' | chpasswd

cat > /etc/sudoers.d/99-packer <<'EOF'
packer ALL=(ALL) NOPASSWD: ALL
EOF

chmod 0440 /etc/sudoers.d/99-packer

dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm
dnf install -y htop

cat > /etc/sysctl.d/99-base.conf <<EOF
net.ipv4.ip_forward = 1
net.ipv4.tcp_syncookies = 1
vm.swappiness = 10
fs.file-max = 100000
EOF

cat > /etc/security/limits.d/99-base.conf <<EOF
* soft nofile 65536
* hard nofile 65536
EOF

mkdir -p /var/log/journal
chmod 2755 /var/log/journal

mkdir -p /etc/cloud/cloud.cfg.d
cat > /etc/cloud/cloud.cfg.d/99_pve.cfg <<'EOF'
datasource_list: [ConfigDrive, NoCloud]
growpart:
  mode: auto
  devices: ['/']
  ignore_growroot_disabled: false
resize_rootfs: true
EOF

systemctl enable chronyd
systemctl enable auditd
systemctl enable cockpit.socket
systemctl enable qemu-guest-agent
systemctl enable NetworkManager
systemctl enable sshd
systemctl enable cloud-config
systemctl enable cloud-init
systemctl enable cloud-init-local
systemctl enable cloud-final

%end
reboot