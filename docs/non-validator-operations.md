# Non-validator operations runbook

This runbook complements the main README with an operator checklist for a Hyperliquid non-validator node.

## Before starting

- Confirm the target chain in ~/visor.json: Mainnet or Testnet.
- Size the host for the current non-validator guidance: 16 vCPUs, 128 GB RAM and 500 GB SSD.
- Allow inbound gossip traffic on ports 4001 and 4002. A node without reachable gossip ports can be deprioritized by peers.
- Treat the binary as an untrusted download until its signature is verified with pub_key.asc and the matching .asc file.

## Mainnet peer bootstrap

Mainnet non-validators need at least one current root peer in ~/override_gossip_config.json. Do not hard-code an old address as a permanent dependency: query gossipRootIps from the Mainnet info API and refresh the configuration when peers change.

Keep try_new_peers enabled unless a controlled troubleshooting session requires otherwise. A single stale root address or a disabled peer search can leave a node unable to find a live stream source.

## Runtime and storage

Start the non-validator with hl-visor run-non-validator. Look for applied block X in the logs to confirm that the node is receiving live data. A process being alive is not sufficient evidence of synchronization.

The default data stream can reach roughly 100 GB per day. Set an explicit retention and monitoring policy for ~/hl/data before enabling high-volume outputs such as order statuses, raw book diffs or mempool data. Alert on disk pressure before the filesystem reaches capacity.

## Optional local services

Enable --serve-eth-rpc or --serve-info only when the local consumer needs them. Bind and firewall these services according to the deployment model; do not expose an unauthenticated local endpoint publicly by accident.

Use the local info server for requests backed by local state, and use the documented external API for unsupported historical or websocket queries. Compare local freshness with exchangeStatus before using data operationally.

## Security and expectations

A non-validator improves independent data access and reduces reliance on external operators, but it does not earn protocol-level validator rewards. Keep signing keys out of non-validator hosts and never paste wallet material into node configuration used only for data ingestion.

For a complete command reference, return to the main README. This document is guidance only; no installation, compilation or runtime test is performed by this change.
