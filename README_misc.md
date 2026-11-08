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

For a standalone image with a custom user, use
`docker build --build-arg USERNAME=myuser -t hl-node .`. The default entrypoint
uses the visor in that user's working directory. The supplied Compose volume
paths still assume the default `hluser`; adjust them separately if needed.

The offline path-resolution regression can be run with
`bash tests/docker-entrypoint.sh`. It uses a placeholder executable to check
the default and custom user paths; it does not build an image or run a node.

## Additional Configuration
The default number of gossip peers for non-validating nodes is 8. To configure a different number between 8 and 100 inclusive, put that integer as `n_gossip_peers` in `override_gossip_config.json`. This does not require restarting the node to take effect.

To override the public IP address of the node:
```
echo "1.2.3.4" > ~/hl/override_public_ip_address
```
