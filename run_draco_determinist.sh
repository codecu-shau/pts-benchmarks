#!/bin/bash

set -euo pipefail

REPEATS=5
DATE_TAG=$(date +%Y%m%d-%H%M%S)
TEST_RUN_NAME="draco-determinism-$DATE_TAG"
RESULTS_DIR="$HOME/pts-results/$TEST_RUN_NAME"
DRACO_DIR="$HOME/.phoronix-test-suite/installed-tests/pts/draco-1.6.1"
MODELS=("church_facade.ply" "lion.ply")

if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
  echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null
fi

echo 0 | sudo tee /proc/sys/kernel/randomize_va_space > /dev/null

LOGICAL_CORES=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
PHYSICAL_CORES=$(lscpu | grep "^Core(s) per socket:" | awk '{print $4}')
THREADS_PER_CORE=$(lscpu | grep "^Thread(s) per core:" | awk '{print $4}')
if [ "$THREADS_PER_CORE" -gt 1 ]; then
  for CPU in $(lscpu -p | grep -v '^#' | awk -F, '$2==1 {print $1}'); do
    STATUS_FILE="/sys/devices/system/cpu/cpu$CPU/online"
    if [ -f "$STATUS_FILE" ]; then
      CURRENT_STATUS=$(cat "$STATUS_FILE")
      if [ "$CURRENT_STATUS" = "1" ]; then
        echo 0 | sudo tee "$STATUS_FILE" > /dev/null 2>&1 || true
      fi
    fi
  done
fi

mkdir -p "$RESULTS_DIR"
cd "$DRACO_DIR"

for MODEL in "${MODELS[@]}"; do
  MODEL_TAG="${MODEL%.ply}"
  for ((i = 1; i <= REPEATS; i++)); do
    OUT_FILE="$RESULTS_DIR/${MODEL_TAG}_$i.drc"
    taskset -c 0 ./draco -i "$MODEL" -o "$OUT_FILE" -cl 10 > /dev/null
  done

  REF="$RESULTS_DIR/${MODEL_TAG}_1.drc"
  DETERMINISTIC=true

  for ((i = 2; i <= REPEATS; i++)); do
    COMP="$RESULTS_DIR/${MODEL_TAG}_$i.drc"
    if ! cmp -s "$REF" "$COMP"; then
      echo "[FAIL] $MODEL_TAG este nedeterminist (diferență la runda $i)"
      DETERMINISTIC=false
      break
    fi
  done

  $DETERMINISTIC && echo "[OK] $MODEL_TAG este determinist"
done

echo 2 | sudo tee /proc/sys/kernel/randomize_va_space > /dev/null

if [ "$THREADS_PER_CORE" -gt 1 ]; then
  for CPU in $(lscpu -p | grep -v '^#' | awk -F, '$2==1 {print $1}'); do
    STATUS_FILE="/sys/devices/system/cpu/cpu$CPU/online"
    if [ -f "$STATUS_FILE" ]; then
      CURRENT_STATUS=$(cat "$STATUS_FILE")
      if [ "$CURRENT_STATUS" = "0" ]; then
        echo 1 | sudo tee "$STATUS_FILE" > /dev/null 2>&1 || true
      fi
    fi
  done
fi

if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
  echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null
fi

