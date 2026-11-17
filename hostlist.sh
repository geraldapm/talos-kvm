#!/bin/bash

### Define IP Subnet for CIDR assignment including floating IP and gateway IP

IP_SUBNET=192.168.104.0/24

### Set IP Subnet Gateway
IP_GATEWAY="$(echo $IP_SUBNET | cut -d. -f1-3).1"

### Define the Virtual IP or Floating IP
IP_FLOATING="$(echo $IP_SUBNET | cut -d. -f1-3).99"

### Define cluster member list
### Ensure that the hostname has "controlplane" and "worker" inside for node role filtering
hostlist=$(cat <<EOF
192.168.104.101    gpmtaloscontrolplane1
192.168.104.102    gpmtaloscontrolplane2
192.168.104.103    gpmtaloscontrolplane3
192.168.104.104    gpmtalosworker1    
192.168.104.105    gpmtalosworker2
EOF
)