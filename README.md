# Talos Linux Provisioning GPM Style
An experiment to provisioning Talos Linux Kubernetes Cluster using Libvirt and Dynamic IP helper.

## Prerequisites
- An Installed Linux System with KVM capabilities
- Then download the correspoding talos linux image from https://factory.talos.dev/ and store in in the ./images folder (recommended using qcow2)
- Installed "talosctl" CLI. Read Documentation [here](https://docs.siderolabs.com/talos/v1.14/getting-started/talosctl)
```shell
curl -sL https://talos.dev/install | sh
```
- Allocatable IP Addresses for each vms
- FAST Internet connection for downloading required binaries

## Environments
3 Control Plane Nodes and 2 Worker Nodes installed with latest Talos Linux. It also has the Floating IP for kubernetes api server reachability and enabling High-Availability, Edit the subnet, ip and hostnames in file [hostlist.sh](./hostlist.sh).

```
floatingip 192.168.104.99

gpmcontrolplane1 192.168.104.101
gpmcontrolplane2 192.168.104.102
gpmcontrolplane3 192.168.104.103
gpmworker1 192.168.104.104
gpmworker2 192.168.104.105
```


## Pre-provisioning

1. Ensure that the latest image is downloaded and inside into the Linux Hypervisor.

2. Generate talos config scripts and other resources with this command:

```shell
bash generate-talos-config.sh 
```

3. When needed, you can delete all talos config scripts and other resources with this command:

```shell
bash reset-talos-config.sh --destroy
```


## Provisioning

Provision the VMs with this command:

```shell
bash start-vm.sh --provision
```

When the VMs are provisioned, They are expected to use Dynamic IPs. Then we will continue to provision the cluster using our allocated Static IPs and Hostname.

```shell
bash provision-talos-cluster.sh
```

## Power Off VMs

When needed, you can stop the VM with this command:

```shell
bash stop-vm.sh
```

and starting it once again with this command:

```shell
bash start-vm.sh
```

## Cleanup

If you need to stop the VMs and deleting all provisioned VMs, use this command

```shell
bash stop-vm.sh --destroy
```