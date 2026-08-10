#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Trade Latency Monitor Configuration File
"""

import os
from typing import Optional

# ==================== Network Configuration ====================
# Support mainnet and testnet
# Read network type from environment variable
NETWORK = os.getenv("NETWORK", "testnet")  # Read from environment variable
IS_TESTNET = NETWORK.lower() == "testnet"

# Set RPC URL based on network type
if IS_TESTNET:
    RPC_URL = "https://api.hyperliquid-testnet.xyz"
    print("🌐 Using testnet configuration")
else:
    RPC_URL = "https://api.hyperliquid.xyz"
    print("🌐 Using mainnet configuration")

# ==================== Private Key Configuration ====================
# Read private key from environment variable
PRIVATE_KEY = os.getenv("PRIVATE_KEY")
if not PRIVATE_KEY:
    raise ValueError("Please set PRIVATE_KEY environment variable")

# Standardize private key format (ensure 0x prefix)
if not PRIVATE_KEY.startswith("0x"):
    PRIVATE_KEY = "0x" + PRIVATE_KEY

# ==================== Trading Configuration ====================
# Use SOL trading pair
SYMBOL = os.getenv("SYMBOL", "SOL")  # Trading pair
SIDE = os.getenv("SIDE", "B")  # B for buy, A for sell
SIZE = float(os.getenv("SIZE", "0.1"))  # Trading amount
print(f"📊 Trading configuration: {SYMBOL}, amount {SIZE}")

LIMIT_PRICE = None  # 市价单设为 None

# ==================== Monitoring Configuration ====================
# Node container file directory
NODE_FILES_DIR = "/home/hluser/hl/data"
print("📁 Monitoring directory: /home/hluser/hl/data")

# Monitor timeout (seconds)
MONITOR_TIMEOUT = int(os.getenv("MONITOR_TIMEOUT", "300"))

# File monitoring polling interval (seconds)
MONITOR_INTERVAL = float(os.getenv("MONITOR_INTERVAL", "0.1"))

# 地址匹配模式
ADDRESS_PATTERNS = [
    r"0x[a-fA-F0-9]{40}",  # 标准以太坊地址
    r"[a-fA-F0-9]{40}",    # 不带0x前缀的地址
]

# ==================== 日志配置 ====================
LOG_LEVEL = "INFO"
LOG_FILE = "/tmp/trade_latency.log"
LOG_FORMAT = "%(asctime)s - %(levelname)s - %(message)s"

# ==================== 重试配置 ====================
MAX_RETRIES = 3
RETRY_DELAY = 1  # 秒

# ==================== Alert Configuration ====================
# Latency threshold (milliseconds)
LATENCY_THRESHOLD = int(
    os.getenv("LATENCY_THRESHOLD", "10000" if IS_TESTNET else "5000")
)
print(
    f"⏱️ {'Testnet' if IS_TESTNET else 'Mainnet'} latency threshold: {LATENCY_THRESHOLD}ms"
)

# 告警配置
ALERT_ENABLED = True
ALERT_EMAIL = "phenix3443@gmail.com"  # 可选：配置告警邮箱

# ==================== Data Save Configuration ====================
SAVE_RESULTS = True
RESULTS_FILE = "/home/hluser/hl/data/latency_results.json"

# ==================== 验证配置 ====================
def validate_config() -> bool:
    """验证配置参数的有效性"""
    errors = []

    # 检查私钥格式
    # 私钥可以是64位十六进制（不带0x）或66位（带0x）
    clean_key = PRIVATE_KEY.replace("0x", "")
    if len(clean_key) != 64:
        errors.append("私钥长度不正确，应为64位十六进制字符")

    # 检查私钥是否为有效的十六进制
    try:
        int(clean_key, 16)
    except ValueError:
        errors.append("私钥必须为有效的十六进制字符串")

    # 检查交易参数
    if SIDE not in ["A", "B"]:
        errors.append("SIDE必须是A或B")

    if SIZE <= 0:
        errors.append("SIZE必须大于0")

    if errors:
        print("配置验证失败:")
        for error in errors:
            print(f"  - {error}")
        return False

    return True

# ==================== 配置信息 ====================
def print_config():
    """打印当前配置信息"""
    print("=== 交易延迟监控配置 ===")
    print(f"网络: {NETWORK}")
    print(f"RPC URL: {RPC_URL}")
    print(f"交易对: {SYMBOL}")
    print(f"交易方向: {'买入' if SIDE == 'B' else '卖出'}")
    print(f"交易数量: {SIZE}")
    print(f"监控目录: {NODE_FILES_DIR}")
    print(f"监控超时: {MONITOR_TIMEOUT}秒")
    print(f"日志级别: {LOG_LEVEL}")
    print(f"告警阈值: {LATENCY_THRESHOLD}毫秒")
    print("========================")

if __name__ == "__main__":
    # 验证配置
    if validate_config():
        print_config()
        print("✅ 配置验证通过")
    else:
        print("❌ 配置验证失败")
        exit(1)
