locals {
  hv1_workers = {
    k8s-worker-1 = { ip = "10.0.0.21", memory = "3636" }
    k8s-worker-2 = { ip = "10.0.0.22", memory = "3636" }
  }
  hv2_workers = {
    k8s-worker-3 = { ip = "10.0.0.23", memory = "7372" }
    k8s-worker-4 = { ip = "10.0.0.24", memory = "7372" }
  }
  total_worker_count = 4
}