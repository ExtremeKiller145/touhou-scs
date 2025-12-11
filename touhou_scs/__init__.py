"""
## Touhou SCS - Shattered Crystal Shards
Bullet pattern generation system for Geometry Dash

A Python-based framework for creating complex bullet hell patterns
within Geometry Dash using automated trigger generation.

# Interpreting the output:

The generated components and triggers are flattened to a list of triggers,
which follows this JSON format:
{
    "{property_number}": value,
    "{group_property_number}": [int1, int2, ...]
}
"""

__version__ = "2.0.0"
__author__ = "xtreme420"

from touhou_scs.lib import (
    Spell,
    GuiderCircle,
    BulletPool,
    get_all_components,
    circle1,
    bullet1,
    bullet2,
    bullet3,
    bullet4,
    save_all,
)
from touhou_scs.component import Component
from touhou_scs import enums, utils
from touhou_scs.types import (
    Trigger,
    ComponentProtocol,
    SpellProtocol,
    GroupID,
    Time,
    Distance,
    Angle,
)

__all__ = [
    # Core classes
    "Component",
    "Spell",
    "GuiderCircle",
    "BulletPool",

    # Core functions
    "save_all",
    "get_all_components",

    # Pre-configured instances
    "circle1",
    "bullet1",
    "bullet2",
    "bullet3",
    "bullet4",

    # Modules
    "enums",
    "utils",

    # Type definitions (for type hints in user code)
    "Trigger",
    "ComponentProtocol",
    "SpellProtocol",
    "GroupID",
    "Time",
    "Distance",
    "Angle",
]
