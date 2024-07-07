terraform {
  required_providers {
    libvirt = {
      source                = "dmacvicar/libvirt"
      configuration_aliases = [libvirt.hv2]
    }
  }
}

provider "libvirt" {
  uri = "qemu+ssh://benr@${var.hypervisor_ip}/system?sshauth=privkey&keyfile=${var.ssh_keyfile_path}"
}

provider "libvirt" {
  alias = "hv2"
  uri   = "qemu+ssh://benr@${var.hypervisor2_ip}/system?sshauth=privkey&keyfile=${var.ssh_keyfile_path}"
}

resource "libvirt_pool" "k8s_hv1" {
  name = "k8s"
  type = "dir"
  path = "/var/lib/k8s-pool"
}

resource "libvirt_pool" "k8s_hv2" {
  provider = libvirt.hv2
  name     = "k8s"
  type     = "dir"
  path     = "/var/lib/k8s-pool"
}

resource "libvirt_volume" "root_cloudinit_hv1" {
  name   = "debian-qcow2"
  source = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
}

resource "libvirt_volume" "root_cloudinit_hv2" {
  provider = libvirt.hv2
  name     = "debian-qcow2"
  source   = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
}