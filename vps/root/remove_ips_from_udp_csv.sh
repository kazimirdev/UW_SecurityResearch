#!/bin/bash

CSV="${1:-udp-realtime.csv}"
IP_LIST="${2:-ips_to_remove.txt}"
TMP="${CSV}.tmp"

if [ ! -f "$CSV" ]; then
    echo "CSV file not found: $CSV"
    exit 1
fi

if [ ! -f "$IP_LIST" ]; then
    echo "IP list file not found: $IP_LIST"
    exit 1
fi

# Keep header, remove matching IP rows
{
    head -n 1 "$CSV"
    tail -n +2 "$CSV" | grep -v -F -f "$IP_LIST"
} > "$TMP"

mv "$TMP" "$CSV"

echo "Done. Removed matching IPs from $CSV"
