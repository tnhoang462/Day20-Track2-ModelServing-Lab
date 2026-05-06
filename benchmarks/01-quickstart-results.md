# 01 — Quickstart Results

Settings: `n_threads=8`, `n_ctx=2048`, `n_batch=512`, `n_gpu_layers=99`.

| Model | Load (ms) | TTFT P50/P95 (ms) | TPOT P50/P95 (ms) | E2E P50/P95/P99 (ms) | Decode rate (tok/s) |
|---|---:|---:|---:|---:|---:|
| Llama-3.2-3B-Instruct-Q4_K_M.gguf | 12547 | 135 / 284 | 46.5 / 52.2 | 3084 / 3548 / 3575 | 21.5 |
| Llama-3.2-3B-Instruct-Q3_K_L.gguf | 1246 | 148 / 277 | 48.9 / 57.8 | 3299 / 3809 / 3859 | 20.4 |

## Observations

- TTFT is the prefill cost. With short prompts this is small; with long prompts it dominates.
- TPOT is per-token decode latency. The decode rate is `1000 / TPOT_p50`.
- The bigger quantization (Q4_K_M) is usually only ~30–60% slower than Q2_K but produces noticeably better text. Q2_K is for *truly* tight RAM.
- `n_threads = physical_cores` is usually best on CPU. Hyperthreading (`logical_cores`) often hurts because the work is bandwidth-bound.

(Edit this file with your own observations before submitting.)
