resource "libvirt_volume" "worker" {
  for_each       = local.hv1_workers
  name           = each.key
  base_volume_id = libvirt_volume.root_cloudinit_hv1.id
  size           = 21474836480 # Size in Bytes (20G)
  pool           = libvirt_pool.k8s_hv1.name
}

data "template_file" "user_data_worker" {
  for_each = local.hv1_workers
  template = file("${path.module}/configs/workers/cloud_init.cfg")
  vars = {
    name          = each.key
    worker_count  = local.total_worker_count
    nfs_server_ip = var.nfs_server_ip
  }
}

data "template_file" "network_config_worker" {
  for_each = local.hv1_workers
  template = file("${path.module}/configs/workers/network_config.cfg")
  vars = {
    ip_addr     = each.value.ip
    node_subnet      = var.node_subnet_range
    ip6_addr    = each.value.ip6
  }
}

resource "libvirt_cloudinit_disk" "commoninit-worker" {
  for_each       = local.hv1_workers
  name           = "commoninit-worker-${each.key}.iso"
  user_data      = data.template_file.user_data_worker[each.key].rendered
  network_config = data.template_file.network_config_worker[each.key].rendered
  pool           = libvirt_pool.k8s_hv1.name
}

# Create the machine
resource "libvirt_domain" "domain-debian-worker" {
  for_each = local.hv1_workers
  name     = each.key
  memory   = each.value.memory
  vcpu     = 7

  cloudinit = libvirt_cloudinit_disk.commoninit-worker[each.key].id

  network_interface {
    macvtap = "enp2s0"
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
    volume_id = libvirt_volume.worker[each.key].id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
  autostart = true
}
