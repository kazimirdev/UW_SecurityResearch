
#!/bin/bash

OUT="/root/tcp-realtime.csv"
TZ_LOCAL="Europe/Warsaw"

[ -f "$OUT" ] || echo "timestamp_warsaw,source_ip,destination_port" > "$OUT"

journalctl -k -f -o short-iso | grep --line-buffered "TCP-ORIG:" | while read -r line; do
    ts_utc=$(echo "$line" | awk '{print $1}')
    ts=$(TZ="$TZ_LOCAL" date -d "$ts_utc" '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null)

    ip=$(echo "$line" | grep -oP 'SRC=\K[0-9.]+' || true)
    dport=$(echo "$line" | grep -oP 'DPT=\K[0-9]+' || true)

    if [ -n "$ts" ] && [ -n "$ip" ] && [ -n "$dport" ]; then
        echo "$ts,$ip,$dport" >> "$OUT"
    fi
done
