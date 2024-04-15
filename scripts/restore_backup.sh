#!/bin/bash
# Pass parameter of backup name with path

source /etc/oci_facts

echo "Restoring from backup, please wait..."
systemctl stop ${service_name}
sleep 10
oci os object get --namespace ${bucket_namespace} --bucket-name ${bucket_name} --name $1 --file ${server_folder}/$1
rm -rf ${server_folder}/world
unzip -q ${server_folder}/$1 -d ${server_folder}
chown -R minecraft:minecraft ${server_folder}/world
rm -rf ${server_folder}/$1
systemctl restart ${service_name}
echo "Restored from backup, $1. Server will restart momentarily."
