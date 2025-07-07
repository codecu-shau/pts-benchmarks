#!/bin/bash
set -euo pipefail

REPEATS=5
DATE_TAG=$(date +%Y%m%d-%H%M%S)
TEST_RUN_NAME="deterministic-run-$DATE_TAG"
RESULTS_DIR="$HOME/pts-results/$TEST_RUN_NAME"

BENCHMARKS=(
  "aom-av1"
  "simdjson"
  "compress-pbzip2"
  "ngspice"
)

echo "[INFO] Pregătire sistem pentru rulare deterministă..."

if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
    echo "[INFO] Dezactivare Turbo Boost"
    echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null
fi

echo "[INFO] Dezactivare ASLR"
echo 0 | sudo tee /proc/sys/kernel/randomize_va_space > /dev/null

mkdir -p "$RESULTS_DIR"

echo "[INFO] Rulare benchmark-uri deterministe (fiecare test va rula de $REPEATS ori, single-threaded)"
echo "[INFO] Rezultatele vor fi salvate în: $RESULTS_DIR"
echo

for BM in "${BENCHMARKS[@]}"; do
  echo "[INFO] Rulez benchmark: $BM (de $REPEATS ori)"

  phoronix-test-suite batch-run "$BM" \
    --repeats="$REPEATS" \
    --test-threads=1 \
    --name="$TEST_RUN_NAME-$BM"

  RESULTS_FOLDERS=($(find "$HOME/.phoronix-test-suite/test-results/" -maxdepth 1 -type d -name "$TEST_RUN_NAME-$BM*" | sort))

  if [ "${#RESULTS_FOLDERS[@]}" -lt "$REPEATS" ]; then
    echo "[WARN] Nu am găsit suficiente rezultate pentru $BM (am găsit ${#RESULTS_FOLDERS[@]}, așteptam $REPEATS)"
    continue
  fi

  REF_DIR="${RESULTS_FOLDERS[0]}"
  DETERMINISTIC=true

  for ((i=1; i < REPEATS; i++)); do
    CMP_DIR="${RESULTS_FOLDERS[i]}"
    diff_output=$(diff -r "$REF_DIR" "$CMP_DIR" || true)
    if [ -n "$diff_output" ]; then
      echo "[FAIL] $BM este nedeterminist (diferențe între rulările 1 și $((i+1)))"
      DETERMINISTIC=false
      break
    fi
  done

  if $DETERMINISTIC; then
    echo "[OK] $BM este determinist"
  fi

  for res in "${RESULTS_FOLDERS[@]}"; do
    cp -r "$res" "$RESULTS_DIR/"
  done

  echo
done

echo "[INFO] Restaurare setări inițiale..."

echo 2 | sudo tee /proc/sys/kernel/randomize_va_space > /dev/null

if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
    echo "[INFO] Reactivare Turbo Boost"
    echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null
fi

echo "[INFO] Benchmark-urile s-au încheiat."
echo "[INFO] Rezultatele complete sunt disponibile în: $RESULTS_DIR"
