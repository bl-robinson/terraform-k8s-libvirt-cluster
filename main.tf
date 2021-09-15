terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu+ssh://root@10.0.0.4/system?keyfile=/home/benr/.ssh/kvm"
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
