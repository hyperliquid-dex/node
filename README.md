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

Download the visor binary, which will spawn and manage the child node process:
```
curl https://binaries.hyperliquid.xyz/Testnet/hl-visor > ~/hl-visor && chmod a+x ~/hl-visor
```

## Running
Run `~/hl-visor run-non-validator`. It may take a while as your node navigates the network to find an appropriate peer to stream from. Once you see logs like `applied block X` then your node should be streaming live data. You can inspect the transactions or other data as described below.

## Reading L1 data
The node process will write data to `~/hl/data`. With default settings, the network will generate around 20 gb of logs per day, so it is also recommended to archive or delete old files.

Blocks parsed as transactions will be streamed to `~/hl/data/replica_cmds/{start_time}/{date}/{height}`

State snapshots will be saved every 10000 blocks to `~/hl/data/periodic_abci_states/{date}/{height}.rmp`

Trades will be streamed to `~/hl/data/node_trades/hourly/{date}/{hour}`.

Orders can be streamed by running `~/hl-visor run-non-validator --write-order-statuses`. This will write every L1 order status to `~/hl/data/node_order_statuses/hourly/{date}/{hour}`. Orders can be a substantial amount of data so this flag is off by default.

EVM RPC can be enabled by passing the --evm flag `~/hl-visor run-non-validator --evm`. Once running you can send evm post requests to localhost port 3001. E.g. `curl -X POST --header 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false],"id":1}' http://localhost:3001/evm`

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
