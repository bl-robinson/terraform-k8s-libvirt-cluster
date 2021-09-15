resource "libvirt_volume" "worker" {
  name           = "worker"
  base_volume_id = libvirt_volume.root_cloudinit.id
  size           = 5368709120
}

data "template_file" "user_data_worker" {
  template = file("${path.module}/configs/workers/cloud_init.cfg")
}

data "template_file" "network_config_worker" {
  template = file("${path.module}/configs/workers/network_config.cfg")
}

resource "libvirt_cloudinit_disk" "commoninit-worker" {
  name           = "commoninit-workers.iso"
  user_data      = data.template_file.user_data_worker.rendered
  network_config = data.template_file.network_config_worker.rendered
  pool           = libvirt_pool.k8s.name
}

# Create the machine
resource "libvirt_domain" "domain-debian-worker" {
  name   = "k8s-worker"
  memory = "2048"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.commoninit-worker.id

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
    volume_id = libvirt_volume.worker.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
