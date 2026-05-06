# Bonus — Thread sweep

Model: `Llama-3.2-3B-Instruct-Q4_K_M.gguf`  ·  GPU layers: `99`

| threads | tg128 (tok/s) |
|---:|---:|
| 1 | 21.2 |
| 2 | 22.5 |
| 4 | 23.1 |
| 8 | 22.5 |
| 16 | 21.2 |

**Best**: `-t 4` at 23.1 tok/s.

Look at the curve. If it peaks around your **physical** core count and drops as you go higher, that's the memory-bandwidth ceiling: extra threads fight over the same memory channels and slow each other down.
