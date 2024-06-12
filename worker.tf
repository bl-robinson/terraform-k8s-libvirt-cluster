resource "libvirt_volume" "worker" {
  count          = var.worker_count
  name           = "worker-${count.index}"
  base_volume_id = libvirt_volume.root_cloudinit.id
  size           = 21474836480 # Size in Bytes (20G)
}

data "template_file" "user_data_worker" {
  count    = var.worker_count
  template = file("${path.module}/configs/workers/cloud_init.cfg")
  vars = {
    count         = count.index + 1
    worker_count  = var.worker_count
    nfs_server_ip = var.nfs_server_ip
  }
}

data "template_file" "network_config_worker" {
  count    = var.worker_count
  template = file("${path.module}/configs/workers/network_config.cfg")
  vars = {
    count     = count.index + 1
    ip_prefix = var.worker_node_ip_start
    subnet    = var.worker_node_subnet_range
  }
}

resource "libvirt_cloudinit_disk" "commoninit-worker" {
  count          = var.worker_count
  name           = "commoninit-worker-${count.index}.iso"
  user_data      = data.template_file.user_data_worker[count.index].rendered
  network_config = data.template_file.network_config_worker[count.index].rendered
  pool           = libvirt_pool.k8s.name
}

# Create the machine
resource "libvirt_domain" "domain-debian-worker" {
  count  = var.worker_count
  name   = "k8s-worker-${count.index + 1}"
  memory = "4096"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.commoninit-worker[count.index].id

  network_interface {
    macvtap = "enp4s0"
  }

  cpu = {
    mode = "host-passthrough"
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
    volume_id = libvirt_volume.worker[count.index].id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
  autostart = true
}
