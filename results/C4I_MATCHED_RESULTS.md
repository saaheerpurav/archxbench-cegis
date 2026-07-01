# C4i Matched-Seed Results

Date: 2026-07-01

## Summary

This table records the current canonical C4i matched-seed evidence. It separates designs where C4i is an actual win over monolithic C2g from designs where C4i also solves but is not exclusive.

All C4i rows use:
- model: `gpt-5.5`
- seeds: `42`, `123`, `456`
- condition: `C4i`
- verifier: official ArchXBench testbench; external golden output where available

## Matched Comparison

| Design | Level | C4i GPT-5.5 | C2g GPT-5.5 Baseline | Verification | Interpretation |
|--------|-------|-------------|----------------------|--------------|----------------|
| `fp_multiplier` | L3 | 3/3 solved, all `10/10` | 3/3 solved, all `10/10` | official self-checking testbench | C4i also solves; not exclusive |
| `gauss_siedel` | L3 | 3/3 solved, all `50/50` | 0/3 solved, all `47/50` | official self-checking testbench | C4i win |
| `newton_raphson_sqrt` | L3 | 3/3 solved, all `50/50` | 3/3 solved, all `50/50` | official self-checking testbench | C4i also solves; not exclusive |
| `fp_adder` | L3 | 3/3 solved, all `36/36` | 3/3 solved, all `36/36` | official self-checking testbench | C4i also solves; not exclusive |
| `gradient_descent` | L3 | 3/3 solved, all `50/50` | 0/3 solved, no passing simulations | official self-checking testbench | C4i win |
| `harris_corner_detection` | L5 | 3/3 solved, all `16384/16384` | 3/3 solved, all `16384/16384` | external golden JSON | both solve; compare cost/trace |
| `newton_raphson_polynomial` | L3 | 0/3 solved; best `89/100` | 0/3 solved; best `97/100` | official self-checking testbench | negative result |

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
| `gradient_descent` | 42 | yes | `50/50` | `0/0` | 22 | 2603.5 |
| `gradient_descent` | 123 | yes | `50/50` | `0/0` | 4 | 291.6 |
| `gradient_descent` | 456 | yes | `50/50` | `0/0` | 5 | 361.7 |
| `newton_raphson_polynomial` | 42 | no | `17/100` | `0/0` | 29 | 1934.9 |
| `newton_raphson_polynomial` | 123 | no | `17/100` | `0/0` | 26 | 1411.8 |
| `newton_raphson_polynomial` | 456 | no | `89/100` | `0/0` | 29 | 1479.9 |

`golden=0/0` means the benchmark does not provide a separate golden-output JSON for that design. Those rows are still verified by the official self-checking testbench, which contains embedded expected outputs or computes the expected values internally.

## Artifact Paths

| Design | Seed 42 | Seed 123 | Seed 456 |
|--------|---------|----------|----------|
| `fp_multiplier` | `experiments/fp_multiplier/C4i/42/` | `experiments/fp_multiplier/C4i/123/` | `experiments/fp_multiplier/C4i/456/` |
| `gauss_siedel` | `experiments/gauss_siedel/C4i/42/` | `experiments/gauss_siedel/C4i/123/` | `experiments/gauss_siedel/C4i/456/` |
| `fp_adder` | `experiments/fp_adder/C4i/42/` | `experiments/fp_adder/C4i/123/` | `experiments/fp_adder/C4i/456/` |
| `newton_raphson_sqrt` | `experiments/newton_raphson_sqrt/C4i/42/` | `experiments/newton_raphson_sqrt/C4i/123/` | `experiments/newton_raphson_sqrt/C4i/456/` |
| `harris_corner_detection` | `experiments/harris_corner_detection/C4i/42/` | `experiments/harris_corner_detection/C4i/123/` | `experiments/harris_corner_detection/C4i/456/` |
| `gradient_descent` | `experiments/gradient_descent/C4i/42/` | `experiments/gradient_descent/C4i/123/` | `experiments/gradient_descent/C4i/456/` |
| `newton_raphson_polynomial` | `experiments/newton_raphson_polynomial/C4i/42/` | `experiments/newton_raphson_polynomial/C4i/123/` | `experiments/newton_raphson_polynomial/C4i/456/` |

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

The later L3 extension was run with:

```powershell
python -m cegis.tdes.fpga.autonomous.run_aaai `
  --conditions C4i `
  --models gpt-5.5 `
  --seeds 42 123 456 `
  --designs gradient_descent newton_raphson_polynomial `
  --output experiments `
  --parallel 0
```

## Interpretation

The strongest C4i wins in the current formal metrics are:

- `gauss_siedel`: C4i `3/3`, C2 `0/3`.
- `gradient_descent`: C4i `3/3`, C2g `0/3`.

`fp_multiplier`, `fp_adder`, `newton_raphson_sqrt`, and `harris_corner_detection` are still useful as robustness/cost/trace examples, but they are not exclusive C4i wins because formal C2g GPT-5.5 also solves them. `newton_raphson_polynomial` remains unsolved. C4i improved over zero-shot but did not beat the monolithic C2g near-miss (`97/100`), so it is recorded as a negative result rather than a main claim.

This supports a narrower mechanism claim: decomposition plus per-module investigative repair can escape some monolithic repair failures, but the paper should not overclaim C4i superiority on every matched design.
