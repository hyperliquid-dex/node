# Running a node

## Machine Specs
Recommended hardware: 4 CPU cores, 16 gb RAM, 50 gb disk.

Currently only Ubuntu 24.04 is supported.

Ports 4001 and 4002 are used for gossip and must be open to the public. Otherwise the node IP address will be deprioritized by peers in the p2p network.

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
EVM RPC can be enabled by passing the --evm flag `~/hl-visor run-non-validator --evm`. Once running, requests can be sent as follows: `curl -X POST --header 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false],"id":1}' http://localhost:3001/evm`

## Delegation
The native token on testnet is TESTH with token address `0x65af5d30d57264645731588b2ebfa8e3`. The token can be delegated by running
```
./hl-node --chain Testnet --key <delegator-wallet-key> delegate <validator-address> <amount-in-wei>
```
Optionally `--undelegate` can be passed to undelegate from the validator.

Delegations can be seen by running
```
curl -X POST --header "Content-Type: application/json" --data '{ "type": "delegations", "user": <delegator-address>}' https://api.hyperliquid-testnet.xyz/info
```

Staking withdrawals are subject to a 5 minute unbonding queue to allow for slashing in the case of malicious behavior. Rewards are sent to the unwithdrawn balance at the end of each epoch. Information about pending withdrawals and rewards can be seen by running
```
curl -X POST --header "Content-Type: application/json" --data '{ "type": "delegatorSummary", "user": <delegator-address>}' https://api.hyperliquid-testnet.xyz/info
```

To initiate a staking withdrawal:
```
./hl-node --chain Testnet --key <delegator-wallet-key> staking-withdrawal <wei>
```
The withdrawal will be reflected in the exchange balance automatically once the unbonding period ends.

## Running a validating node
The non-validating node setup above is a prerequisite for running a validating node.

### Generate config

Generate a validator wallet (use a cryptographically secure key, e.g. the output of `openssl rand -hex 32`):
```
echo '{"key": "<node-wallet-key>"}' > ~/hl/hyperliquid_data/node_config.json
```
In the commands below, `<node-wallet-key>` is the same hex string in the config file above.

### Ensure validator user exists
The validator address should have non-zero perps USDC balance, or it will not be able to send the signed actions to register as a validator.
This command prints the validator user:
```
~/hl-node --chain Testnet --key <node-wallet-key> print-address
```

### Join network
During the initial phase of testing, the validator address from the previous step needs to be whitelisted.

Register public IP address of validator, along with display name and description:
```
~/hl-node --chain Testnet --key <node-wallet-key> send-signed-action '{"type": "CValidatorAction", "register": {"profile": {"node_ip": {"Ip": "1.2.3.4"}, "name": "...", "description": "..." }}}'
```

Make sure ports 4000-4010 are open to other validators (currently only ports 4001-4006 are used, but additional ports in the range 4000-4010 may be used in the future). Either open the ports to the public, or keep a firewall allowing the validators which are found in `c_staking` in the state snapshots. Note that the validator set and IPs are dynamic.

### Run the validator
Run the validator using the visor binary to pick up updates `curl https://binaries.hyperliquid.xyz/Testnet/hl-visor > hl-visor && ./hl-visor run-validator`

To debug an issue, it is often easier to run `./hl-node run-validator` to immediately see stderr and disable restarts.

The validator bootstraps the state with a non-validator first. To use a known reliable peer for faster bootstrapping:
```
echo '{ "root_node_ips": [{"Ip": "1.2.3.4"}], "try_new_peers": false, "chain": "Testnet" }' > ~/override_gossip_config.json
```

### Begin validating
For now, registering and changing IP address automatically jails the validator so that it does not participate in consensus initially. When the expected outputs are streaming to `~/hl/data/consensus{wallet_user}/{date}`, send the following action to begin participating in consensus:
```
~/hl-node --chain Testnet --key <node-wallet-key> send-signed-action '{"type": "CSignerAction", "unjailSelf": null}'
```

To exit consensus, run the following command to "self jail" and wait for the validator to leave the active set before shutting down.
```
~/hl-node --chain Testnet --key <node-wallet-key> send-signed-action '{"type": "CSignerAction", "jailSelf": null}'
```

Note: if a separate signer is set in the validator profile, pass in the hot wallet signer key instead.

## Misc
See information about the current validators:
```
curl -X POST --header "Content-Type: application/json" --data '{ "type": "validatorSummaries"}' https://api.hyperliquid-testnet.xyz/info
```

Change validator profile if already registered:
```
~/hl-node --chain Testnet --key <node-wallet-key> send-signed-action '{"type": "CValidatorAction", "changeProfile": {"node_ip": {"Ip": "1.2.3.4"}, "name": "..."}}'
```

Other validator profile options:
- `disable_delegations`: Disables delegations when this is set to true.
- `commission_bps`: Amount of the staking rewards the validator takes before the remainder is distributed proportionally to stake delegated. Defaults to 10000 (all rewards go to the validator) and is not allowed to increase.
- `signer`: Allows the validator to set a hot address for signing messages in consensus.

### Running with Docker
To build the node, run:

```bash
docker compose build
```

To run the node, run:

```bash
docker compose up -d
```

### Troubleshooting
Crash logs from the child process will be written to `~/hl/data/visor_child_stderr/{date}/{node_binary_index}`
