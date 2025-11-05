"""
Touhou SCS - Component Module

Component class for building trigger sequences with method chaining.

URGENT: SpellBuilder is not yet implemented! stuff is commented out until then.
"""

from __future__ import annotations
# from typing import TYPE_CHECKING

from touhou_scs import enums as enum, lib, utils as util
from touhou_scs.types import Trigger

# if TYPE_CHECKING:
#     from touhou_scs.spellbuilder import InstantPatterns, TimedPatterns

_RESTRICTED_LOOKUP = { group_id: True for group_id in enum.RESTRICTED_GROUPS }

ppt = enum.Properties # shorthand

class Component:
    """
    Component for building trigger sequences.
    Auto-registers to lib.all_components. All methods return self for chaining.
    """
    
    def __init__(self, componentName: str, callerGroup: int, editorLayer: int = 4):
        self.componentName: str = componentName
        self.callerGroup: int = callerGroup
        self.editorLayer: int = editorLayer
        self.requireSpawnOrder: bool | None = None
        self.triggers: list[Trigger] = []
        
        lib.all_components.append(self)
        
        # self._instant: InstantPatterns | None = None
        # self._timed: TimedPatterns | None = None
    
    # @property
    # def instant(self) -> InstantPatterns:
    #     """Access instant pattern methods (lazy-loaded)"""
    #     if self._instant is None:
    #         from touhou_scs.spellbuilder import InstantPatterns
    #         self._instant = InstantPatterns(self)
    #     return self._instant
    
    # @property
    # def timed(self) -> TimedPatterns:
    #     """Access timed pattern methods (lazy-loaded)"""
    #     if self._timed is None:
    #         from touhou_scs.spellbuilder import TimedPatterns
    #         self._timed = TimedPatterns(self)
    #     return self._timed
    
    def _create_trigger(self, obj_id: int, x: float, target: int) -> Trigger:
        """
        Create trigger with component defaults.
        
        Note: 
            X is not time-based
            
            Target does not accept Component objects.
        """
        
        if _RESTRICTED_LOOKUP.get(target):
            raise ValueError(f"Group '{target}' is restricted due to known conflicts.")
        
        return {
            ppt.OBJ_ID: obj_id,
            ppt.X: x,
            ppt.TARGET: target,
            ppt.GROUPS: self.callerGroup,
            ppt.EDITOR_LAYER: self.editorLayer,
            ppt.SPAWN_TRIGGERED: True,
            ppt.MULTI_TRIGGERED: True,
        }
    
    def assert_spawn_order(self, required: bool):
        """Set component spawn order requirement."""
        self.requireSpawnOrder = required
        return self
    
    # ========================================================================
    # TRIGGER METHODS
    # ========================================================================
    
    def Spawn(self, time: float,
        target: int | Component,
        spawnOrdered: bool, *,
        remap: str | None = None,
        delay: float = 0 ):
        """
        Spawn another component or group's triggers
        
        Optional: remap string, spawnDelay
        """
        
        target = target.callerGroup if isinstance(target, Component) else target
        
        trigger = self._create_trigger(enum.ObjectID.SPAWN, util.time_to_dist(time), target)
        trigger[ppt.SPAWN_ORDERED] = spawnOrdered
        
        if delay > 0: trigger[ppt.SPAWN_DELAY] = delay
        if remap:
            _, clean_remap = util.translate_remap_string(remap)
            trigger[ppt.REMAP_STRING] = clean_remap
        
        self.triggers.append(trigger)
        return self
    
    def Toggle(self, time: float, target: int | Component, activateGroup: bool):
        """
        Toggle a group or component on or off
        
        WARNING: A deactivated object cannot be reactivated by a different group
        (collision triggers might be different)
        """
        target = target.callerGroup if isinstance(target, Component) else target
        
        trigger = self._create_trigger(enum.ObjectID.TOGGLE, util.time_to_dist(time), target)
        trigger[ppt.ACTIVATE_GROUP] = activateGroup
        
        self.triggers.append(trigger)
        return self
    
    def MoveTowards(self, time: float, target: int, targetDir: int, *,
        t: float, dist: float,
        type: int = 0, rate: float = 1.0, dynamic: bool = False,
        center: int = 0):
        """
        Move target a set distance towards another group (direction mode)
        
        Optional: type, rate, dynamic, center of target
        """
        
        trigger = self._create_trigger(enum.ObjectID.MOVE, util.time_to_dist(time), target)
        
        trigger[ppt.DURATION] = t
        trigger[ppt.MOVE_DIRECTION_MODE] = True
        trigger[ppt.MOVE_SMALL_STEP] = True
        trigger[ppt.MOVE_TARGET_DIR] = targetDir
        trigger[ppt.MOVE_TARGET_CENTER] = center if center != 0 else target

        trigger[ppt.MOVE_DIRECTION_MODE_DISTANCE] = dist
        trigger[ppt.EASING] = type
        trigger[ppt.EASING_RATE] = rate
        
        if dynamic: trigger[ppt.DYNAMIC] = True
        
        self.triggers.append(trigger)
        return self
    
    def Pulse(self, time: float, target: int, *,
        h: int, s: int, b: int, exclusive: bool = False,
        fadeIn: float = 0, t: float = 0, fadeOut: float = 0):
        """
        Pulse a group's HSV/color
        
        Optional: fadeIn, t, fadeOut
        """
        
        trigger = self._create_trigger(enum.ObjectID.PULSE, util.time_to_dist(time), target)

        trigger[ppt.PULSE_HSV] = True
        trigger[ppt.PULSE_TARGET_TYPE] = True
        trigger[ppt.PULSE_HSV_STRING] = f"{h}a{s}a{b}a0a0"
        trigger[ppt.PULSE_FADE_IN] = fadeIn
        trigger[ppt.PULSE_HOLD] = t
        trigger[ppt.PULSE_FADE_OUT] = fadeOut

        if exclusive: trigger[ppt.PULSE_EXCLUSIVE] = False
        
        self.triggers.append(trigger)
        return self
