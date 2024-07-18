# Running a node

## Machine Specs
Recommended hardware: 4 CPU cores, 16 gb RAM, 50 gb disk.

Currently only Ubuntu 24.04 is supported.

Ports 8000 and 9000 are used for gossip and must be open to the public. Otherwise your IP address will be deprioritized by peers in the p2p network.

For lowest latency, run the node in Tokyo, Japan.

## Setup
Save an initial set of initial peers to connect to, or use the public list:
```
curl https://binaries.hyperliquid.xyz/Testnet/initial_peers.json > ~/initial_peers.json
```

Configure chain to testnet. Mainnet will be available once testing is complete on testnet:
```
echo '{"chain": "Testnet"}' > ~/visor.json
```

For now, the non-validating node requires a configuration file. This will no longer be required in a future update when the node will verify the validator beacon chain from genesis:
```
curl https://binaries.hyperliquid.xyz/Testnet/non_validator_config.json > ~/non_validator_config.json
```

Download the visor binary, which will spawn and manage the child node process:
```
curl https://binaries.hyperliquid.xyz/Testnet/hl-visor > ~/hl-visor && chmod a+x ~/hl-visor
```
## Create a non-root User
Add a new user named hluser
```
sudo adduser hluser
```
Add hluser to the sudo group
```
sudo usermod -aG sudo hluser
```

## Running
To start the visor, switch to the hluser account
```
su - hluser
```
Run `~/hl-visor`. The node process will write data to `~/hl/data`. The network will generate around 20 gb of logs per day, so it is also recommended to archive or delete old files.

Blocks parsed as transactions will be streamed to `~/hl/data/replica_cmds/{start_time}/{date}/{height}`

State snapshots will be saved every 10000 blocks to `~/hl/data/periodic_abci_states/{date}/{height}.rmp`

## Examining the Blockchain data
The state can be translated to JSON format for examination:

```
./hl-node translate-abci-state ~/hl/data/periodic_abci_states/{date}/{height}.rmp /tmp/out.json
```

## Troubleshooting
Crash logs from the child process will be written to `~/hl/data/visor_child_stderr/{date}/{node_binary_index}`
