#!/bin/bash
# /opt/honeypot/honeypot-backend.sh
# Full-port TCP/UDP honeypot backend for Debian 13
# Opens listeners on high-value ports, keeps sockets active, logs interactions.

LOG_DIR="/var/log/honeypot"
TCP_LOG="$LOG_DIR/backend-tcp.log"
UDP_LOG="$LOG_DIR/backend-udp.log"

mkdir -p "$LOG_DIR"
touch "$TCP_LOG" "$UDP_LOG"

# Common TCP honeypot ports
TCP_PORTS=(
22 23 21 25 53 80 110 123 135 139 143 443 445
993 995 1433 1521 3306 3389 5432 5900 6379 8080
2222 2323 5433 5434 5435 8443 8888 9999
)

# Common UDP honeypot ports
UDP_PORTS=(
53 67 68 69 123 137 138 161 389 443 500
1194 1434 1900 3478 3702 4500 5060
5353 5355 11211
)

start_tcp_listener() {
    local port="$1"
    while true; do
        nc -lvkp "$port" >> "$TCP_LOG" 2>&1
        sleep 1
    done
}

start_udp_listener() {
    local port="$1"
    while true; do
        nc -lukp "$port" >> "$UDP_LOG" 2>&1
        sleep 1
    done
}

echo "[*] Starting TCP honeypot listeners..."
for port in "${TCP_PORTS[@]}"; do
    start_tcp_listener "$port" &
done

echo "[*] Starting UDP honeypot listeners..."
for port in "${UDP_PORTS[@]}"; do
    start_udp_listener "$port" &
done

echo "[*] Honeypot backend active."
wait
