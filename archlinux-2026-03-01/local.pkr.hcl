data "git-repository" "cwd" {}

locals {
  build_by          = "built by: hashicorp packer ${packer.version}"
  build_date        = formatdate("DD-MM-YYYY hh:mm 'CST'", timestamp())
  build_version     = data.git-repository.cwd.head
  build_description = "version: ${local.build_version}\nbuilt on: ${local.build_date}\n${local.build_by}\ncloud-init: ${var.vm_cloudinit}"
  vm_name           = "${var.vm_os_name}-${var.vm_os_version}"
  proxmox_url       = var.proxmox_url
  proxmox_id        = var.proxmox_id
  proxmox_secret    = var.proxmox_secret
  communicator      = "ssh"
  ssh_username      = "packer"
  ssh_password      = "packer"
  ssh_timeout       = "20m"
  install_content = {
    "/install.sh" = templatefile("${abspath(path.root)}/install.sh.pkrtpl.hcl", {})
  }
}