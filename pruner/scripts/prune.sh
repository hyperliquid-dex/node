DATA_PATH="/home/hluser/hl/data"

# Delete data older than 1 days.
find "$DATA_PATH" -mindepth 1 -mtime +1 -depth -delete
