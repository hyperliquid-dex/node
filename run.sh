#!/bin/bash

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

       # 显示帮助信息
       show_help() {
           echo -e "${BLUE}Hyperliquid Node 管理脚本${NC}"
           echo ""
           echo "用法: $0 [命令]"
           echo ""
           echo "命令:"
           echo "  start     启动 hl-node 服务"
           echo "  stop      停止 hl-node 服务"
           echo "  restart   重启 hl-node 服务"
           echo "  status    查看服务状态"
           echo "  logs      查看服务日志"
           echo "  logs-f    实时查看服务日志"
           echo "  shell     进入容器 shell"
           echo "  data      查看数据目录"
           echo "  clean     清理旧数据"
           echo "  help      显示此帮助信息"
           echo ""
           echo "注意: 网络类型通过 config.env 文件配置"
           echo ""
           echo "示例:"
           echo "  $0 start             # 启动服务"
           echo "  $0 stop              # 停止服务"
           echo "  $0 logs              # 查看日志"
       }

# 检查 docker 和 docker-compose 是否可用
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}错误: 未找到 docker 命令${NC}"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo -e "${RED}错误: 未找到 docker-compose 命令${NC}"
        exit 1
    fi
}

# Build startup command with all parameters
build_startup_command() {
    local cmd=""

    # Add optional flags based on config.env
    if [ "${WRITE_TRADES:-true}" = "true" ]; then
        cmd="$cmd --write-trades"
    fi

    if [ "${WRITE_FILLS:-true}" = "true" ]; then
        cmd="$cmd --write-fills"
    fi

    if [ "${WRITE_ORDER_STATUSES:-true}" = "true" ]; then
        cmd="$cmd --write-order-statuses"
    fi

    if [ "${WRITE_MISC_EVENTS:-true}" = "true" ]; then
        cmd="$cmd --write-misc-events"
    fi

    if [ "${SERVE_ETH_RPC:-true}" = "true" ]; then
        cmd="$cmd --serve-eth-rpc"
    fi

    if [ "${SERVE_INFO:-true}" = "true" ]; then
        cmd="$cmd --serve-info"
    fi

    cmd="$cmd --replica-cmds-style ${REPLICA_CMDS_STYLE:-actions}"

    echo "$cmd"
}

# Start service
start_service() {
    echo -e "${BLUE}Starting Hyperliquid Node service...${NC}"

    # Create data directory
    mkdir -p ~/hl/data

    # Build startup command and export as environment variable
    export HL_STARTUP_ARGS=$(build_startup_command)
    echo -e "${YELLOW}Startup arguments: $HL_STARTUP_ARGS${NC}"

    # Start service (network type controlled by config.env)
    if command -v docker-compose &> /dev/null; then
        docker-compose up -d
    else
        docker compose up -d
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Service started successfully!${NC}"
        echo -e "${YELLOW}Tip: Use '$0 logs' to view logs${NC}"
        echo -e "${YELLOW}Tip: Use '$0 status' to view status${NC}"
        echo -e "${YELLOW}Tip: Network type controlled by config.env file${NC}"
    else
        echo -e "${RED}Service startup failed!${NC}"
        exit 1
    fi
}

# Stop service
stop_service() {
    echo -e "${BLUE}Stopping Hyperliquid Node service...${NC}"

    if command -v docker-compose &> /dev/null; then
        docker-compose down
    else
        docker compose down
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Service stopped${NC}"
    else
        echo -e "${RED}Failed to stop service!${NC}"
        exit 1
    fi
}

# Restart service
restart_service() {
    echo -e "${BLUE}Restarting Hyperliquid Node service...${NC}"
    stop_service
    sleep 2
    start_service
}

# Show service status
show_status() {
    echo -e "${BLUE}Hyperliquid Node service status:${NC}"
    echo ""

    if command -v docker-compose &> /dev/null; then
        docker-compose ps
    else
        docker compose ps
    fi

    echo ""
    echo -e "${BLUE}Container resource usage:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# 查看日志
show_logs() {
    echo -e "${BLUE}Hyperliquid Node 服务日志:${NC}"
    echo ""

    if command -v docker-compose &> /dev/null; then
        docker-compose logs --tail=50
    else
        docker compose logs --tail=50
    fi
}

# 实时查看日志
show_logs_follow() {
    echo -e "${BLUE}实时查看 Hyperliquid Node 服务日志 (按 Ctrl+C 退出):${NC}"
    echo ""

    if command -v docker-compose &> /dev/null; then
        docker-compose logs -f
    else
        docker compose logs -f
    fi
}

# Enter container shell
enter_shell() {
    echo -e "${BLUE}Entering Hyperliquid Node container...${NC}"
    echo -e "${YELLOW}Tip: Use 'exit' to leave container${NC}"
    echo ""

    docker exec -it hyperliquid-node bash
}

# Show data directory
show_data() {
    echo -e "${BLUE}Hyperliquid Node data directory:${NC}"
    echo ""

    if [ -d ~/hl/data ]; then
        echo -e "${GREEN}Host data directory (~/hl/data):${NC}"
        ls -la ~/hl/data
        echo ""
    else
        echo -e "${YELLOW}Host data directory does not exist${NC}"
    fi

    echo -e "${GREEN}Container data directory:${NC}"
    docker exec hyperliquid-node ls -la /home/hluser/hl/data
}

# Clean old data
clean_data() {
    echo -e "${YELLOW}Warning: This will delete old data files!${NC}"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Cleaning old data...${NC}"

        # Delete data older than 7 days
        find ~/hl/data -type f -mtime +7 -delete 2>/dev/null || true
        find ~/hl/data -type d -empty -delete 2>/dev/null || true

        echo -e "${GREEN}Old data cleanup completed${NC}"
    else
        echo -e "${YELLOW}Cleanup operation cancelled${NC}"
    fi
}

# Main function
main() {
    # Check docker environment
    check_docker

    case "${1:-help}" in
        start)
            start_service
            ;;
        stop)
            stop_service
            ;;
        restart)
            restart_service
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        logs-f)
            show_logs_follow
            ;;
        shell)
            enter_shell
            ;;
        data)
            show_data
            ;;
        clean)
            clean_data
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown command: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"