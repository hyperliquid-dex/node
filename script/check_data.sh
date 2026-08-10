#!/bin/bash

# Hyperliquid Node Data Check Script
# Check data file status in ~/hl/data directory of node container

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directory list to check
DATA_DIRS=("misc_events" "node_fills" "node_order_statuses" "node_trades" "replica_cmds")

# Check if container is running
check_container_running() {
    if ! docker ps --format "{{.Names}}" | grep -q "hyperliquid-node"; then
        echo -e "${RED}Error: hyperliquid-node container is not running${NC}"
        echo "Please start the service first: ./run.sh start"
        exit 1
    fi
}

# Check data status of a single directory
check_directory_data() {
    local dir_name="$1"
    local container_path="/home/hluser/hl/data/$dir_name"

    echo -e "\n${BLUE}Checking directory: $dir_name${NC}"
    echo "Container path: $container_path"

    # Check if directory exists
    if docker exec hyperliquid-node test -d "$container_path"; then
        echo -e "${GREEN}✓ Directory exists${NC}"

        # Get file count in directory
        local file_count=$(docker exec hyperliquid-node find "$container_path" -type f | wc -l)
        echo "File count: $file_count"

        if [ "$file_count" -gt 0 ]; then
            # Get total directory size
            local dir_size=$(docker exec hyperliquid-node du -sh "$container_path" | cut -f1)
            echo "Directory size: $dir_size"

            # List the latest few files
            echo "Latest files:"
            docker exec hyperliquid-node find "$container_path" -type f -printf "%T@ %p\n" | sort -nr | head -5 | while read timestamp filepath; do
                local filename=$(basename "$filepath")
                local filesize=$(docker exec hyperliquid-node stat -c "%s" "$filepath")
                local filedate=$(docker exec hyperliquid-node stat -c "%y" "$filepath")
                echo "  - $filename (${filesize} bytes, $filedate)"
            done

            # Check if there are non-empty files
            local non_empty_files=$(docker exec hyperliquid-node find "$container_path" -type f -size +0 | wc -l)
            if [ "$non_empty_files" -gt 0 ]; then
                echo -e "${GREEN}✓ Contains $non_empty_files non-empty files${NC}"
            else
                echo -e "${YELLOW}⚠ All files are empty${NC}"
            fi

        else
            echo -e "${YELLOW}⚠ No files in directory${NC}"
        fi

    else
        echo -e "${RED}✗ Directory does not exist${NC}"
    fi
}

# Check overall status of data directories
check_overall_data_status() {
    echo -e "\n${BLUE}=== Overall Data Directory Status ===${NC}"

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

    echo "Total files: $total_files"
    echo "Total data size: $(numfmt --to=iec $total_size)"
    echo "Missing directories: $missing_dirs"

    if [ "$total_files" -gt 0 ]; then
        echo -e "${GREEN}✓ Data directories contain data files${NC}"
    else
        echo -e "${RED}✗ No data files in data directories${NC}"
    fi
}

# Check real-time updates of data files
check_data_updates() {
    echo -e "\n${BLUE}=== Checking Data File Real-time Updates ===${NC}"

    for dir in "${DATA_DIRS[@]}"; do
        local container_path="/home/hluser/hl/data/$dir"
        if docker exec hyperliquid-node test -d "$container_path"; then
            local recent_files=$(docker exec hyperliquid-node find "$container_path" -type f -mmin -5 | wc -l)
            if [ "$recent_files" -gt 0 ]; then
                echo -e "${GREEN}✓ $dir: $recent_files files updated in last 5 minutes${NC}"
            else
                echo -e "${YELLOW}⚠ $dir: No files updated in last 5 minutes${NC}"
            fi
        fi
    done
}

# Show help information
show_help() {
    echo "Hyperliquid Node Data Check Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -s, --summary  Show summary only"
    echo "  -v, --verbose  Show detailed information"
    echo ""
    echo "Examples:"
    echo "  $0              # Full check"
    echo "  $0 -s           # Summary only"
    echo "  $0 -v           # Verbose mode"
}

# Main function
main() {
    local verbose=false
    local summary_only=false

    # Parse command line arguments
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
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    echo -e "${BLUE}Hyperliquid Node Data Check Script${NC}"
    echo "Check time: $(date)"
    echo "Container name: hyperliquid-node"

    # Check container status
    check_container_running

    if [ "$summary_only" = true ]; then
        # Show summary only
        check_overall_data_status
    else
        # Full check
        for dir in "${DATA_DIRS[@]}"; do
            check_directory_data "$dir"
        done

        check_overall_data_status

        if [ "$verbose" = true ]; then
            check_data_updates
        fi
    fi

    echo -e "\n${GREEN}Data check completed!${NC}"
}

# Run main function
main "$@"
