"""
Touhou SCS - Utilities Module

Helper functions for component building and validation.
"""
from warnings import warn

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


def translate_remap_string(remap_string: str):
    """
    Parse remap string into source -> target dictionary.
    
    Returns (dict[source] = target, clean_remap_string)
    """
    
    parts = remap_string.split(".")
    if len(parts) == 0:
        raise ValueError("Remap string is empty")
    if len(parts) % 2 != 0:
        raise ValueError(f"Remap string must contain an even number of parts:\n{remap_string}")

    # Build pairs[source] = target
    pairs: dict[str,str] = {}
    for i in range(0, len(parts), 2):
        pairs[parts[i]] = parts[i + 1]

    source_check: dict[str, bool] = {}
    target_check: dict[str, bool] = {}

    for source, target in pairs.items():
        if source in source_check:
            raise ValueError(f"Duplicate source '{source}' in remap string - cannot remap one group to multiple targets")
        source_check[source] = True

        if target in target_check:
            raise ValueError(f"Duplicate target '{target}' in remap string - cannot remap multiple groups to same target")
        target_check[target] = True

    # Rebuild clean remap string (removing redundant mappings like 10 => 10)
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
