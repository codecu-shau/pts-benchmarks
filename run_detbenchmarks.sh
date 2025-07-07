#!/bin/bash
set -euo pipefail

BENCHMARKS=(
"compress-pbzip2-1.2.0"
"simdjson-3.13.0"
"ngspice-44.2"
"draco-1.6.1"
"aom-av1_3.7.1"
)

TARGET_FREQ=2400000
DATE_TAG=$( date  +%Y%m%d-%H%M%S)
RESULT_DIR="$HOME/pts-results/deterministic-$DATE_TAG"
mkdir -p "$RESULTS_DIR"

echo 0 | sudo tee /proc/sys/kernel/randomize_va_space > /dev/null
echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo
echo off | sudo tee /sys/devices/system/cpu/smt/control

for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
  echo performance | sudo tee "$cpu/cpufreq/scaling_governor" > /dev/null
  echo $TARGET_FREQ | sudo tee "$cpu/cpufreq/scaling_max_freq" > /dev/null
  echo $TARGET_FREQ | sudo tee "$cpu/cpufreq/scaling_min_freq" > /dev/null
done

for test in "${BENCHMARKS[@]}"; do
    echo "Instalare benchmark: $test "
    phoronix-test-suite install "$test"
done

echo "batch-setup cu răspunsuri presetate și salvare ca 'deterministic-suite'..."
cat <<EOF | phoronix-test-suite batch-setup
Y
N
Y
N
N
N
Y
deterministic-suite
EOF

echo "rulare automată..."
export PHORONIX_TEST_SUITE_AUTO_YES=1
export PHORONIX_TEST_SUITE_BATCH_MODE=1
export PHORONIX_TEST_SUITE_BATCH_UPLOAD_RESULTS=1

echo "Rulez batch 'deterministic-suite'..."
phoronix-test-suite batch-run local/deterministic-suite

echo "Copiere toate rezultatele în $RESULTS_DIR"
cp -r "$HOME/.phoronix-test-suite/test-results/"* "$RESULTS_DIR/"

echo "Procesul s-a încheiat. Rezultatele sunt în $RESULT_DIR"
