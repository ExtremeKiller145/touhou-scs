"""
Touhou SCS - Enums and Constants Module

All game constants, property IDs, and enumerated values.
Central location for magic numbers with type safety and IDE autocomplete.
"""

from enum import IntEnum
from typing import Final


# ============================================================================
# OBJECT IDs - Trigger Types
# ============================================================================

class ObjectID(IntEnum):
    """Geometry Dash trigger object IDs"""
    TOGGLE = 1049
    SPAWN = 1268
    PULSE = 1006
    SCALE = 2067
    MOVE = 901
    ROTATE = 1346
    COLLISION = 1815
    STOP = 1616
    COUNT = 1611
    FOLLOW = 1347
    ALPHA = 1007
    INSTANT_COUNT = 1811
    RANDOM = 1912
    ADVANCED_RANDOM = 2068


# ============================================================================
# EASING TYPES
# ============================================================================

class Easing(IntEnum):
    """Easing curve types for trigger animations"""
    NONE = 0
    EASE_IN_OUT = 1
    EASE_IN = 2
    EASE_OUT = 3
    ELASTIC_IN_OUT = 4
    ELASTIC_IN = 5
    ELASTIC_OUT = 6
    BOUNCE_IN_OUT = 7
    BOUNCE_IN = 8
    BOUNCE_OUT = 9
    EXPONENTIAL_IN_OUT = 10
    EXPONENTIAL_IN = 11
    EXPONENTIAL_OUT = 12
    SINE_IN_OUT = 13
    SINE_IN = 14
    SINE_OUT = 15
    BACK_IN_OUT = 16
    BACK_IN = 17
    BACK_OUT = 18


# ============================================================================
# TRIGGER PROPERTIES - Field IDs
# ============================================================================

class Properties(str):
    """Trigger property field IDs for Geometry Dash level data"""
    
    # ========== General Properties ==========
    OBJ_ID = "1"
    X = "2"
    Y = "3"
    DURATION = "10"
    EDITOR_LAYER = "20"
    EASING = "30"
    TARGET = "51"
    GROUPS = "57"  # Requires JS-side translation, must be wrapped in array
    EDITOR_LAYER_2 = "61"
    SPAWN_TRIGGERED = "62"
    EASING_RATE = "85"
    MULTI_TRIGGERED = "87"
    DYNAMIC = "397"
    
    # ========== Alpha Trigger ==========
    OPACITY = "35"
    
    # ========== Follow Trigger ==========
    FOLLOW_GROUP = "71"
    
    # ========== Stop Trigger ==========
    STOP_OPTION = "580"
    """0=stop, 1=pause, 2=resume"""
    STOP_USE_CONTROL_ID = "535"  # boolean
    
    # ========== Toggle Trigger ==========
    ACTIVATE_GROUP = "56"
    
    # ========== Collision Trigger ==========
    BLOCK_A = "80"
    BLOCK_B = "95"
    
    # ========== Pulse Trigger ==========
    PULSE_FADE_IN = "45"
    PULSE_HOLD = "46"
    PULSE_FADE_OUT = "47"
    PULSE_HSV = "48"
    """HSV mode boolean"""
    PULSE_HSV_STRING = "49"
    """'a' separated string like 'HaSaBa0a0'"""
    PULSE_TARGET_TYPE = "52"  
    """false = color channel, true = group ID"""
    PULSE_EXCLUSIVE = "86"
    
    # ========== Scale Trigger ==========
    SCALE_X = "150"
    SCALE_Y = "151"
    SCALE_CENTER = "71"
    SCALE_DIV_BY_X = "153"
    SCALE_DIV_BY_Y = "154"
    
    # ========== Rotate Trigger ==========
    ROTATE_ANGLE = "68"  # In degrees, clockwise is +
    ROTATE_CENTER = "71"  # For Rotate triggers, type group
    ROTATE_TARGET = "401"
    ROTATE_AIM_MODE = "100"
    ROTATE_DYNAMIC_EASING = "403"
    
    # ========== Spawn Trigger ==========
    REMAP_STRING = "442"  
    """Dot separated. e.g. '1.2.3.4' remaps 1->2 and 3->4"""
    RESET_REMAP = "581"  
    """Bool: Blocks other spawn triggers from remapping"""
    SPAWN_ORDERED = "441"
    """Bool: spawns a trigger function from left to right with time gaps based on player speed"""
    SPAWN_DELAY = "63"
    
    # ========== Move Trigger ==========
    MOVE_X = "28"
    MOVE_Y = "29"
    MOVE_SMALL_STEP = "393"  
    """Bool: Sets Move triggers to the '1/30 of a block' unit standard"""
    MOVE_TARGET_CENTER = "395"  # Target's center for Direction/Goto
    MOVE_TARGET_DIR = "71"
    """Target for Direction mode"""
    MOVE_TARGET_LOCATION = "71"
    """Target for Goto mode"""
    MOVE_TARGET_MODE = "100"
    """'Goto' mode boolean"""
    MOVE_DIRECTION_MODE = "394" # Direction mode boolean
    MOVE_DIRECTION_MODE_DISTANCE = "396"
    MOVE_SILENT = "544"  # Platformer mode 'silent' boolean


# ========== Fields That Can Target Groups ==========
# Used for trigger validation systems
TARGET_FIELDS: Final[tuple[str, ...]] = ("51", "71", "401", "395")


# ============================================================================
# GAME CONSTANTS
# ============================================================================

# Timing
TICK: Final[float] = 1 / 240  # One game tick in seconds

# Speed
PLR_SPEED: Final[float] = 311.58  # Player movement speed in studs/second

# Special Groups
PLR: Final[int] = 2  # Player group ID
SCREEN_CENTER: Final[int] = 30  # Center group of game window
NORTH_GROUP: Final[int] = 26

# Empty Groups for Remapping   (e.g. 21 => group)
# Holder object for empty groups is directly placed on the physical player, layer 0
EMPTY1: Final[int] = 21  
EMPTY2: Final[int] = 23  
EMPTY3: Final[int] = 24  
EMPTY_BULLET: Final[int] = 10
EMPTY_TARGET_GROUP: Final[int] = 20

EMPTY_MULTITARGET: Final[int] = 9989 # Restricted; multitarget exclusive

# Distance
OFFSCREEN_DIST: Final[int] = 480  # Minimum distance to get bullet offscreen
MIN_ANGLE: Final[int] = 3  # Minimum angle for GuiderCircles

EDITOR_LAYER: Final[int] = 4
"""Default editor layer"""

RESTRICTED_GROUPS: Final[tuple[int, ...]] = (
    1, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 19, 22, 25, 9999
)
"""Reserved groups for various safety reasons - DO NOT USE THESE GROUP IDs"""

# ============================================================================
# SPEED PROFILES
# ============================================================================

# Predefined speed profiles for bullet movement.
# Time to travel OFFSCREEN_DIST (480 studs) at different speeds.
SPEED_VERY_SLOW: Final[float] = 480 / 32  # 15.0 seconds
SPEED_SLOW: Final[float] = 480 / 16       # 7.5 seconds
SPEED_MEDIUM: Final[float] = 480 / 8      # 3.75 seconds
SPEED_FAST: Final[float] = 480 / 4        # 1.875 seconds
SPEED_VERY_FAST: Final[float] = 480 / 2   # 0.9375 seconds
