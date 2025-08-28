#!/bin/bash

# Hyperliquid Node Data Check Script
# 检查 node 容器中 ~/hl/data 目录下的数据文件状态

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查的目录列表
DATA_DIRS=("misc_events" "node_fills" "node_order_statuses" "node_trades" "replica_cmds")

# 检查容器是否运行
check_container_running() {
    if ! docker ps --format "{{.Names}}" | grep -q "hyperliquid-node"; then
        echo -e "${RED}错误: hyperliquid-node 容器未运行${NC}"
        echo "请先启动服务: ./run.sh start"
        exit 1
    fi
}

# 检查单个目录的数据状态
check_directory_data() {
    local dir_name="$1"
    local container_path="/home/hluser/hl/data/$dir_name"

    echo -e "\n${BLUE}检查目录: $dir_name${NC}"
    echo "容器路径: $container_path"

    # 检查目录是否存在
    if docker exec hyperliquid-node test -d "$container_path"; then
        echo -e "${GREEN}✓ 目录存在${NC}"

        # 获取目录中的文件数量
        local file_count=$(docker exec hyperliquid-node find "$container_path" -type f | wc -l)
        echo "文件数量: $file_count"

        if [ "$file_count" -gt 0 ]; then
            # 获取目录总大小
            local dir_size=$(docker exec hyperliquid-node du -sh "$container_path" | cut -f1)
            echo "目录大小: $dir_size"

            # 列出最新的几个文件
            echo "最新文件:"
            docker exec hyperliquid-node find "$container_path" -type f -printf "%T@ %p\n" | sort -nr | head -5 | while read timestamp filepath; do
                local filename=$(basename "$filepath")
                local filesize=$(docker exec hyperliquid-node stat -c "%s" "$filepath")
                local filedate=$(docker exec hyperliquid-node stat -c "%y" "$filepath")
                echo "  - $filename (${filesize} bytes, $filedate)"
            done

            # 检查是否有非空文件
            local non_empty_files=$(docker exec hyperliquid-node find "$container_path" -type f -size +0 | wc -l)
            if [ "$non_empty_files" -gt 0 ]; then
                echo -e "${GREEN}✓ 包含 $non_empty_files 个非空文件${NC}"
            else
                echo -e "${YELLOW}⚠ 所有文件都是空的${NC}"
            fi

        else
            echo -e "${YELLOW}⚠ 目录中没有文件${NC}"
        fi

    else
        echo -e "${RED}✗ 目录不存在${NC}"
    fi
}

# 检查数据目录的整体状态
check_overall_data_status() {
    echo -e "\n${BLUE}=== 数据目录整体状态 ===${NC}"

    local total_files=0
    local total_size=0
    local missing_dirs=0

    for dir in "${DATA_DIRS[@]}"; do
        local container_path="/home/hluser/hl/data/$dir"
        if docker exec hyperliquid-node test -d "$container_path"; then
            local file_count=$(docker exec hyperliquid-node find "$container_path" -type f | wc -l)
            total_files=$((total_files + file_count))

            if [ "$file_count" -gt 0 ]; then
                local dir_size_bytes=$(docker exec hyperliquid-node du -sb "$container_path" | cut -f1)
                total_size=$((total_size + dir_size_bytes))
            fi
        else
            missing_dirs=$((missing_dirs + 1))
        fi
    done

    echo "总文件数: $total_files"
    echo "总数据大小: $(numfmt --to=iec $total_size)"
    echo "缺失目录数: $missing_dirs"

    if [ "$total_files" -gt 0 ]; then
        echo -e "${GREEN}✓ 数据目录包含数据文件${NC}"
    else
        echo -e "${RED}✗ 数据目录中没有数据文件${NC}"
    fi
}

# 检查数据文件的实时更新
check_data_updates() {
    echo -e "\n${BLUE}=== 检查数据文件实时更新 ===${NC}"

    for dir in "${DATA_DIRS[@]}"; do
        local container_path="/home/hluser/hl/data/$dir"
        if docker exec hyperliquid-node test -d "$container_path"; then
            local recent_files=$(docker exec hyperliquid-node find "$container_path" -type f -mmin -5 | wc -l)
            if [ "$recent_files" -gt 0 ]; then
                echo -e "${GREEN}✓ $dir: 最近5分钟内有 $recent_files 个文件更新${NC}"
            else
                echo -e "${YELLOW}⚠ $dir: 最近5分钟内没有文件更新${NC}"
            fi
        fi
    done
}

# 显示帮助信息
show_help() {
    echo "Hyperliquid Node 数据检查脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -s, --summary  只显示摘要信息"
    echo "  -v, --verbose  显示详细信息"
    echo ""
    echo "示例:"
    echo "  $0              # 完整检查"
    echo "  $0 -s           # 只显示摘要"
    echo "  $0 -v           # 详细模式"
}

# 主函数
main() {
    local verbose=false
    local summary_only=false

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -s|--summary)
                summary_only=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            *)
                echo "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done

    echo -e "${BLUE}Hyperliquid Node 数据检查脚本${NC}"
    echo "检查时间: $(date)"
    echo "容器名称: hyperliquid-node"

    # 检查容器状态
    check_container_running

    if [ "$summary_only" = true ]; then
        # 只显示摘要
        check_overall_data_status
    else
        # 完整检查
        for dir in "${DATA_DIRS[@]}"; do
            check_directory_data "$dir"
        done

        check_overall_data_status

        if [ "$verbose" = true ]; then
            check_data_updates
        fi
    fi

    echo -e "\n${GREEN}数据检查完成!${NC}"
}

# 运行主函数
main "$@"
