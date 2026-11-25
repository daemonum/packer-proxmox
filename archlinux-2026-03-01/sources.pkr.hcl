source "proxmox-iso" "archlinux" {
  communicator             = local.communicator
  ssh_username             = local.ssh_username
  ssh_password             = local.ssh_password
  ssh_timeout              = local.ssh_timeout
  proxmox_url              = local.proxmox_url
  username                 = local.proxmox_id
  token                    = local.proxmox_secret
  node                     = var.node
  vm_id                    = var.vm_id
  vm_name                  = local.vm_name
  template_name            = local.vm_name
  template_description     = local.build_description
  cores                    = var.cpu
  cpu_type                 = var.cpu_type
  memory                   = var.memory
  insecure_skip_tls_verify = true
  boot_command             = var.boot_command
  boot_wait                = var.boot_wait
  cloud_init               = var.vm_cloudinit
  cloud_init_storage_pool  = var.disk_storage

  boot_iso {
    iso_file         = var.iso_file
    iso_checksum     = var.iso_checksum
    iso_storage_pool = var.iso_storage
    unmount          = var.unmount
  }

  bios    = var.bios
  machine = var.machine

  efi_config {
    efi_storage_pool  = var.disk_storage
    pre_enrolled_keys = false
  }

  disks {
    disk_size    = var.disk_size
    storage_pool = var.disk_storage
    format       = var.disk_format
    type         = var.disk_type
  }

  network_adapters {
    model    = var.network_model
    bridge   = var.network_bridge
    firewall = var.network_firewall
  }

  http_content = local.install_content
}
