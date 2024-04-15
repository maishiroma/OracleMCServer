#!/bin/bash

source /etc/oci_facts

backup_name="backup_$(date "+%Y%m%d-%H%M%S").zip"

echo "Backup is in progress, please wait..."
systemctl stop ${service_name}
sleep 10
(cd ${server_folder} && zip -qr ${server_folder}/${backup_name} ./world)
oci os object put --namespace ${bucket_namespace} --bucket-name ${bucket_name} --file ${server_folder}/${backup_name} --no-multipart
rm -f ${server_folder}/${backup_name}
systemctl start ${service_name}
echo "Backup, ${backup_name}, saved to bucket, ${bucket_name}. Server will restart momentarily."
