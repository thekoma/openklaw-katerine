#!/bin/bash
# security_watchdog.sh - Detection of unauthorized outbound connections
# This script is saved in /home/node/.openclaw/workspace to survive container nuclearization.

# Whitelist of safe subnets/IPs (RegEx)
# 127.0.0.1 (localhost)
# 10.240. / 10.241. (internal container network)
# 149.154. / 91.108. (Telegram API range)
# 192.168. (Home Network)
# 142.251. (Google/Gemini API)
# 172. (Docker/Internal range)
# 185.199.108.0/22 (GitHub Pages/CDN)
WHITELIST='127\.0\.0\.1|10\.24[01]\.|192\.168\.|149\.154\.|91\.108\.|142\.251\.|172\.|185\.199\.(108|109|110|111)\.'

# Function to convert little-endian hex IP from /proc/net/tcp to dotted decimal
hex_to_ip() {
    local hex=$1
    local a=$((16#${hex:6:2}))
    local b=$((16#${hex:4:2}))
    local c=$((16#${hex:2:2}))
    local d=$((16#${hex:0:2}))
    echo "$a.$b.$c.$d"
}

# Scan established connections from /proc/net/tcp (state 01)
ALERTS=""
while read -r line; do
    # Match lines with state 01 (ESTABLISHED)
    if [[ $line =~ [0-9]+:\ ([0-9A-F]+):([0-9A-F]+)\ ([0-9A-F]+):([0-9A-F]+)\ 01 ]]; then
        REM_HEX=${BASH_REMATCH[3]}
        REM_IP=$(hex_to_ip $REM_HEX)
        REM_PORT=$((16#${BASH_REMATCH[4]}))
        
        if [[ ! $REM_IP =~ $WHITELIST ]]; then
            ALERTS+="[ALERT] Connection to $REM_IP:$REM_PORT detected!\n"
        fi
    fi
done < /proc/net/tcp

if [ ! -z "$ALERTS" ]; then
    echo -e "$ALERTS"
    exit 1
fi

exit 0
