"""
Touhou SCS - Enums and Constants Module

Contains all game constants, property IDs, and enumerated values.
Central location for magic numbers to ensure type safety and IDE autocomplete.
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

class Properties:
    """Trigger property field IDs for Geometry Dash level data"""
    
    # ========== General Properties ==========
    OBJ_ID: Final[int] = 1
    X: Final[int] = 2
    Y: Final[int] = 3
    DURATION: Final[int] = 10
    EDITOR_LAYER: Final[int] = 20
    EASING: Final[int] = 30
    TARGET: Final[int] = 51
    GROUPS: Final[int] = 57  # Requires JS-side translation, must be wrapped in array
    EDITOR_LAYER_2: Final[int] = 61
    SPAWN_TRIGGERED: Final[int] = 62
    EASING_RATE: Final[int] = 85
    MULTI_TRIGGERED: Final[int] = 87
    DYNAMIC: Final[int] = 397
    
    # ========== Alpha Trigger ==========
    OPACITY: Final[int] = 35
    
    # ========== Follow Trigger ==========
    FOLLOW_GROUP: Final[int] = 71
    
    # ========== Stop Trigger ==========
    STOP_OPTION: Final[int] = 580  # 0=stop, 1=pause, 2=resume
    STOP_USE_CONTROL_ID: Final[int] = 535  # boolean
    
    # ========== Toggle Trigger ==========
    ACTIVATE_GROUP: Final[int] = 56
    
    # ========== Collision Trigger ==========
    BLOCK_A: Final[int] = 80
    BLOCK_B: Final[int] = 95
    
    # ========== Pulse Trigger ==========
    PULSE_FADE_IN: Final[int] = 45
    PULSE_HOLD: Final[int] = 46
    PULSE_FADE_OUT: Final[int] = 47
    PULSE_HSV: Final[int] = 48  # HSV mode boolean
    PULSE_HSV_STRING: Final[int] = 49  # 'a' separated string like 'HaSaBa0a0'
    PULSE_TARGET_TYPE: Final[int] = 52  # false = color channel, true = group ID
    PULSE_EXCLUSIVE: Final[int] = 86
    
    # ========== Scale Trigger ==========
    SCALE_X: Final[int] = 150
    SCALE_Y: Final[int] = 151
    SCALE_CENTER: Final[int] = 71
    SCALE_DIV_BY_X: Final[int] = 153
    SCALE_DIV_BY_Y: Final[int] = 154
    
    # ========== Rotate Trigger ==========
    ROTATE_ANGLE: Final[int] = 68  # In degrees, clockwise is +
    ROTATE_CENTER: Final[int] = 71  # For Rotate triggers, type group
    ROTATE_TARGET: Final[int] = 401
    ROTATE_AIM_MODE: Final[int] = 100
    ROTATE_DYNAMIC_EASING: Final[int] = 403
    
    # ========== Spawn Trigger ==========
    REMAP_STRING: Final[int] = 442  # Dot separated. e.g. '1.2.3.4' remaps 1->2 and 3->4
    RESET_REMAP: Final[int] = 581  # Blocks other spawn triggers from remapping
    SPAWN_ORDERED: Final[int] = 441  # Boolean
    SPAWN_DELAY: Final[int] = 63
    
    # ========== Move Trigger ==========
    MOVE_X: Final[int] = 28
    MOVE_Y: Final[int] = 29
    MOVE_SMALL_STEP: Final[int] = 393  # Small step boolean. Better accuracy
    MOVE_TARGET_CENTER: Final[int] = 395  # Target's center for Direction/Goto
    MOVE_TARGET_DIR: Final[int] = 71  # Target for Direction mode
    MOVE_TARGET_LOCATION: Final[int] = 71  # Target for Goto mode
    MOVE_TARGET_MODE: Final[int] = 100  # 'Goto' mode boolean
    MOVE_DIRECTION_MODE: Final[int] = 394  # Direction mode boolean
    MOVE_DIRECTION_MODE_DISTANCE: Final[int] = 396
    MOVE_SILENT: Final[int] = 544  # Platformer mode 'silent' boolean
    
    # ========== Fields That Can Target Groups ==========
    # Used for trigger validation systems
    TARGET_FIELDS: Final[tuple[int, ...]] = (51, 71, 401, 395)


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

# Empty Groups for Remapping
# Holder object for empty groups is directly placed on the physical player, layer 0
EMPTY1: Final[int] = 21  # Empty group for targeting and remapping 21 -> whatever
EMPTY2: Final[int] = 23  # Empty group for targeting and remapping 23 -> whatever
EMPTY3: Final[int] = 24  # Empty group for targeting and remapping 24 -> whatever
EMPTY_BULLET: Final[int] = 10  # EMPTY1 for multitarget functionality only
EMPTY_TARGET_GROUP: Final[int] = 20  # EMPTY2 for multitarget functionality only
EMPTY_MULTITARGET: Final[int] = 9989  # Exclusively for multitarget functionality

# Distance
OFFSCREEN_DIST: Final[int] = 480  # Minimum distance to get bullet offscreen
MIN_ANGLE: Final[int] = 3  # Minimum angle for GuiderCircles

# Special Values
ROTATE_INFINITE_DURATION: Final[int] = -1
EDITOR_LAYER: Final[int] = 4  # Default editor layer

# Restricted Groups - DO NOT USE THESE GROUP IDs
# These groups are known to cause conflicts/corruption
RESTRICTED_GROUPS: Final[tuple[int, ...]] = (
    1, 3, 4, 5, 6, 7, 8, 9,
    11, 12, 13, 14, 15, 16, 17, 18, 19,
    22, 25, 9989, 9999
)


# ============================================================================
# SPEED PROFILES
# ============================================================================

class SpeedProfiles:
    """
    Predefined speed profiles for bullet movement.
    Time to travel OFFSCREEN_DIST for 'easing.t' parameters
    """
    VERY_SLOW: Final[float] = 480 / 32  # 15.0 seconds
    SLOW: Final[float] = 480 / 16       # 7.5 seconds
    MEDIUM: Final[float] = 480 / 8      # 3.75 seconds
    FAST: Final[float] = 480 / 4        # 1.875 seconds
    VERY_FAST: Final[float] = 480 / 2   # 0.9375 seconds


# ============================================================================
# DEFAULT CONFIGURATIONS
# ============================================================================

class DefaultEasing:
    """Default values for easing configurations"""
    T: Final[float] = 0
    TYPE: Final[int] = 0
    RATE: Final[float] = 1
    DIST: Final[int] = 480
    ANGLE: Final[int] = 90
    DYNAMIC: Final[bool] = False