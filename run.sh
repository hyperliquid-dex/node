#!/bin/bash

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_help() {
    echo -e "${BLUE}Hyperliquid Node Management Script${NC}"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start     Start hl-node service"
    echo "  stop      Stop hl-node service"
    echo "  restart   Restart hl-node service"
    echo "  status    Show service status"
    echo "  logs      Show service logs"
    echo "  logs-f    Follow service logs"
    echo "  shell     Enter container shell"
    echo "  clean-data Clean old data files"
    echo "  clean     Clean all Docker resources"
    echo "  help      Show this help"
    echo ""
    echo "Note: Environment variables configured via config.env file"
    echo ""
    echo "Examples:"
    echo "  $0 start             # Start service"
    echo "  $0 stop              # Stop service"
    echo "  $0 logs              # Show logs"
    echo "  $0 clean             # Clean all Docker resources"
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: docker command not found${NC}"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo -e "${RED}Error: docker-compose command not found${NC}"
        exit 1
    fi
}

DOCKER_COMPOSE_CMD=""
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
else
    DOCKER_COMPOSE_CMD="docker compose"
fi


start_service() {
    echo -e "${BLUE}Starting Hyperliquid Node service...${NC}"

    # Create data directory with proper permissions
    # Use environment variable or default to ./hl-data
    DATA_DIR="${HL_DATA_DIR:-./hl-data}"
    mkdir -p "$DATA_DIR"
    chmod 755 "$DATA_DIR"
    echo -e "${YELLOW}Data directory: $DATA_DIR${NC}"

    # Start service (environment variables controlled by config.env)
    $DOCKER_COMPOSE_CMD up -d

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Service started successfully!${NC}"
        echo -e "${YELLOW}Tip: Use '$0 logs' to view logs${NC}"
        echo -e "${YELLOW}Tip: Use '$0 status' to view status${NC}"
        echo -e "${YELLOW}Tip: Environment variables controlled by config.env file${NC}"
    else
        echo -e "${RED}Service startup failed!${NC}"
        exit 1
    fi
}

stop_service() {
    echo -e "${BLUE}Stopping Hyperliquid Node service...${NC}"

    $DOCKER_COMPOSE_CMD down

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Service stopped${NC}"
    else
        echo -e "${RED}Failed to stop service!${NC}"
        exit 1
    fi
}

restart_service() {
    echo -e "${BLUE}Restarting Hyperliquid Node service...${NC}"
    stop_service
    sleep 2
    start_service
}

show_status() {
    echo -e "${BLUE}Hyperliquid Node service status:${NC}"
    echo ""

    $DOCKER_COMPOSE_CMD ps

    echo ""
    echo -e "${BLUE}Container resource usage:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
}

show_logs() {
    echo -e "${BLUE}Hyperliquid Node service logs:${NC}"
    echo ""

    $DOCKER_COMPOSE_CMD logs --tail=50
}

show_logs_follow() {
    echo -e "${BLUE}Follow Hyperliquid Node service logs (Press Ctrl+C to exit):${NC}"
    echo ""

    $DOCKER_COMPOSE_CMD logs -f
}

enter_shell() {
    echo -e "${BLUE}Entering Hyperliquid Node container...${NC}"
    echo -e "${YELLOW}Tip: Use 'exit' to leave container${NC}"
    echo ""

    docker exec -it hyperliquid-node bash
}

clean_data() {
    echo -e "${YELLOW}Warning: This will delete old data files!${NC}"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Cleaning old data...${NC}"

        # Delete data older than 7 days
        DATA_DIR="${HL_DATA_DIR:-./hl-data}"
        find "$DATA_DIR" -type f -mtime +7 -delete 2>/dev/null || true
        find "$DATA_DIR" -type d -empty -delete 2>/dev/null || true

        echo -e "${GREEN}Old data cleanup completed${NC}"
    else
        echo -e "${YELLOW}Cleanup operation cancelled${NC}"
    fi
}

clean_all() {
    echo -e "${RED}Warning: This will delete ALL Docker resources for this project!${NC}"
    echo -e "${RED}This includes:${NC}"
    echo -e "${RED}  - All containers${NC}"
    echo -e "${RED}  - All images${NC}"
    echo -e "${RED}  - All networks${NC}"
    echo -e "${RED}  - Host data directory${NC}"
    echo ""
    read -p "Are you absolutely sure you want to continue? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Cleaning all Docker resources...${NC}"

        echo "Stopping and removing containers..."
        $DOCKER_COMPOSE_CMD down --remove-orphans

        echo "Removing all images..."
        docker rmi $(docker images -q hyperliquid_node hyperliquid_pruner) 2>/dev/null || true

        echo "Removing all networks..."
        docker network rm $(docker network ls -q | grep hyperliquid) 2>/dev/null || true

        echo "Cleaning host data directory..."
        DATA_DIR="${HL_DATA_DIR:-./hl-data}"
        rm -rf "$DATA_DIR" 2>/dev/null || true

        echo -e "${GREEN}All Docker resources cleanup completed${NC}"
        echo -e "${YELLOW}Note: You may need to rebuild images on next start${NC}"
    else
        echo -e "${YELLOW}Cleanup operation cancelled${NC}"
    fi
}

main() {
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
        clean-data)
            clean_data
            ;;
        clean)
            clean_all
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

main "$@"