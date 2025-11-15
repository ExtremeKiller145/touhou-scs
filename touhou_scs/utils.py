"""
Touhou SCS - Utilities Module

Helper functions for component building and validation.
"""

from warnings import warn
from touhou_scs import enums as enum
from touhou_scs.types import ComponentProtocol

def time_to_dist(time: float) -> float:
    """
    Convert time in seconds to distance in studs (X position).
    Based on player movement speed of 311.58 studs/second.
    """
    return 311.58 * time


_unknown_counter = 10000

def unknown_g() -> int:
    """
    Generate unique unknown group ID for placeholder groups.
    
    Returns integer starting from 10,000 and incrementing.
    These placeholders are resolved to actual group IDs by main.js before export.
    """
    global _unknown_counter
    result = _unknown_counter
    _unknown_counter += 1
    return result


def group(group_id: int) -> int:
    """Group integer wrapper for self-documenting code"""
    return group_id


def translate_remap_string(remap_string: str) -> tuple[dict[int, int], str]:
    """
    Parse remap string into source -> target dictionary, w/ remap validation.
    
    Returns (dict[source] = target, clean_remap_string)
    """
    
    parts = remap_string.split(".")
    if len(parts) == 0:
        raise ValueError("Remap string is empty")
    if len(parts) % 2 != 0:
        raise ValueError(f"Remap string must contain an even number of parts:\n{remap_string}")

    # Build pairs[source] = target as integers
    pairs: dict[int, int] = {}
    for i in range(0, len(parts), 2):
        source = int(parts[i])
        target = int(parts[i + 1])
        pairs[source] = target

    source_check: dict[int, bool] = {}

    # Duplicate targets are allowed.
    # (i.e. must pass Vertical Line Test, but doesnt need to be one-to-one)
    for source, target in pairs.items():
        if source in source_check:
            raise ValueError(f"Duplicate source '{source}' in remap string - cannot remap one group to multiple targets")
        source_check[source] = True

    clean_pairs: list[str] = []
    for source, target in pairs.items():
        if source != target:
            clean_pairs.append(f"{source}.{target}")
    
    clean_string = ".".join(clean_pairs)
    
    if clean_string != remap_string:
        warn(f"Remap string had redundant mappings:\n{remap_string}", stacklevel=2)
    if len(clean_string) == 0:
        raise ValueError(f"Remap string is empty after cleaning redundant mappings: \n {remap_string}")

    return pairs, clean_string


class Remap:
    """
    Remap string builder class with chainable API
    
    Example:
        rb = Remap().pair(10, 20).pair(30, 40)
        
        remap_string = rb.build()  # "10.20.30.40"
    """
    
    def __init__(self):
        self._pairs: dict[int,int] = {}
    
    def pair(self, source: int, target: int):
        """Add a source -> target remap pair"""
        self._pairs[source] = target
        return self
    
    def build(self) -> str:
        """Build to remap string from added pairs"""
        parts: list[str] = []
        for source, target in self._pairs.items():
            parts.append(f"{source}.{target}")
        return ".".join(parts)


def create_number_cycler(min_val: int, max_val: int):
    """Returns a cycler function that returns sequential numbers in a range."""
    if min_val > max_val: raise ValueError("create_number_cycler: min cannot be greater than max")
    
    current = min_val - 1
    def cycler() -> int:
        nonlocal current
        current += 1
        if current > max_val: current = min_val
        return current
    return cycler


def enforce_component_targets(fn_name: str, comp: ComponentProtocol,*,
    requires: set[int] | None = None, excludes: set[int] | None = None):
    """
    Validate that component targets (or doesn't target) specific groups.
    
    requires: Set of group IDs that must be targeted
    excludes: Set of group IDs that must NOT be targeted
    """
    if comp.requireSpawnOrder is not True:
        raise ValueError(f"{fn_name}: component must require spawn order")

    requires = requires or set()
    excludes = excludes or set()
    
    found_targets: set[int] = set()
    for trigger in comp.triggers:
        for field in enum.TARGET_FIELDS:
            target = trigger.get(field)
            if target is not None and isinstance(target, int):
                found_targets.add(target)
    
    missing = requires - found_targets
    if missing:
        missing_names = [f"{g}" for g in missing]
        raise ValueError(
            f"{fn_name}: component must target {', '.join(missing_names)}"
        )
    
    forbidden = found_targets & excludes
    if forbidden:
        forbidden_names = [f"{g}" for g in forbidden]
        raise ValueError(
            f"{fn_name}: component must not target {', '.join(forbidden_names)}"
        )
