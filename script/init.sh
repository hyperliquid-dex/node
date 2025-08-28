#!/bin/bash

# Hyperliquid Node initialization script

set -e

echo "Initializing Hyperliquid Node environment..."

# Download and import GPG public key
echo "Downloading and importing GPG public key..."
curl -o /home/hluser/pub_key.asc "${PUB_KEY_URL:-https://raw.githubusercontent.com/hyperliquid-dex/node/refs/heads/main/pub_key.asc}"
gpg --import /home/hluser/pub_key.asc

# Download both Mainnet and Testnet binaries for flexibility
echo "Downloading Mainnet binary..."
curl -o /home/hluser/hl-visor-mainnet https://binaries.hyperliquid.xyz/Mainnet/hl-visor
curl -o /home/hluser/hl-visor-mainnet.asc https://binaries.hyperliquid.xyz/Mainnet/hl-visor.asc

echo "Downloading Testnet binary..."
curl -o /home/hluser/hl-visor-testnet https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor
curl -o /home/hluser/hl-visor-testnet.asc https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor.asc

# Verify both binaries
echo "Verifying Mainnet binary..."
gpg --verify /home/hluser/hl-visor-mainnet.asc /home/hluser/hl-visor-mainnet

echo "Verifying Testnet binary..."
gpg --verify /home/hluser/hl-visor-testnet.asc /home/hluser/hl-visor-testnet

# Set permissions
chmod +x /home/hluser/hl-visor-mainnet
chmod +x /home/hluser/hl-visor-testnet

# Note: Binary verification and permissions already set above

# Note: Configuration files are now created dynamically in startup.sh
echo "Configuration files will be created at runtime based on environment variables"