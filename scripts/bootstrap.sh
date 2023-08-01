#!/bin/bash

source /etc/oci_facts

home_folder="/home/minecraft"
server_folder="${home_folder}/server"
mod_folder="${server_folder}/mods"
service_name="minecraft"
jar_name="$(basename ${minecraft_server_jar_download_url})"

new_server_properties_path="/etc/server.properites"
new_ops_path="/etc/ops.json"

if [ ! -d "${server_folder}" ]; then
    echo "## Performing initial bootstrap ##"

    useradd -r -m -U -d ${home_folder} -s /bin/bash minecraft
    mkdir ${server_folder}
    chown -R minecraft:minecraft ${server_folder}
    cd ${server_folder}

    yum install -y java-17-openjdk zip unzip
    dnf -y install oraclelinux-developer-release-el8
    dnf -y install python36-oci-cli

    curl https://rclone.org/install.sh | bash

    echo "## Creating backup script ##"
    cat << EOF > /etc/backup.sh
#!/bin/bash
backup_name="backup_\$(date "+%Y%m%d-%H%M%S").zip"

echo "Backup is in progress, please wait..."
systemctl stop ${service_name}
sleep 10
(cd ${server_folder} && zip -qr ${server_folder}/\${backup_name} ./world)
oci os object put --namespace ${bucket_namespace} --bucket-name ${bucket_name} --file ${server_folder}/\${backup_name} --no-multipart --auth instance_principal
rm -f ${server_folder}/\${backup_name}
systemctl start ${service_name}
echo "Backup, ${backup_name}, saved to bucket, ${bucket_name}. Server will restart momentarily."
EOF
    chmod +x /etc/backup.sh

    echo "## Creating restore from backup script ##"
    cat << EOF > /etc/restore_backup.sh
#!/bin/bash
# Pass parameter of backup name with path

echo "Restoring from backup, please wait..."
systemctl stop ${service_name}
sleep 10
oci os object get --namespace ${bucket_namespace} --bucket-name ${bucket_name} --name \$1 --file ${server_folder}/\$1 --auth instance_principal
rm -rf ${server_folder}/world
unzip -q ${server_folder}/\$1 -d ${server_folder}
chown -R minecraft:minecraft ${server_folder}/world
rm -rf ${server_folder}/\$1
systemctl restart ${service_name}
echo "Restored from backup, \$1. Server will restart momentarily."
EOF
    chmod +x /etc/restore_backup.sh
    
    echo "## Download Server Jar ##"
    curl -s -O "${minecraft_server_jar_download_url}"
    run_command="/usr/bin/java -Xms${min_memory} -Xmx${max_memory} -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -jar ${jar_name} nogui"
    
    if [ ${is_modded} ]; then
        echo "## Creating mod sync script ##"
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

        echo "## Creating rclone config ##"
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
        
        echo "## Installing Modded Server ##"
        /usr/bin/java -jar ${jar_name} --installServer
        run_command="/bin/sh run.sh"
    fi

    echo "## Creating systemd service for minecraft ##"
    cat << EOF > /etc/systemd/system/minecraft.service
[Unit]
Description=Minecraft Server
After=local-fs.target network.target
[Service]
User=minecraft
Nice=5
TimeoutStopSec=120
KillSignal=SIGINT
SuccessExitStatus=0 1 130
WorkingDirectory=${server_folder}
ExecStart=${run_command}
[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl start ${service_name}
    echo "## Waiting for eula to show up in server directory ##"
    while [ ! -f "${server_folder}/eula.txt" ]; do
        sleep 5
    done
    sed -i 's/eula=false/eula=true/g' ${server_folder}/eula.txt

    if [ ${is_modded} ]; then
        echo "## Creating JVM arguments for modded server ##"
        cat << EOF > "${server_folder}/user_jvm_args.txt"
-Xms${min_memory} 
-Xmx${max_memory} 
-XX:+UseG1GC 
-XX:+UnlockExperimentalVMOptions 
-XX:+DisableExplicitGC 
-XX:+ParallelRefProcEnabled
EOF
        echo "## Initial sync of mods ##"
        rclone sync oos:${bucket_name}/mods ${mod_folder} --create-empty-src-dirs
    fi

    echo "## Configuring Firewall ##"
    firewall-offline-cmd --zone=public --add-port=25565/tcp
    firewall-offline-cmd --zone=public --add-port=25565/udp
    echo "NOTE: Need to run firewall-cmd --reload manually!" 
else
    echo "## Initial bootstrap already happened! ##"
fi

echo "## Move Server and OPs files to proper location ##"
if [ -f $new_server_properties_path ]; then
    mv $new_server_properties_path "${server_folder}/server.properties" -f
fi
if [ -f $new_ops_path ]; then
    mv $new_ops_path "${server_folder}/ops.json" -f
fi

echo "## Starting up Server ##"
systemctl restart ${service_name}

echo "## Bootstrap Complete! ##"