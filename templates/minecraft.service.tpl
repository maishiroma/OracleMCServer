[Unit]
Description=${full_service_name}
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