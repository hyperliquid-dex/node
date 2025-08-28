#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Trade Latency Monitor Script
Monitor time delay from sending transaction to Node container receiving record
"""

import os
import sys
import time
import json
import logging
import asyncio
import re
from datetime import datetime
from typing import Optional, Dict, List, Tuple
from pathlib import Path

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

try:
    from watchdog.observers import Observer
    from watchdog.events import FileSystemEventHandler
except ImportError as e:
    print(f"❌ Missing dependency: {e}")
    print("Please run: pip install watchdog")
    sys.exit(1)

# Import configuration
from config import *

class FileMonitor(FileSystemEventHandler):
    """File system monitor"""

    def __init__(self, target_address: str, callback):
        self.target_address = target_address.lower()
        self.callback = callback
        self.found = False

    def on_created(self, event):
        if not event.is_directory:
            self._check_file(event.src_path)

    def on_modified(self, event):
        if not event.is_directory:
            self._check_file(event.src_path)

    def _check_file(self, file_path: str):
        """Check if file contains target address"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                if self.target_address in content.lower():
                    logging.info(f"Address match found in file {file_path}")
                    self.found = True
                    self.callback(file_path, content)
        except Exception as e:
            logging.warning(f"Failed to read file {file_path}: {e}")

class TradeLatencyMonitor:
    """Trade latency monitor"""

    def __init__(self):
        self.hyperliquid = None
        self.wallet_address = None
        self.monitor_observer = None
        self.received_time = None
        self.received_file = None
        self.received_content = None

        # Setup logging
        self._setup_logging()

        # Initialize Hyperliquid connection
        self._init_hyperliquid()

        # Derive address from private key
        self._derive_address()

    def _setup_logging(self):
        """Setup logging configuration"""
        logging.basicConfig(
            level=getattr(logging, LOG_LEVEL),
            format=LOG_FORMAT,
            handlers=[
                logging.FileHandler(LOG_FILE),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)

    def _init_hyperliquid(self):
        """Initialize Hyperliquid connection"""
        try:
            # Initialize using hyperliquid-python-sdk
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
            # Generate wallet address using private key
            from eth_account import Account
            account = Account.from_key(PRIVATE_KEY)
            self.wallet_address = account.address
            self.logger.info(f"Wallet address: {self.wallet_address}")
        except ImportError:
            # If eth_account package is not available, use simple hash method
            import hashlib
            import hmac
            from eth_keys import keys

            try:
                # Try using eth_keys
                pk = keys.PrivateKey(bytes.fromhex(PRIVATE_KEY.replace("0x", "")))
                self.wallet_address = pk.public_key.to_checksum_address()
                self.logger.info(f"Wallet address: {self.wallet_address}")
            except ImportError:
                # Final fallback: use simple hash
                self.logger.warning("⚠️ Cannot import eth_account or eth_keys, using fallback address generation method")
                hash_obj = hashlib.sha256(PRIVATE_KEY.encode())
                address_bytes = hash_obj.digest()[:20]
                self.wallet_address = "0x" + address_bytes.hex()
                self.logger.info(f"Wallet address: {self.wallet_address}")
        except Exception as e:
            self.logger.error(f"❌ Failed to derive address: {e}")
            raise

    def send_market_order(self) -> Tuple[str, float]:
        """发送市价单并返回交易哈希和发送时间"""
        try:
            # 记录发送时间
            send_time = time.time()
            send_time_str = datetime.fromtimestamp(send_time).strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]

            self.logger.info(f"📤 发送 {SYMBOL} 市价单...")
            self.logger.info(f"发送时间: {send_time_str}")

            # 构建订单参数
            order_params = {
                'symbol': SYMBOL,
                'type': 'market',
                'side': 'buy' if SIDE == 'B' else 'sell',
                'amount': SIZE,
                'params': {
                    'reduceOnly': False
                }
            }

            self.logger.info(f"交易参数: {order_params}")

                                    # 使用 Hyperliquid API 发送真实订单
            try:
                # 构建订单参数
                side = 'buy' if SIDE == 'B' else 'sell'

                self.logger.info(f"发送 {SYMBOL} {side} 市价单，数量: {SIZE}")

                # 使用 market_open 方法发送市价单
                # 参考: /home/lsl/github/hyperliquid/hyperliquid-python-sdk/examples/basic_market_order.py
                is_buy = (side == 'buy')
                response = self.hyperliquid.market_open(
                    SYMBOL,  # 第一个参数：交易对名称
                    is_buy,  # 第二个参数：是否买入（布尔值）
                    SIZE,  # 第三个参数：交易数量
                    None,  # 第四个参数：设为 None
                    0.1,  # 第五个参数：滑点
                )

                if response and hasattr(response, 'hash'):
                    tx_hash = response.hash
                    self.logger.info(f"✅ 交易发送成功，哈希: {tx_hash}")
                elif response and hasattr(response, 'id'):
                    tx_hash = response.id
                    self.logger.info(f"✅ 交易发送成功，订单ID: {tx_hash}")
                else:
                    # 尝试从响应中提取订单ID
                    tx_hash = self._extract_order_id_from_response(response)
                    if tx_hash:
                        self.logger.info(f"✅ 从响应中提取到订单ID (oid): {tx_hash}")
                    else:
                        # 检查是否是订单被拒绝的情况
                        if self._is_order_rejected(response):
                            self.logger.error("❌ 订单被拒绝，无法继续监控")
                            return None, send_time

                        self.logger.warning(
                            f"⚠️ 无法从响应中提取订单ID (oid): {response}"
                        )
                        # 使用钱包地址作为标识符
                        tx_hash = f"addr_{self.wallet_address[:10]}"
                        self.logger.info(f"✅ 使用钱包地址标识符: {tx_hash}")

            except Exception as e:
                self.logger.error(f"❌ 发送真实订单失败: {e}")
                # 如果真实API失败，回退到模拟模式
                self.logger.warning("⚠️ 回退到模拟模式")
                tx_hash = f"addr_{self.wallet_address[:10]}"
                self.logger.info(f"✅ 模拟交易发送成功，标识符: {tx_hash}")
            return tx_hash, send_time

        except Exception as e:
            self.logger.error(f"❌ 发送交易失败: {e}")
            raise

    def start_file_monitoring(self):
        """开始文件监控"""
        try:
            # 确保监控目录存在
            Path(NODE_FILES_DIR).mkdir(parents=True, exist_ok=True)

            # 创建文件监控器
            event_handler = FileMonitor(self.wallet_address, self._on_address_found)
            self.monitor_observer = Observer()
            self.monitor_observer.schedule(event_handler, NODE_FILES_DIR, recursive=True)

            # 启动监控
            self.monitor_observer.start()

            # 等待监控器完全启动
            time.sleep(0.1)

            self.logger.info(f"🔍 开始监控目录: {NODE_FILES_DIR}")
            self.logger.info(f"目标地址: {self.wallet_address}")

        except Exception as e:
            self.logger.error(f"❌ 启动文件监控失败: {e}")
            raise

    def _is_order_rejected(self, response) -> bool:
        """检查订单是否被拒绝"""
        try:
            if isinstance(response, dict) and "response" in response:
                response_data = response["response"]
                if isinstance(response_data, dict) and "data" in response_data:
                    data = response_data["data"]
                    if (
                        "statuses" in data
                        and isinstance(data["statuses"], list)
                        and len(data["statuses"]) > 0
                    ):
                        status = data["statuses"][0]
                        return isinstance(status, dict) and "error" in status
            return False
        except Exception:
            return False

    def _extract_order_id_from_response(self, response) -> Optional[str]:
        """从API响应中提取订单ID"""
        try:
            if not response:
                return None

            # 尝试从响应中提取订单ID
            if hasattr(response, "response"):
                response_data = response.response
            elif isinstance(response, dict) and "response" in response:
                response_data = response["response"]
            else:
                response_data = response

            # 查找嵌套的 oid 字段
            if isinstance(response_data, dict):
                # 查找嵌套的 oid 字段
                if "data" in response_data and isinstance(response_data["data"], dict):
                    data = response_data["data"]
                    if (
                        "statuses" in data
                        and isinstance(data["statuses"], list)
                        and len(data["statuses"]) > 0
                    ):
                        status = data["statuses"][0]
                        if isinstance(status, dict):
                            # 检查是否有错误
                            if "error" in status:
                                error_msg = status["error"]
                                self.logger.error(f"❌ 订单被拒绝: {error_msg}")
                                # 如果是金额不足，提供建议
                                if "minimum value" in error_msg.lower():
                                    self.logger.warning(
                                        "💡 建议：增加交易数量以满足最低价值要求"
                                    )
                                return None

                            # 查找 filled.oid 或直接 oid
                            if "filled" in status and isinstance(
                                status["filled"], dict
                            ):
                                if "oid" in status["filled"]:
                                    return str(status["filled"]["oid"])
                            elif "oid" in status:
                                return str(status["oid"])

            return None

        except Exception as e:
            self.logger.warning(f"提取订单ID时出错: {e}")
            return None

    def _on_address_found(self, file_path: str, content: str):
        """地址匹配回调函数"""
        self.received_time = time.time()
        self.received_file = file_path
        self.received_content = content

        received_time_str = datetime.fromtimestamp(self.received_time).strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]
        self.logger.info(f"📥 地址匹配成功！")
        self.logger.info(f"接收时间: {received_time_str}")
        self.logger.info(f"文件路径: {file_path}")

    def wait_for_receipt(self, timeout: int = None) -> bool:
        """等待接收确认"""
        if timeout is None:
            timeout = MONITOR_TIMEOUT

        start_time = time.time()
        self.logger.info(f"⏳ 开始等待接收确认，超时时间: {timeout}秒")

        while time.time() - start_time < timeout:
            if self.received_time:
                elapsed = time.time() - start_time
                self.logger.info(f"✅ 收到确认，等待时间: {elapsed:.2f}秒")
                return True

            # 每10秒记录一次等待状态
            elapsed = time.time() - start_time
            if int(elapsed) % 10 == 0 and elapsed > 0:
                self.logger.info(f"⏳ 等待中... 已等待 {elapsed:.1f}秒")

            time.sleep(MONITOR_INTERVAL)

        self.logger.warning(f"⏰ 监控超时 ({timeout}秒)")
        return False

    def calculate_latency(self, send_time: float) -> Optional[float]:
        """计算延迟时间"""
        if not self.received_time:
            return None

        latency_seconds = self.received_time - send_time
        latency_ms = latency_seconds * 1000

        return latency_seconds, latency_ms

    def generate_report(self, tx_hash: str, send_time: float) -> Dict:
        """生成延迟报告"""
        latency_info = self.calculate_latency(send_time)

        if not latency_info:
            return {
                "status": "failed",
                "error": "未收到确认"
            }

        latency_seconds, latency_ms = latency_info

        send_time_str = datetime.fromtimestamp(send_time).strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]
        received_time_str = datetime.fromtimestamp(self.received_time).strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]

        report = {
            "status": "success",
            "tx_hash": tx_hash,
            "send_time": send_time_str,
            "received_time": received_time_str,
            "latency_seconds": round(latency_seconds, 3),
            "latency_ms": round(latency_ms, 3),
            "received_file": self.received_file,
            "wallet_address": self.wallet_address,
            "symbol": SYMBOL,
            "side": SIDE,
            "size": SIZE,
            "network": NETWORK,
            "timestamp": datetime.now().isoformat()
        }

        return report

    def print_report(self, report: Dict):
        """打印延迟报告"""
        print("\n" + "="*50)
        print("=== 交易延迟监控报告 ===")
        print("="*50)

        if report["status"] == "success":
            print(f"✅ 状态: 成功")
            print(f"🔗 交易哈希: {report['tx_hash']}")
            print(f"📤 发送时间: {report['send_time']}")
            print(f"📥 接收时间: {report['received_time']}")
            print(f"⏱️  延迟时间: {report['latency_seconds']} 秒 ({report['latency_ms']} 毫秒)")
            print(f"📁 接收文件: {report['received_file']}")
            print(f"👛 钱包地址: {report['wallet_address']}")
            print(f"💱 交易对: {report['symbol']}")
            print(f"📊 交易方向: {'买入' if report['side'] == 'B' else '卖出'}")
            print(f"📈 交易数量: {report['size']}")
            print(f"🌐 网络: {report['network']}")

            # 检查是否超过告警阈值
            if report['latency_ms'] > LATENCY_THRESHOLD:
                print(f"⚠️  告警: 延迟超过阈值 {LATENCY_THRESHOLD}ms")
        else:
            print(f"❌ 状态: 失败")
            print(f"❌ 错误: {report['error']}")

        print("="*50)

    def save_results(self, report: Dict):
        """保存结果到文件"""
        if not SAVE_RESULTS:
            return

        try:
            results_file = Path(RESULTS_FILE)

            # 读取现有结果
            existing_results = []
            if results_file.exists():
                with open(results_file, 'r', encoding='utf-8') as f:
                    existing_results = json.load(f)

            # 添加新结果
            existing_results.append(report)

            # 保存结果
            with open(results_file, 'w', encoding='utf-8') as f:
                json.dump(existing_results, f, indent=2, ensure_ascii=False)

            self.logger.info(f"💾 结果已保存到: {RESULTS_FILE}")

        except Exception as e:
            self.logger.error(f"❌ 保存结果失败: {e}")

    def cleanup(self):
        """清理资源"""
        if self.monitor_observer:
            self.monitor_observer.stop()
            self.monitor_observer.join()
            self.logger.info("🔍 文件监控已停止")

    def run_single_test(self) -> bool:
        """运行单次测试"""
        try:
            # 1. 启动文件监控（异步）
            self.logger.info("🔍 启动文件监控...")
            self.start_file_monitoring()

            # 给监控系统一点时间初始化
            time.sleep(0.5)

            # 2. 发送交易
            self.logger.info("📤 准备发送交易...")
            tx_hash, send_time = self.send_market_order()

            # 3. 等待接收确认
            if not self.wait_for_receipt():
                self.logger.error("❌ 等待接收确认超时")
                return False

            # 4. 生成报告
            report = self.generate_report(tx_hash, send_time)

            # 5. 打印报告
            self.print_report(report)

            # 6. 保存结果
            self.save_results(report)

            return report["status"] == "success"

        except Exception as e:
            self.logger.error(f"❌ 测试运行失败: {e}")
            return False
        finally:
            self.cleanup()

def main():
    """主函数"""
    print("🚀 启动交易延迟监控脚本")

    try:
        # 验证配置
        if not validate_config():
            print("❌ 配置验证失败")
            return False

        # 创建监控器
        monitor = TradeLatencyMonitor()

        # 运行测试
        success = monitor.run_single_test()

        if success:
            print("✅ 测试完成")
            return True
        else:
            print("❌ 测试失败")
            return False

    except KeyboardInterrupt:
        print("\n⏹️  用户中断")
        return False
    except Exception as e:
        print(f"❌ 程序异常: {e}")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
