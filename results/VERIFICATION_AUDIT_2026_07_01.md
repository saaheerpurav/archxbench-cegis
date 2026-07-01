# Verification Audit - 2026-07-01

Scope: replay saved RTL artifacts against the current corrected ArchXBench testbenches/checkers. No LLM calls were made.

## Method

- L3/L4 self-checking designs were replayed with Icarus Verilog against the current benchmark testbench selected by `read_benchmark`.
- L5 file-output designs were replayed with the current golden comparison path.
- DCT was audited after the local harness repair: bounded waits, no golden overwrite, and separate DCT/IDCT golden comparison.

## Canonical C4i Matched-Seed Audit

All rows use GPT-5.5 seeds `42`, `123`, and `456`.

| Design | Claimed status | Replay audit |
|--------|----------------|--------------|
| `fp_multiplier` | 3/3 solved, `10/10` | PASS: all 3 seeds replayed `10/10` |
| `fp_adder` | 3/3 solved, `36/36` | PASS: all 3 seeds replayed `36/36` |
| `newton_raphson_sqrt` | 3/3 solved, `50/50` | PASS: all 3 seeds replayed `50/50` |
| `gauss_siedel` | 3/3 solved, `50/50` | PASS: all 3 seeds replayed `50/50` |
| `gradient_descent` | 3/3 solved, `50/50` | PASS: all 3 seeds replayed `50/50` |
| `harris_corner_detection` | 3/3 solved, `16384/16384` | PASS: all 3 seeds replayed `16384/16384` against external golden JSON |
| `newton_raphson_polynomial` | negative matched result | CONFIRMED NEGATIVE: seeds replayed `17/100`, `17/100`, `89/100` |

## Imported C4tl L4 Audit

All rows use imported Codex GPT-5.5 C4tl artifacts.

| Design | Seeds | Replay audit |
|--------|-------|--------------|
| `fp_mult_pipeline` | `42`, `123`, `456`, `789`, `1024` | PASS: all 5 seeds replayed `31/31` |
| `fp_adder_pipeline` | `42`, `123`, `456`, `789`, `1024` | PASS: all 5 seeds replayed `23/23` |
| `fft_16pt_iterative` | `42`, `123`, `456`, `789`, `1024` | PASS: all 5 seeds replayed `33/33` with `tb_selfcheck.v` |
| `ifft_16pt_iterative` | `42`, `123`, `456`, `789`, `1024` | PASS: all 5 seeds replayed `33/33` with `tb_selfcheck.v` |

## DCT Status

`dct_idct_8pt_pipelined` is not claimable.

- The old seed-42 C4tl native-testbench pass is false under the repaired checker: `0/16`.
- A fresh repaired C4tl seed-42 rerun failed: no useful DUT outputs.
- C4tl with decomposition retry and golden-reference validation also failed: no valid reference decomposition after 3 attempts.
- Do not run more DCT seeds without a stronger decomposition method.

## Audit Conclusion

The current canonical claims verified locally:

- C4i matched-seed L3/L5 table verifies as documented.
- Imported C4tl L4 solves verify as documented.
- DCT must stay out of solved-result claims.

Legacy seed-42 L5/L6 rows in the README are historical context only and should not be used as paper claims unless each artifact is separately golden-replayed.
