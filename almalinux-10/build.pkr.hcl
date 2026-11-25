build {
  sources = ["source.proxmox-iso.almalinux-10"]

  provisioner "shell" {
    inline = [
      # Cloud-init / machine identity cleanup
      "sudo cloud-init clean --logs --seed || true",
      "sudo rm -rf /var/lib/cloud/*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo rm -f /etc/udev/rules.d/70-persistent-net.rules",

      # Log cleanup
      "sudo rm -f /var/log/audit/audit.log",
      "sudo rm -f /var/log/btmp /var/log/wtmp /var/log/lastlog",
      "sudo rm -f /var/log/boot.log /var/log/cron",
      "sudo rm -f /var/log/dnf.log /var/log/yum.log",
      "sudo rm -f /var/log/maillog /var/log/messages /var/log/secure",

      # Temp/history cleanup
      "sudo find /tmp /var/tmp -mindepth 1 -delete",
      "sudo rm -f /root/.bash_history"
    ]
  }

  provisioner "shell" {
    expect_disconnect = true
    skip_clean        = true
    execute_command   = "chmod +x {{ .Path }}; sudo env {{ .Vars }} {{ .Path }}"

    inline = [
      # SSH hardening
      "mkdir -p /etc/ssh/sshd_config.d",
      "tee /etc/ssh/sshd_config.d/99-hardening.conf >/dev/null <<'EOF'\nPermitRootLogin no\nPasswordAuthentication no\nPubkeyAuthentication yes\nX11Forwarding no\nEOF",
      "sshd -t",

      # SELinux enforcing
      "sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config",
      "setenforce 1 || true",

      # Remove packer access
      "rm -rf /home/packer/.ssh",
      "rm -f /etc/sudoers.d/packer /etc/sudoers.d/99-packer",
      "passwd -l packer",
      "usermod -s /sbin/nologin packer",

      # Regenerate SSH host keys on first boot
      "rm -f /etc/ssh/ssh_host_*",

      # Fix SELinux labels before templating
      "restorecon -RFv /usr/libexec/openssh /etc/ssh /home /root /etc/sudoers.d || true",

      # Shutdown template
      "systemctl poweroff"
    ]
  }
}