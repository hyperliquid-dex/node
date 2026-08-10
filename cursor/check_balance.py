#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Account Balance Checker Script
Check account balance and positions on Hyperliquid
"""

import os
import sys
import json
import logging
from typing import Dict, List, Optional
from pathlib import Path
from datetime import datetime

# Add current directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    from hyperliquid.exchange import Exchange
    from eth_account import Account
    print("✅ Successfully imported Hyperliquid SDK")
except ImportError as e:
    print(f"❌ Missing dependency: {e}")
    print("Please run: poetry install")
    sys.exit(1)

# Import configuration
from config import *

class BalanceChecker:
    """Account balance checker"""

    def __init__(self):
        self.hyperliquid = None
        self.wallet_address = None

        # Setup logging
        self._setup_logging()

        # Initialize Hyperliquid connection
        self._init_hyperliquid()

        # Derive address from private key
        self._derive_address()

    def _setup_logging(self):
        """Setup logging configuration"""
        # Use a writable directory for log files
        log_file = f"/home/hluser/hl/data/balance_check_{NETWORK}.log"
        
        logging.basicConfig(
            level=getattr(logging, LOG_LEVEL),
            format=LOG_FORMAT,
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)

    def _init_hyperliquid(self):
        """Initialize Hyperliquid connection"""
        try:
            # Create wallet account
            wallet = Account.from_key(PRIVATE_KEY)

            # Select correct configuration based on network type
            if NETWORK.lower() == 'testnet':
                base_url = "https://api.hyperliquid-testnet.xyz"
            else:
                base_url = "https://api.hyperliquid.xyz"

            self.hyperliquid = Exchange(
                wallet=wallet,
                base_url=base_url
            )

            self.logger.info(f"✅ Successfully connected to Hyperliquid {NETWORK}")

        except Exception as e:
            self.logger.error(f"❌ Failed to connect to Hyperliquid: {e}")
            raise

    def _derive_address(self):
        """Derive wallet address from private key"""
        try:
            account = Account.from_key(PRIVATE_KEY)
            self.wallet_address = account.address
            self.logger.info(f"Wallet address: {self.wallet_address}")
        except Exception as e:
            self.logger.error(f"❌ Failed to derive address: {e}")
            raise

    def get_user_state(self) -> Optional[Dict]:
        """Get user account state"""
        try:
            # Get user state from Hyperliquid using Info class
            from hyperliquid.info import Info

            # Create Info instance with the same base URL
            if NETWORK.lower() == 'testnet':
                base_url = "https://api.hyperliquid-testnet.xyz"
            else:
                base_url = "https://api.hyperliquid.xyz"

            info = Info(base_url)
            user_state = info.user_state(self.wallet_address)
            return user_state
        except Exception as e:
            self.logger.error(f"❌ Failed to get user state: {e}")
            return None

    def get_asset_info(self) -> Optional[Dict]:
        """Get asset information"""
        try:
            # Get asset info from Hyperliquid using Info class
            from hyperliquid.info import Info

            if NETWORK.lower() == 'testnet':
                base_url = "https://api.hyperliquid-testnet.xyz"
            else:
                base_url = "https://api.hyperliquid.xyz"

            info = Info(base_url)
            asset_info = info.meta_and_asset_ctxs()
            return asset_info
        except Exception as e:
            self.logger.error(f"❌ Failed to get asset info: {e}")
            return None

    def get_open_orders(self) -> Optional[List]:
        """Get open orders"""
        try:
            # Get open orders from Hyperliquid using Info class
            from hyperliquid.info import Info

            if NETWORK.lower() == 'testnet':
                base_url = "https://api.hyperliquid-testnet.xyz"
            else:
                base_url = "https://api.hyperliquid.xyz"

            info = Info(base_url)
            open_orders = info.frontend_open_orders(self.wallet_address)
            return open_orders
        except Exception as e:
            self.logger.error(f"❌ Failed to get open orders: {e}")
            return None

    def format_balance_info(self, user_state: Dict) -> str:
        """Format balance information for display"""
        if not user_state:
            return "❌ No user state data available"

        try:
            # Extract relevant information based on Hyperliquid API structure
            margin_summary = user_state.get('marginSummary', {})
            cross_margin_summary = user_state.get('crossMarginSummary', {})
            asset_positions = user_state.get('assetPositions', [])
            withdrawable = user_state.get('withdrawable', '0')

            # Format margin summary
            margin_info = f"""
💰 **Margin Summary:**
  - Account Value: ${margin_summary.get('accountValue', 'N/A')}
  - Total Margin Used: ${margin_summary.get('totalMarginUsed', 'N/A')}
  - Total Net Position: ${margin_summary.get('totalNtlPos', 'N/A')}
  - Total Raw USD: ${margin_summary.get('totalRawUsd', 'N/A')}
  - Withdrawable: ${withdrawable}
"""

            # Format cross margin summary if available
            if cross_margin_summary:
                cross_margin_info = f"""
🔄 **Cross Margin Summary:**
  - Account Value: ${cross_margin_summary.get('accountValue', 'N/A')}
  - Total Margin Used: ${cross_margin_summary.get('totalMarginUsed', 'N/A')}
  - Total Net Position: ${cross_margin_summary.get('totalNtlPos', 'N/A')}
  - Total Raw USD: ${cross_margin_summary.get('totalRawUsd', 'N/A')}
"""
                margin_info += cross_margin_info

            # Format asset positions
            positions_info = "\n📊 **Asset Positions:**\n"
            if asset_positions:
                for pos in asset_positions:
                    if 'position' in pos:
                        position_data = pos['position']
                        coin = position_data.get('coin', 'Unknown')
                        size = position_data.get('szi', '0')
                        entry_price = position_data.get('entryPx', '0')
                        position_value = position_data.get('positionValue', '0')
                        unrealized_pnl = position_data.get('unrealizedPnl', '0')
                        margin_used = position_data.get('marginUsed', '0')
                        leverage = position_data.get('leverage', {})
                        leverage_type = leverage.get('type', 'N/A')
                        leverage_value = leverage.get('value', 'N/A')

                        positions_info += f"""
  **{coin}:**
    - Position Size: {size}
    - Entry Price: ${entry_price}
    - Position Value: ${position_value}
    - Unrealized PnL: ${unrealized_pnl}
    - Margin Used: ${margin_used}
    - Leverage: {leverage_type} {leverage_value}x
"""
            else:
                positions_info += "  No open positions\n"

            return margin_info + positions_info

        except Exception as e:
            return f"❌ Error formatting balance info: {e}"

    def check_balance(self):
        """Main method to check account balance"""
        try:
            self.logger.info("🔍 Checking account balance...")

            # Get user state
            user_state = self.get_user_state()
            if user_state:
                self.logger.info("✅ Successfully retrieved user state")

                # Display formatted balance info
                balance_info = self.format_balance_info(user_state)
                print(balance_info)

                # Save detailed info to file
                self.save_balance_report(user_state)

            else:
                self.logger.error("❌ Failed to retrieve user state")

        except Exception as e:
            self.logger.error(f"❌ Error checking balance: {e}")

    def save_balance_report(self, user_state: Dict):
        """Save detailed balance report to file"""
        try:
            # Use writable directory for report files
            report_file = f"/home/hluser/hl/data/balance_report_{NETWORK}.json"
            
            # Add metadata
            report_data = {
                "timestamp": str(datetime.now()),
                "network": NETWORK,
                "wallet_address": self.wallet_address,
                "user_state": user_state
            }
            
            # Save to file
            with open(report_file, 'w', encoding='utf-8') as f:
                json.dump(report_data, f, indent=2, ensure_ascii=False)
            
            self.logger.info(f"💾 Balance report saved to: {report_file}")
            
        except Exception as e:
            self.logger.error(f"❌ Failed to save balance report: {e}")

def main():
    """Main function"""
    try:
        print(f"🌐 Checking balance on {NETWORK} network...")
        print(f"📁 Configuration file: {os.path.basename(__file__)}")
        print("=" * 50)

        checker = BalanceChecker()
        checker.check_balance()

        print("=" * 50)
        print("✅ Balance check completed")

    except Exception as e:
        print(f"❌ Error in main: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
