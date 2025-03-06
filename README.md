# Running a Node

## Machine Specs
Recommended minimum hardware: 4 CPU cores, 32 GB RAM, 200 GB disk.

Currently, only Ubuntu 24.04 is supported.

Ports 4001 and 4002 are used for gossip and must be open to the public. Otherwise, the node IP address will be deprioritized by peers in the P2P network.

For lowest latency, run the node in Tokyo, Japan.

## Setup
Configure the chain to testnet when testing:
```
echo '{"chain": "Testnet"}' > ~/visor.json
```
For mainnet, use:
```
echo '{"chain": "Mainnet"}' > ~/visor.json
```

Download the visor binary, which will spawn and manage the child node process:
```
curl https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor > ~/hl-visor && chmod a+x ~/hl-visor
```
For mainnet:
```
curl https://binaries.hyperliquid.xyz/Mainnet/hl-visor > ~/hl-visor && chmod a+x ~/hl-visor
```

## Verify Signed Binaries
Binaries are signed for extra security. The public key is found at `pub_key.asc` in this repo.
Import this key:
```
gpg --import pub_key.asc
```

Verify any (signature, binary) pair manually. Signatures are located at `{binary}.asc`:
```
curl https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor.asc > hl-visor.asc
gpg --verify hl-visor.asc hl-visor
```
For mainnet:
```
curl https://binaries.hyperliquid.xyz/Mainnet/hl-visor.asc > hl-visor.asc
gpg --verify hl-visor.asc hl-visor
```

`hl-visor` will also verify `hl-node` automatically and will not upgrade on verification failure.

## Running a Non-Validator
To run a non-validator node:
```
~/hl-visor run-non-validator
```
It may take a while as the node navigates the network to find an appropriate peer to stream from. Logs like `applied block X` mean the node should be streaming live data.

## Reading L1 Data
The node process will write data to `~/hl/data`. By default, the network will generate around 20 GB of logs per day, so it is recommended to archive or delete old files.

Blocks parsed as transactions will be streamed to:
```
~/hl/data/replica_cmds/{start_time}/{date}/{height}
```

State snapshots will be saved every 10,000 blocks to:
```
~/hl/data/periodic_abci_states/{date}/{height}.rmp
```

To translate the state into JSON format:
```
./hl-node --chain Testnet translate-abci-state ~/hl/data/periodic_abci_states/{date}/{height}.rmp /tmp/out.json
```
For mainnet:
```
./hl-node --chain Mainnet translate-abci-state ~/hl/data/periodic_abci_states/{date}/{height}.rmp /tmp/out.json
```

## Running a Validating Node
The non-validating node setup above is a prerequisite for running a validating node.

### Generate Config
Generate two wallets: a validator wallet and a signer wallet. The validator wallet holds funds and receives delegation rewards. The signer wallet is used only for signing consensus messages.
```
echo '{"key": "<signer-key>"}' > ~/hl/hyperliquid_data/node_config.json
```

### Ensure Validator User Exists
Both the signer address and the validator address should have a non-zero perps USDC balance.
```
~/hl-node --chain Testnet --key <signer-key> print-address
~/hl-node --chain Testnet --key <validator-key> print-address
```
For mainnet:
```
~/hl-node --chain Mainnet --key <signer-key> print-address
~/hl-node --chain Mainnet --key <validator-key> print-address
```

### Join Network
The validator set is permissionless.

For testnet:
```
~/hl-node --chain Testnet --key <validator-key> send-signed-action '{"type": "CValidatorAction", "register": {"profile": {"node_ip": {"Ip": "1.2.3.4"}, "signer": "<signer-address>", "name": "...", "description": "..." }, "initial_wei": 1000000000000}}'
```
For mainnet:
```
~/hl-node --chain Mainnet --key <validator-key> send-signed-action '{"type": "CValidatorAction", "register": {"profile": {"node_ip": {"Ip": "1.2.3.4"}, "signer": "<signer-address>", "name": "...", "description": "..." }, "initial_wei": 1000000000000}}'
```

Make sure ports 4000-4010 are open to other validators.

### Run the Validator
For testnet:
```
curl https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor > hl-visor && ./hl-visor run-validator
```
For mainnet:
```
curl https://binaries.hyperliquid.xyz/Mainnet/hl-visor > hl-visor && ./hl-visor run-validator
```

To debug issues, it may be easier to run manually:
```
./hl-node --chain Testnet run-validator
```
For mainnet:
```
./hl-node --chain Mainnet run-validator
```

### Mainnet Non-Validator Seed Peers
To run a non-validator on mainnet, add at least one of these IP addresses to `~/override_gossip_config.json`:
```
operator_name,root_ips
ASXN,20.188.6.225
ASXN,74.226.182.22
B-Harvest,57.182.103.24
B-Harvest,3.115.170.40
Nansen,46.105.222.166
Nansen,91.134.41.52
Hypurrscan,57.180.50.253
```

## Logs and Troubleshooting
Logs are stored in `~/hl/data/node_logs/consensus`. For example, to check whether Vote messages were sent to validator `0x5ac9...`:
```
grep destination...0x5ac9  ~/hl/data/node_logs/consensus/hourly/20241210/9  | grep T09:25 | grep Vote
```
To check for timeout issues:
```
grep suspect ~/hl/data/node_logs/consensus/hourly/{date}/{hour}
```

For crash logs from the child process:
```
~/hl/data/visor_child_stderr/{date}/{node_binary_index}
```

### Validator Endpoints
See information about the current validators:
```
curl -X POST --header "Content-Type: application/json" --data '{ "type": "validatorSummaries"}' https://api.hyperliquid-testnet.xyz/info
```
For mainnet:
```
curl -X POST --header "Content-Type: application/json" --data '{ "type": "validatorSummaries"}' https://api.hyperliquid.xyz/info
```

