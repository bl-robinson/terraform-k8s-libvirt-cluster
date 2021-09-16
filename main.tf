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
  source = "http://cloud.debian.org/images/cloud/bullseye/20210814-734/debian-11-generic-amd64-20210814-734.qcow2"
}
