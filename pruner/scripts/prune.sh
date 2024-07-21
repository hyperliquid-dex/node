DATA_PATH="/home/hluser/hl/data"

# Delete data older than 2 days.
find "$DATA_PATH" -mindepth 1 -depth -mtime +2 -delete

