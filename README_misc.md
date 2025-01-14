This file contains optional configuration. Refer to `README.md` the essential information.

## Running as a System Service
Many node operators prefer to run the node as a system service.

Create the system service config file:
```
sudo nano /etc/systemd/system/hl-visor.service
```

Add the required information to the config, replace ALL instances of USERNAME:
```
[Unit]
Description=HL-Visor Non-Validator Service
After=network.target

[Service]
Type=simple
User=USERNAME
WorkingDirectory=/home/USERNAME
ExecStart=/home/USERNAME/hl-visor run-non-validator
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target

```
Enable the service:
```
sudo systemctl enable hl-visor.service
```

Start the service:
```
sudo systemctl start hl-visor
```

And finally to follow the logs use command:
```
journalctl -u hl-visor -f
```

### Running with Docker
To build the node, run:

```bash
docker compose build
```

To run the node, run:

```bash
docker compose up -d
```
