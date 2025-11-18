#!/bin/bash
DATA_PATH="/home/hluser/hl/data/node_fills/hourly"
S3_BUCKET="${S3_BUCKET:-s3://defi-app-hyperliquid-node-data}"
# Log startup for debugging
echo "$(date): S3 sync script started" >> /proc/1/fd/1

# Check if data directory exists
if [ ! -d "$DATA_PATH" ]; then
    echo "$(date): Error: Data directory $DATA_PATH does not exist." >> /proc/1/fd/1
    exit 1
fi

echo "$(date): Starting S3 sync for hourly data" >> /proc/1/fd/1

# Find files modified in the last hour (60 minutes) and sync to S3
# Using -mmin -60 to get files modified in the last 60 minutes
FILES=$(find "$DATA_PATH" -type f -mmin -60)

if [ -z "$FILES" ]; then
    echo "$(date): No files modified in the last hour, skipping sync" >> /proc/1/fd/1
    exit 0
fi

# Count files to sync
file_count=$(echo "$FILES" | wc -l)
echo "$(date): Found $file_count files modified in the last hour" >> /proc/1/fd/1

# Create a temporary file list
TEMP_FILE=$(mktemp)
echo "$FILES" > "$TEMP_FILE"

# Sync files to S3 using aws s3 sync with --files-from
# We'll use rsync-style approach with aws s3 cp in a loop
synced=0
failed=0

while IFS= read -r file; do
    # Get relative path from DATA_PATH
    rel_path="${file#$DATA_PATH/}"
    
    # Compress file with lz4
    compressed_file="${file}.lz4"
    if ! lz4 -q "$file" "$compressed_file"; then
        ((failed++))
        echo "$(date): Failed to compress: $file" >> /proc/1/fd/1
        continue
    fi
    
    # Upload compressed file to S3
    if aws s3 cp "$compressed_file" "$S3_BUCKET/${rel_path}.lz4" --only-show-errors 2>> /proc/1/fd/2; then
        ((synced++))
        # Remove compressed file after successful upload
        rm "$compressed_file"
    else
        ((failed++))
        echo "$(date): Failed to sync: $file" >> /proc/1/fd/1
        rm "$compressed_file"
    fi
done < "$TEMP_FILE"

rm "$TEMP_FILE"

echo "$(date): S3 sync completed. Synced: $synced files, Failed: $failed files" >> /proc/1/fd/1

