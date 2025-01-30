Here's a simple README for your script:

---

# Validator Monitoring Script

This script monitors a specified validator on the Hyperliquid network (testnet or mainnet) and sends alerts to a Telegram channel if the validator is not active or is jailed.

## Prerequisites

-  **Bash**: Ensure you have a Unix-like environment with Bash installed.
-  **Curl**: The script uses `curl` to make HTTP requests.
-  **JQ**: A lightweight and flexible command-line JSON processor. Install it using your package manager (e.g., `apt-get install jq` on Debian-based systems).

## Setup

1. **Make the Script Executable**:

   ```bash
   chmod +x /path/to/your/script.sh
   ```

2. **Crontab Setup**:
   To run the script every 15 minutes, add it to your crontab:

   ```bash
   crontab -e
   ```

   Add the following line, replacing placeholders with your actual values:

   ```bash
   */15 * * * * /path/to/your/script.sh -t your_telegram_api_token -c your_telegram_chat_id -v your_target_validator_address -n testnet >> /path/to/your/logfile.log 2>&1
   ```

## Usage

Run the script with the following options:

```bash
./script.sh -t TELEGRAM_API_TOKEN -c TELEGRAM_CHAT_ID -v TARGET_VALIDATOR -n NETWORK
```

-  `-t TELEGRAM_API_TOKEN`: Your Telegram bot API token.
-  `-c TELEGRAM_CHAT_ID`: The chat ID of the Telegram channel or user to send alerts to.
-  `-v TARGET_VALIDATOR`: The address of the validator to monitor.
-  `-n NETWORK`: Specify the network to use: `testnet` or `mainnet`.

## Example

```bash
./script.sh -t 123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11 -c -987654321 -v 0xd5f63fd075529c9fea3bd051c9926e4e080bd4aa -n testnet
```

## Logging

The script logs its activities with timestamps to the console. If you have set up the cron job, it will also log to the specified file, helping you monitor its execution and troubleshoot any issues.

## License

This script is provided "as-is" without any warranties. Use it at your own risk.

---

### Notes:
-  Ensure all paths and values are correctly set in the crontab and when running the script manually.
-  Modify the script as needed to fit your specific requirements or environment settings.


