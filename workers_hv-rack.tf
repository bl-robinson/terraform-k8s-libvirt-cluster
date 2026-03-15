variable "hypervisor_rack_ip" {
  type = string
}

provider "libvirt" {
  alias = "hv_rack"
  uri   = "qemu+ssh://benr@${var.hypervisor_rack_ip}/system?sshauth=privkey&keyfile=${var.ssh_keyfile_path}"
}

resource "libvirt_pool" "k8s_hv_rack" {
  provider = libvirt.hv_rack
  name     = "k8s"
  type     = "dir"
  path     = "/var/lib/k8s-pool"
}

resource "libvirt_volume" "root_cloudinit_hv_rack" {
  provider = libvirt.hv_rack
  name     = "debian-qcow2"
  pool     = libvirt_pool.k8s_hv_rack.name
  source   = local.debian_image_source
}

locals {
  hv_rack_workers = {
    k8s-worker-5 = { ip = "10.0.0.25", ip6 = "2a06:61c2:27ae::1:000D", memory = "16184" }
  }
}

resource "libvirt_volume" "worker_hv_rack" {
  for_each       = local.hv_rack_workers
  provider       = libvirt.hv_rack
  pool           = libvirt_pool.k8s_hv_rack.name
  name           = each.key
  base_volume_id = libvirt_volume.root_cloudinit_hv_rack.id
  size           = 483183820800 # Size in Bytes (450G)
}

data "template_file" "user_data_worker_hv_rack" {
  for_each = local.hv_rack_workers
  template = file("${path.module}/configs/workers/cloud_init.cfg")
  vars = {
    name          = each.key
    worker_count  = local.total_worker_count
    nfs_server_ip = var.nfs_server_ip
    ip_addr     = each.value.ip
    ip6_addr    = each.value.ip6
  }
}

data "template_file" "network_config_worker_hv_rack" {
  for_each = local.hv_rack_workers
  template = file("${path.module}/configs/workers/network_config.cfg")
  vars = {
    ip_addr     = each.value.ip
    node_subnet      = var.node_subnet_range
    ip6_addr    = each.value.ip6
  }
}

resource "libvirt_cloudinit_disk" "commoninit-worker_hv_rack" {
  for_each       = local.hv_rack_workers
  provider       = libvirt.hv_rack
  name           = "commoninit-worker-${each.key}.iso"
  user_data      = data.template_file.user_data_worker_hv_rack[each.key].rendered
  network_config = data.template_file.network_config_worker_hv_rack[each.key].rendered
  pool           = libvirt_pool.k8s_hv_rack.name
}

# Create the machine
resource "libvirt_domain" "domain-debian-worker_hv_rack" {
  for_each = local.hv_rack_workers
  provider = libvirt.hv_rack
  name     = each.key
  memory   = each.value.memory
  vcpu     = 8

  cloudinit = libvirt_cloudinit_disk.commoninit-worker_hv_rack[each.key].id

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
    volume_id = libvirt_volume.worker_hv_rack[each.key].id
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
    autoport    = true
  }
  autostart = true
}
