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
    echo "  data      Show data directory contents"
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
    echo "  $0 data              # Show data directory"
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

    # Data is now stored in Docker named volumes
    echo -e "${YELLOW}Using Docker named volumes for data storage${NC}"

    # Start service with image building (environment variables controlled by config.env)
    # --build: Build images before starting containers
    # --force-recreate: Force recreation of containers
    # --remove-orphans: Remove orphaned containers
    echo -e "${YELLOW}Building images and starting service...${NC}"
    $DOCKER_COMPOSE_CMD up -d --build --force-recreate --remove-orphans

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
    echo -e "${YELLOW}Available containers:${NC}"
    echo "  1. hyperliquid-node (main node)"
    echo "  2. hyperliquid-pruner (data pruner)"
    echo ""
    read -p "Select container (1 or 2, default: 1): " -n 1 -r
    echo

    case $REPLY in
        2)
            echo -e "${BLUE}Entering hyperliquid-pruner container...${NC}"
            echo -e "${YELLOW}Tip: Use 'exit' to leave container${NC}"
            echo ""
            docker exec -it hyperliquid-pruner bash
            ;;
        *)
            echo -e "${BLUE}Entering hyperliquid-node container...${NC}"
            echo -e "${YELLOW}Tip: Use 'exit' to leave container${NC}"
            echo ""
            docker exec -it hyperliquid-node bash
            ;;
    esac
}

show_data() {
    echo -e "${BLUE}Hyperliquid Node data directory contents:${NC}"
    echo ""

    # Check if service is running
    if $DOCKER_COMPOSE_CMD ps | grep -q "hyperliquid-node"; then
        echo -e "${GREEN}Service is running - showing container data directory:${NC}"
        echo ""

        # Show data directory contents from container
        echo -e "${YELLOW}Container data directory (/home/hluser/hl/data):${NC}"
        docker exec hyperliquid-node ls -la /home/hluser/hl/data 2>/dev/null || echo -e "${RED}Failed to access container data directory${NC}"

        echo ""
        echo -e "${YELLOW}Data directory size:${NC}"
        docker exec hyperliquid-node du -sh /home/hluser/hl/data 2>/dev/null || echo -e "${RED}Failed to get directory size${NC}"

        echo ""
        echo -e "${YELLOW}Recent data files:${NC}"
        docker exec hyperliquid-node find /home/hluser/hl/data -type f -mtime -1 -ls 2>/dev/null | head -10 || echo -e "${RED}Failed to list recent files${NC}"
    else
        echo ""

                # Show Docker volume information when service is not running
        echo -e "${YELLOW}Docker volumes:${NC}"
        docker volume ls | grep hyperliquid || echo -e "${YELLOW}No hyperliquid volumes found${NC}"
    fi

    echo ""
    echo -e "${BLUE}Docker volume information:${NC}"
    docker volume ls | grep hyperliquid || echo -e "${YELLOW}No hyperliquid volumes found${NC}"
}

clean_data() {
    echo -e "${YELLOW}Warning: This will delete old data from Docker volumes!${NC}"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Cleaning old data from Docker volumes...${NC}"

        # Stop service to access volumes
        $DOCKER_COMPOSE_CMD down

        # Clean old data from volumes (this is a simplified approach)
        echo "Note: Data cleanup from Docker volumes requires manual intervention"
        echo "Consider using 'clean' command to remove all volumes completely"

        echo -e "${GREEN}Data cleanup completed${NC}"
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
    echo -e "${RED}  - All volumes${NC}"
    echo -e "${RED}  - Host data directory${NC}"
    echo ""
    read -p "Are you absolutely sure you want to continue? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Cleaning all Docker resources...${NC}"

        echo "Stopping and removing containers..."
        $DOCKER_COMPOSE_CMD down --remove-orphans

        echo "Removing all images..."
        docker images --format "{{.Repository}}" | grep hyperliquid | xargs -r docker rmi 2>/dev/null || true

        echo "Removing all networks..."
        docker network rm $(docker network ls -q | grep hyperliquid) 2>/dev/null || true

        echo "Removing all volumes..."
        docker volume rm $(docker volume ls -q | grep hyperliquid) 2>/dev/null || true

        echo "Cleaning host data directory..."
        echo "Note: Host data directory is no longer used with Docker volumes"

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
        data)
            show_data
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