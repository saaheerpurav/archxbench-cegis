#!/usr/bin/env python3
import json
import matplotlib.pyplot as plt

# --- Load data ---
inputs = json.load(open("inputs/stimuli.json"))
golden_dct = json.load(open("outputs/golden_dct.json"))
golden_idct = json.load(open("outputs/golden_idct.json"))
dut_dct = json.load(open("outputs/dut_dct.json"))
dut_idct = json.load(open("outputs/dut_idct.json"))


def compare(label, ref, dut):
    n = min(len(ref), len(dut))
    mismatches = [(i, ref[i], dut[i]) for i in range(n) if abs(ref[i] - dut[i]) > 1]
    missing = max(0, len(ref) - len(dut))
    if mismatches or missing:
        print(f"[FAIL] {label}: {len(mismatches) + missing}/{len(ref)} mismatches:")
        for i, r, d in mismatches[:10]:
            print(f"  idx={i}: ref={r}  dut={d}")
        if missing:
            print(f"  missing {missing} DUT entries")
        return False
    print(f"[PASS] {label}: all {len(ref)} samples match")
    return True


ok_dct = compare("DCT", golden_dct, dut_dct)
ok_idct = compare("IDCT", golden_idct, dut_idct)
if not (ok_dct and ok_idct):
    raise SystemExit(1)

# --- Plot ---
plt.figure(figsize=(8,4))
x = list(range(len(inputs)))
plt.plot(x, inputs, marker='o', linestyle='-', label='Input')
plt.plot(x, golden_dct, marker='s', linestyle='--', label='DCT reference')
plt.plot(x, dut_dct, marker='^', linestyle=':', label='DCT DUT')
plt.xlabel("Sample Index")
plt.ylabel("Value")
plt.title("DCT-IDCT 8pt Pipelined: Input vs Reference vs DUT")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.show()
