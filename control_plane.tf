resource "libvirt_volume" "control_plane" {
  name           = "control_plane"
  base_volume_id = libvirt_volume.root_cloudinit.id
  size           = 5368709120
}

data "template_file" "user_data_control" {
  template = file("${path.module}/configs/control_plane/cloud_init.cfg")
}

data "template_file" "network_config_control" {
  template = file("${path.module}/configs/control_plane/network_config.cfg")
  vars = {
    ip_addr = var.control_node_ip
  }
}

resource "libvirt_cloudinit_disk" "control_init" {
  name           = "commoninit.iso"
  user_data      = data.template_file.user_data_control.rendered
  network_config = data.template_file.network_config_control.rendered
  pool           = libvirt_pool.k8s.name
}

# Create the machine
resource "libvirt_domain" "domain-control" {
  name   = "k8s-control-plane"
  memory = "2048"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.control_init.id

  network_interface {
    macvtap = "bond0"
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.control_plane.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
