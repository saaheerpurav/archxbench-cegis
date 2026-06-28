#!/usr/bin/env python3
"""Backfill golden_correct / golden_total into existing result.json files.

For each result.json that is missing golden fields and has a verilog/
subdirectory with saved sources, re-runs the golden comparison against
the ArchXBench reference outputs.

Requires: iverilog and vvp on PATH.

Usage:
    python scripts/backfill_golden.py experiments/
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ARCHX_ROOT = Path(__file__).resolve().parent.parent / "cegis" / "tdes" / "fpga" / "benchmarks" / "archxbench"

LEVEL_DESIGNS = {
    "level-2": [
        "aes128_single_round", "cla_32bit_pipe", "dadda_mult_pipe",
        "rca_32bit_pipe", "wallace_tree_mult_pipe",
    ],
    "level-3": [
        "fp_adder", "fp_multiplier", "gauss_siedel",
        "gradient_descent", "newton_raphson_polynomial", "newton_raphson_sqrt",
    ],
    "level-4": [
        "fp_mult_pipeline", "fp_adder_pipeline",
        "fft_16pt_iterative", "ifft_16pt_iterative",
        "band_pass_fir", "high_pass_fir", "low_pass_fir",
    ],
    "level-5": [
        "conv1d", "conv2d", "dct_idct_8pt_pipelined",
        "harris_corner_detection", "systolic_gemm", "unsharp_mask",
    ],
    "level-6": [
        "aes_decryption", "aes_encryption", "conv_3d",
        "fft_streaming_64pt", "fp_band_pass_fir", "fp_high_pass_fir",
        "fp_low_pass_fir", "quantized_matmul",
    ],
}


def _find_design_dir(design_name: str) -> Path | None:
    for level, designs in LEVEL_DESIGNS.items():
        if design_name in designs:
            d = ARCHX_ROOT / level / design_name
            if d.is_dir():
                return d
    for level_dir in ARCHX_ROOT.iterdir():
        if level_dir.is_dir():
            d = level_dir / design_name
            if d.is_dir():
                return d
    return None


def _run_golden_comparison(data_dir: Path, sim_workdir: Path):
    dut_path = sim_workdir / "outputs" / "dut_output.json"
    golden_path = data_dir / "outputs" / "golden_output.json"

    if not dut_path.exists():
        return 0, 1, "DUT output file not written"
    if not golden_path.exists():
        return 0, 0, "No golden file"

    try:
        dut = json.loads(dut_path.read_text())
    except (json.JSONDecodeError, ValueError):
        return 0, 1, "DUT output is malformed JSON"
    try:
        golden = json.loads(golden_path.read_text())
    except (json.JSONDecodeError, ValueError):
        return 0, 1, "Golden output is malformed JSON"

    if isinstance(dut, dict):
        dut = list(dut.values())
    if isinstance(golden, dict):
        golden = list(golden.values())
    if isinstance(dut, list) and dut and isinstance(dut[0], list):
        dut = [x for row in dut for x in row]
    if isinstance(golden, list) and golden and isinstance(golden[0], list):
        golden = [x for row in golden for x in row]

    if not golden:
        return 0, 0, "Golden is empty"
    if not dut:
        return 0, len(golden), "DUT produced no output"

    n_total = len(golden)
    mismatches = 0
    for i in range(min(len(golden), len(dut))):
        try:
            if abs(float(golden[i]) - float(dut[i])) > 1:
                mismatches += 1
        except (TypeError, ValueError):
            if golden[i] != dut[i]:
                mismatches += 1

    missing = max(0, n_total - len(dut))
    passes = n_total - mismatches - missing
    return passes, n_total, f"{passes}/{n_total} correct"


def backfill_one(result_dir: Path, design_name: str, dry_run: bool = False):
    result_file = result_dir / "result.json"
    verilog_dir = result_dir / "verilog"

    if not result_file.exists():
        return None
    if not verilog_dir.exists():
        return None

    result = json.loads(result_file.read_text())

    if result.get("golden_correct") not in (None, "MISSING", 0) or \
       result.get("golden_total") not in (None, "MISSING", 0):
        if "golden_correct" in result and "golden_total" in result:
            return None

    design_dir = _find_design_dir(design_name)
    if not design_dir:
        return f"SKIP {result_dir}: design dir not found for {design_name}"

    data_dir = None
    for sub in ("inputs", "outputs"):
        if (design_dir / sub).is_dir():
            data_dir = design_dir
            break

    if not data_dir:
        result["golden_correct"] = 0
        result["golden_total"] = 0
        if not dry_run:
            result_file.write_text(json.dumps(result, indent=2))
        return f"SET {result_dir}: golden=0/0 (no golden data for this design)"

    # Read testbench
    tb_files = list(design_dir.glob("testbench*.v")) + list(design_dir.glob("tb*.v"))
    if not tb_files:
        tb_files = [f for f in design_dir.glob("*.v")
                    if "dut" not in f.name.lower() and "dummy" not in f.name.lower()]
    if not tb_files:
        result["golden_correct"] = 0
        result["golden_total"] = 0
        if not dry_run:
            result_file.write_text(json.dumps(result, indent=2))
        return f"SET {result_dir}: golden=0/0 (no testbench found)"

    testbench = tb_files[0].read_text(encoding="utf-8", errors="replace")

    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        for sub_d in ("inputs", "outputs"):
            src = data_dir / sub_d
            if src.is_dir():
                shutil.copytree(src, tmp / sub_d)
        (tmp / "outputs").mkdir(exist_ok=True)

        for f in data_dir.iterdir():
            if f.suffix == ".mem":
                shutil.copy2(f, tmp / f.name)

        for v_file in verilog_dir.iterdir():
            if v_file.suffix == ".v":
                shutil.copy2(v_file, tmp / v_file.name)

        tb_file = tmp / "tb.v"
        tb_file.write_text(testbench, encoding="utf-8")

        srcs = [str(f) for f in tmp.glob("*.v")]
        compile_result = subprocess.run(
            ["iverilog", "-g2012", "-o", str(tmp / "sim.vvp")] + srcs,
            capture_output=True, text=True, encoding="utf-8", errors="replace",
        )
        if compile_result.returncode != 0:
            result["golden_correct"] = 0
            result["golden_total"] = 0
            if not dry_run:
                result_file.write_text(json.dumps(result, indent=2))
            return f"SET {result_dir}: golden=0/0 (compile failed)"

        try:
            subprocess.run(
                ["vvp", str(tmp / "sim.vvp")],
                capture_output=True, text=True, cwd=str(tmp), timeout=120,
                encoding="utf-8", errors="replace",
            )
        except subprocess.TimeoutExpired:
            result["golden_correct"] = 0
            result["golden_total"] = 0
            if not dry_run:
                result_file.write_text(json.dumps(result, indent=2))
            return f"SET {result_dir}: golden=0/0 (simulation timed out)"

        gp, gt, detail = _run_golden_comparison(data_dir, tmp)

    result["golden_correct"] = gp
    result["golden_total"] = gt

    if gt > 0 and gp == gt and not result.get("solved"):
        result["solved"] = True

    if not dry_run:
        result_file.write_text(json.dumps(result, indent=2))

    return f"{'DRY ' if dry_run else ''}SET {result_dir}: golden={gp}/{gt} ({detail})"


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <experiments_dir> [--dry-run]")
        sys.exit(1)

    experiments_dir = Path(sys.argv[1])
    dry_run = "--dry-run" in sys.argv

    updated = 0
    skipped = 0

    for result_file in sorted(experiments_dir.rglob("result.json")):
        result_dir = result_file.parent
        parts = result_dir.parts
        design_name = None
        for p in parts:
            for designs in LEVEL_DESIGNS.values():
                if p in designs:
                    design_name = p
                    break
            if design_name:
                break

        if not design_name:
            continue

        msg = backfill_one(result_dir, design_name, dry_run=dry_run)
        if msg:
            print(msg)
            if "SET" in msg:
                updated += 1
        else:
            skipped += 1

    print(f"\nDone. Updated: {updated}, Skipped (already had golden): {skipped}")


if __name__ == "__main__":
    main()
