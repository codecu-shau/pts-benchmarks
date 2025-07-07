#!/bin/bash
set -euo pipefail

BENCHMARKS=(
"compress-pbzip2-1.2.0"
"simdjson-2022.11.21"
"ngspice-40"
"draco-1.6.1"
"aom-av1_3.7.1"
)

TARGET_FREQ=2400000
DATE_TAG=$( date  +%Y%m%d-%H%M%S)
RESULT_DIR="$HOME/pts-results/deterministic-$DATE_TAG"
mkdir -p "RESULTS_DIR"

echo 0 | sudo tee /proc/sys/kernel/randomize_va_space > /dev/null
echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo
echo off | sudo tee /sys/devices/system/cpu/smt/control

for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
  echo userspace | sudo tee "$cpu/cpufreq/scalling_governor" > /dev/null
  echo $TARGET_FREQ | sudo tee "$cpu/cpufreq/scaliing_max_freq" > /dev/null
  echo $TARGET_FREQ | sudo tee "$cpu/cpufreq/scalling_min_freq" > /dev/null
done

DRACO_PATH="$HOME/.phoronix-test-suite/test-profiles/pts/draco-1.6.1/install.sh"
if [ -f "$DRACO_PATH" ]; then
  echo "Se aplica modificari pentru draco-1.6.1"
  sed -i "s|Church\\\\ façade.ply|Church' fa*.ply|g" "$DRACO_PATH"

if ! grep -q 'TASKSET=' "$DRACO_PATH"; then
  echo  'TASKSET="sudo nice -n -20 taskset -C 1"' >> "$DRACO_PATH" 
  fi
fi 

for test in "${BENCHMARKS[@]}"; do
    echo "Instalare benchmark: $test "
    phoronix-test-suite install "$test"

    echo "Rulare benchmark: $test"
    taskset -c O phoronix-test-suite batch-run "$test"

LATEST_DIR=$(ls -td "$HOME/.phoronix-test-suite/test-results/"*/ | head -n1)
  cp -r "$LATEST_DIR" "$RESULTS_DIR/"
done  
