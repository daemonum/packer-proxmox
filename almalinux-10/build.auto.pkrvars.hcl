boot_wait        = "15s"
node             = "bael"
vm_id            = 9001
cpu              = 2
cpu_type         = "host"
memory           = "2048"
vm_os_name       = "almalinux"
vm_os_version    = "10"
iso_file         = "local:iso/AlmaLinux-10.1-x86_64_v2-minimal.iso"
iso_checksum     = "sha256:b0dd2dc3ff4b390a6af8e79c231931bc547cd3f71a89e9bca2a01118f48e200e"
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
boot_command     = [
  "<wait5>",
  "e<wait2>",
  "<down><down><wait1>",
  "<end>",
  " inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg inst.text",
  "<wait1>",
  "<f10><wait>"
]
