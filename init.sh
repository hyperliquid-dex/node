#!/bin/bash

# Hyperliquid Node initialization script

set -e

echo "Initializing Hyperliquid Node environment..."

# Download and import GPG public key
echo "Downloading and importing GPG public key..."
curl -o /home/hluser/pub_key.asc "${PUB_KEY_URL:-https://raw.githubusercontent.com/hyperliquid-dex/node/refs/heads/main/pub_key.asc}"
gpg --import /home/hluser/pub_key.asc

# Download and verify binaries based on network type
if [ "${HL_NETWORK:-testnet}" = "mainnet" ]; then
    echo "Downloading Mainnet binary..."
    curl -o /home/hluser/hl-visor https://binaries.hyperliquid.xyz/Mainnet/hl-visor
    curl -o /home/hluser/hl-visor.asc https://binaries.hyperliquid.xyz/Mainnet/hl-visor.asc
else
    echo "Downloading Testnet binary..."
    curl -o /home/hluser/hl-visor https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor
    curl -o /home/hluser/hl-visor.asc https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor.asc
fi

# Verify binary and set permissions
echo "Verifying binary and setting permissions..."
gpg --verify /home/hluser/hl-visor.asc /home/hluser/hl-visor
chmod +x /home/hluser/hl-visor

# Create initial configuration
echo "Creating initial configuration..."
if [ "${HL_NETWORK:-testnet}" = "mainnet" ]; then
    echo '{"chain": "Mainnet"}' > /home/hluser/visor.json
else
    echo '{"chain": "Testnet"}' > /home/hluser/visor.json
fi

# Create gossip configuration
echo "Creating gossip configuration..."
# Convert comma-separated IPs to JSON array
ROOT_IPS=$(echo "${ROOT_NODE_IPS:-64.31.48.111,64.31.51.137}" | sed 's/,/"},{"Ip":"/g')
RESERVED_IPS=$(echo "${RESERVED_PEER_IPS:-}" | sed 's/,/"},{"Ip":"/g')

cat > /home/hluser/override_gossip_config.json << EOF
{
  "root_node_ips": [{"Ip":"64.31.48.111"},{"Ip":"64.31.51.137"}],
  "try_new_peers": ${TRY_NEW_PEERS:-true},
  "chain": "${HL_NETWORK:-Testnet}",
  "reserved_peer_ips": []
}
EOF