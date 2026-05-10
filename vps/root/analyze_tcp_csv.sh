#!/bin/bash

IN="${1:-tcp-realtime.csv}"
CLEAN="tcp-clean.csv"
SUMMARY="tcp-analysis.txt"

if [ ! -f "$IN" ]; then
    echo "File not found: $IN"
    exit 1
fi

# Keep header + remove exact duplicates + remove localhost
{
    head -n 1 "$IN"
    tail -n +2 "$IN" | grep -v '^.*127\.0\.0\.1,' | sort -u
} > "$CLEAN"

{
echo "===== TCP TRAFFIC ANALYSIS ====="
echo "Generated: $(date)"
echo

echo "Total unique TCP rows:"
tail -n +2 "$CLEAN" | wc -l
echo

echo "Top source IPs:"
tail -n +2 "$CLEAN" | cut -d',' -f2 | sort | uniq -c | sort -nr | head -100
echo

echo "Top destination ports:"
tail -n +2 "$CLEAN" | cut -d',' -f3 | sort | uniq -c | sort -nr | head -100
echo

echo "Common attack ports:"
tail -n +2 "$CLEAN" | awk -F',' '$3 ~ /^(21|22|23|25|53|80|110|123|135|139|143|443|445|993|995|1433|1521|3306|3389|5432|5900|6379|8080)$/ {print $3}' \
| sort | uniq -c | sort -nr
echo

echo "Non-standard TCP ports:"
tail -n +2 "$CLEAN" | awk -F',' '$3 !~ /^(21|22|23|25|53|80|110|123|135|139|143|443|445|993|995|1433|1521|3306|3389|5432|5900|6379|8080)$/ {print $3}' \
| sort | uniq -c | sort -nr | head -30
echo

echo "TCP by hour:"
tail -n +2 "$CLEAN" | cut -d',' -f1 | awk '{print $2}' | cut -d: -f1 | sort | uniq -c
echo

echo "Top repeated scanners:"
tail -n +2 "$IN" | grep -v '^.*127\.0\.0\.1,' | cut -d',' -f2 | sort | uniq -c | sort -nr | head -100
} > "$SUMMARY"

echo "Clean CSV: $CLEAN"
echo "Summary: $SUMMARY"
