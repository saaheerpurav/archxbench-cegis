# Current Run Matrix

Date: 2026-07-01

This file is the repo-local source of truth for what has actually been run. It exists to avoid confusing "not present in one folder" with "not run."

## Complete Baselines

| Condition | Models | Seeds | Designs | Status |
|-----------|--------|-------|---------|--------|
| C1 | `gpt-5.5`, `o4-mini`, `gpt-4o` | `42`, `123`, `456` | all 32 valid ArchXBench designs | complete |
| C2g | `gpt-5.5`, `o4-mini`, `gpt-4o` | `42`, `123`, `456` | all 32 valid ArchXBench designs | complete |

`multich_conv2d` is excluded because the benchmark directory selects `dut_dummy.v` instead of the real testbench.

## C4i Matched Results

All rows below use `gpt-5.5` and seeds `42`, `123`, `456`.

| Design | Level | C4i | C2g GPT-5.5 | Verification | Claim |
|--------|-------|-----|-------------|--------------|-------|
| `fp_multiplier` | L3 | 3/3 solved, `10/10` | 3/3 solved | self-checking testbench | not exclusive |
| `fp_adder` | L3 | 3/3 solved, `36/36` | 3/3 solved | self-checking testbench | not exclusive |
| `newton_raphson_sqrt` | L3 | 3/3 solved, `50/50` | 3/3 solved | self-checking testbench | not exclusive |
| `gauss_siedel` | L3 | 3/3 solved, `50/50` | 0/3 solved, `47/50` best | self-checking testbench | C4i win |
| `gradient_descent` | L3 | 3/3 solved, `50/50` | 0/3 solved | self-checking testbench | C4i win |
| `harris_corner_detection` | L5 | 3/3 solved, `16384/16384` | 3/3 solved | external golden JSON | both solve |
| `newton_raphson_polynomial` | L3 | 0/3 solved, best `89/100` | 0/3 solved, best `97/100` | self-checking testbench | negative result |

Artifacts are in `experiments/{design}/C4i/{42,123,456}/`.

## Imported C4tl L4 Results

These were generated in the older `openevolve` workspace and imported into this repo on 2026-07-01. Each imported cell includes `result.json`, `decomposition.json`, and generated `verilog/`.

| Design | Level | Seeds | Result | Artifact path |
|--------|-------|-------|--------|---------------|
| `fp_mult_pipeline` | L4 | `42`, `123`, `456`, `789`, `1024` | 5/5 solved, all `31/31` | `experiments/fp_mult_pipeline/C4tl/{seed}/` |
| `fp_adder_pipeline` | L4 | `42`, `123`, `456`, `789`, `1024` | 5/5 solved, all `23/23` | `experiments/fp_adder_pipeline/C4tl/{seed}/` |
| `fft_16pt_iterative` | L4 | `42`, `123`, `456`, `789`, `1024` | 5/5 solved, all `33/33` | `experiments/fft_16pt_iterative/C4tl/{seed}/` |
| `ifft_16pt_iterative` | L4 | `42`, `123`, `456`, `789`, `1024` | 5/5 solved, all `33/33` | `experiments/ifft_16pt_iterative/C4tl/{seed}/` |

Imported metric snapshots:

- `results/metrics_c4tl_l4_imported_seed42.json`
- `results/metrics_c4tl_l4_imported_123_456_789_1024.json`

## FIR Status

The FIR-family designs were already run. They are not missing experiments.

| Design group | Designs | Status | Framing |
|--------------|---------|--------|---------|
| L4 integer FIR | `band_pass_fir`, `high_pass_fir`, `low_pass_fir` | C1/C2/C4 and seed-42 C4i/C4tl attempts failed; `band_pass_fir` debug artifacts are in `experiments_bandpass_debug/` | benchmark spec/golden-contract issue: hidden or mismatched coefficients/parameters |
| L6 floating FIR | `fp_band_pass_fir`, `fp_high_pass_fir`, `fp_low_pass_fir` | C1/C2g failed across formal baseline sweeps | unresolved; likely same FIR-family risk |

Do not list L4 FIRs as "left to run" unless the benchmark contract is changed first.

## Remaining Optional Runs

These are the only real run gaps, assuming Supreet's unpublished artifacts are trusted when he reports them.

| Design | Level | Current status | Useful next action |
|--------|-------|----------------|--------------------|
| `conv_3d` | L6 | C2g/C4tl seed-42 debug failed `0/0`; baselines failed | optional new-method attempt |
| `quantized_matmul` | L6 | C2g/C4tl seed-42 debug failed `0/0`; baselines failed | optional new-method attempt |
| `systolic_gemm` | L5 | baselines and C4tl attempts failed; testbench has weak/no machine-readable verdict | only rerun after adding a reliable checker |
| `dct_idct_8pt_pipelined` | L5 | seed-42 C4tl solved in older L5/L6 run; C2g failed | run/import 3-seed C4tl only if needed for matched L5 table |

## Do Not Treat As Missing

- L4 FFT/IFFT C4tl results: imported and solved.
- L4 FIR attempts: already run and failed.
- C1/C2g formal baselines: complete for 32 valid designs, 3 models, 3 seeds.
