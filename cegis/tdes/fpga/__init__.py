"""
TDES-FPGA: evolve Verilog RTL against hierarchical testbenches.

Additive layer over ``cegis.tdes`` that swaps the Python import/exec test
runner for an open-source EDA pipeline (Icarus Verilog + Yosys), while reusing
the TDES controller, selection, complementary-coverage crossover, and negative
memory unchanged.

Modules:
  * ``verilog_runner``       — iverilog/vvp compile+simulate + output interpreter
  * ``verilog_suite``        — VerilogTestSuite (drop-in for TDESTestSuite)
  * ``synthesis``            — Yosys resource extraction (system-level tests)
  * ``prompts`` / ``mutation`` — Verilog LLM mutation
  * ``config`` / ``fpga_controller`` — FPGA defaults + controller wrapper
  * ``benchmark_loader`` / ``testbench_decomposer`` — ArchXBench/RTLLM/ResBench
"""

from cegis.tdes.fpga.config import FPGAConfig
from cegis.tdes.fpga.fpga_controller import FPGAController, load_verilog_seed
from cegis.tdes.fpga.mutation import VerilogLLMMutator
from cegis.tdes.fpga.verilog_runner import (
    SimResult,
    TestOutcome,
    activate_toolchain,
    find_tool,
    simulate,
    tools_available,
)
from cegis.tdes.fpga.verilog_suite import VerilogTest, VerilogTestSuite

# Phase 2/3 entry points (imported lazily-safe; loaders need no EDA tools to import)
from cegis.tdes.fpga.benchmark_loader import (
    apply_reference,
    is_usable,
    load_archxbench,
    load_resbench,
    load_rtllm,
)

__all__ = [
    "FPGAConfig",
    "FPGAController",
    "load_verilog_seed",
    "VerilogLLMMutator",
    "VerilogTest",
    "VerilogTestSuite",
    "simulate",
    "find_tool",
    "tools_available",
    "activate_toolchain",
    "SimResult",
    "TestOutcome",
    "load_rtllm",
    "load_archxbench",
    "load_resbench",
    "is_usable",
    "apply_reference",
]
