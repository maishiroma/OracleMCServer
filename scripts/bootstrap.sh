#!/bin/bash

home_folder="/home/minecraft"
server_folder="${home_folder}/server"
service_name="minecraft"
min_memory="1G"
max_memory="5G"
bucket_namespace="axngd0vpjssw"
bucket_name="mc-server-1n9kf-backups"

useradd -r -m -U -d ${home_folder} -s /bin/bash minecraft
mkdir ${server_folder}
chown -R minecraft:minecraft ${server_folder}
cd ${server_folder}

yum install -y jdk-18.x86_64 zip
dnf -y install oraclelinux-developer-release-el8
dnf -y install python36-oci-cli

cat << EOF > /etc/backup.sh
#!/bin/bash

systemctl stop ${service_name}
zip -qr ${server_folder}/backup.zip ${server_folder}/world
oci os object put --namespace ${bucket_namespace} --bucket-name ${bucket_name} --file ${server_folder}/backup.zip --no-multipart --auth instance_principal
rm -f ${server_folder}/backup.zip
echo "Backup done and saved to bucket"
EOF
chmod +x /etc/backup.sh

curl -s -O "https://piston-data.mojang.com/v1/objects/8f3112a1049751cc472ec13e397eade5336ca7ae/server.jar"

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
ExecStart=/usr/bin/java -Xms${min_memory} -Xmx${max_memory} -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -jar server.jar nogui
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload

firewall-cmd --permanent --zone=public --add-port=25565/tcp
firewall-cmd --permanent --zone=public --add-port=25565/udp
firewall-cmd --reload

systemctl start ${service_name}
while [ ! -f "${server_folder}/eula.txt" ]; do
    sleep 5
done
sed -i 's/eula=false/eula=true/g' ${server_folder}/eula.txt
systemctl restart ${service_name}