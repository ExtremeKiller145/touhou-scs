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
        type: int = 0, rate: float = 1.0, dynamic: bool = False):
        """
        Move target a set distance towards another group (direction mode)
        
        Optional: type, rate, dynamic, center of target
        """
        
        trigger = self._create_trigger(enum.ObjectID.MOVE, util.time_to_dist(time), target)
        
        trigger[ppt.DURATION] = t
        trigger[ppt.MOVE_DIRECTION_MODE] = True
        trigger[ppt.MOVE_SMALL_STEP] = True
        trigger[ppt.MOVE_TARGET_DIR] = targetDir
        trigger[ppt.MOVE_TARGET_CENTER] = target

        trigger[ppt.MOVE_DIRECTION_MODE_DISTANCE] = dist
        trigger[ppt.EASING] = type
        trigger[ppt.EASING_RATE] = rate
        
        if dynamic: trigger[ppt.DYNAMIC] = True
        
        self.triggers.append(trigger)
        return self
    
    def Pulse(self, time: float, target: int, 
        hsb: lib.HSB, *, exclusive: bool = False,
        fadeIn: float = 0, t: float = 0, fadeOut: float = 0):
        """
        Pulse a group's HSV/color
        
        Optional: fadeIn, t, fadeOut
        """
        
        trigger = self._create_trigger(enum.ObjectID.PULSE, util.time_to_dist(time), target)

        trigger[ppt.PULSE_HSV] = True
        trigger[ppt.PULSE_TARGET_TYPE] = True
        trigger[ppt.PULSE_HSV_STRING] = f"{hsb.h}a{hsb.s}a{hsb.b}a0a0"
        trigger[ppt.PULSE_FADE_IN] = fadeIn
        trigger[ppt.PULSE_HOLD] = t
        trigger[ppt.PULSE_FADE_OUT] = fadeOut

        if exclusive: trigger[ppt.PULSE_EXCLUSIVE] = False
        
        self.triggers.append(trigger)
        return self
    
    def MoveBy(self, time: float, target: int, *,
        dx: float, dy: float,
        t: float = 0, type: int = 0, rate: float = 1.0):
        """
        Move target by a relative offset (dx, dy)
        
        Optional: t, type, rate
        """
        
        trigger = self._create_trigger(enum.ObjectID.MOVE, util.time_to_dist(time), target)
        
        trigger[ppt.DURATION] = t
        trigger[ppt.MOVE_X] = dx
        trigger[ppt.MOVE_Y] = dy
        trigger[ppt.MOVE_SILENT] = (t == 0)
        trigger[ppt.MOVE_SMALL_STEP] = True
        trigger[ppt.EASING] = type
        trigger[ppt.EASING_RATE] = rate
        
        self.triggers.append(trigger)
        return self
    
    def GotoGroup(self, time: float, target: int, location: int, *,
        t: float = 0, type: int = 0, rate: float = 1.0):
        """
        Move target to another group's position
        
        Optional: t, type, rate
        """
        
        trigger = self._create_trigger(enum.ObjectID.MOVE, util.time_to_dist(time), target)
        
        trigger[ppt.MOVE_TARGET_CENTER] = target
        trigger[ppt.MOVE_TARGET_LOCATION] = location
        trigger[ppt.MOVE_TARGET_MODE] = True
        trigger[ppt.MOVE_SILENT] = (t == 0)
        trigger[ppt.DURATION] = t
        trigger[ppt.EASING] = type
        trigger[ppt.EASING_RATE] = rate
        
        self.triggers.append(trigger)
        return self
    
    def Rotate(self, time: float, *,
        target: int, angle: float,
        center: int | None = None,
        t: float = 0, type: int = 0, rate: float = 1.0):
        """
        Rotate target by angle (degrees, clockwise is positive)
        
        Optional: center, t, type, rate
        """
        if center is None: center = target
        elif _RESTRICTED_LOOKUP.get(center):
            raise ValueError(f"Center group '{center}' is restricted.")
        
        trigger = self._create_trigger(enum.ObjectID.ROTATE, util.time_to_dist(time), target)
        
        trigger[ppt.ROTATE_CENTER] = center
        trigger[ppt.ROTATE_ANGLE] = angle
        trigger[ppt.DURATION] = t
        trigger[ppt.EASING] = type
        trigger[ppt.EASING_RATE] = rate
        
        self.triggers.append(trigger)
        return self
    
    def PointToGroup(self, time: float, 
        target: int, targetDir: int, *,
        t: float = 0, type: int = 0, rate: float = 1.0, dynamic: bool = False):
        """
        Point target towards another group
        
        Optional: t, type, rate
        """
        
        trigger = self._create_trigger(enum.ObjectID.ROTATE, util.time_to_dist(time), target)
        
        trigger[ppt.ROTATE_TARGET] = targetDir
        trigger[ppt.ROTATE_CENTER] = target
        trigger[ppt.ROTATE_AIM_MODE] = True
        trigger[ppt.DURATION] = t
        trigger[ppt.EASING] = type
        trigger[ppt.EASING_RATE] = rate
        trigger[ppt.DYNAMIC] = dynamic
        
        self.triggers.append(trigger)
        return self
    
    def Scale(self, time: float, target: int, *,
        factor: float,
        divide: bool = False,
        t: float = 0, type: int = 0, rate: float = 1.0):
        """
        Scale target by a factor
        
        Optional: divide, t, type, rate
        """
        
        trigger = self._create_trigger(enum.ObjectID.SCALE, util.time_to_dist(time), target)
        
        trigger[ppt.SCALE_CENTER] = target
        trigger[ppt.SCALE_X] = factor
        trigger[ppt.SCALE_Y] = factor
        trigger[ppt.DURATION] = t
        trigger[ppt.EASING] = type
        trigger[ppt.EASING_RATE] = rate
        trigger[ppt.SCALE_DIV_BY_X] = divide
        trigger[ppt.SCALE_DIV_BY_Y] = divide
        
        self.triggers.append(trigger)
        return self
    
    def Follow(self, time: float, target: int, targetDir: int, *, t: float = 0):
        """
        Make target follow another group's movement
        
        Optional: t (duration)
        """
        
        trigger = self._create_trigger(enum.ObjectID.FOLLOW, util.time_to_dist(time), target)
        
        trigger[ppt.FOLLOW_GROUP] = targetDir
        trigger[ppt.DURATION] = t
        
        self.triggers.append(trigger)
        return self
    
    def Alpha(self, time: float, target: int, *, opacity: float, t: float = 0):
        """
        Change target's opacity from a range of 0-100
        
        Optional: t (duration)
        """
        if opacity < 0 or opacity > 100:
            raise ValueError("Opacity must be between 0 and 100")
        
        trigger = self._create_trigger(enum.ObjectID.ALPHA, util.time_to_dist(time), target)
        
        trigger[ppt.OPACITY] = opacity / 100.0
        trigger[ppt.DURATION] = t
        
        self.triggers.append(trigger)
        return self
    
    def Stop(self, time: float, target: int, *, useControlID: bool = False):
        """
        Stop target's active triggers (Move, Rotate, Follow, Pulse, Alpha, Scale, Spawn)
        
        Optional: useControlID
        """
        
        trigger = self._create_trigger(enum.ObjectID.STOP, util.time_to_dist(time), target)
        
        trigger[ppt.STOP_OPTION] = 0
        trigger[ppt.STOP_USE_CONTROL_ID] = useControlID
        
        self.triggers.append(trigger)
        return self
    
    def Pause(self, time: float, target: int, *, useControlID: bool = False):
        """
        Pause target's active triggers (Move, Rotate, Follow, Pulse, Alpha, Scale, Spawn)
        
        Optional: useControlID
        """
        
        trigger = self._create_trigger(enum.ObjectID.STOP, util.time_to_dist(time), target)
        
        trigger[ppt.STOP_OPTION] = 1
        trigger[ppt.STOP_USE_CONTROL_ID] = useControlID
        
        self.triggers.append(trigger)
        return self
    
    def Resume(self, time: float, target: int, *, useControlID: bool = False):
        """
        Resume target's paused triggers (Move, Rotate, Follow, Pulse, Alpha, Scale, Spawn)
        
        Optional: useControlID
        """
        
        trigger = self._create_trigger(enum.ObjectID.STOP, util.time_to_dist(time), target)
        
        trigger[ppt.STOP_OPTION] = 2
        trigger[ppt.STOP_USE_CONTROL_ID] = useControlID
        
        self.triggers.append(trigger)
        return self
