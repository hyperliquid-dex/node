#!/bin/bash

# Function to log messages
log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message"
}

# Function to display usage
usage() {
    echo "Usage: $0 -t TELEGRAM_API_TOKEN -c TELEGRAM_CHAT_ID -v TARGET_VALIDATOR -n NETWORK"
    echo "  -n NETWORK  Specify the network to use: 'testnet' or 'mainnet'"
    exit 1
}

# Parse command-line arguments
while getopts ":t:c:v:n:" opt; do
    case $opt in
        t) TELEGRAM_API_TOKEN="$OPTARG"
        ;;
        c) TELEGRAM_CHAT_ID="$OPTARG"
        ;;
        v) TARGET_VALIDATOR="$OPTARG"
        ;;
        n) NETWORK="$OPTARG"
        ;;
        *) usage
        ;;
    esac
done

# Check if all required arguments are provided
if [ -z "$TELEGRAM_API_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ] || [ -z "$TARGET_VALIDATOR" ] || [ -z "$NETWORK" ]; then
    usage
fi

# Set API URL based on the network
case $NETWORK in
    testnet)
        API_URL="https://api.hyperliquid-testnet.xyz/info"
        ;;
    mainnet)
        API_URL="https://api.hyperliquid.xyz/info"
        ;;
    *)
        echo "Invalid network specified. Use 'testnet' or 'mainnet'."
        exit 1
        ;;
esac

# Payload for the API request
PAYLOAD='{ "type": "validatorSummaries"}'

log "Starting script with target validator: $TARGET_VALIDATOR on $NETWORK using API URL: $API_URL"

# Fetch the JSON data from the API
response=$(curl -s -X POST --header "Content-Type: application/json" --data "$PAYLOAD" "$API_URL")

# Clean the response to remove any control characters
clean_response=$(echo "$response" | tr -d '\000-\037')

# Convert the target validator address to lowercase for comparison
target_validator=$(echo "$TARGET_VALIDATOR" | tr '[:upper:]' '[:lower:]')

# Check if the response contains the desired validator with the specific conditions
validator_status=$(echo "$clean_response" | jq -r --arg target_validator "$target_validator" '
    .[] | select(.validator | ascii_downcase == $target_validator) | {isActive, isJailed}
')

is_active=$(echo "$validator_status" | jq -r '.isActive')
is_jailed=$(echo "$validator_status" | jq -r '.isJailed')

log "Validator status - isActive: $is_active, isJailed: $is_jailed"

# Check the conditions and send an alert if necessary
if [ "$is_active" != "true" ] || [ "$is_jailed" != "false" ]; then
    message="Alert: Validator $TARGET_VALIDATOR is not active or is jailed."
    log "$message"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_API_TOKEN/sendMessage" \
         -d chat_id="$TELEGRAM_CHAT_ID" \
         -d text="$message"
fi

log "Script execution completed."

