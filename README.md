Relys on a few things.

- Hardcoded ip addrs
  - 10.0.0.20 controller
  - 10.0.0.2X (number of the worker instance) for each worker node
- A NFS fileserver with a /mnt/k8s mount avaliable to mount at 10.0.0.14
- ssh access to the kvm host with a key as specified in main.tf

Terraform apply will just start the instances then the startup cloudinit handles the order of setup to get k8s working

Note kubeconfig files are avaliable in the 10.0.0.14:/mnt/k8s mount.

# BGP and MetalLB

MetalLB runs in BGP mode, peering with the UniFi Cloud Gateway (UCG) at 10.0.0.1. The gateway runs FRR and the config is stored in `unifi-config/bgp.conf`.

- Gateway ASN: 65000
- Cluster ASN: 65001
- Each k8s node runs a MetalLB speaker that peers with the gateway

## Adding a new worker node

When adding a new worker node to the cluster, you **must** also add it as a BGP neighbor on the gateway. Otherwise any LoadBalancer services with `externalTrafficPolicy: Local` running on that node will be unreachable ("no route to host").

1. Update `unifi-config/bgp.conf` — add the new node's IP (10.0.0.2X) in three places:
   - As a neighbor under `router bgp 65000` (with remote-as, description, route-map)
   - Activated under `address-family ipv4 unicast`
   - Activated under `address-family ipv6 unicast` (with route-map)
2. Upload the config to the UCG:
   - UniFi Network UI > Settings > Routing > BGP, paste the config
   - This will briefly reset all BGP sessions while the config is applied
3. Verify from the gateway: `ssh root@10.0.0.1` then `vtysh -c "show bgp summary"` — all neighbors should show as Established

## SSH to the UCG

SSH credentials for the gateway are set separately from the Device SSH Authentication settings:
- Username: `root`
- Password: set via the UniFi OS console at `https://10.0.0.1` (not the Network app's Device SSH settings)

## Debugging BGP issues

If a LoadBalancer service is unreachable ("no route to host" or "connection refused"):

1. Check which node the target pod is running on:
   ```
   kubectl get pods -n <namespace> -o wide
   ```

2. Check if the MetalLB speaker on that node has an established BGP session:
   ```
   kubectl exec -n metallb-system <speaker-pod> -c frr -- vtysh -c "show bgp summary"
   ```
   Look for `Established` state and non-zero `PfxSnt`. If the state is `Active` with `Up/Down: never`, the gateway is rejecting the connection — the node is likely missing from the gateway's BGP config.

3. Check what routes the speaker is advertising:
   ```
   kubectl exec -n metallb-system <speaker-pod> -c frr -- vtysh -c "show ip bgp neighbors 10.0.0.1 advertised-routes"
   ```

4. Check the speaker logs for errors:
   ```
   kubectl logs -n metallb-system <speaker-pod> -c frr --tail=50
   ```
   Repeated `bgp_read_packet error: Connection reset by peer` means the gateway is refusing the connection.

5. Verify from the gateway side:
   ```
   ssh root@10.0.0.1
   vtysh -c "show bgp summary"
   ```

## Note on externalTrafficPolicy

Services with `externalTrafficPolicy: Local` will **only** be advertised from the node running the pod. If that node's BGP session is down, the service is completely unreachable. Services with `externalTrafficPolicy: Cluster` are advertised from all nodes but lose source IP preservation.

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