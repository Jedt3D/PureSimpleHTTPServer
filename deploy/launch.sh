#!/bin/bash
# launch.sh — start multiple PureSimpleHTTPServer instances
#
# Usage:
#   ./launch.sh [COUNT] [OPTIONS]
#   ./launch.sh 4                          # 4 instances on ports 8080-8083
#   ./launch.sh 4 --root /var/www          # with custom root
#   ./launch.sh stop                       # stop all running instances
#
# Instances start on consecutive ports from 8080.
# PID files are written to /tmp/pshs_<port>.pid.

set -e

BINARY="${BINARY:-./PureSimpleHTTPServer}"
BASE_PORT="${BASE_PORT:-8080}"
PID_DIR="${PID_DIR:-/tmp}"

usage() {
    echo "Usage: $0 [COUNT] [SERVER_OPTIONS...]"
    echo "       $0 stop"
    echo ""
    echo "  COUNT   Number of instances to start (default: 4)"
    echo "  stop    Stop all running instances"
    echo ""
    echo "Environment variables:"
    echo "  BINARY     Path to server binary (default: ./PureSimpleHTTPServer)"
    echo "  BASE_PORT  First port number (default: 8080)"
    echo "  PID_DIR    Directory for PID files (default: /tmp)"
    echo ""
    echo "Examples:"
    echo "  $0 4 --root /var/www --log /var/log/pshs/access.log"
    echo "  $0 2 --root ./wwwroot --browse"
    echo "  $0 stop"
}

stop_instances() {
    local stopped=0
    for pidfile in "$PID_DIR"/pshs_*.pid; do
        [ -f "$pidfile" ] || continue
        local pid
        pid=$(cat "$pidfile" 2>/dev/null)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            local port
            port=$(basename "$pidfile" .pid | sed 's/pshs_//')
            echo "Stopping instance on port $port (PID $pid)"
            kill "$pid"
            stopped=$((stopped + 1))
        fi
        rm -f "$pidfile"
    done
    if [ "$stopped" -eq 0 ]; then
        echo "No running instances found"
    else
        echo "Stopped $stopped instance(s)"
    fi
}

# Handle stop command
if [ "${1:-}" = "stop" ]; then
    stop_instances
    exit 0
fi

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
fi

# Parse instance count (first arg if numeric, default 4)
COUNT=4
if [ -n "${1:-}" ] && [ "$1" -eq "$1" ] 2>/dev/null; then
    COUNT="$1"
    shift
fi

# Remaining args are passed to each server instance
SERVER_OPTS="$*"

if [ ! -x "$BINARY" ]; then
    echo "ERROR: Server binary not found or not executable: $BINARY"
    echo "       Compile first: pbcompiler -cl -t -o PureSimpleHTTPServer src/main.pb"
    exit 1
fi

echo "Starting $COUNT instance(s) on ports $BASE_PORT-$((BASE_PORT + COUNT - 1))..."
echo ""

for i in $(seq 0 $((COUNT - 1))); do
    PORT=$((BASE_PORT + i))
    PIDFILE="$PID_DIR/pshs_$PORT.pid"

    # shellcheck disable=SC2086
    "$BINARY" --port "$PORT" --pid-file "$PIDFILE" $SERVER_OPTS &

    echo "  Instance $((i + 1)): port $PORT (PID $!)"
done

echo ""
echo "All instances started."
echo "Stop with: $0 stop"
