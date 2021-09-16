variable "worker_count" {
  type = number
}

variable "control_node_ip" {
  type = string
}

variable "worker_node_ip_start" {
  type = string
}

variable "worker_node_subnet_range" {
  type = string
}

variable "nfs_server_ip" {
  type = string
}

variable "hypervisor_ip" {
  type = string
}

variable "ssh_keyfile_path" {
  type = string
}