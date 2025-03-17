# Running a node

## Machine Specs
Recommended minimum hardware: 4 CPU cores, 32 GB RAM, 200 GB disk.

Currently only Ubuntu 24.04 is supported.

Ports 4001 and 4002 are used for gossip and must be open to the public. Otherwise, the node IP address will be deprioritized by peers in the p2p network.

For lowest latency, run the node in Tokyo, Japan.

---

## Setup

### Configure Chain
For testing, configure your chain as follows:

- **Testnet**:
  ```bash
  echo '{"chain": "Testnet"}' > ~/visor.json
  ```
- **Mainnet**:
  ```bash
  echo '{"chain": "Mainnet"}' > ~/visor.json
  ```

### Download the Visor Binary
The visor binary spawns and manages the child node process.

- **Testnet**:
  ```bash
  curl https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor > ~/hl-visor && chmod a+x ~/hl-visor
  ```
- **Mainnet**:
  ```bash
  curl https://binaries.hyperliquid.xyz/Mainnet/hl-visor > ~/hl-visor && chmod a+x ~/hl-visor
  ```

---

## Verify Signed Binaries

Binaries are signed for extra security. The public key is found at `pub_key.asc` in this repo.

1. **Import the Key:**
   ```bash
   gpg --import pub_key.asc
   ```

2. **Verify the Binary:**
   Signatures are located at `{binary}.asc`.

   - **Testnet**:
     ```bash
     curl https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor.asc > hl-visor.asc
     gpg --verify hl-visor.asc hl-visor
     ```
   - **Mainnet**:
     ```bash
     curl https://binaries.hyperliquid.xyz/Mainnet/hl-visor.asc > hl-visor.asc
     gpg --verify hl-visor.asc hl-visor
     ```

`hl-visor` will also verify `hl-node` automatically and will not upgrade on verification failure. **Important:** The public key must be imported as shown above. Optionally, sign the key using `gpg --sign-key` to avoid warnings when verifying its signatures.

---

## Running Non-Validator

To start a non-validator node:

```bash
~/hl-visor run-non-validator
```

It may take a while as the node navigates the network to find an appropriate peer to stream from. Logs such as `applied block X` indicate that the node is streaming live data.

> **Note:** The same command is used regardless of whether your chain is set to Testnet or Mainnet (as configured in `~/visor.json`).

---

## Reading L1 Data

The node writes data to `~/hl/data`. With default settings, the network will generate around 20 GB of logs per day, so it is recommended to archive or delete old files.

- **Transaction Blocks:**
  Blocks parsed as transactions are streamed to:
  ```
  ~/hl/data/replica_cmds/{start_time}/{date}/{height}
  ```

- **State Snapshots:**
  State snapshots are saved every 10,000 blocks to:
  ```
  ~/hl/data/periodic_abci_states/{date}/{height}.rmp
  ```

  To translate the state to JSON for examination:

  - **Testnet**:
    ```bash
    ./hl-node --chain Testnet translate-abci-state ~/hl/data/periodic_abci_states/{date}/{height}.rmp /tmp/out.json
    ```
  - **Mainnet**:
    ```bash
    ./hl-node --chain Mainnet translate-abci-state ~/hl/data/periodic_abci_states/{date}/{height}.rmp /tmp/out.json
    ```

---

## Flags

When running validators or non-validators, you can use the following flags:

- `--write-trades`: Streams trades to `~/hl/data/node_trades/hourly/{date}/{hour}`.
- `--write-order-statuses`: Writes every L1 order status to `~/hl/data/node_order_statuses/hourly/{date}/{hour}`. (Note that orders can be a substantial amount of data.)
- `--replica-cmds-style`: Configures what is written to `~/hl/data/replica_cmds/{start_time}/{date}/{height}`.
  Options:
  - `actions` (default) – only actions
  - `actions-and-responses` – both actions and responses
  - `recent-actions` – only preserves the two latest height files
- `--serve-eth-rpc`: Enables the EVM RPC (see next section).

For example, to run a non-validator with all flags enabled:
```bash
~/hl-visor run-non-validator --write-trades --write-order-statuses --serve-eth-rpc
```

> **Note:** These flags work independently of the chain setting. Just ensure that your `~/visor.json` is configured for Testnet or Mainnet as needed.

---

## EVM

Enable the EVM RPC by adding the `--serve-eth-rpc` flag:
```bash
~/hl-visor run-non-validator --serve-eth-rpc
```

Once running, you can send RPC requests. For example, to retrieve the latest block:
```bash
curl -X POST --header 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false],"id":1}' http://localhost:3001/evm
```

> **This applies for both Testnet and Mainnet.**

---

## Delegation

The native token on Testnet is **HYPE** with token address:
```
0x7317beb7cceed72ef0b346074cc8e7ab
```

**Delegation Process (applies to both chains):**

1. **Staking Deposit:**
   Transfer tokens from your spot balance into the staking balance:
   - **Testnet:**
     ```bash
     ./hl-node --chain Testnet --key <delegator-wallet-key> staking-deposit <wei>
     ```
   - **Mainnet:**
     ```bash
     ./hl-node --chain Mainnet --key <delegator-wallet-key> staking-deposit <wei>
     ```

2. **Delegate Tokens:**
   Delegate tokens to a validator:
   - **Testnet:**
     ```bash
     ./hl-node --chain Testnet --key <delegator-wallet-key> delegate <validator-address> <amount-in-wei>
     ```
   - **Mainnet:**
     ```bash
     ./hl-node --chain Mainnet --key <delegator-wallet-key> delegate <validator-address> <amount-in-wei>
     ```

   Optionally, add `--undelegate` to undelegate from the validator.

3. **View Delegations:**
   - **Testnet:**
     ```bash
     curl -X POST --header "Content-Type: application/json" --data '{ "type": "delegations", "user": <delegator-address>}' https://api.hyperliquid-testnet.xyz/info
     ```
   - **Mainnet:**
     Use the corresponding API endpoint for mainnet (if available).

4. **Staking Withdrawal:**
   Initiate a staking withdrawal (subject to a 5-minute unbonding period):
   - **Testnet:**
     ```bash
     ./hl-node --chain Testnet --key <delegator-wallet-key> staking-withdrawal <wei>
     ```
   - **Mainnet:**
     ```bash
     ./hl-node --chain Mainnet --key <delegator-wallet-key> staking-withdrawal <wei>
     ```
   The withdrawal will reflect in the exchange balance automatically once the unbonding period ends.

---

## Running a Validating Node

*Note: The non-validating node setup above is a prerequisite for running a validating node.*

### Generate Config

Generate two wallets:
- **Validator wallet:** Holds funds and receives delegation rewards (cold wallet).
- **Signer wallet:** Used solely for signing consensus messages (hot wallet).

They can be the same wallet for simplicity.

Create a config file for the signer wallet:
```bash
echo '{"key": "<signer-key>"}' > ~/hl/hyperliquid_data/node_config.json
```
Keep both `<signer-key>` and `<validator-key>` secure.

### Ensure Validator User Exists

Both the signer and validator addresses must have a non-zero perps USDC balance to be able to send signed actions. Print the addresses:

- **Testnet:**
  ```bash
  ~/hl-node --chain Testnet --key <signer-key> print-address
  ~/hl-node --chain Testnet --key <validator-key> print-address
  ```
- **Mainnet:**
  ```bash
  ~/hl-node --chain Mainnet --key <signer-key> print-address
  ~/hl-node --chain Mainnet --key <validator-key> print-address
  ```

### Join Network

The validator set on Testnet is entirely permissionless.

- **Register and Self-Delegate:**

  On **Testnet** (self-delegate 10_000, i.e. 1000000000000 wei):
  ```bash
  ~/hl-node --chain Testnet --key <validator-key> send-signed-action '{"type": "CValidatorAction", "register": {"profile": {"node_ip": {"Ip": "1.2.3.4"}, "signer": "<signer-address>", "name": "...", "description": "..." }, "initial_wei": 1000000000000}}'
  ```

  On **Mainnet**:
  ```bash
  ~/hl-node --chain Mainnet --key <validator-key> send-signed-action '{"type": "CValidatorAction", "register": {"profile": {"node_ip": {"Ip": "1.2.3.4"}, "signer": "<signer-address>", "name": "...", "description": "..." }, "initial_wei": 1000000000000}}'
  ```

Make sure ports 4000-4010 are open to other validators. (Currently, only ports 4001-4006 are used, but additional ports in this range may be used in the future.) Either open the ports publicly or configure your firewall to allow validators (which can be found in `c_staking` in the state snapshots). Note that the validator set and IPs are dynamic.

### Run the Validator

- **Testnet:**
  ```bash
  curl https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor > hl-visor && ./hl-visor run-validator
  ```
- **Mainnet:**
  ```bash
  curl https://binaries.hyperliquid.xyz/Mainnet/hl-visor > hl-visor && ./hl-visor run-validator
  ```

> **Debugging Tip:** To see stderr immediately and disable restarts, run:
> - **Testnet:**
>   ```bash
>   ./hl-node --chain Testnet run-validator
>   ```
> - **Mainnet:**
>   ```bash
>   ./hl-node --chain Mainnet run-validator
>   ```

For faster bootstrapping, use a known reliable peer:
- **Testnet:**
  ```bash
  echo '{ "root_node_ips": [{"Ip": "1.2.3.4"}], "try_new_peers": false, "chain": "Testnet" }' > ~/override_gossip_config.json
  ```
- **Mainnet:**
  ```bash
  echo '{ "root_node_ips": [{"Ip": "1.2.3.4"}], "try_new_peers": false, "chain": "Mainnet" }' > ~/override_gossip_config.json
  ```

### Begin Validating

When first registered or after changing your IP, the validator is automatically jailed (i.e. it does not participate in consensus initially). Once you see the expected outputs streaming to:
```
~/hl/data/node_logs/consensus/hourly/{date}/{hour}
```
send the following action to begin participating in consensus:

- **Testnet:**
  ```bash
  ~/hl-node --chain Testnet --key <signer-key> send-signed-action '{"type": "CSignerAction", "unjailSelf": null}'
  ```
- **Mainnet:**
  ```bash
  ~/hl-node --chain Mainnet --key <signer-key> send-signed-action '{"type": "CSignerAction", "unjailSelf": null}'
  ```

To exit consensus (i.e. “self jail”) and wait for the validator to leave the active set before shutting down:

- **Testnet:**
  ```bash
  ~/hl-node --chain Testnet --key <signer-key> send-signed-action '{"type": "CSignerAction", "jailSelf": null}'
  ```
- **Mainnet:**
  ```bash
  ~/hl-node --chain Mainnet --key <signer-key> send-signed-action '{"type": "CSignerAction", "jailSelf": null}'
  ```

### Jailing

Performance and uptime are critical for the mainnet L1. To achieve this, a key feature of HyperBFT consensus is "jailing." When a validator is jailed, it can still participate in the consensus network by forwarding messages to peers, but does not vote on or propose blocks. To avoid jailing, it is recommended to achieve 200ms two-way latency to at least one‑third of validators by stake.

Once jailed, a validator can only be unjailed through the `unjailSelf` action (which will succeed only after the L1 time exceeds the "jailed until" time). Self‑jailing does not extend the jailing duration.

If a validator repeatedly gets jailed, check stdout for signs of crashing or other unusual logs. Also, logs in `~/hl/data/node_logs/status/` may help diagnose latency or connectivity issues.

### Alerting

It is recommended that validators set up an alerting system to maintain optimal uptime.

- **Testnet Example (Slack Alerts):**
  ```bash
  echo '{"testnet_slack_channel": "C000...", "slack_key": "Bearer xoxb-..."}' > ~/hl/api_secrets.json
  ```
  Test the Slack alert configuration:
  ```bash
  ~/hl-node --chain Testnet send-slack-alert "hello hyperliquid"
  ```

For **Mainnet**, use a similar configuration (with keys/channels specific to Mainnet if needed).

---

## Logs

The directory `node_logs/consensus` contains most messages sent and received by the consensus algorithm, which is often useful for debugging.

For example, to check whether Vote messages were sent to validator `0x5ac9...` around `2024-12-10T09:25`, you can run:
```bash
grep destination...0x5ac9 ~/hl/data/node_logs/consensus/hourly/20241210/9 | grep T09:25 | grep Vote
```

Validators with issues may experience timeouts on rounds when they do not propose a block. Searching for `suspect` in the consensus logs can help pinpoint the cause, which is often correlated with jailing.

Crash logs from the child process are written to:
```
~/hl/data/visor_child_stderr/{date}/{node_binary_index}
```

---

## Validator Endpoints

To view current validator information:

- **Testnet:**
  ```bash
  curl -X POST --header "Content-Type: application/json" --data '{ "type": "validatorSummaries"}' https://api.hyperliquid-testnet.xyz/info
  ```
- **Mainnet:**
  Use the corresponding Mainnet endpoint if available.

To change your validator profile (for example, updating your IP address):

- **Testnet:**
  ```bash
  ~/hl-node --chain Testnet --key <validator-key> send-signed-action '{"type": "CValidatorAction", "changeProfile": {"node_ip": {"Ip": "1.2.3.4"}, "name": "..."}}'
  ```
- **Mainnet:**
  ```bash
  ~/hl-node --chain Mainnet --key <validator-key> send-signed-action '{"type": "CValidatorAction", "changeProfile": {"node_ip": {"Ip": "1.2.3.4"}, "name": "..."}}'
  ```

Other validator profile options include:
- `disable_delegations`: Disables delegations when set to true.
- `commission_bps`: Sets the percentage of staking rewards the validator takes before the remainder is distributed proportionally to stake delegated (defaults to 10000, meaning all rewards go to the validator, and is not allowed to increase).
- `signer`: Allows the validator to set a hot address for signing consensus messages.

---

## Mainnet Non-Validator Seed Peers

The community runs several independent root peers for non-validators to connect to on Mainnet. To run a non-validator on Mainnet, add at least one of these IP addresses to your `~/override_gossip_config.json`:
```
operator_name,root_ips
ASXN,20.188.6.225
ASXN,74.226.182.22
B-Harvest,57.182.103.24
B-Harvest,3.115.170.40
Nansen x HypurrCollective,46.105.222.166
Nansen x HypurrCollective,91.134.41.52
Hypurrscan,57.180.50.253
Hypurrscan,54.248.41.39
Infinite Field,52.68.71.160
Infinite Field,13.114.116.44
LiquidSpirit x Rekt Gang,199.254.199.190
LiquidSpirit x Rekt Gang,199.254.199.247
Imperator.co,45.32.32.21
Imperator.co,157.90.207.92
Enigma,148.251.76.7
Enigma,45.63.123.73
TMNT,31.223.196.172
TMNT,31.223.196.238
HyperStake,91.134.71.237
HyperStake,57.129.140.247
```

---

## Troubleshooting

Crash logs from the child process are written to:
```
~/hl/data/visor_child_stderr/{date}/{node_binary_index}
```

---
