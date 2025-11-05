"""
Touhou SCS - Type Definitions
"""

from typing import Protocol


# ==========================================
# TRIGGER STRUCTURE
# ==========================================

Trigger = dict[int, int | str | bool | float]
"""
Trigger dictionary with integer property IDs as keys.

Keys are from enums.Properties (e.g., Properties.X, Properties.DURATION)
Values are limited to int, str, bool, or float for type safety.

Common fields (all triggers):
- OBJ_ID: ObjectID - Trigger type
- X: float - X position (time-based)
- Y: float - Y position (set by spread)
- GROUPS: int - Caller group
- EDITOR_LAYER: int - Editor layer
- SPAWN_TRIGGERED: bool - Must be spawn-triggered
- MULTI_TRIGGERED: bool - Can trigger multiple times

Other fields depend on trigger type - see enums.Properties for full list.
"""


# ==========================================
# COMPONENT PROTOCOL
# ==========================================

class ComponentProtocol(Protocol):
    """
    Interface for Component objects.
    
    Any class implementing these attributes/methods can be used as a Component.
    This is Python's way of doing duck typing with type safety.
    """
    componentName: str
    callerGroup: int
    editorLayer: int
    requireSpawnOrder: bool | None
    triggers: list[Trigger]
    
    def assert_spawn_order(self, required: bool) -> "ComponentProtocol":
        """Set spawn order requirement. Returns self for chaining."""
        ...


# ==========================================
# SPELL PROTOCOL
# ==========================================

class SpellProtocol(Protocol):
    """Interface for Spell objects"""
    spell_name: str
    caller_group: int
    components: list[ComponentProtocol]
    
    def add_component(self, component: ComponentProtocol) -> "SpellProtocol":
        """Add component to spell. Returns self for chaining."""
        ...


# ==========================================
# TYPE ALIASES FOR SELF-DOCUMENTING CODE
# ==========================================

GroupID = int
"""Normal group (0-9999) or unknown_g placeholder (10000+)"""

Time = float
"""Time in seconds (positional arg in most triggers)"""

Distance = float
"""Distance in studs"""

Angle = float
"""Angle in degrees"""
