"""
OpenEvolve: An open-source implementation of AlphaEvolve
"""

from cegis._version import __version__
from cegis.config import Config
from cegis.controller import OpenEvolve
from cegis.api import (
    run_evolution,
    evolve_function,
    evolve_algorithm,
    evolve_code,
    EvolutionResult,
)

__all__ = [
    "Config",
    "OpenEvolve",
    "__version__",
    "run_evolution",
    "evolve_function",
    "evolve_algorithm",
    "evolve_code",
    "EvolutionResult",
]
