"""
TDES-FPGA: evolve Verilog RTL against hierarchical testbenches.

Additive layer over ``cegis.tdes`` that swaps the Python import/exec test
runner for an open-source EDA pipeline (Icarus Verilog + Yosys), while reusing
the TDES controller, selection, complementary-coverage crossover, and negative
memory unchanged.
"""

from cegis.tdes.fpga.config import FPGAConfig
from cegis.tdes.fpga.verilog_runner import (
    SimResult,
    TestOutcome,
    activate_toolchain,
    find_tool,
    simulate,
    tools_available,
)
from cegis.tdes.fpga.verilog_suite import VerilogTest, VerilogTestSuite

__all__ = [
    "FPGAConfig",
    "VerilogTest",
    "VerilogTestSuite",
    "simulate",
    "find_tool",
    "tools_available",
    "activate_toolchain",
    "SimResult",
    "TestOutcome",
]
