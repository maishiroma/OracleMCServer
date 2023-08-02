#!/bin/bash

source /etc/oci_facts

if [ ${is_modded} ]; then
    echo "Syncing mods from bucket..."
    systemctl stop ${service_name}
    sleep 10
    rclone sync oos:${bucket_name}/mods ${mod_folder} --create-empty-src-dirs
    systemctl start ${service_name}
    echo "Syncing complete! Server will be restarted momentarily."
else
    echo "Server is not a modded server!"
fi
