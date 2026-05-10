#!/bin/bash

IN="${1:-udp-realtime.csv}"
CLEAN="udp-clean.csv"
SUMMARY="udp-analysis.txt"

if [ ! -f "$IN" ]; then
    echo "File not found: $IN"
    exit 1
fi

echo "timestamp,source_ip,destination_port" > "$CLEAN"

awk '
BEGIN { pending="" }

# normal line: timestamp,ip,port
/^[0-9]{4}-[0-9]{2}-[0-9]{2} .*CEST,[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+,[0-9]+$/ {
    print
    next
}

# broken line start: timestamp,52
/^[0-9]{4}-[0-9]{2}-[0-9]{2} .*CEST,[0-9]+$/ {
    pending=$0
    next
}

# broken line continuation: ip,port
pending != "" && /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+,[0-9]+$/ {
    split(pending, a, ",")
    print a[1] "," $0
    pending=""
    next
}
' "$IN" | sort -u >> "$CLEAN"

{
echo "===== UDP TRAFFIC ANALYSIS ====="
echo "Generated: $(date)"
echo

echo "Total unique UDP rows:"
tail -n +2 "$CLEAN" | wc -l
echo

echo "Top source IPs:"
tail -n +2 "$CLEAN" | cut -d',' -f2 | sort | uniq -c | sort -nr | head -100
echo

echo "Top destination ports:"
tail -n +2 "$CLEAN" | cut -d',' -f3 | sort | uniq -c | sort -nr | head -100
echo

echo "Likely amplification / discovery ports:"
tail -n +2 "$CLEAN" | awk -F',' '$3 ~ /^(53|123|161|1900|5353|5355|11211|389|500|4500)$/ {print $3}' \
| sort | uniq -c | sort -nr
echo

echo "Non-standard UDP ports:"
tail -n +2 "$CLEAN" | awk -F',' '$3 !~ /^(53|67|68|69|123|137|138|161|162|500|514|520|1900|4500|5353|5355|11211)$/ {print $3}' \
| sort | uniq -c | sort -nr | head -100
echo

echo "UDP by hour:"
tail -n +2 "$CLEAN" | cut -d',' -f1 | awk '{print $2}' | cut -d: -f1 | sort | uniq -c
} > "$SUMMARY"

echo "Clean CSV: $CLEAN"
echo "Summary: $SUMMARY"
