#!/bin/bash

set -e

BENCHMARKS=("aom-av1")

TEST_RUN_NAME="custom-local-run-$(date +%Y%m%d-%H%M%S)"

RESULTS_DIR="$HOME/pts-results/$TEST_RUN_NAME"
mkdir -p "$RESULTS_DIR"

echo "[INFO] Începem testarea Phoronix..."

if ! command -v phoronix-test-suite &> /dev/null; then
  echo "[ERROR] Phoronix Test Suite nu este instalat. Rulează: sudo apt install phoronix-test-suite"
  exit 1
fi

for test in "${BENCHMARKS[@]}"; do
  echo "[INFO] Se instalează $test..."
  phoronix-test-suite install "$test"
done

for test in "${BENCHMARKS[@]}"; do
  echo "[INFO] Se rulează $test..."
  phoronix-test-suite batch-run "$test" <<EOF
y
EOF

  echo "[INFO] Se copiază rezultatul în $RESULTS_DIR"
  cp -r "$HOME/.phoronix-test-suite/test-results/$test" "$RESULTS_DIR/"
done

echo "[INFO] Testele s-au terminat. Rezultatele sunt în: $RESULTS_DIR"

