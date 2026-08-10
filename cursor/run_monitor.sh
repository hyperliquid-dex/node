#!/bin/bash

# Trade Latency Monitor Runner Script
# Usage: ./run_monitor.sh [testnet|mainnet]

set -e

# Default to testnet if no argument provided
ENVIRONMENT=${1:-testnet}

# Check if environment file exists
ENV_FILE="${ENVIRONMENT}.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Environment file $ENV_FILE not found!"
    echo "Available environments: testnet, mainnet"
    exit 1
fi

echo "🚀 Starting Trade Latency Monitor with $ENVIRONMENT configuration..."

# Load environment variables
export $(cat "$ENV_FILE" | xargs)

# Validate required environment variables
if [ -z "$PRIVATE_KEY" ] || [ "$PRIVATE_KEY" = "YOUR_MAINNET_PRIVATE_KEY_HERE" ]; then
    echo "❌ Please set a valid PRIVATE_KEY in $ENV_FILE"
    exit 1
fi

# Run the monitor
echo "📋 Configuration:"
echo "  Network: $NETWORK"
echo "  Symbol: $SYMBOL"
echo "  Size: $SIZE"
echo "  Latency Threshold: ${LATENCY_THRESHOLD}ms"
echo ""

poetry run python trade_latency_monitor.py
