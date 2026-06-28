# ArchXBench-CEGIS: Autonomous RTL Synthesis via LLM-Driven CEGIS

Autonomous Verilog RTL generation using Counter-Example Guided Inductive Synthesis (CEGIS) with large language models. Evaluated on a corrected fork of the [ArchXBench](https://github.com/abdelrahman-elhaddad/ArchXBench) benchmark suite (Levels 2-6, 32 designs).

## Conditions

| Condition | Description | Feedback Type | Multi-turn |
|-----------|-------------|---------------|------------|
| **C1** | Zero-shot Pass@5 — 5 independent generations, pick best | None | No |
| **C2g** | Monolithic CEGIS — iterative repair on the full module, 30 rounds | Golden comparison | Yes |
| **C4i** | **Investigative CEGIS** — decompose into sub-modules, then study-diagnose-fix loop per sub-module | Structured diagnostic | Yes |
| **C4tl** | **Trace-Lifted CEGIS** — decompose, then localize faults via reference-gating and targeted repair | Golden comparison + fault localization | Per-repair |

**C4i and C4tl are the paper's main contributions.** C4i decomposes complex designs into sub-modules and uses a multi-turn investigative loop (study spec → generate → diagnose failures by tracing expected vs actual values → fix root cause). C4tl adds fault localization: it swaps each candidate sub-module with the reference to identify which module is the culprit, then focuses repair on that module alone.

## Results (Preliminary — Seed Expansion In Progress)

Current results are from GPT-5.5 with seed 42 only. Full 3-model × 3-seed sweep is in progress.

### C4i vs C4tl on L5-L6 (GPT-5.5, seed 42)

| Design | Level | C4i | C4tl |
|--------|-------|-----|------|
| conv1d | L5 | SOLVED | SOLVED |
| conv2d | L5 | SOLVED | SOLVED |
| harris_corner_detection | L5 | SOLVED | SOLVED |
| unsharp_mask | L5 | SOLVED | SOLVED |
| dct_idct_8pt_pipelined | L5 | FAILED | SOLVED |
| systolic_gemm | L5 | FAILED | FAILED |
| aes_decryption | L6 | SOLVED | SOLVED |
| aes_encryption | L6 | SOLVED | SOLVED |
| fft_streaming_64pt | L6 | SOLVED | SOLVED |

### Baseline Comparison (C1 vs C2g, GPT-5.5, 3 seeds)

| Model | C1 (zero-shot) | C2g (CEGIS) | Lift |
|-------|----------------|-------------|------|
| gpt-5.5 | 16/96 (16.7%) | 43/96 (44.8%) | +169% |
| o4-mini | 7/96 (7.3%) | 23/96 (24.0%) | +229% |
| gpt-4o | 4/96 (4.2%) | 7/96 (7.3%) | +75% |

## ArchXBench Bug Fixes

This repo includes a corrected copy of the ArchXBench benchmark. The original benchmark has several bugs that cause false negatives and incorrect scoring. All fixes are in `cegis/tdes/fpga/benchmarks/archxbench/` and `cegis/tdes/fpga/verilog_runner.py`.

### Testbench and Spec Corrections

| Design | Level | Bug | Fix |
|--------|-------|-----|-----|
| **conv1d** | L5 | Testbench captures only N-1 of N outputs due to NBA timing: when `valid_in` deasserts after the main loop, the last valid output is missed. Spec also contains a contradictory "latency of KERNEL_SIZE-1 cycles" claim that conflicts with the golden reference (which expects zero-latency output from cycle 0). | Added pipeline drain cycles after the main loop to capture the final output (15/16 -> 16/16 tests). Removed false latency claim from spec. Hardcoded the actual kernel coefficients `[2, 8, 12, 8, 2]` and clarified `data_out = MAC >> GAIN_W`. |
| **band_pass_fir** | L4 | Spec defaults `DATA_W=16` but the golden testbench stimuli exceed 16-bit range (requires 20-bit input). `TAP_CNT` default is also wrong; the golden reference uses `scipy.signal.firwin(101, ...)` (101-tap filter). | Corrected to `DATA_W=20`, `TAP_CNT=101`. Added all 101 hardcoded quantized coefficients with `scale=32768`. |
| **high_pass_fir** | L4 | Same class of bug as band_pass_fir: wrong `DATA_W` and `TAP_CNT` defaults in the spec don't match the golden testbench. | Corrected parameters and hardcoded coefficient arrays to match golden. |
| **low_pass_fir** | L4 | Same class of bug as band_pass_fir. | Corrected parameters and hardcoded coefficient arrays to match golden. |
| **multich_conv2d** | L6 | Benchmark directory contains `dut_dummy.v` and `testbench.v`. The loader picks the first `.v` file alphabetically (`dut_dummy.v`), not the actual testbench. All cells crash before any LLM call. | **Excluded from all experiments.** Effective L6 = 8 designs instead of 9. |

### Verdict Parser Fixes (Infrastructure)

The original ArchXBench testbenches use inconsistent output formats across designs. Our verdict parser (`verilog_runner.py`) was extended to handle all of them:

- **False negatives from format mismatch**: Many ArchXBench testbenches output `PASS = N, FAIL = M` but the original parser only recognized `TEST SUMMARY: N PASS, M FAILED`. Correct designs were scored as 0/1. Fixed by generalizing to recognize 6+ verdict formats.
- **False positives from incomplete output**: Golden comparison counted `n_total = min(len(golden), len(dut))`, so a DUT producing fewer outputs than expected had its missing entries silently ignored. Fixed by using `n_total = len(golden)` — missing DUT entries now count as mismatches.

### Impact

Without these fixes, the FIR filter designs (L4) are unsolvable because the spec contradicts the testbench, conv1d (L5) silently drops 1 test, and many correct solutions score 0/1 due to verdict parsing. These are bugs in the benchmark, not in the generated RTL.

## Repository Structure

```
archxbench-cegis/
├── cegis/                          # Source code
│   ├── tdes/                       # Test-Driven Evolutionary Synthesis framework
│   │   ├── fpga/
│   │   │   ├── autonomous/         # CEGIS pipeline (run_aaai.py, orchestrator, client)
│   │   │   ├── benchmarks/         # Corrected ArchXBench L0-L6 testbenches and specs
│   │   │   └── experiments/        # Experiment runner infrastructure
│   │   └── ...                     # Base TDES types, selection, crossover, memory
│   └── utils/
├── experiments/                    # Generated artifacts per condition/model/design/seed
│   ├── C1/                         # Zero-shot baseline
│   ├── C2g/                        # Monolithic CEGIS
│   ├── C4/                         # Decompose + stateless CEGIS
│   ├── C4i/                        # Investigative CEGIS (paper's main contribution)
│   ├── C4tl/                       # Trace-Lifted CEGIS (paper's main contribution)
│   └── logs/
├── results/                        # Metrics and summary tables
│   ├── EXPERIMENT_RESULTS.md
│   └── metrics_*.json
└── scripts/                        # Utilities
    ├── backfill_golden.py          # Backfill golden_correct/golden_total into old results
    └── reorganize_experiments.py   # Reorganize experiment folder structure
```

### Cell Artifacts

Each experiment cell at `experiments/{condition}/{model}/{design}/{seed}/` produces:

| File | Description | Present in |
|------|-------------|------------|
| `result.json` | Metrics: solved, best_passes, total_tests, golden_correct, golden_total, llm_calls, wall_seconds, token counts | All conditions |
| `verilog/` | Generated Verilog source files (one per module) | C4, C4i, C4tl |
| `decomposition.json` | Sub-module names and descriptions from the decomposition step | C4, C4i, C4tl |

**Key fields in `result.json`:**
- `solved`: Boolean — did all tests pass (and golden comparison, for L5/L6)?
- `golden_correct` / `golden_total`: Golden output comparison score. Non-zero for L5/L6 designs that use file-based I/O. Zero for L2-L4 designs (testbench-only verification).
- `best_passes` / `total_tests`: Testbench pass count.
- `module_solve_rounds`: (C4i/C4tl) Which round each sub-module was solved.
- `total_input_tokens` / `total_output_tokens`: Token usage for cost tracking.

## Setup

```bash
pip install openai anthropic httpx pyyaml
```

Requires [iverilog](http://iverilog.icarus.com/) and `vvp` on PATH for Verilog simulation.

## Running Experiments

```bash
# Load API credentials (Bedrock Mantle — serves all models via OpenAI-compatible endpoint)
source .env.bedrock  # or: set vars manually

# Investigative CEGIS (C4i) — the paper's main method
python -m cegis.tdes.fpga.autonomous.run_aaai \
    --conditions C4i --models gpt-5.5 claude-opus-4-8 claude-haiku-4-5 \
    --seeds 42 123 456 --designs L2 L3 L4 L5 L6 --parallel 3 --output runs/

# Trace-Lifted CEGIS (C4tl)
python -m cegis.tdes.fpga.autonomous.run_aaai \
    --conditions C4tl --models gpt-5.5 --seeds 42 123 456 \
    --designs L2 L3 L4 L5 L6 --parallel 3 --output runs/

# Zero-shot baseline (C1)
python -m cegis.tdes.fpga.autonomous.run_aaai \
    --conditions C1 --models gpt-5.5 --seeds 42 123 456 \
    --designs L2 L3 L4 L5 L6 --parallel 3 --output runs/

# Monolithic CEGIS baseline (C2g)
python -m cegis.tdes.fpga.autonomous.run_aaai \
    --conditions C2g --models gpt-5.5 --seeds 42 123 456 \
    --designs L2 L3 L4 L5 L6 --parallel 3 --output runs/

# Budget-constrained run (stops after $250 spent)
python -m cegis.tdes.fpga.autonomous.run_aaai \
    --conditions C4i --models gpt-5.5 --seeds 42 123 456 \
    --designs P1 --parallel 3 --output runs/ --budget-usd 250

# Priority design lists: P1 (15 proven), P2 (4 near-misses), P1P2 (combined)
python -m cegis.tdes.fpga.autonomous.run_aaai \
    --conditions C4i C4tl --models gpt-5.5 --seeds 42 123 456 \
    --designs P1P2 --parallel 3 --output runs/
```

Set `OPENAI_API_KEY` and `OPENAI_BASE_URL` for Bedrock Mantle (serves both OpenAI and Anthropic models).
For direct API access, set `OPENAI_API_KEY` for OpenAI models or `ANTHROPIC_API_KEY` for Anthropic models.

## Backfilling Golden Metrics

Older result.json files may be missing `golden_correct`/`golden_total` fields. To backfill:

```bash
# Dry run first
python scripts/backfill_golden.py experiments/ --dry-run

# Apply
python scripts/backfill_golden.py experiments/
```

Requires `iverilog` and `vvp` on PATH.

## License

MIT
