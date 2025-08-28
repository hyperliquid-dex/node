#!/bin/bash

# Create configuration files based on environment variables
echo "Creating configuration files..."

# Select the appropriate binary based on HL_NETWORK
if [ "${HL_NETWORK:-testnet}" = "mainnet" ]; then
    echo "Using Mainnet binary"
    ln -sf /home/hluser/hl-visor-mainnet /home/hluser/hl-visor
    echo '{"chain": "Mainnet"}' > /home/hluser/visor.json
    echo "Configured for Mainnet"
else
    echo "Using Testnet binary"
    ln -sf /home/hluser/hl-visor-testnet /home/hluser/hl-visor
    echo '{"chain": "Testnet"}' > /home/hluser/visor.json
    echo "Configured for Testnet"
fi

# Create gossip configuration
ROOT_IPS=$(echo "${ROOT_NODE_IPS:-64.31.48.111,64.31.51.137}" | sed 's/,/"},{"Ip":"/g')
RESERVED_IPS=$(echo "${RESERVED_PEER_IPS:-}" | sed 's/,/"},{"Ip":"/g')

cat > /home/hluser/override_gossip_config.json << EOF
{
  "root_node_ips": [{"Ip":"64.31.48.111"},{"Ip":"64.31.51.137"}],
  "try_new_peers": ${TRY_NEW_PEERS:-true},
  "chain": "$(echo "${HL_NETWORK:-testnet}" | sed 's/^./\U&/')",
  "reserved_peer_ips": []
}
EOF

echo "Configuration files created"

build_startup_command() {
    local args=()

    if [ "${WRITE_TRADES:-true}" = "true" ]; then
        args+=("--write-trades")
    fi

    if [ "${WRITE_FILLS:-true}" = "true" ]; then
        args+=("--write-fills")
    fi

    if [ "${WRITE_ORDER_STATUSES:-true}" = "true" ]; then
        args+=("--write-order-statuses")
    fi

    if [ "${WRITE_MISC_EVENTS:-true}" = "true" ]; then
        args+=("--write-misc-events")
    fi

    if [ "${SERVE_ETH_RPC:-true}" = "true" ]; then
        args+=("--serve-eth-rpc")
    fi

    if [ "${SERVE_INFO:-true}" = "true" ]; then
        args+=("--serve-info")
    fi

    # Always add replica-cmds-style (recent-actions will minimize storage)
    args+=("--replica-cmds-style" "${REPLICA_CMDS_STYLE:-actions}")

    # Join all arguments with spaces
    printf '%s ' "${args[@]}"
}

ARGS=$(build_startup_command)
if [ -n "$ARGS" ]; then
    exec /home/hluser/hl-visor run-non-validator $ARGS
else
    exec /home/hluser/hl-visor run-non-validator
fi