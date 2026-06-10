#!/bin/zsh
# Record a Metal System Trace for one HOLD config and reduce it to
# app-attributed GPU ms/frame. Launches the profile binary DIRECTLY (env
# propagation proven) and attaches xctrace — xctrace --launch resolves via
# LaunchServices and can pick a stale app copy.
# Usage: gpu_trace.sh <configId> <appBinary>
set -e
CONFIG=$1
BIN=$2
DIR=$(dirname "$0")
TRACE="$DIR/_tmp_${CONFIG}.trace"
XML="$DIR/_tmp_${CONFIG}.xml"
APPLOG="$DIR/_tmp_${CONFIG}.applog"

rm -rf "$TRACE" "$XML" "$APPLOG"
BENCH_HOLD=$CONFIG "$BIN" > "$APPLOG" 2>&1 &
APP_PID=$!
trap "kill $APP_PID 2>/dev/null || true" EXIT
sleep 6  # window up + past first-frame allocations

xcrun xctrace record --template 'Metal System Trace' --time-limit 10s \
  --attach $APP_PID --no-prompt --output "$TRACE" > /dev/null 2>&1

kill $APP_PID 2>/dev/null || true
trap - EXIT

xcrun xctrace export --input "$TRACE" \
  --xpath '/trace-toc/run[@number="1"]/data/table[@schema="metal-gpu-intervals"]' \
  > "$XML" 2>/dev/null

RESULT=$(python3 "$DIR/parse_trace.py" "$XML")
HOLD=$(grep -o '\[hold\].*' "$APPLOG" 2>/dev/null | tail -1)
rm -rf "$TRACE" "$XML" "$APPLOG"
echo "$CONFIG $RESULT ${HOLD:-no-hold-line}"
