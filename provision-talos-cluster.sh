#!/bin/bash

PATH=$PATH:$(pwd)

source hostlist.sh

CURRENT_DIR=$(pwd)

GENERATED_CONFIG_DIR=$CURRENT_DIR/generated-config

### Define the first controlplane IP to init the talos kubernetes cluster
IP_RANGE_CONTROLPLANE1="$(echo $IP_SUBNET | cut -d. -f1-3).101"

### Setup talosconfig access
export TALOSCONFIG=$(realpath ${GENERATED_CONFIG_DIR}/talosconfig)
talosctl config endpoint $IP_RANGE_CONTROLPLANE1
talosctl config node $IP_RANGE_CONTROLPLANE1

# Define the VM names array
vms=($(echo "$hostlist" | awk '{print $2}'))

### It is assumed that all VMs are booted with Dynamic IPs.
### Then we will get the current Dynamic IPs to reconfig the IP and provision the cluster.
for vm in ${vms[*]}; do
  APPLIED_IP_ADDR="$(echo "$hostlist" | grep $vm | awk '{print $1}')"
  export NODE_IP=$(virsh domifaddr --source arp $vm | egrep '/' | awk '{print $4}' | cut -d/ -f1)
  echo "Found current IP Address of $vm: $NODE_IP"
  talosctl get address --nodes $NODE_IP --insecure

  # Set node role to controlplane/worker
  K8S_SERVER_STRING="controlplane"
  K8S_MODE="controlplane"

  if [[ "$vm" == *"$K8S_SERVER_STRING"*  ]]; then
  echo "Applying Talos Config for $vm as kubernetes $K8S_MODE node"
  else
  K8S_MODE="worker"
  echo "Applying Talos Config for $vm as kubernetes $K8S_MODE node"
  fi

  if [[ "$K8S_MODE" == "controlplane"  ]]; then
    talosctl apply-config --insecure --nodes $NODE_IP \
      --file $GENERATED_CONFIG_DIR/controlplane.yaml \
      --config-patch @${GENERATED_CONFIG_DIR}/machineconfig-$vm.yaml

    ### Add delay 30s for applying current talos config
    echo "Wait until address applied (30s)..."
    sleep 30s
    if [[ "$APPLIED_IP_ADDR" == "$IP_RANGE_CONTROLPLANE1" ]]; then 
      echo "Bootstrapping the first controlplane node..."
      talosctl bootstrap -n $APPLIED_IP_ADDR -e $APPLIED_IP_ADDR --talosconfig="${GENERATED_CONFIG_DIR}/talosconfig"
      
      ### Setup and kubeconfig
      talosctl -n $APPLIED_IP_ADDR -e $APPLIED_IP_ADDR kubeconfig ${GENERATED_CONFIG_DIR}/kubeconfig
      export KUBECONFIG=${GENERATED_CONFIG_DIR}/kubeconfig

      echo "Sleeping for 3m to ensure bootstrapping complete..."
      sleep 3m
    fi
  else
    talosctl apply-config --insecure --nodes $NODE_IP \
      --file $GENERATED_CONFIG_DIR/worker.yaml \
      --config-patch @${GENERATED_CONFIG_DIR}/machineconfig-$vm.yaml
    echo "Wait until address applied (30s)..."
    sleep 30s
  fi
done
