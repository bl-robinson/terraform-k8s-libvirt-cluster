locals {
  hv1_workers = {
    k8s-worker-1 = { ip = "10.0.0.21", memory = "4096" }
    k8s-worker-2 = { ip = "10.0.0.22", memory = "4096" }
  }
  hv2_workers = {
    k8s-worker-3 = { ip = "10.0.0.23", memory = "7168" }
    k8s-worker-4 = { ip = "10.0.0.24", memory = "7168" }
  }
  total_worker_count = 4
}