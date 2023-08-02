#!/bin/bash

source /etc/oci_facts

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

    echo "## Download Server Jar ##"
    curl -s -O "${minecraft_server_jar_download_url}"
    
    if [ ${is_modded} ]; then
        mkdir -p ~/.config/rclone
        mv -f /etc/rclone.conf ~/.config/rclone/rclone.conf

        echo "## Installing Modded Server ##"
        /usr/bin/java -jar ${jar_name} --installServer
    fi

    echo "## Creating systemd service for minecraft ##"
    mv -f /etc/minecraft.service /etc/systemd/system/minecraft.service
    
    systemctl daemon-reload
    systemctl start ${service_name}
    echo "## Waiting for eula to show up in server directory ##"
    while [ ! -f "${server_folder}/eula.txt" ]; do
        sleep 5
    done
    sed -i 's/eula=false/eula=true/g' ${server_folder}/eula.txt

    if [ ${is_modded} ]; then
        echo "## Creating JVM arguments for modded server ##"
        mv -f /etc/user_jvm_args.txt "${server_folder}/user_jvm_args.txt"
        
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
if [ -f /etc/server.properites ]; then
    mv -f /etc/server.properites "${server_folder}/server.properties" -f
fi
if [ -f /etc/ops.json ]; then
    mv -f /etc/ops.json "${server_folder}/ops.json" -f
fi

echo "## Starting up Server ##"
systemctl restart ${service_name}

echo "## Bootstrap Complete! ##"
