#!/bin/bash
set -e

DRACO_DIR="$HOME/.phoronix-test-suite/installed-tests/pts/draco-1.6.1"
cd "$DRACO_DIR" || { echo "Directorul nu există."; exit 1; }

if ! [[ -x ./draco ]]; then
  echo "draco nu este executabil sau nu există."
  exit 1
fi

run_test() {
  local model=$1
  local output=$2

  if [[ ! -f "$model" ]]; then
    echo "[ERROR] Fișierul $model nu există."
    return 1
  fi

  echo "[INFO] Rulez draco pentru $model..."
  ./draco -i "$model" -o "$output"
  echo "[OK] $output generat."
}

run_test church_facade.ply church.drc
run_test lion.ply lion.drc

