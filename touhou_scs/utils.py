"""
Touhou SCS - Utilities Module

Utility functions, validators, type aliases, and helper classes.
"""

from typing import Callable
from . import enums as e


# ============================================================================
# TYPE ALIASES
# ============================================================================

GroupID = int | str
"""Type alias for group identifiers (can be int or string for unknown groups)"""


# ============================================================================
# UNKNOWN GROUP GENERATION
# ============================================================================

_unknown_group_counter: int = 100000
"""Counter for generating unique unknown group IDs starting at 100000"""


def unknownG() -> int:
    """Generate unique unknown group ID in 100000+ range"""
    global _unknown_group_counter
    current = _unknown_group_counter
    _unknown_group_counter += 1
    
    if current > 110000:
        print(f"\nWARNING: High unknown group usage ({current - 100000}/10000 used)\n")
    
    return current


def resetUnknownGCounter() -> None:
    """Reset unknown group counter (for testing)"""
    global _unknown_group_counter
    _unknown_group_counter = 100000


# ============================================================================
# SEMANTIC WRAPPERS
# ============================================================================

def group(val: GroupID) -> GroupID:
    """Semantic wrapper for group values"""
    return val


# ============================================================================
# CONVERSION FUNCTIONS
# ============================================================================

def timeToDist(time: float) -> float:
    """Convert time in seconds to distance in studs"""
    return e.PLR_SPEED * time


def distToTime(dist: float) -> float:
    """Convert distance in studs to time in seconds"""
    return dist / e.PLR_SPEED


def spacingBullet(speedOfProjectile: float, studsOfSpacing: float) -> float:
    """Convert block studs & projectile speed to projectile spacing"""
    return studsOfSpacing / speedOfProjectile * e.PLR_SPEED


# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

def validateGroups(methodName: str, *groups: GroupID) -> None:
    """Validate groups are not restricted (0-9999 or 100000+)"""
    for group in groups:
        if isinstance(group, int):
            if 0 <= group <= 9999 and group in e.RESTRICTED_GROUPS:
                raise ValueError(
                    f"{methodName}: Group {group} is restricted due to known conflicts"
                )
            elif not (0 <= group <= 9999 or group >= 100000):
                raise ValueError(
                    f"{methodName}: Group {group} is not in valid range (0-9999 or 100000+)"
                )
        else:
            raise ValueError(
                f"{methodName}: Invalid group type: {type(group).__name__}"
            )



def isInteger(num: float) -> bool:
    """Check if a number is an integer value"""
    return num == int(num)


# ============================================================================
# CYCLER FACTORIES
# ============================================================================

def createNumberCycler(min_val: int, max_val: int) -> Callable[[], int]:
    """Create cycler that returns sequential numbers in a range, cycling back to min after max"""
    if not isInteger(min_val) or not isInteger(max_val):
        raise ValueError("createNumberCycler: min and max must be integers")
    
    if min_val > max_val:
        raise ValueError("createNumberCycler: min cannot be greater than max")
    
    current = min_val - 1
    
    def cycler() -> int:
        nonlocal current
        current += 1
        if current > max_val:
            current = min_val
        return current
    
    return cycler


def createBulletCycler(min_val: int, max_val: int) -> Callable[[], tuple[int, int]]:
    """Create bullet cycler returning (bullet_group, collision_group) tuple"""
    cycler = createNumberCycler(min_val, max_val)
    range_size = max_val - min_val + 1
    
    def bulletCycler() -> tuple[int, int]:
        bullet = cycler()
        collision = bullet + range_size
        return bullet, collision
    
    return bulletCycler


# ============================================================================
# REMAP STRING UTILITIES
# ============================================================================

def translateRemapString(remapString: str) -> dict[str, str]:
    """Parse dot-separated remap string into dictionary (e.g. '1.2.3.4' -> {1:2, 3:4})"""
    
    parts = remapString.split('.')
    
    if len(parts) == 0:
        raise ValueError("translateRemapString: remapString must contain at least one valid pair")
    
    if len(parts) % 2 != 0:
        raise ValueError(
            f"translateRemapString: remapString must contain an even number of parts:\n{remapString}"
        )
    
    pairs: dict[str, str] = {}
    for i in range(0, len(parts), 2):
        pairs[parts[i]] = parts[i + 1]
    
    return pairs


def validateRemapString(methodName: str, remapString: str) -> str:
    """Validate and clean remap string by removing redundant mappings"""
    
    remapPairs = translateRemapString(remapString)
    
    # Check for duplicates
    sourceCheck: set[str] = set()
    targetCheck: set[str] = set()
    
    for source, target in remapPairs.items():
        if source in sourceCheck:
            raise ValueError(
                f"{methodName}: Duplicate source '{source}' in remap string - " +
                "cannot remap one group to multiple targets"
            )
        sourceCheck.add(source)
        
        if target in targetCheck:
            raise ValueError(
                f"{methodName}: Duplicate target '{target}' in remap string - " +
                "cannot remap multiple groups to same target"
            )
        targetCheck.add(target)
    
    cleanPairs: list[str] = []
    for source, target in remapPairs.items():
        if source != target:
            cleanPairs.extend([source, target])
    
    cleanString = '.'.join(cleanPairs)
    
    if cleanString != remapString:
        print(f"{methodName}: WARNING! Remap string had redundant mappings removed")
    
    return cleanString


# ============================================================================
# REMAP BUILDER
# ============================================================================

class RemapBuilder:
    """
    Fluent builder for constructing dot-separated remap strings safely.
    
    Example:
        >>> builder = RemapBuilder()
        >>> builder.pair(10, 6001).pair(20, 6002).build()
        '10.6001.20.6002'
    """
    
    def __init__(self):
        self._pairs: list[tuple[str, str | Callable[[], int]]] = []
    
    def pair(self, source: GroupID, target: GroupID) -> 'RemapBuilder':
        """Add source->target remap pair"""
        self._pairs.append((str(source), str(target)))
        return self
    
    def pairFunc(self, source: GroupID, targetFn: Callable[[], int]) -> 'RemapBuilder':
        """Add source->target pair where target is lazily evaluated (useful for cyclers)"""
        
        self._pairs.append((str(source), targetFn))
        return self
    
    def build(self) -> str:
        """Build final remap string with validation, removes identity mappings"""
        parts: list[str] = []
        seenSources: set[str] = set()
        seenTargets: set[str] = set()
        
        for source, target in self._pairs:
            if callable(target):
                tgt = str(target())
            else:
                tgt = str(target)
            
            src = str(source)
            
            if not tgt:
                raise ValueError(f"RemapBuilder: Unresolved target for source {src}")
            
            if src in seenSources:
                raise ValueError(f"RemapBuilder: Duplicate source '{src}'")
            
            if tgt in seenTargets:
                raise ValueError(f"RemapBuilder: Duplicate target '{tgt}'")
            
            seenSources.add(src)
            seenTargets.add(tgt)
            
            if src != tgt:
                parts.append(src)
                parts.append(tgt)
        
        return '.'.join(parts)
