"""
Touhou SCS - Type Definitions

Centralized type definitions using Python's typing system.
Provides structure and IDE autocomplete without runtime overhead.

How this works:
- TypedDict: Define dictionary structures with typed keys (like trigger dicts)
- Protocol: Define interfaces that classes can implement (duck typing with types)
- Type aliases: Create readable names for complex types
- These are purely for type checking (mypy/pyright) and IDE hints
- No runtime validation - use business logic validation only when needed

API Design Philosophy:
==================
Use Python's keyword-only arguments (args after *) to force explicit naming
of specialized/optional parameters. This replaces Lua's table argument pattern.

Arguments before * : Required positional or positional with defaults
Arguments after *  : Keyword-only (must be named), order doesn't matter

Component Method Signatures:
============================

# Basic triggers
spawn(time, target, spawn_ordered, *, remap=None, spawn_delay=0)
toggle(time, target, activate_group)

# Movement triggers  
move_towards(time, target, target_dir, *, t=0, dist, type=0, rate=1.0, dynamic=False)
move_by(time, target, *, dx, dy, t=0, type=0, rate=1.0)
goto_group(time, target, location, *, t=0, type=0, rate=1.0)

# Transform triggers
rotate(time, *, target, angle, center=None, t=0, type=0, rate=1.0, dynamic=False)
point_to_group(time, target, target_dir, *, t=0, type=0, rate=1.0, dynamic=False)
scale(time, target, *, factor, divide=False, t=0, type=0, rate=1.0)

# Visual triggers
pulse(time, target, hsv_type, *, fade_in=0, t=0, fade_out=0)
follow(time, target, target_dir, *, t=0)
alpha(time, target, *, opacity, t=0)

# Control triggers
stop(time, target, *, use_control_id=False)
pause(time, target, *, use_control_id=False)
resume(time, target, *, use_control_id=False)

# Pattern generation (implemented later)
instant_radial(time, component, guider_circle, bullet_type, *, 
               spacing=0, num_bullets=12, center_at=None)
instant_arc(time, component, guider_circle, bullet_type, *, 
            spacing, num_bullets, center_at=None, radial_bypass=False)
instant_line(time, component, target_dir, bullet_type, *, 
             num_bullets, t_fast, t_slow, dist, delay=0, rate=1.0, type=0)

Example Usage:
=============

comp = Component("Pattern", unknown_g())

# Spawn - boolean positional, keywords optional
comp.spawn(0.5, bullet_group, True, remap="10.20")
comp.spawn(0.5, bullet_group, False)

# Move - mix of positional and keyword-only
comp.move_towards(1.0, bullet, player, dist=300, t=2.0, type=1)
comp.move_by(0.5, bullet, dx=100, dy=-50, t=1.5)

# Rotate - target and angle are keyword-only
comp.rotate(1.0, target=bullet, angle=90, t=2.0, type=1)

# Pulse - hsv_type positional, timing keywords
comp.pulse(0.2, bullet, "red", fade_in=0.3, t=1.0, fade_out=0.2)
"""

from typing import TypedDict, Protocol, Literal, Callable

# ============================================================================
# TRIGGER STRUCTURE
# ============================================================================

# TypedDict requires string keys, so we use a type alias instead
Trigger = dict[int, int | str | bool | float]

class ComponentProtocol(Protocol):
    """Interface for Component objects."""

    componentName: str
    callerGroup: int
    editorLayer: int
    requireSpawnOrder: bool | None
    triggers: list[Trigger]
    
    def assert_spawn_order(self, required: bool) -> "ComponentProtocol":
        """Set spawn order requirement. Returns self for chaining."""
        ...


class SpellProtocol(Protocol):
    """Interface for Spell objects"""
    spell_name: str
    caller_group: int
    components: list[ComponentProtocol]
    
    def add_component(self, component: ComponentProtocol) -> "SpellProtocol":
        """Add component to spell. Returns self for chaining."""
        ...


class RemapPair(TypedDict, total=False):
    source: str
    target: str  # Set directly
    targetFn: Callable[[], int]  # Or computed from function

NumberCycler = Callable[[], int]
"""Function that returns sequential numbers, cycling back to min after max"""

BulletCycler = Callable[[], tuple[int, int]]
"""Function that returns (bullet_group, collision_group) tuple"""


# ============================================================================
# BUILTIN REFERENCES TO LEVEL OBJECTS
# ============================================================================

class GuiderCircleData(TypedDict):
    """Data structure for GuiderCircle configuration"""
    all: int  # Group containing entire circle
    center: int  # Center group for positioning
    pointer: int  # First group in circle (angle 1)
    groups: dict[int, int]  # groups[1..360] = group IDs for each angle

class BulletPoolData(TypedDict):
    """Data structure for bullet pool configuration"""
    minGroup: int
    maxGroup: int
    nextBullet: BulletCycler

# ============================================================================
# EXPORT STRUCTURES
# ============================================================================

class TriggerArea(TypedDict):
    """Bounds for trigger spreading in SaveAll"""
    minX: int
    minY: int
    maxX: int
    maxY: int


class ExportData(TypedDict):
    """Final export format for triggers.json"""
    triggers: list[Trigger]


class BudgetStats(TypedDict):
    """Budget analysis statistics"""
    totalTriggers: int
    objectBudget: int
    usagePercent: float
    remainingBudget: int


class Statistics(TypedDict):
    """Complete statistics from SaveAll"""
    spellStats: dict[str, int]
    componentStats: dict[str, int]
    sharedTriggerCount: int
    budget: BudgetStats


# ============================================================================
# TYPE ALIASES FOR SELF-DOCUMENTING CODE
# ============================================================================

GroupID = int  # Normal group (0-9999) or unknown_g placeholder (10000+)
Time = float  # Time in seconds (positional arg in most triggers)
Distance = float  # Distance in studs
Angle = float  # Angle in degrees

# Literal types for specific options
SpawnOrderRequirement = Literal[True, False, None]
EasingType = Literal[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18]
SpeedProfile = Literal["VERY_SLOW", "SLOW", "MEDIUM", "FAST", "VERY_FAST"]
