#!/usr/bin/env python3
"""Reorganize experiments/ into a consistent folder structure.

Current structure (messy):
    experiments/c1/{model}/{design}/C1/{seed}/
    experiments/c2g/{model}/{design}/{C1,C2,C4}/{seed}/
    experiments/c2g/l5l6/{design}/{C4i,C4tl}/{seed}/

Target structure:
    experiments/{condition}/{model}/{design}/{seed}/

Usage:
    python scripts/reorganize_experiments.py [--dry-run]
"""
from __future__ import annotations

import json
import os
import shutil
import sys
from pathlib import Path

EXPERIMENTS = Path("experiments")

RENAMES = {
    "C2": "C2g",
}


def _infer_condition_from_result(result_dir: Path) -> str | None:
    result_file = result_dir / "result.json"
    if result_file.exists():
        try:
            data = json.loads(result_file.read_text())
            return data.get("condition")
        except Exception:
            pass
    return None


def _infer_model_from_result(result_dir: Path) -> str | None:
    result_file = result_dir / "result.json"
    if result_file.exists():
        try:
            data = json.loads(result_file.read_text())
            return data.get("model")
        except Exception:
            pass
    return None


def _model_short(model: str) -> str:
    return model.replace("claude-", "").split("-202")[0]


def reorganize(dry_run: bool = False):
    moves = []

    # Pattern 1a: experiments/c1/{model}/{design}/C1/{seed}/
    # Pattern 1b: experiments/c1/{model}/{design}/{seed}/ (no condition subdir)
    c1_dir = EXPERIMENTS / "c1"
    if c1_dir.exists():
        for model_dir in sorted(c1_dir.iterdir()):
            if not model_dir.is_dir():
                continue
            model = model_dir.name
            for design_dir in sorted(model_dir.iterdir()):
                if not design_dir.is_dir():
                    continue
                design = design_dir.name
                for sub_dir in sorted(design_dir.iterdir()):
                    if not sub_dir.is_dir():
                        continue
                    # Check if this is a condition subdir or a seed subdir
                    if sub_dir.name.startswith("C") and not sub_dir.name.isdigit():
                        # Pattern 1a: condition subdir
                        condition = RENAMES.get(sub_dir.name, sub_dir.name)
                        for seed_dir in sorted(sub_dir.iterdir()):
                            if not seed_dir.is_dir():
                                continue
                            seed = seed_dir.name
                            target = EXPERIMENTS / condition / model / design / seed
                            if seed_dir.resolve() != target.resolve():
                                moves.append((seed_dir, target))
                    else:
                        # Pattern 1b: seed dir directly (infer condition from result.json)
                        seed_dir = sub_dir
                        seed = seed_dir.name
                        cond = _infer_condition_from_result(seed_dir) or "C1"
                        condition = RENAMES.get(cond, cond)
                        m = _infer_model_from_result(seed_dir)
                        if m:
                            model_name = _model_short(m)
                        else:
                            model_name = model
                        target = EXPERIMENTS / condition / model_name / design / seed
                        if seed_dir.resolve() != target.resolve():
                            moves.append((seed_dir, target))

    # Pattern 2a: experiments/c2g/{model}/{design}/{C1,C2,C4}/{seed}/
    # Pattern 2b: experiments/c2g/{model}/{design}/{seed}/ (no condition subdir)
    c2g_dir = EXPERIMENTS / "c2g"
    if c2g_dir.exists():
        for model_dir in sorted(c2g_dir.iterdir()):
            if not model_dir.is_dir() or model_dir.name == "l5l6":
                continue
            model = model_dir.name
            for design_dir in sorted(model_dir.iterdir()):
                if not design_dir.is_dir():
                    continue
                design = design_dir.name
                for sub_dir in sorted(design_dir.iterdir()):
                    if not sub_dir.is_dir():
                        continue
                    if sub_dir.name.startswith("C") and not sub_dir.name.isdigit():
                        # Pattern 2a: condition subdir
                        condition = RENAMES.get(sub_dir.name, sub_dir.name)
                        for seed_dir in sorted(sub_dir.iterdir()):
                            if not seed_dir.is_dir():
                                continue
                            seed = seed_dir.name
                            target = EXPERIMENTS / condition / model / design / seed
                            if seed_dir.resolve() != target.resolve():
                                moves.append((seed_dir, target))
                    else:
                        # Pattern 2b: seed dir directly
                        seed_dir = sub_dir
                        seed = seed_dir.name
                        cond = _infer_condition_from_result(seed_dir) or "C2g"
                        condition = RENAMES.get(cond, cond)
                        m = _infer_model_from_result(seed_dir)
                        if m:
                            model_name = _model_short(m)
                        else:
                            model_name = model
                        target = EXPERIMENTS / condition / model_name / design / seed
                        if seed_dir.resolve() != target.resolve():
                            moves.append((seed_dir, target))

    # Pattern 3: experiments/c2g/l5l6/{design}/{C4i,C4tl}/{seed}/
    l5l6_dir = EXPERIMENTS / "c2g" / "l5l6"
    if l5l6_dir.exists():
        for design_dir in sorted(l5l6_dir.iterdir()):
            if not design_dir.is_dir():
                continue
            design = design_dir.name
            for cond_dir in sorted(design_dir.iterdir()):
                if not cond_dir.is_dir():
                    continue
                condition = cond_dir.name
                for seed_dir in sorted(cond_dir.iterdir()):
                    if not seed_dir.is_dir():
                        continue
                    seed = seed_dir.name
                    model = _infer_model_from_result(seed_dir)
                    if not model:
                        model = "unknown"
                    else:
                        model = _model_short(model)
                    target = EXPERIMENTS / condition / model / design / seed
                    if seed_dir.resolve() != target.resolve():
                        moves.append((seed_dir, target))

    if not moves:
        print("Nothing to reorganize.")
        return

    print(f"{'DRY RUN: ' if dry_run else ''}Moving {len(moves)} cell directories:\n")
    for src, dst in moves:
        print(f"  {src} -> {dst}")
        if not dry_run:
            dst.parent.mkdir(parents=True, exist_ok=True)
            if dst.exists():
                print(f"  WARNING: target exists, merging...")
                for item in src.iterdir():
                    target_item = dst / item.name
                    if not target_item.exists():
                        shutil.move(str(item), str(target_item))
            else:
                shutil.move(str(src), str(dst))

    if not dry_run:
        # Clean up empty directories
        for dirpath, dirnames, filenames in os.walk(str(EXPERIMENTS), topdown=False):
            dp = Path(dirpath)
            if dp == EXPERIMENTS:
                continue
            if not any(dp.iterdir()):
                dp.rmdir()
                print(f"  Removed empty: {dp}")

    print(f"\n{'DRY RUN complete.' if dry_run else 'Reorganization complete.'}")


if __name__ == "__main__":
    dry_run = "--dry-run" in sys.argv
    reorganize(dry_run=dry_run)
