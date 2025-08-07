locals {
  hv1_workers = {
    k8s-worker-1 = { ip = "10.0.0.21", ip6 = "2a06:61c2:27ae::1:0007", memory = "12288" }
    k8s-worker-2 = { ip = "10.0.0.22", ip6 = "2a06:61c2:27ae::1:0008", memory = "12288" }
  }
  hv2_workers = {
    k8s-worker-3 = { ip = "10.0.0.23", ip6 = "2a06:61c2:27ae::1:0009", memory = "7168" }
    k8s-worker-4 = { ip = "10.0.0.24", ip6 = "2a06:61c2:27ae::1:000A", memory = "7168" }
  }
  total_worker_count = 4
}