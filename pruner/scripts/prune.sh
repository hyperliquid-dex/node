#!/bin/bash
DATA_PATH="/home/hluser/hl/data"
# Path to write logs to, defaults to Docker logs
LOG_PATH="/proc/1/fd/1"

# Folders to exclude from pruning
# Example: EXCLUDES=("visor_child_stderr" "rate_limited_ips" "node_logs")
EXCLUDES=("visor_child_stderr")

# Log startup for debugging
echo "$(date): Prune script started" >> $LOG_PATH

# Check if data directory exists
if [ ! -d "$DATA_PATH" ]; then
    echo "$(date): Error: Data directory $DATA_PATH does not exist." >> $LOG_PATH
    exit 1
fi

echo "$(date): Starting pruning process at $(date)" >> $LOG_PATH

# Get directory size before pruning
size_before=$(du -sh "$DATA_PATH" | cut -f1)
files_before=$(find "$DATA_PATH" -type f | wc -l)
echo "$(date): Size before pruning: $size_before with $files_before files" >> $LOG_PATH

# Build the -prune arguments for excluding directories
PRUNE_ARGS=()
for dir in "${EXCLUDES[@]}"; do
    PRUNE_ARGS+=(-path "*/$dir" -prune -o)
done

# Delete data older than 48 hours = 60 minutes * 48 hours
HOURS=$((60*48))
find "$DATA_PATH" -mindepth 1 "${PRUNE_ARGS[@]}" -type f -mmin +$HOURS -exec rm {} +

# Get directory size after pruning
size_after=$(du -sh "$DATA_PATH" | cut -f1)
files_after=$(find "$DATA_PATH" -type f | wc -l)
echo "$(date): Size after pruning: $size_after with $files_after files" >> $LOG_PATH
echo "$(date): Pruning completed. Reduced from $size_before to $size_after ($(($files_before - $files_after)) files removed)." >> $LOG_PATH
