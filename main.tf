terraform {
  required_providers {
    libvirt = {
      source                = "dmacvicar/libvirt"
      configuration_aliases = [libvirt.hv2] #, libvirt.hv_rack]
    }
  }
}

provider "libvirt" {
  uri = "qemu+ssh://benr@${var.hypervisor_ip}/system?sshauth=privkey&keyfile=${var.ssh_keyfile_path}"
}

locals {
  debian_image_source = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
  total_worker_count  = 4
}

# hv1 pool and base volume live here because the control plane also depends on them
resource "libvirt_pool" "k8s_hv1" {
  name = "k8s"
  type = "dir"
  path = "/var/lib/k8s-pool"
}

resource "libvirt_volume" "root_cloudinit_hv1" {
  name   = "debian-qcow2"
  source = local.debian_image_source
}
