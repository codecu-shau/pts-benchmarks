
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
  "graphics-magick"
  "draco"
)

echo "Pregătire sistem pentru rulare deterministă..."

if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
    echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo
fi

echo 0 | sudo tee /proc/sys/kernel/randomize_va_space

mkdir -p "$RESULTS_DIR"

echo "Rulare benchmark-uri deterministe (fiecare test de $REPEATS ori, single-threaded)"
echo "Rezultatele vor fi salvate în: $RESULTS_DIR"
echo

for BM in "${BENCHMARKS[@]}"; do
  echo "Rulez benchmark: $BM"

  phoronix-test-suite batch-run \
    "$BM" \
    -n "$TEST_RUN_NAME-$BM" \
    --save-results "$TEST_RUN_NAME-$BM" \
    --repeats="$REPEATS" \
    --test-threads=1

  echo "Finalizat: $BM"
  echo
done

echo "Copiere rezultate în $RESULTS_DIR"
cp -r "$HOME/.phoronix-test-suite/test-results/"*"$TEST_RUN_NAME"* "$RESULTS_DIR" || true

echo "Restaurare setări inițiale..."

echo 2 | sudo tee /proc/sys/kernel/randomize_va_space

if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
    echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo
fi

echo "Benchmark-urile s-au încheiat. Rezultatele sunt disponibile în: $RESULTS_DIR"

