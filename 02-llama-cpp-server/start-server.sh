#!/usr/bin/env bash
# Launch llama-server reading models/active.json.
# Prefers the C++ binary built in BONUS-llama-cpp-optimization/llama.cpp (has /metrics
# Prometheus endpoint + --parallel for continuous batching). Falls back to
# llama-cpp-python's FastAPI wrapper if the binary isn't built.
set -euo pipefail

cd "$(dirname "$0")/.."

PY=".venv/bin/python"
[ -x "$PY" ] || PY="python"

MODEL=$($PY -c 'import json; print(json.load(open("models/active.json"))["primary_model"])')
THREADS=$($PY -c 'import json; hw=json.load(open("hardware.json")); print(hw["cpu"].get("cores_physical") or 4)')
GPU_LAYERS="${LAB_N_GPU_LAYERS:-99}"
PARALLEL="${LAB_PARALLEL:-4}"
CTX="${LAB_N_CTX:-2048}"
PORT="${LAB_SERVER_PORT:-8080}"

CPP_BIN="BONUS-llama-cpp-optimization/llama.cpp/build/bin/llama-server"

echo "==> Starting llama-server"
echo "    model     : $MODEL"
echo "    threads   : $THREADS"
echo "    gpu_layers: $GPU_LAYERS"
echo "    parallel  : $PARALLEL"
echo "    ctx       : $CTX"
echo "    listening : http://0.0.0.0:$PORT"
echo

if [ -x "$CPP_BIN" ]; then
    echo "    backend   : llama.cpp C++ binary (with /metrics)"
    echo
    exec "$CPP_BIN" \
        --model "$MODEL" \
        --host 0.0.0.0 --port "$PORT" \
        --threads "$THREADS" \
        --n-gpu-layers "$GPU_LAYERS" \
        --ctx-size "$((CTX * PARALLEL))" \
        --parallel "$PARALLEL" \
        --metrics
else
    echo "    backend   : llama-cpp-python (no /metrics)"
    echo
    exec "$PY" -m llama_cpp.server \
        --model "$MODEL" \
        --host 0.0.0.0 --port "$PORT" \
        --n_threads "$THREADS" \
        --n_gpu_layers "$GPU_LAYERS" \
        --n_ctx "$CTX"
fi
