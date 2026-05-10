#!/bin/bash

TOP_LIMIT="${1:-100}"
SLEEP_SECONDS="${2:-3}"

TCP_IN="tcp-clean.csv"
UDP_IN="udp-clean.csv"

TCP_OUT="tcp-top-ips-enriched.csv"
UDP_OUT="udp-top-ips-enriched.csv"

describe_port() {
    local port="$1"
    local svc

    svc=$(getent services "$port" 2>/dev/null | awk '{print $1}' | head -1)

    if [ -n "$svc" ]; then
        echo "$svc service"
    elif [ "$port" -ge 0 ] && [ "$port" -le 1023 ]; then
        echo "Well-known port / standard service"
    elif [ "$port" -ge 1024 ] && [ "$port" -le 49151 ]; then
        echo "Registered port / software-specific"
    elif [ "$port" -ge 49152 ] && [ "$port" -le 65535 ]; then
        echo "Dynamic / ephemeral / random"
    else
        echo "Unknown"
    fi
}

enrich_file() {
    local IN="$1"
    local OUT="$2"
    local MODE="$3"

    if [ ! -f "$IN" ]; then
        echo "Skip $MODE: file not found: $IN"
        return
    fi

    echo "source_ip,hits,country,org,top_port,port_description,protocol" > "$OUT"

    tail -n +2 "$IN" \
    | cut -d',' -f2 \
    | sort \
    | uniq -c \
    | sort -nr \
    | head -"$TOP_LIMIT" \
    | while read -r hits ip; do

        port=$(grep ",$ip," "$IN" | cut -d',' -f3 | sort | uniq -c | sort -nr | head -1 | awk '{print $2}')
        desc=$(describe_port "$port")

        geo=$(timeout 5 curl -A "Mozilla/5.0" -s "http://ip-api.com/csv/$ip?fields=country,org" 2>/dev/null)

        if [ -z "$geo" ]; then
            country="Lookup failed"
            org="Lookup failed"
        else
            country=$(echo "$geo" | cut -d',' -f1 | tr ',' ';')
            org=$(echo "$geo" | cut -d',' -f2- | tr ',' ';')
        fi

        echo "$ip,$hits,\"$country\",\"$org\",$port,\"$desc\",$MODE" >> "$OUT"

        sleep "$SLEEP_SECONDS"
    done

    echo "$MODE enriched CSV: $OUT"
}

enrich_file "$TCP_IN" "$TCP_OUT" "tcp"
enrich_file "$UDP_IN" "$UDP_OUT" "udp"
