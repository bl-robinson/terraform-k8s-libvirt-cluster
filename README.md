Relys on a few things.

- Hardcoded ip addrs
  - 10.0.0.20 controller
  - 10.0.0.2X (number of the worker instance) for each worker node
- A NFS fileserver with a /mnt/k8s mount avaliable to mount at 10.0.0.14
- ssh access to the kvm host with a key as specified in main.tf

Terraform apply will just start the instances then the startup cloudinit handles the order of setup to get k8s working


Note kubeconfig files are avaliable in the 10.0.0.14:/mnt/k8s mount.

# Notes RE IPv4 on the home network

10.0.0.0/23 -> Main "default" network range
            DCHP is 10.0.1.1 -> 10.0.1.255
            Statically allocated all below that.

10.0.255.1/24 -> 'Work' Network isolated all DHCP


# Notes RE IPv6 on the home network

My Range ->2a06:61c2:27ae/48

Main network Range 2a06:61c2:27ae:: /64
  Assigned DCHP -> 2001:db8::/112
  Assigned Static Allocations -> 2001:db8::1:0/112
  Assigned Pod Network -> 2001:db8::2:0/112
  Assigned Service Network -> 2001:db8::3:0/112

SLAAC is permitted in this range in order to allow for Android devices connected to the main network.
  - But practically changes of collisions are low and we can rely on IPv6 to detect and SLAAC to handle. (I think)

Work network Range 2a06:61c2:27ae:1:: /64
  Assigned via SLAAC