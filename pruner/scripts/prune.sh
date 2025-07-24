#!/bin/bash

# Configuration via environment variables with defaults
DATA_PATH="${DATA_PATH:-/home/hluser/hl/data}"
PRUNE_DAYS="${PRUNE_DAYS:-2}"
PRUNE_EXCLUDES="${PRUNE_EXCLUDES:-visor_child_stderr}"

# Parse comma-separated excludes into array
IFS=',' read -ra EXCLUDES <<< "$PRUNE_EXCLUDES"

# Log startup and configuration for debugging
echo "$(date): Prune script started" >> /proc/1/fd/1
echo "$(date): Configuration - DATA_PATH: $DATA_PATH, PRUNE_DAYS: $PRUNE_DAYS, EXCLUDES: ${EXCLUDES[*]}" >> /proc/1/fd/1

# Check if data directory exists
if [ ! -d "$DATA_PATH" ]; then
    echo "$(date): Error: Data directory $DATA_PATH does not exist." >> /proc/1/fd/1
    exit 1
fi

echo "$(date): Starting pruning process at $(date)" >> /proc/1/fd/1

# Get directory size before pruning
size_before=$(du -sh "$DATA_PATH" | cut -f1)
files_before=$(find "$DATA_PATH" -type f | wc -l)
echo "$(date): Size before pruning: $size_before with $files_before files" >> /proc/1/fd/1

# Build the exclusion part of the find command
EXCLUDE_EXPR=""
for name in "${EXCLUDES[@]}"; do
    EXCLUDE_EXPR+=" ! -name \"$name\""
done

# Convert days to minutes for find command
MINUTES=$((60*24*PRUNE_DAYS))
eval "find \"$DATA_PATH\" -mindepth 1 -depth -mmin +$MINUTES -type f $EXCLUDE_EXPR -delete"

# Get directory size after pruning
size_after=$(du -sh "$DATA_PATH" | cut -f1)
files_after=$(find "$DATA_PATH" -type f | wc -l)
echo "$(date): Size after pruning: $size_after with $files_after files" >> /proc/1/fd/1
echo "$(date): Pruning completed. Reduced from $size_before to $size_after ($(($files_before - $files_after)) files removed)." >> /proc/1/fd/1
