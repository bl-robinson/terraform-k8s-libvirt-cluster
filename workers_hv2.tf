resource "libvirt_volume" "worker_hv2" {
  for_each       = local.hv2_workers
  provider       = libvirt.hv2
  pool           = libvirt_pool.k8s_hv2.name
  name           = each.key
  base_volume_id = libvirt_volume.root_cloudinit_hv2.id
  size           = 21474836480 # Size in Bytes (20G)
}

data "template_file" "user_data_worker_hv2" {
  for_each = local.hv2_workers
  template = file("${path.module}/configs/workers/cloud_init.cfg")
  vars = {
    name          = each.key
    worker_count  = local.total_worker_count
    nfs_server_ip = var.nfs_server_ip
  }
}

data "template_file" "network_config_worker_hv2" {
  for_each = local.hv2_workers
  template = file("${path.module}/configs/workers/network_config.cfg")
  vars = {
    ip     = each.value.ip
    subnet = var.node_subnet_range
  }
}

resource "libvirt_cloudinit_disk" "commoninit-worker_hv2" {
  for_each       = local.hv2_workers
  provider       = libvirt.hv2
  name           = "commoninit-worker-${each.key}.iso"
  user_data      = data.template_file.user_data_worker_hv2[each.key].rendered
  network_config = data.template_file.network_config_worker_hv2[each.key].rendered
  pool           = libvirt_pool.k8s_hv2.name
}

# Create the machine
resource "libvirt_domain" "domain-debian-worker_hv2" {
  for_each = local.hv2_workers
  provider = libvirt.hv2
  name     = each.key
  memory   = each.value.memory
  vcpu     = 2

  cloudinit = libvirt_cloudinit_disk.commoninit-worker_hv2[each.key].id

  network_interface {
    macvtap = "enx00e04c6806c5"
  }

  cpu {
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
    volume_id = libvirt_volume.worker_hv2[each.key].id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
  autostart = true
}
