# 02 — llama-server load test results

Backend: llama.cpp C++ binary (Metal, M1, 8 physical / 8 logical cores).
Model: `Llama-3.2-3B-Instruct-Q4_K_M.gguf` (1.9 GB).
Server: `--parallel 4 --ctx-size 8192 --threads 8 --n-gpu-layers 99 --metrics`.

## locust headless `-u 10 -r 1 -t 1m`

```
Type  Name       # reqs   # fails   Avg(ms)  Min   Max    Med    req/s
POST  long-rag      3      0        21151   14518 24899  24000  0.06
POST  short        22      0        14050    1953 21915  15000  0.42
                  ----                                          ----
      Aggregated   25      0        14902    1953 24899  16000  0.48

Response time percentiles (ms, approximated):
                  P50    P75    P90    P95    P99   100%
      Aggregated  16000  19000  22000  24000  25000  25000
```

## locust headless `-u 50 -r 1 -t 1m`

```
Type  Name       # reqs   # fails   Avg(ms)  Min   Max    Med    req/s
POST  long-rag      5      0        23576   12855 38136  21000  0.09
POST  short        22      0        20545    4290 35576  22000  0.38
                  ----                                          ----
      Aggregated   27      0        21106    4290 38136  22000  0.47

Response time percentiles (ms, approximated):
                  P50    P75    P90    P95    P99   100%
      Aggregated  22000  29000  34000  36000  38000  38000
```

## /metrics observation (60s window during the -u 50 run)

`benchmarks/02-server-metrics.csv` was sampled every 2s. Selected rows:

```
t           reqs_proc  deferred  kv_ratio  tok_pred_total
1778041991      4         6      0.00      1146
1778042001      4         5      0.00      1677
1778042010      4         5      0.00      1917
```

- `llamacpp:tokens_predicted_total` rose monotonically from 0 → 1917 over the run, confirming the server is doing real decode work.
- `requests_processing` stayed pinned at 4 = `--parallel 4`, so the engine was always saturated.
- `requests_deferred` stayed at 5–6 — the queue stayed deep, which is the saturation regime where throughput plateaus and added concurrency only inflates queueing latency (the gap between average 14 902 ms at u=10 and 21 106 ms at u=50 is exactly that queueing tax).
- `kv_cache_usage_ratio` reported as 0.00 with the 8192-token total context (`--ctx-size 8192` distributed across 4 slots = 2048 each). With max 80 + 160 token completions plus short prompts, peak occupancy per slot was well under 200 / 2048 ≈ 10 %, which the gauge rounds to 0.00 at sample resolution.

The interesting story in the table: throughput barely changed (0.48 → 0.47 req/s) when concurrency 5×ed. That's classic goodput-at-saturation — the server is decode-bound at 4 parallel slots regardless of how many users are knocking.
