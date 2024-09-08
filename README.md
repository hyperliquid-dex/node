# Running a node

## Machine Specs
Recommended hardware: 4 CPU cores, 16 gb RAM, 50 gb disk.

Currently only Ubuntu 24.04 is supported.

Ports 8000 and 9000 are used for gossip and must be open to the public. Otherwise the node IP address will be deprioritized by peers in the p2p network.

For lowest latency, run the node in Tokyo, Japan.

## Setup
Configure chain to testnet. Mainnet will be available once testing is complete on testnet:
```
echo '{"chain": "Testnet"}' > ~/visor.json
```

Download the visor binary, which will spawn and manage the child node process:
```
curl https://binaries.hyperliquid.xyz/Testnet/hl-visor > ~/hl-visor && chmod a+x ~/hl-visor
```

## Running non-validator
Run `~/hl-visor run-non-validator`. It may take a while as the node navigates the network to find an appropriate peer to stream from. Logs like `applied block X` mean the node should be streaming live data.

## Reading L1 data
The node process will write data to `~/hl/data`. With default settings, the network will generate around 20 gb of logs per day, so it is also recommended to archive or delete old files.

Blocks parsed as transactions will be streamed to `~/hl/data/replica_cmds/{start_time}/{date}/{height}`

State snapshots will be saved every 10000 blocks to `~/hl/data/periodic_abci_states/{date}/{height}.rmp`

The state can be translated to JSON format for examination:

```
./hl-node translate-abci-state ~/hl/data/periodic_abci_states/{date}/{height}.rmp /tmp/out.json
```

Trades will be streamed to `~/hl/data/node_trades/hourly/{date}/{hour}`.

Orders can be streamed by running `~/hl-visor run-non-validator --write-order-statuses`. This will write every L1 order status to `~/hl/data/node_order_statuses/hourly/{date}/{hour}`. Orders can be a substantial amount of data so this flag is off by default.

## EVM
EVM RPC can be enabled by passing the --evm flag `~/hl-visor run-non-validator --evm`. Once running you can send evm post requests to localhost port 3001. E.g. `curl -X POST --header 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false],"id":1}' http://localhost:3001/evm`

## Running a validating node
The non-validating node setup above is a prerequisite for running a validating node.

### Generate config

Generate a validator wallet (use a securely generated key):
```
echo '{"key": "8888888888888888888888888888888888888888888888888888888888888888"}' > ~/hl/hyperliquid_data/node_config.json
```
In the commands below, `<node-wallet-key>` is the hex string in the config file above.

### Ensure validator user exists
The validator address should have non-zero perps USDC balance, or it will not be able to send the signed actions to register as a validator.
This command prints the validator user:
```
~/hl-node --chain Testnet print-address <node-wallet-key>
```

### Join network
During the initial phase of testing, the validator address from the previous step needs to be whitelisted.

Register public IP address of validator, along with display name and description:
```
~/hl-node --chain Testnet send-signed-action '{"type": "CValidatorAction", "register": {"profile": {"node_ip": {"Ip": "1.2.3.4"}, "name": "...", "description": "..." }}}' <node-wallet-key>
```

Make sure ports 4000, 5000, 6000, 7000, 8000, 9000 are open to the validators. Either open the ports to the public, or keep a firewall allowing the validators which are found in `c_staking` in the state snapshots. Note that the validator set and IPs are dynamic.

### Run the validator
Run the validator using the visor binary to pick up updates `curl https://binaries.hyperliquid.xyz/Testnet/hl-visor > hl-visor && ./hl-visor run-validator`

To debug an issue, it is often easier to run `./hl-node run-validator` to immediately see stderr and disable restarts.

The validator bootstraps the state with a non-validator first. To use a known reliable peer for faster bootstrapping:
```
echo '{ "root_node_ips": [{"Ip": "1.2.3.4"}], "try_new_peers": false }' > ~/override_gossip_config.json
```

### Begin validating
For now, registering and changing IP address automatically jails the validator so that it does not participate in consensus initially. When the expected outputs are streaming to `~/hl/data/consensus{wallet_user}/{date}`, send the following action to begin participating in consensus:
```
~/hl-node --chain Testnet send-signed-action '{"type": "CValidatorAction", "unjailSelf": null}' <node-wallet-key>
```

To exit consensus, run the following command to "self jail" and wait for the validator to leave the active set before shutting down.
```
~/hl-node --chain Testnet send-signed-action '{"type": "CValidatorAction", "jailSelf": null}' <node-wallet-key>
```

## Misc
See information about the current validators:
```
curl -X POST --header "Content-Type: application/json" --data '{ "type": "validatorSummaries"}' https://api.hyperliquid-testnet.xyz/info
```

Change validator profile if already registered:
```
~/hl-node --chain Testnet send-signed-action '{"type": "CValidatorAction", "changeProfile": {"node_ip": {"Ip": "1.2.3.4"}, "name": "..."}}' <node-wallet-key>
```

## Running with Docker
To build the node, run:

```bash
docker compose build
```

To run the node, run:

```bash
docker compose up -d
```

## Troubleshooting
Crash logs from the child process will be written to `~/hl/data/visor_child_stderr/{date}/{node_binary_index}`
