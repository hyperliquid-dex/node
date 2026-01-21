#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
批量交易延迟监控测试脚本
用于运行多次测试并收集统计数据
"""

import os
import time
import json
import statistics
from datetime import datetime
from typing import List, Dict, Any

# 导入配置
from config import *

class BatchTestRunner:
    """批量测试运行器"""

    def __init__(self, test_count: int = 5, interval: int = 30):
        """
        初始化批量测试运行器
        
        Args:
            test_count: 测试次数
            interval: 测试间隔（秒）
        """
        self.test_count = test_count
        self.interval = interval
        self.results: List[Dict[str, Any]] = []
        self.start_time = None

        print(f"🚀 批量测试配置")
        print(f"📊 测试次数: {test_count}")
        print(f"⏱️  测试间隔: {interval} 秒")
        print(f"🌐 网络: {NETWORK}")
        print(f"📊 交易对: {SYMBOL}")
        print(f"📁 监控目录: {NODE_FILES_DIR}")
        print("=" * 50)

    def run_single_test(self, test_id: int) -> Dict[str, Any]:
        """
        运行单次测试
        
        Args:
            test_id: 测试ID
            
        Returns:
            测试结果字典
        """
        print(f"\n🔄 开始第 {test_id} 次测试")
        print(f"⏰ 开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

        # 模拟测试过程
        test_start = time.time()

        # 模拟发送订单
        print("📤 模拟发送订单...")
        time.sleep(1)  # 模拟网络延迟

        # 模拟等待接收
        print("📋 等待接收确认...")
        time.sleep(2)  # 模拟处理时间

        # 计算延迟（模拟）
        latency = (time.time() - test_start) * 1000
        test_end = time.time()

        # 生成测试结果
        result = {
            "test_id": test_id,
            "start_time": datetime.fromtimestamp(test_start).isoformat(),
            "end_time": datetime.fromtimestamp(test_end).isoformat(),
            "latency_ms": round(latency, 2),
            "latency_seconds": round(latency / 1000, 3),
            "status": "success" if latency < LATENCY_THRESHOLD else "warning",
            "network": NETWORK,
            "symbol": SYMBOL,
            "side": SIDE,
            "size": SIZE,
            "threshold_ms": LATENCY_THRESHOLD
        }

        # 显示结果
        if result["status"] == "success":
            print(f"✅ 测试 {test_id} 完成 - 延迟: {result['latency_ms']} 毫秒")
        else:
            print(f"⚠️  测试 {test_id} 完成 - 延迟: {result['latency_ms']} 毫秒 (超过阈值)")

        return result

    def run_batch_tests(self) -> None:
        """运行批量测试"""
        print(f"🚀 开始批量测试，共 {self.test_count} 次")
        self.start_time = time.time()

        for i in range(1, self.test_count + 1):
            try:
                result = self.run_single_test(i)
                self.results.append(result)

                # 如果不是最后一次测试，等待间隔
                if i < self.test_count:
                    print(f"⏳ 等待 {self.interval} 秒后开始下次测试...")
                    time.sleep(self.interval)

            except KeyboardInterrupt:
                print(f"\n⏹️  用户中断测试，已完成 {i-1} 次")
                break
            except Exception as e:
                print(f"❌ 测试 {i} 失败: {e}")
                error_result = {
                    "test_id": i,
                    "start_time": datetime.now().isoformat(),
                    "end_time": datetime.now().isoformat(),
                    "latency_ms": 0,
                    "latency_seconds": 0,
                    "status": "error",
                    "error": str(e),
                    "network": NETWORK,
                    "symbol": SYMBOL,
                    "side": SIDE,
                    "size": SIZE,
                    "threshold_ms": LATENCY_THRESHOLD
                }
                self.results.append(error_result)

        self.end_time = time.time()
        print(f"\n🏁 批量测试完成，共运行 {len(self.results)} 次")

    def generate_report(self) -> Dict[str, Any]:
        """生成测试报告"""
        if not self.results:
            return {"error": "没有测试结果"}

        # 过滤成功的测试结果
        successful_results = [r for r in self.results if r["status"] == "success"]
        error_results = [r for r in self.results if r["status"] == "error"]
        warning_results = [r for r in self.results if r["status"] == "warning"]

        if successful_results:
            latencies = [r["latency_ms"] for r in successful_results]
            report = {
                "summary": {
                    "total_tests": len(self.results),
                    "successful_tests": len(successful_results),
                    "error_tests": len(error_results),
                    "warning_tests": len(warning_results),
                    "success_rate": round(len(successful_results) / len(self.results) * 100, 2)
                },
                "latency_stats": {
                    "min_ms": min(latencies),
                    "max_ms": max(latencies),
                    "mean_ms": round(statistics.mean(latencies), 2),
                    "median_ms": round(statistics.median(latencies), 2),
                    "std_dev_ms": round(statistics.stdev(latencies), 2) if len(latencies) > 1 else 0
                },
                "threshold_analysis": {
                    "threshold_ms": LATENCY_THRESHOLD,
                    "below_threshold": len([l for l in latencies if l < LATENCY_THRESHOLD]),
                    "above_threshold": len([l for l in latencies if l >= LATENCY_THRESHOLD])
                },
                "test_duration": {
                    "start_time": datetime.fromtimestamp(self.start_time).isoformat() if self.start_time else None,
                    "end_time": datetime.fromtimestamp(self.end_time).isoformat() if self.end_time else None,
                    "total_duration_seconds": round(self.end_time - self.start_time, 2) if self.start_time and self.end_time else 0
                },
                "configuration": {
                    "network": NETWORK,
                    "symbol": SYMBOL,
                    "side": SIDE,
                    "size": SIZE,
                    "monitor_timeout": MONITOR_TIMEOUT,
                    "latency_threshold": LATENCY_THRESHOLD
                },
                "detailed_results": self.results
            }
        else:
            report = {
                "summary": {
                    "total_tests": len(self.results),
                    "successful_tests": 0,
                    "error_tests": len(error_results),
                    "warning_tests": len(warning_results),
                    "success_rate": 0.0
                },
                "error": "没有成功的测试结果",
                "detailed_results": self.results
            }

        return report

    def print_report(self, report: Dict[str, Any]) -> None:
        """打印测试报告"""
        print("\n" + "=" * 60)
        print("📊 批量测试报告")
        print("=" * 60)

        if "error" in report:
            print(f"❌ {report['error']}")
            return

        # 摘要信息
        summary = report["summary"]
        print(f"📈 测试摘要:")
        print(f"   总测试次数: {summary['total_tests']}")
        print(f"   成功次数: {summary['successful_tests']}")
        print(f"   失败次数: {summary['error_tests']}")
        print(f"   警告次数: {summary['warning_tests']}")
        print(f"   成功率: {summary['success_rate']}%")

        # 延迟统计
        if "latency_stats" in report:
            stats = report["latency_stats"]
            print(f"\n⏱️  延迟统计 (毫秒):")
            print(f"   最小值: {stats['min_ms']}")
            print(f"   最大值: {stats['max_ms']}")
            print(f"   平均值: {stats['mean_ms']}")
            print(f"   中位数: {stats['median_ms']}")
            print(f"   标准差: {stats['std_dev_ms']}")

        # 阈值分析
        if "threshold_analysis" in report:
            threshold = report["threshold_analysis"]
            print(f"\n🎯 阈值分析:")
            print(f"   阈值: {threshold['threshold_ms']} 毫秒")
            print(f"   低于阈值: {threshold['below_threshold']} 次")
            print(f"   高于阈值: {threshold['above_threshold']} 次")

        # 测试时长
        if "test_duration" in report:
            duration = report["test_duration"]
            print(f"\n⏰ 测试时长:")
            print(f"   开始时间: {duration['start_time']}")
            print(f"   结束时间: {duration['end_time']}")
            print(f"   总耗时: {duration['total_duration_seconds']} 秒")

        # 配置信息
        if "configuration" in report:
            config = report["configuration"]
            print(f"\n⚙️  配置信息:")
            print(f"   网络: {config['network']}")
            print(f"   交易对: {config['symbol']}")
            print(f"   交易方向: {'买入' if config['side'] == 'B' else '卖出'}")
            print(f"   交易数量: {config['size']}")
            print(f"   监控超时: {config['monitor_timeout']} 秒")
            print(f"   延迟阈值: {config['latency_threshold']} 毫秒")

        print("=" * 60)

    def save_results(self, report: Dict[str, Any]) -> None:
        """保存测试结果到文件"""
        if SAVE_RESULTS:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"batch_test_results_{timestamp}.json"

            try:
                with open(filename, 'w', encoding='utf-8') as f:
                    json.dump(report, f, indent=2, ensure_ascii=False)
                print(f"💾 测试结果已保存到: {filename}")
            except Exception as e:
                print(f"❌ 保存结果失败: {e}")

    def run(self) -> None:
        """运行完整的批量测试流程"""
        try:
            # 运行批量测试
            self.run_batch_tests()

            # 生成报告
            report = self.generate_report()

            # 打印报告
            self.print_report(report)

            # 保存结果
            self.save_results(report)

        except KeyboardInterrupt:
            print("\n⏹️  批量测试被用户中断")
        except Exception as e:
            print(f"❌ 批量测试失败: {e}")

def main():
    """主函数"""
    print("=== Hyperliquid 批量交易延迟监控测试 ===")

    # 验证配置
    if not validate_config():
        print("❌ 配置验证失败")
        return

    # 批量测试参数
    TEST_COUNT = 5      # 测试次数
    TEST_INTERVAL = 30  # 测试间隔（秒）

    # 创建并运行批量测试
    runner = BatchTestRunner(TEST_COUNT, TEST_INTERVAL)
    runner.run()

if __name__ == "__main__":
    main()
