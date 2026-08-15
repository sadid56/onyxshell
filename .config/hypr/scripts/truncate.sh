#!/bin/bash

if [ "$SWAYNC_APP_NAME" = "swaync-truncated" ]; then
    exit 0
fi

LIMIT=110

if [ ${#SWAYNC_BODY} -gt $LIMIT ]; then
    # Truncate the body text and add ellipsis
    TRUNCATED="${SWAYNC_BODY:0:$LIMIT}..."
    
    sleep 0.02
    swaync-client --close-latest
    
    # Re-send the truncated notification
    notify-send -a "swaync-truncated" -u "${SWAYNC_URGENCY,,}" "$SWAYNC_SUMMARY" "$TRUNCATED"
fi
