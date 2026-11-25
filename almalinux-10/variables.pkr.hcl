variable "vm_os_name" {
  type = string
}

variable "vm_os_version" {
  type = string
}

variable "proxmox_url" {
  type = string
}

variable "proxmox_id" {
  type      = string
  sensitive = true
}

variable "proxmox_secret" {
  type      = string
  sensitive = true
}

variable "node" {
  type = string
}

variable "vm_id" {
  type = number
}

variable "cpu" {
  type = number
}

variable "cpu_type" {
  type = string
}

variable "memory" {
  type = number
}

variable "boot_command" {
  type = list(string)
}

variable "boot_wait" {
  type = string
}

variable "bios" {
  type = string
}

variable "machine" {
  type = string
}

variable "vm_cloudinit" {
  type = bool
}

variable "iso_file" {
  type = string
}

variable "iso_checksum" {
  type = string
}

variable "iso_storage" {
  type = string
}

variable "unmount" {
  type = bool
}

variable "disk_size" {
  type = string
}

variable "disk_storage" {
  type = string
}

variable "disk_format" {
  type = string
}

variable "disk_type" {
  type = string
}

variable "network_model" {
  type = string
}

variable "network_bridge" {
  type = string
}

variable "network_firewall" {
  type = bool
}
