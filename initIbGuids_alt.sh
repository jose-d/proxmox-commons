#!/bin/bash

num=4

curr_num=$(cat /sys/class/infiniband/mlx5_0/device/mlx5_num_vfs)

# if we'd do this twice, kernel will cry "kobject_add_internal failed for 0 with -EEXIST"..
if [[ "${curr_num}" != "${num}" ]]; then
  echo ${num} > /sys/class/infiniband/mlx5_0/device/mlx5_num_vfs
fi

for vdev in $(seq 0 $((num-1))); do
  echo Follow > /sys/class/infiniband/mlx5_0/device/sriov/${vdev}/policy
done

node_uuid_random_part=$(hexdump -n 14 -e '4/4 "%08X" 1 "\n"' /dev/urandom | tail -c 14)


OLDIFS=$IFS

array=()
for (( CNTR=0; CNTR<${#node_uuid_random_part}; CNTR+=2 )); do
  array+=( ${node_uuid_random_part:CNTR:2} )
done
IFS=':'
node_uuid_random_part_formatted="${array[*]}"

IFS=$OLDIFS

node_prefix="11:$node_uuid_random_part_formatted"

node_prefix=$(echo "$node_prefix" | xargs)

for vdev in $(seq $((num))); do
  second_devN=$((vdev*2))
  first_devN=$((second_devN-1))

  first_devID=${node_prefix}${first_devN}
  second_devID=${node_prefix}${second_devN}

  device_number=$((vdev-1))

  echo ${first_devID} > /sys/class/infiniband/mlx5_0/device/sriov/${device_number}/node
  echo ${second_devID} > /sys/class/infiniband/mlx5_0/device/sriov/${device_number}/port

done

#rebind all virtual devices to apply guid:

devices=$(lspci | grep Mellanox | grep Virtual | awk '{print $1}' | xargs)

for device in $devices; do

  # in centos77 there are no leading zeros needed by mellanox driver by default
  if [[ $device != 0000* ]]; then
    device="0000:${device}"
  fi

  echo "${device}" > /sys/bus/pci/drivers/mlx5_core/unbind
  echo "${device}" > /sys/bus/pci/drivers/mlx5_core/bind
done
