#!/bin/bash

source /etc/oci_facts

home_folder="/home/minecraft"
server_folder="${home_folder}/server"
mod_folder="${server_folder}/mods"
service_name="minecraft"
jar_name="$(basename ${minecraft_server_jar_download_url})"

if [ ! -d "${server_folder}" ]; then
    echo "Performing initial bootstrap"

    useradd -r -m -U -d ${home_folder} -s /bin/bash minecraft
    mkdir ${server_folder}
    chown -R minecraft:minecraft ${server_folder}
    cd ${server_folder}

    yum install -y jdk-18.x86_64 zip unzip
    dnf -y install oraclelinux-developer-release-el8
    dnf -y install python36-oci-cli

    curl https://rclone.org/install.sh | bash

    echo "Creating backup script"
    cat << EOF > /etc/backup.sh
#!/bin/bash
backup_name="backup_\$(date "+%Y%m%d-%H%M%S").zip"

echo "Backup is in progress, please wait..."
systemctl stop ${service_name}
sleep 10
zip -qr ${server_folder}/\${backup_name} ${server_folder}/world
oci os object put --namespace ${bucket_namespace} --bucket-name ${bucket_name} --file ${server_folder}/\${backup_name} --no-multipart --auth instance_principal
rm -f ${server_folder}/\${backup_name}
systemctl start ${service_name}
echo "Backup done and saved to bucket, ${bucket_name}. Server will restart momentarily."
EOF
    chmod +x /etc/backup.sh

    echo "Creating restore from backup script"
    cat << EOF > /etc/restore_backup.sh
#!/bin/bash
# Pass parameter of backup name with path

echo "Restoring from backup, please wait..."
systemctl stop ${service_name}
sleep 10
oci os object get --namespace ${bucket_namespace} --bucket-name ${bucket_name} --name \$1 --file ${server_folder}/\$1 --auth instance_principal
rm -rf ${server_folder}/world
unzip -q ${server_folder}/\$1 -d ${server_folder}
systemctl restart ${service_name}
echo "Restored from backup, \$1. Server will restart momentarily."
EOF
    chmod +x /etc/restore_backup.sh
    
    if [ "${server_type}" != "vanilla" ]; 
        echo "Creating mod sync script"
        cat << EOF > /etc/mod_refresh.sh
#!/bin/bash

echo "Syncing mods from bucket..."
systemctl stop ${service_name}
sleep 10
rclone sync oos:${bucket_name}/mods ${mod_folder} --create-empty-src-dirs
systemctl start ${service_name}
echo "Syncing complete! Server will be restarted momentarily."
EOF
        chmod +x /etc/mod_refresh.sh

        echo "Creating rclone config"
        mkdir -p ~/.config/rclone
        cat << EOF > ~/.config/rclone/rclone.conf
[oos]
type = oracleobjectstorage
namespace = ${bucket_namespace}
env_auth = false
compartment = ${compartment_id}
region = ${region_name}
endpoint = https://${bucket_namespace}.compat.objectstorage.${region_name}.oraclecloud.com
provider = instance_principal_auth
EOF
    fi

    curl -s -O "${minecraft_server_jar_download_url}"
    echo "Creating systemd service for minecraft"
    cat << EOF > /etc/systemd/system/minecraft.service
[Unit]
Description=Minecraft Server
After=local-fs.target network.target
[Service]
User=minecraft
Nice=5
KillMode=process
KillSignal=SIGINT
SuccessExitStatus=130
WorkingDirectory=${server_folder}
ExecStart=/usr/bin/java -Xms${min_memory} -Xmx${max_memory} -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -jar ${jar_name} nogui
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl start ${service_name}
    echo "Waiting for eula to show up in server directory"
    while [ ! -f "${server_folder}/eula.txt" ]; do
        sleep 5
    done
    sed -i 's/eula=false/eula=true/g' ${server_folder}/eula.txt

    echo "Configuring Firewall"
    firewall-offline-cmd --zone=public --add-port=25565/tcp
    firewall-offline-cmd --zone=public --add-port=25565/udp

    echo "Need to run firewall-cmd --reload manually!" 
else
    echo "Initial bootstrap already happened."
fi
systemctl restart ${service_name}