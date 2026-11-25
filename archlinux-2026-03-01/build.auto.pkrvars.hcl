boot_wait        = "40s"
node             = "bael"
vm_id            = 9002
cpu              = 2
cpu_type         = "host"
memory           = "2048"
vm_os_name       = "archlinux"
vm_os_version    = "2026.06.01"
iso_file         = "local:iso/archlinux-2026.06.01-x86_64.iso"
iso_checksum     = "sha256:569f7331bbcb882d130035324ab5feb1cd9807ccc9a49aa61102d40121518db6"
iso_storage      = "local"
unmount          = true
vm_cloudinit     = true
bios             = "ovmf"
machine          = "q35"
disk_size        = "30G"
disk_storage     = "local-zfs"
disk_format      = "raw"
disk_type        = "virtio"
network_model    = "virtio"
network_bridge   = "vmbr0"
network_firewall = "false"
boot_command = [
  "<enter><wait5>",
  "pwd<enter><wait2>",
  "ip addr<enter><wait2>",
  "curl -v http://{{ .HTTPIP }}:{{ .HTTPPort }}/install.sh -o /root/install.sh<enter><wait10>",
  "ls -l /root/install.sh<enter><wait3>",
  "chmod +x /root/install.sh<enter><wait3>",
  "bash /root/install.sh 2>&1 | tee /root/install.log<enter>"
]
