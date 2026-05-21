"""
Touhou SCS - Type Definitions
"""

from typing import TypedDict, Protocol, Any

from gmdbuilder import AllPropsType


# ==========================================
# TRIGGER STRUCTURE
# ==========================================
GenericObj = AllPropsType

# ==========================================
# COMPONENT PROTOCOL
# ==========================================

class ComponentProtocol(Protocol):
    """
    Interface for Component objects.

    Any class implementing these attributes/methods can be used as a Component.
    This is Python's way of doing duck typing with type safety.
    """
    name: str
    caller: int
    groups: set[int]
    editorLayer: int
    requireSpawnOrder: bool | None
    triggers: list[GenericObj]
    target: int
    current_pc: Any

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
# RANDOM TYPE ALIASES AND STUFF
# ==========================================

TriggerArea = TypedDict('TriggerArea', {
    "min_x": int,
    "min_y": int,
    "max_x": int,
    "max_y": int
})
