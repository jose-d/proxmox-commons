#!/bin/bash

first_dev=$(ibstat --list_of_cas | head -n 1)

node_guid=$(ibstat ${first_dev} | grep "Node GUID" | cut -d ':' -f 2 | xargs | cut -d 'x' -f 2)
port_guid=$(ibstat ${first_dev} | grep "Port GUID" | cut -d ':' -f 2 | xargs | cut -d 'x' -f 2)

base_addr=""

if ip link show ibp96s0 &> /dev/null ; then
  for vf in {0..3}; do
    ip link set dev ${first_dev} vf $vf port_guid $(echo "${port_guid::-5}cafe$((vf+1))" | sed 's/..\B/&:/g')
    ip link set dev ${first_dev} vf $vf node_guid $(echo "${port_guid::-5}cafe$((vf+1))" | sed 's/..\B/&:/g')
    ip link set dev ${first_dev} vf $vf state auto
  done
fi
