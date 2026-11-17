#!/bin/bash

PATH=$PATH:$(pwd)

source hostlist.sh

# Define the VM names array
vms=($(echo "$hostlist" | awk '{print $2}'))

### Define the default directory gen
CURRENT_DIR=$(pwd)
GENERATED_CONFIG_DIR=$CURRENT_DIR/generated-config

for vm in ${vms[*]}; do
    echo "Reset talos machineconfig for VM $vm"
    rm -f $GENERATED_CONFIG_DIR/machineconfig-$vm.yaml
done

if [[ $1 == "--destroy" ]]; then rm -rf $GENERATED_CONFIG_DIR; fi
