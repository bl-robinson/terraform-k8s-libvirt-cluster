Relys on a few things.

- Hardcoded ip addrs
  - 10.0.0.20 controller
  - 10.0.0.2X (number of the worker instance) for each worker node
- A NFS fileserver with a /mnt/k8s mount avaliable to mount at 10.0.0.14
- ssh access to the kvm host with a key as specified in main.tf

Terraform apply will just start the instances then the startup cloudinit handles the order of setup to get k8s working


Note kubeconfig files are avaliable in the 10.0.0.14:/mnt/k8s mount.

