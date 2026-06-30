# C4i Matched-Seed Results

Date: 2026-06-30

## Summary

This table is the current canonical evidence for Investigative CEGIS (`C4i`) against monolithic CEGIS (`C2`/`C2g`) on the key designs where decomposition changes the result.

All C4i rows use:
- model: `gpt-5.5`
- seeds: `42`, `123`, `456`
- condition: `C4i`
- verifier: official ArchXBench testbench; external golden output where available

## Matched Comparison

| Design | Level | C4i GPT-5.5 | C2/C2g GPT-5.5 Baseline | Verification |
|--------|-------|-------------|--------------------------|--------------|
| `fp_multiplier` | L3 | 3/3 solved, all `10/10` | 0/3 solved, best `7/10` | official self-checking testbench |
| `gauss_siedel` | L3 | 3/3 solved, all `50/50` | 0/3 solved, all `45/50` | official self-checking testbench |
| `newton_raphson_sqrt` | L3 | 3/3 solved, all `50/50` | 0/3 solved for GPT-5.5 | official self-checking testbench |
| `fp_adder` | L3 | 3/3 solved, all `36/36` | 1/3 solved on seeds `42,123,456` | official self-checking testbench |
| `harris_corner_detection` | L5 | 3/3 solved, all `16384/16384` | seed `42` solved, slower | external golden JSON |

## C4i Per-Seed Details

| Design | Seed | Solved | Score | Golden | LLM Calls | Wall Seconds |
|--------|------|--------|-------|--------|-----------|--------------|
| `fp_multiplier` | 42 | yes | `10/10` | `0/0` | 5 | 270.9 |
| `fp_multiplier` | 123 | yes | `10/10` | `0/0` | 5 | 254.5 |
| `fp_multiplier` | 456 | yes | `10/10` | `0/0` | 5 | 403.7 |
| `gauss_siedel` | 42 | yes | `50/50` | `0/0` | 4 | 317.2 |
| `gauss_siedel` | 123 | yes | `50/50` | `0/0` | 19 | 945.7 |
| `gauss_siedel` | 456 | yes | `50/50` | `0/0` | 20 | 880.3 |
| `fp_adder` | 42 | yes | `36/36` | `0/0` | 6 | 551.8 |
| `fp_adder` | 123 | yes | `36/36` | `0/0` | 4 | 269.8 |
| `fp_adder` | 456 | yes | `36/36` | `0/0` | 6 | 361.4 |
| `newton_raphson_sqrt` | 42 | yes | `50/50` | `0/0` | 5 | 215.3 |
| `newton_raphson_sqrt` | 123 | yes | `50/50` | `0/0` | 5 | 230.4 |
| `newton_raphson_sqrt` | 456 | yes | `50/50` | `0/0` | 5 | 203.4 |
| `harris_corner_detection` | 42 | yes | `16384/16384` | `16384/16384` | 7 | 437.2 |
| `harris_corner_detection` | 123 | yes | `16384/16384` | `16384/16384` | 10 | 566.9 |
| `harris_corner_detection` | 456 | yes | `16384/16384` | `16384/16384` | 15 | 685.7 |

`golden=0/0` means the benchmark does not provide a separate golden-output JSON for that design. Those rows are still verified by the official self-checking testbench, which contains embedded expected outputs or computes the expected values internally.

## Artifact Paths

| Design | Seed 42 | Seed 123 | Seed 456 |
|--------|---------|----------|----------|
| `fp_multiplier` | `experiments/fp_multiplier/C4i/42/` | `experiments/fp_multiplier/C4i/123/` | `experiments/fp_multiplier/C4i/456/` |
| `gauss_siedel` | `experiments/gauss_siedel/C4i/42/` | `experiments/gauss_siedel/C4i/123/` | `experiments/gauss_siedel/C4i/456/` |
| `fp_adder` | `experiments/fp_adder/C4i/42/` | `experiments/fp_adder/C4i/123/` | `experiments/fp_adder/C4i/456/` |
| `newton_raphson_sqrt` | `experiments/newton_raphson_sqrt/C4i/42/` | `experiments/newton_raphson_sqrt/C4i/123/` | `experiments/newton_raphson_sqrt/C4i/456/` |
| `harris_corner_detection` | `experiments/harris_corner_detection/C4i/42/` | `experiments/harris_corner_detection/C4i/123/` | `experiments/harris_corner_detection/C4i/456/` |

## Reproduction Command

The seed-123 and seed-456 extension was run locally with the Codex CLI backend:

```powershell
$env:USE_CODEX_CLI='1'
$env:CODEX_REASONING_EFFORT='low'
$env:CODEX_CLI_TIMEOUT='300'
$env:PATH='C:\Users\saahe\Desktop\Programming\Stuff\College\Research\tools\oss-cad-suite\bin;' + $env:PATH
python -m cegis.tdes.fpga.autonomous.run_aaai `
  --conditions C4i `
  --models gpt-5.5 `
  --seeds 123 456 `
  --designs fp_multiplier gauss_siedel fp_adder newton_raphson_sqrt harris_corner_detection `
  --output experiments `
  --parallel 0
```

## Interpretation

The strongest result is not just that C4i solves isolated cells. It solves multiple matched-seed cells where monolithic GPT-5.5 CEGIS reaches the round budget and stagnates:

- `fp_multiplier`: C4i `3/3`, C2 `0/3`.
- `gauss_siedel`: C4i `3/3`, C2 `0/3`.
- `newton_raphson_sqrt`: C4i `3/3`, C2 `0/3` for GPT-5.5.
- `fp_adder`: C4i `3/3`, C2 `1/3` on the matched seeds.

This supports the main mechanism claim: decomposition plus per-module investigative repair can escape monolithic repair failures on RTL synthesis tasks.
