#!/bin/bash

source /etc/oci_facts

if [ ${is_modded} ]; then
    echo "Syncing mods from bucket..."
    systemctl stop ${service_name}
    sleep 10
    rm -rf ${mod_folder}
    mkdir ${mod_folder}
    oci os object list --bucket-name ${bucket_name} --prefix "mods/" | jq -r '.data' > "${server_folder}/mods.json"
    count=$(cat ${server_folder}/mods.json | jq '. | length')
    for ((i=0; i<$count; i++)); do
        obj_name=`jq -r '.['$i'].name' ${server_folder}/mods.json`
        obj_size=`jq -r '.['$i'].size' ${server_folder}/mods.json`
        if [ $obj_size -gt 0 ]; then 
            raw_obj_name=$(basename ${obj_name})
            oci os object get --bucket-name ${bucket_name} --name ${obj_name} --file "${mod_folder}/${raw_obj_name}"
        fi
    done
    rm "${server_folder}/mods.json" -f
    systemctl start ${service_name}
    echo "Syncing complete! Server will be restarted momentarily."
else
    echo "Server is not a modded server!"
fi
