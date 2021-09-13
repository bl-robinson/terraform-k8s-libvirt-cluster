resource "libvirt_pool" "debian" {
  name = "debian"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-debian"
}

# We fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "debian-qcow2" {
  name   = "ubuntu-qcow2"
  pool   = libvirt_pool.debian.name
  source = "http://cloud.debian.org/images/cloud/bullseye/20210814-734/debian-11-generic-amd64-20210814-734.qcow2"
  format = "qcow2"
}

data "template_file" "user_data" {
  template = file("${path.module}/configs/cloud_init.cfg")
}

data "template_file" "network_config" {
  template = file("${path.module}/configs/network_config.cfg")
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.debian.name
}

# Create the machine
resource "libvirt_domain" "domain-debian" {
  name   = "debian-terraform"
  memory = "512"
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name = "default"
  }

  network_interface {
    macvtap = "bond0"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.debian-qcow2.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
