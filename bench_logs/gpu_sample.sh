#!/bin/zsh
# Samples whole-GPU utilization while one bench config runs in HOLD mode.
# At vsync-locked fps, GPU ms/frame ≈ util% × (1000 / fps).
# Usage: gpu_sample.sh <configId> <appBinary>   (configId=IDLE → ambient only)
# Output: "<configId> gpu_util_mean=<pct> gpu_util_p90=<pct> <last [hold] line>"
set -e
CONFIG=$1
BIN=$2
APPLOG=$(mktemp)

if [[ "$CONFIG" != "IDLE" ]]; then
  BENCH_HOLD=$CONFIG "$BIN" > "$APPLOG" 2>&1 &
  APP_PID=$!
  trap "kill $APP_PID 2>/dev/null || true" EXIT
  sleep 11  # warmup + first [hold] telemetry line (600 frames)
fi

samples=()
for i in {1..20}; do
  u=$(ioreg -r -d 1 -c IOAccelerator 2>/dev/null \
      | grep -oE '"Device Utilization %"=[0-9]+' | head -1 | grep -oE '[0-9]+$')
  samples+=($u)
  sleep 0.5
done

if [[ "$CONFIG" != "IDLE" ]]; then
  kill $APP_PID 2>/dev/null || true
  trap - EXIT
  sleep 1
fi

sorted=($(printf '%s\n' "${samples[@]}" | sort -n))
n=${#sorted[@]}
sum=0; for s in "${sorted[@]}"; do sum=$((sum + s)); done
mean=$((sum / n))
p90=${sorted[$(( (n * 9 + 9) / 10 ))]}
hold=$(grep -o '\[hold\].*' "$APPLOG" 2>/dev/null | tail -1)
rm -f "$APPLOG"
echo "$CONFIG gpu_util_mean=${mean}% gpu_util_p90=${p90}% ${hold:-no-hold-line}"
