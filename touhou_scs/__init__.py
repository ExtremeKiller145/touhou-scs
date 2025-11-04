"""
Touhou SCS - Shattered Crystal Shards
Bullet pattern generation system for Geometry Dash

A Python-based framework for creating complex bullet hell patterns
within Geometry Dash using automated trigger generation.
"""

__version__ = "2.0.0"
__author__ = "xtreme420"

from touhou_scs.lib import (
    Spell,
    GuiderCircle,
    BulletPool,
    save_all,
    circle1,
    bullet_pool_1,
    bullet_pool_2,
    bullet_pool_3,
    bullet_pool_4,
)
from touhou_scs import enums
from touhou_scs.types import (
    Trigger,
    ComponentProtocol,
    SpellProtocol,
    GuiderCircleData,
    BulletPoolData,
    GroupID,
    Time,
    Distance,
    Angle,
)

__all__ = [
    # Core classes
    "Spell",
    "GuiderCircle",
    "BulletPool",
    
    # Export function
    "save_all",
    
    # Pre-configured instances
    "circle1",
    "bullet_pool_1",
    "bullet_pool_2",
    "bullet_pool_3",
    "bullet_pool_4",
    
    # Enums module
    "enums",
    
    # Type definitions (for type hints in user code)
    "Trigger",
    "ComponentProtocol",
    "SpellProtocol",
    "GuiderCircleData",
    "BulletPoolData",
    "GroupID",
    "Time",
    "Distance",
    "Angle",
]