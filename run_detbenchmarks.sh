#!/bin/bash
set -euo pipefail

BENCHMARKS=(
"compress-pbzip2-1.6.1"
"simdjson-2.1.0"
"ngspice-1.0.0"
"draco-1.6.1"
"aom-av1_3.12.0"
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

for test in "${BENCHMARKS[@]}"; do
    echo "Batch setup pentru $test..."
    cat <<EOF | phoronix-test-suite batch-setup
Y
N
Y
N
N
N
Y
EOF
    echo "Rulare benchmark $test..."
    phoronix-test-suite batch-run "$test"
done

echo "Copiere toate rezultatele în $RESULTS_DIR"
cp -r "$HOME/.phoronix-test-suite/test-results/"* "$RESULTS_DIR/"

echo "Procesul s-a încheiat. Rezultatele sunt în $RESULTS_DIR"
