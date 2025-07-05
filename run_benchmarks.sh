set -e

BENCHMARKS=(
  "compress-pbzip2"
  "graphics-magick"
  "simdjson"
  "ngspice"
  "draco"
)

TEST_RUN_NAME="custom-local-run-$(date +%Y%m%d-%H%M%S)"
RESULTS_DIR="$HOME/pts-results/$TEST_RUN_NAME"
mkdir -p "$RESULTS_DIR"

echo "[INFO] Începem testarea Phoronix..."

if ! command -v phoronix-test-suite &> /dev/null; then
  echo "[ERROR] Phoronix Test Suite nu este instalat. Rulează: sudo apt install phoronix-test-suite"
  exit 1
fi

sudo apt update
sudo apt install -y build-essential libxaw7-dev libx11-dev libxmu-dev libxt-dev

echo "[INFO] Executăm batch-setup pentru configurare completă..."
phoronix-test-suite batch-setup <<EOF
Y
N
Y
N
Y
EOF

for test in "${BENCHMARKS[@]}"; do
  echo "[INFO] Reinstalăm testul: $test"
  phoronix-test-suite remove-installed-test "$test" || true
  phoronix-test-suite install "$test"

  echo "[INFO] Rulăm testul: $test"
  if phoronix-test-suite batch-run "$test"; then

    RESULT_PATH=$(find "$HOME/.phoronix-test-suite/test-results/" -maxdepth 1 -type d -name "${test}-*" | sort | tail -n 1)

    if [ -n "$RESULT_PATH" ] && [ -d "$RESULT_PATH" ]; then
      cp -r "$RESULT_PATH" "$RESULTS_DIR/"
      echo "[INFO] Rezultatul pentru $test a fost salvat în: $RESULT_PATH"
    else
      echo "[WARN] Testul $test s-a rulat, dar nu a generat folderul de rezultat."
    fi
  else
    echo "[ERROR] Testul $test a eșuat la rulare."
  fi
done

echo ""
echo "[INFO] Toate testele s-au încheiat."
echo "[INFO] Rezultatele complete se află în: $RESULTS_DIR"


