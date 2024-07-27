# Running a node

## Machine Specs
Recommended hardware: 4 CPU cores, 16 gb RAM, 50 gb disk.

Currently only Ubuntu 24.04 is supported.

Ports 8000 and 9000 are used for gossip and must be open to the public. Otherwise your IP address will be deprioritized by peers in the p2p network.

For lowest latency, run the node in Tokyo, Japan.

## Setup
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

## Running
By using screen, you can maintain persistent terminal sessions even after disconnecting, ensuring that your processes continue to run uninterrupted. Follow the steps below to set up and use screen to manage your session effectively.
Ensure you have completed the setup session mentioned above before proceeding.

### Step 1: Update and Install Screen
First, update your package lists and install screen:
```
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install screen -y
```

### Step 2: Create a Screen Session
Now that the installation is complete, create a new screen session. In this example, we will name the session hl:
```
screen -S hl
```

### Step 3: Launch the Hyperliquid Node
Within the newly created screen session, launch the hyperliquid node:
```
~/hl-visor
```

### Step 4: Detach from the Screen Session
To detach from the current screen session (named hl) without terminating it, press Ctrl+a followed by d.

### Step 5: Reattach to the Screen Session
If you need to return to the screen session, use the following command:
```
screen -r hl
```

By following these steps, you can ensure that your node continues to run seamlessly, even if you disconnect from your terminal session.


## Reading L1 data
The node process will write data to `~/hl/data`. With default settings, the network will generate around 20 gb of logs per day, so it is also recommended to archive or delete old files.

Blocks parsed as transactions will be streamed to `~/hl/data/replica_cmds/{start_time}/{date}/{height}`

State snapshots will be saved every 10000 blocks to `~/hl/data/periodic_abci_states/{date}/{height}.rmp`

Trades will be streamed to `~/hl/data/node_trades/hourly/{date}/{hour}`.

Orders can be streamed by running `~/hl-visor --write-order-statuses`. This will write every L1 order status to `~/hl/data/node_order_statuses/hourly/{date}/{hour}`. Orders can be a substantial amount of data so this flag is off by default.

## Running with Docker
To build the node, run:

```bash
docker compose build
```

To run the node, run:

```bash
docker compose up -d
```

## Examining the Blockchain data
The state can be translated to JSON format for examination:

```
./hl-node translate-abci-state ~/hl/data/periodic_abci_states/{date}/{height}.rmp /tmp/out.json
```

## Troubleshooting
Crash logs from the child process will be written to `~/hl/data/visor_child_stderr/{date}/{node_binary_index}`
