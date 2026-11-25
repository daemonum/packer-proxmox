build {
  sources = ["source.proxmox-iso.archlinux"]

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo env {{ .Vars }} {{ .Path }}"

    inline = [
      # Cloud-init / machine identity cleanup
      "cloud-init clean --logs --seed || true",
      "truncate -s 0 /etc/machine-id",
      "rm -f /var/lib/dbus/machine-id",

      # Log cleanup
      "rm -f /var/log/btmp /var/log/wtmp /var/log/lastlog",

      # Temp/history cleanup
      "find /tmp /var/tmp -mindepth 1 -delete",
      "rm -f /root/.bash_history"
    ]
  }

  provisioner "shell" {
    expect_disconnect = true
    skip_clean        = true
    execute_command   = "chmod +x {{ .Path }}; sudo env {{ .Vars }} {{ .Path }}"

    inline = [
      # Permanent SSH configuration
      "mkdir -p /etc/ssh/sshd_config.d",
      "rm -f /etc/ssh/sshd_config.d/10-packer.conf",
      "printf '%s\n' 'PermitRootLogin no' 'PasswordAuthentication no' 'KbdInteractiveAuthentication no' 'PubkeyAuthentication yes' 'X11Forwarding no' > /etc/ssh/sshd_config.d/zz-hardening.conf",
      "sshd -t",

      # Remove temporary Packer access
      "rm -rf /home/packer/.ssh",
      "rm -f /etc/sudoers.d/zz-packer",
      "passwd --lock packer",
      "usermod --shell /usr/bin/nologin packer",

      # Ensure Arch regenerates unique host keys on clone boot
      "systemctl enable sshdgenkeys.service",
      "systemctl enable sshd.service",
      "rm -f /etc/ssh/ssh_host_*",

      # Shut down for template conversion
      "systemctl poweroff"
    ]
  }
}