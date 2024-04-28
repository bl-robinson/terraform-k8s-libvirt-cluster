terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu+ssh://root@${var.hypervisor_ip}/system?keyfile=${var.ssh_keyfile_path}"
}

resource "libvirt_pool" "k8s" {
  name = "k8s"
  type = "dir"
  path = "/tmp/k8s-pool"
}

resource "libvirt_volume" "root_cloudinit" {
  name   = "debian-qcow2"
  source = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
}
