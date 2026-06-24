# ArchXBench-CEGIS: Autonomous RTL Synthesis via LLM-Driven CEGIS

Autonomous Verilog RTL generation using Counter-Example Guided Inductive Synthesis (CEGIS) with large language models. Evaluated on a corrected fork of the [ArchXBench](https://github.com/abdelrahman-elhaddad/ArchXBench) benchmark suite (Levels 2-6, 32 designs).

## Results

Three OpenAI models evaluated under two conditions:
- **C1 (Zero-shot Pass@5)**: 5 independent generation attempts, no feedback
- **C2g (Monolithic Golden CEGIS)**: Multi-turn conversation with golden comparison feedback, 30 rounds max

| Model | C1 (zero-shot) | C2g (CEGIS) | Lift |
|-------|----------------|-------------|------|
| gpt-5.5 | 16/96 (16.7%) | 43/96 (44.8%) | +169% |
| o4-mini | 7/96 (7.3%) | 23/96 (24.0%) | +229% |
| gpt-4o | 4/96 (4.2%) | 7/96 (7.3%) | +75% |

CEGIS feedback unlocks 9 new designs for gpt-5.5, 7 for o4-mini, and 3 for gpt-4o that zero-shot cannot solve. Full results in [`results/EXPERIMENT_RESULTS.md`](results/EXPERIMENT_RESULTS.md).

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
├── results/                        # Metrics and summary tables
│   ├── EXPERIMENT_RESULTS.md
│   └── metrics_*.json
└── experiments/                    # Generated Verilog artifacts per model per condition
    ├── c2g/                        # Multi-turn CEGIS runs (gpt55, o4mini, gpt4o)
    ├── c1/                         # Zero-shot baseline runs (gpt55, o4mini, gpt4o)
    └── logs/
```

## Setup

```bash
pip install openai anthropic httpx pyyaml
```

Requires [iverilog](http://iverilog.icarus.com/) and `vvp` on PATH for Verilog simulation.

## Running Experiments

```bash
# Zero-shot baseline (C1) for a single model
python -m cegis.tdes.fpga.autonomous.run_aaai \
    --condition C1 --model gpt-5.5 --seeds 42 123 456 \
    --levels L2 L3 L4 L5 L6 --parallel 3 --output runs/

# Multi-turn CEGIS (C2g)
python -m cegis.tdes.fpga.autonomous.run_aaai \
    --condition C2 --model gpt-5.5 --seeds 42 123 456 \
    --levels L2 L3 L4 L5 L6 --parallel 3 --output runs/
```

Set `OPENAI_API_KEY` for OpenAI models or `ANTHROPIC_API_KEY` for Anthropic models.

## License

MIT
