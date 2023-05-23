#!/bin/bash

home_folder="/home/minecraft"
server_folder="${home_folder}/server"

useradd -r -m -U -d ${home_folder} -s /bin/bash minecraft
mkdir ${server_folder}
cd ${server_folder}

yum install -y jdk-18.x86_64

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
ExecStart=/usr/bin/java -Xms1G -Xmx5G -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -jar server.jar nogui
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload

firewall-cmd --permanent --zone=public --add-port=25565/tcp
firewall-cmd --permanent --zone=public --add-port=25565/udp
firewall-cmd --reload

systemctl start minecraft
while [ ! -f "${server_folder}/eula.txt" ]; do
    sleep 5
done
sed -i 's/eula=false/eula=true/g' ${server_folder}/eula.txt
systemctl restart minecraft