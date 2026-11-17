#!/bin/bash

PATH=$PATH:$(pwd)

source hostlist.sh

# Define the VM names array
vms=($(echo "$hostlist" | awk '{print $2}'))

### Define the first controlplane IP to init the kubeadm cluster
IP_RANGE_CONTROLPLANE1="$(echo $IP_SUBNET | cut -d. -f1-3).101"

### Define the default directory gen
CURRENT_DIR=$(pwd)

BASE_CONFIG_DIR=$CURRENT_DIR/base-config
GENERATED_CONFIG_DIR=$CURRENT_DIR/generated-config

mkdir -p $GENERATED_CONFIG_DIR $BASE_CONFIG_DIR

### POD and service CIDR
POD_CIDR=10.244.0.0/16
SERVICE_CIDR=10.96.0.0/12

### Default Interface Name
IFACE_NAME=enp1s0

### Generate host aliases
hostlist_parsed=""
while read -r ip aliases; do
  ip="${ip%%#*}"
  aliases="${aliases%%#*}"
  [[ -z "$ip" || -z "$aliases" ]] && continue

  hostlist_parsed+="      - ip: $ip"$'\n'
  hostlist_parsed+="        aliases:"$'\n'
  for alias in $aliases; do
    hostlist_parsed+="          - $alias"$'\n'
  done
done <<< "$hostlist"
hostlist_parsed="${hostlist_parsed%$'\n'}"

cat > "$GENERATED_CONFIG_DIR/hosts-config.yaml" <<-EOF
machine:
  network:
    extraHostEntries:
$hostlist_parsed
EOF

### Generate Pod CIDR and Service CIDR Settings
sed -e "s+###POD_CIDR###+$POD_CIDR+g" \
  -e "s+###SERVICE_CIDR###+$SERVICE_CIDR+g" \
  $BASE_CONFIG_DIR/pod-subnet.yaml > $GENERATED_CONFIG_DIR/pod-subnet.yaml

### Generate Virtual IP Settings
sed -e "s/###FLOATINGIP###/$IP_FLOATING/g" \
  -e "s+###INTERFACE###+$IFACE_NAME+g" \
  $BASE_CONFIG_DIR/vip-config.yaml > $GENERATED_CONFIG_DIR/vip-config.yaml

### Generate per-VMs Config with IP Addressing and Hostname
for vm in ${vms[*]}; do 
    IP_ADDR="$(echo "$hostlist" | grep $vm | awk '{print $1}')"
    CIDR="$(echo $IP_SUBNET | cut -d'/' -f2)"

    echo "Generating talos machineconfig for VM $vm with IP Address $IP_ADDR/$CIDR gateway $IP_GATEWAY"

    sed -e "s+###HOSTNAME###+$vm+g" \
        -e "s+###INTERFACE###+$IFACE_NAME+g" \
        -e "s+/###CIDR###+/$CIDR+g" \
        -e "s+###IP_ADDRESS###+$IP_ADDR+g" \
        -e "s+###IP_GATEWAY###+$IP_GATEWAY+g" \
        $BASE_CONFIG_DIR/common-config.yaml > $GENERATED_CONFIG_DIR/machineconfig-$vm.yaml
done

### Generate Talos Base Config
talosctl gen config gpmcluster https://${IP_FLOATING}:6443 \
    --output-dir ${GENERATED_CONFIG_DIR}/ \
    --config-patch-control-plane @${GENERATED_CONFIG_DIR}/vip-config.yaml \
    --config-patch @${BASE_CONFIG_DIR}/hostname-static.yaml \
    --config-patch @${GENERATED_CONFIG_DIR}/pod-subnet.yaml \
    --config-patch @${GENERATED_CONFIG_DIR}/hosts-config.yaml \
