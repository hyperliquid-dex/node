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
curl https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor > ~/hl-visor && chmod a+x ~/hl-visor
```

## Verify signed binaries
Binaries are signed for extra security. The public key is found at `pub_key.asc` in this repo.
Import this key:
```
gpg --import pub_key.asc
```

Verify any (signature, binary) pair manually:
```
gpg --import pub_key.asc
gpg --verify hl-visor.asc hl-visor
```

`hl-visor` will also verify `hl-node` automatically and will not upgrade on verification failure. Important: the public key must be imported as above or the visor will not work.

Optionally, sign this key using `gpg --sign-key` to avoid warnings when verifying its signatures.

## Running non-validator
Run `~/hl-visor run-non-validator`. It may take a while as the node navigates the network to find an appropriate peer to stream from. Logs like `applied block X` mean the node should be streaming live data.

## Running as a System Service (optional)

To have more control over the running service, it is considered good practice to run the program as a system service.

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

## Reading L1 data
The node process will write data to `~/hl/data`. With default settings, the network will generate around 20 gb of logs per day, so it is also recommended to archive or delete old files.

Blocks parsed as transactions will be streamed to `~/hl/data/replica_cmds/{start_time}/{date}/{height}`.

State snapshots will be saved every 10000 blocks to `~/hl/data/periodic_abci_states/{date}/{height}.rmp`

The state can be translated to JSON format for examination:

```
./hl-node --chain Testnet translate-abci-state ~/hl/data/periodic_abci_states/{date}/{height}.rmp /tmp/out.json
```

### Flags
Certain flags can be turned on when running validators or non-validators:
- `--write-trades` will stream trades to `~/hl/data/node_trades/hourly/{date}/{hour}`.
- `--write-order-statuses` will write every L1 order status to `~/hl/data/node_order_statuses/hourly/{date}/{hour}`. Orders can be a substantial amount of data.
- `--replica-cmds-style` configures what is written down to `~/hl/data/replica_cmds/{start_time}/{date}/{height}`. Possible values are `actions` for only actions (default), `actions-and-responses` for actions and responses, and `recent-actions` which is the same as `actions` but only preserving the two latest height files.
- `--serve-eth-rpc` enables the EVM rpc. More details in the following section.

For example, to run a non-validator with all flags enabled:
```
~/hl-visor run-non-validator --write-trades --write-order-statuses --serve-eth-rpc
```

## EVM
EVM RPC can be enabled by passing the `--serve-eth-rpc` flag `~/hl-visor run-non-validator --serve-eth-rpc`. Once running, requests can be sent as follows: `curl -X POST --header 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false],"id":1}' http://localhost:3001/evm`

## Delegation
The native token on testnet is HYPE with token address `0x7317beb7cceed72ef0b346074cc8e7ab`.

Delegations occur from the staking balance, which is separate from the spot balance. The token can be transferred from the spot balance into the staking balance by running
```
./hl-node --chain Testnet --key <delegator-wallet-key> staking-deposit <wei>
```

The token can be delegated by running
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

Generate two wallets: a validator wallet and a signer wallet (use cryptographically secure keys, e.g. the output of `openssl rand -hex 32`). The validator wallet is "cold" in the sense that it holds funds and receives delegation rewards. The signer wallet is "hot" in the sense that it is used only for signing consensus messages. They can be the same wallet for simplicity.
```
echo '{"key": "<signer-key>"}' > ~/hl/hyperliquid_data/node_config.json
```
In the commands below, `<signer-key>` is the same hex string in the config file above and `<validator-key>` is analogous (do not lose either key).

### Ensure validator user exists
Both the signer address and the validator address should have non-zero perps USDC balance, or they will not be able to send the signed actions to register as a validator or otherwise operate properly.
These command print the addresses:
```
~/hl-node --chain Testnet --key <signer-key> print-address
~/hl-node --chain Testnet --key <validator-key> print-address
```

### Join network
The validator set on testnet is entirely permissionless.

Register public IP and signer address of validator, along with display name and description. On testnet, self-delegate 10_000 (1000000000000 wei) to run the validator.

```
~/hl-node --chain Testnet --key <validator-key> send-signed-action '{"type": "CValidatorAction", "register": {"profile": {"node_ip": {"Ip": "1.2.3.4"}, "signer": "<signer-address>", "name": "...", "description": "..." }, "initial_wei": 1000000000000}}'
```

Make sure ports 4000-4010 are open to other validators (currently only ports 4001-4006 are used, but additional ports in the range 4000-4010 may be used in the future). Either open the ports to the public, or keep a firewall allowing the validators which are found in `c_staking` in the state snapshots. Note that the validator set and IPs are dynamic.

### Run the validator
Run the validator using the visor binary to pick up updates `curl https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor > hl-visor && ./hl-visor run-validator`

To debug an issue, it is often easier to run `./hl-node --chain Testnet run-validator` to immediately see stderr and disable restarts.

The validator bootstraps the state with a non-validator first. To use a known reliable peer for faster bootstrapping:
```
echo '{ "root_node_ips": [{"Ip": "1.2.3.4"}], "try_new_peers": false, "chain": "Testnet" }' > ~/override_gossip_config.json
```

### Begin validating
For now, registering and changing IP address automatically jails the validator so that it does not participate in consensus initially. When the expected outputs are streaming to `~/hl/data/node_logs/consensus/hourly/{date}/{hour}`, send the following action to begin participating in consensus:
```
~/hl-node --chain Testnet --key <signer-key> send-signed-action '{"type": "CSignerAction", "unjailSelf": null}'
```

To exit consensus, run the following command to "self jail" and wait for the validator to leave the active set before shutting down.
```
~/hl-node --chain Testnet --key <signer-key> send-signed-action '{"type": "CSignerAction", "jailSelf": null}'
```

### Jailing
Performance and uptime are critical for the mainnet L1. To achieve this, a key feature of HyperBFT consensus is "jailing." When a validator is jailed, it can still participate in the consensus network by forwarding messages to peers, but does not vote on or propose blocks. To avoid jailing, it is recommended to achieve 200ms two-way latency to at least 1/3 of validators by stake.

Once a validator is jailed, it can only be unjailed through the `unjailSelf` action described above. This action will only succeed if the L1 time is later than the "jailed until" time of the validator. Self-jailing does not advance the "jailed until" duration, and is therefore the only way to disable a validator without penalty.

To debug a validator that repeatedly gets jailed, first check stdout for signs of crashing or other unusual logs. If the binary is running without problems, logs in `~/hl/data/node_logs/status/` may be helpful to debug latencies to other validators or other connectivity issues.

### Alerting
It is recommended for validators to set up an alerting system to maintain optimal uptime.

To configure Slack to alert on critical messages:
```
echo '{"testnet_slack_channel": "C000...", "slack_key": "Bearer xoxb-..."}' > ~/hl/api_secrets.json
```

Test the Slack alert configuration:
```
~/hl-node --chain Testnet send-slack-alert "hello hyperliquid"
```

Alternative alerting systems can be configured by filtering to the lines in stdout at level `CRIT`.

## Misc
See information about the current validators:
```
curl -X POST --header "Content-Type: application/json" --data '{ "type": "validatorSummaries"}' https://api.hyperliquid-testnet.xyz/info
```

Change validator profile if already registered:
```
~/hl-node --chain Testnet --key <validator-key> send-signed-action '{"type": "CValidatorAction", "changeProfile": {"node_ip": {"Ip": "1.2.3.4"}, "name": "..."}}'
```

Other validator profile options:
- `disable_delegations`: Disables delegations when this is set to true.
- `commission_bps`: Amount of the staking rewards the validator takes before the remainder is distributed proportionally to stake delegated. Defaults to 10000 (all rewards go to the validator) and is not allowed to increase.
- `signer`: Allows the validator to set a hot address for signing consensus messages.

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
