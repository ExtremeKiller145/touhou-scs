"""
Touhou SCS - Component Module

Component class for building trigger sequences with method chaining.

URGENT: SpellBuilder is not yet implemented! stuff is commented out until then.
"""

from __future__ import annotations
from typing import Any
from warnings import warn

from touhou_scs import enums as enum, lib, utils as util
from touhou_scs.types import Trigger


_RESTRICTED_LOOKUP = { group_id: True for group_id in enum.RESTRICTED_GROUPS }

ppt = enum.Properties # shorthand

class Component:
    """
    Component for building trigger sequences.
    Auto-registers to lib.all_components. All methods return self for chaining.
    """
    
    def __init__(self, name: str, callerGroup: int, editorLayer: int = 4):
        self.name: str = name
        self.callerGroup: int = callerGroup
        self.editorLayer: int = editorLayer
        self.requireSpawnOrder: bool | None = None
        self.triggers: list[Trigger] = []
        self._instant: InstantPatterns | None = None
        self._timed: TimedPatterns | None = None
        
        lib.all_components.append(self)
    
    @property
    def instant(self):
        if self._instant is None: self._instant = InstantPatterns(self)
        return self._instant

    @property
    def timed(self):
        if self._timed is None: self._timed = TimedPatterns(self)
        return self._timed
    
    def create_trigger(self, obj_id: int, x: float, target: int) -> Trigger:
        """Create trigger with component defaults & target validation."""
        
        if _RESTRICTED_LOOKUP.get(target):
            raise ValueError(f"Group '{target}' is restricted due to known conflicts.")
        
        return Trigger({
            ppt.OBJ_ID: obj_id,
            ppt.X: x,
            ppt.TARGET: target,
            ppt.GROUPS: [self.callerGroup],
            ppt.EDITOR_LAYER: self.editorLayer,
            ppt.SPAWN_TRIGGERED: True,
            ppt.MULTI_TRIGGERED: True,
        })
        
    def _validate_params(self, *, 
        t:Any = None, center:Any = None, target:Any = None):
        """Value check common trigger parameters"""

        if t is not None and t < 0:
            raise ValueError("Duration 't' must be non-negative")
        if center is not None and _RESTRICTED_LOOKUP.get(center):
            raise ValueError(f"Center group '{center}' is restricted.")
        if target is not None and _RESTRICTED_LOOKUP.get(target):
            raise ValueError(f"Target group '{target}' is restricted.")
    
    def assert_spawn_order(self, required: bool):
        """Set component spawn order requirement."""
        self.requireSpawnOrder = required
        return self
    
    # ===========================================================
    # 
    # TRIGGER METHODS
    # 
    # ===========================================================
    
    def Spawn(self, time: float,
        target: int | Component, spawnOrdered: bool, *,
        remap: str | None = None, delay: float = 0 ):
        """
        Spawn another component or group's triggers
        
        Optional: remap string, spawnDelay
        """
        target = target.callerGroup if isinstance(target, Component) else target
        self._validate_params(target=target)
        
        trigger = self.create_trigger(enum.ObjectID.SPAWN, util.time_to_dist(time), target)
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
        self._validate_params(target=target)
        
        trigger = self.create_trigger(enum.ObjectID.TOGGLE, util.time_to_dist(time), target)
        trigger[ppt.ACTIVATE_GROUP] = activateGroup
        
        self.triggers.append(trigger)
        return self
    
    def MoveTowards(self, time: float, target: int, targetDir: int, *,
        t: float, dist: int,
        type: int = 0, rate: float = 1.0, dynamic: bool = False):
        """
        Move target a set distance towards another group (direction mode)
        
        Optional: type, rate, dynamic, center of target
        """
        self._validate_params(t=t, target=targetDir)
        
        trigger = self.create_trigger(enum.ObjectID.MOVE, util.time_to_dist(time), target)
        
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
        self._validate_params(t=t, target=target)
        
        trigger = self.create_trigger(enum.ObjectID.PULSE, util.time_to_dist(time), target)

        trigger[ppt.PULSE_HSV] = True
        trigger[ppt.PULSE_TARGET_TYPE] = True
        #a0a0 for multiplicative, a1a1 for additive (its the checkbox for 's' and 'v')
        trigger[ppt.PULSE_HSV_STRING] = f"{hsb.h}a{hsb.s}a{hsb.b}a1a1"  
        trigger[ppt.PULSE_FADE_IN] = fadeIn
        trigger[ppt.PULSE_HOLD] = t
        trigger[ppt.PULSE_FADE_OUT] = fadeOut
        trigger[ppt.PULSE_EXCLUSIVE] = exclusive
        
        self.triggers.append(trigger)
        return self
    
    def MoveBy(self, time: float, target: int, *,
        dx: float, dy: float,
        t: float = 0, type: int = 0, rate: float = 1.0):
        """
        Move target by a relative offset (dx, dy)
        
        Optional: t, type, rate
        """
        self._validate_params(t=t, target=target)
        
        trigger = self.create_trigger(enum.ObjectID.MOVE, util.time_to_dist(time), target)
        
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
        self._validate_params(t=t, target=target)
        
        trigger = self.create_trigger(enum.ObjectID.MOVE, util.time_to_dist(time), target)
        
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
        
        Optional: center (defaults to target), t, type, rate
        """
        self._validate_params(t=t, target=target, center=center)
        
        if center is None: center = target
        elif _RESTRICTED_LOOKUP.get(center):
            raise ValueError(f"Center group '{center}' is restricted.")
        
        trigger = self.create_trigger(enum.ObjectID.ROTATE, util.time_to_dist(time), target)
        
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
        self._validate_params(t=t, target=target)
        
        trigger = self.create_trigger(enum.ObjectID.ROTATE, util.time_to_dist(time), target)
        
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
        self._validate_params(t=t, target=target)
        
        trigger = self.create_trigger(enum.ObjectID.SCALE, util.time_to_dist(time), target)
        
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
        self._validate_params(t=t, target=target)
        
        trigger = self.create_trigger(enum.ObjectID.FOLLOW, util.time_to_dist(time), target)
        
        trigger[ppt.FOLLOW_GROUP] = targetDir
        trigger[ppt.DURATION] = t
        
        self.triggers.append(trigger)
        return self
    
    def Alpha(self, time: float, target: int, *, opacity: float, t: float = 0):
        """
        Change target's opacity from a range of 0-100
        
        Optional: t (duration)
        """
        self._validate_params(t=t, target=target)
        if opacity < 0 or opacity > 100:
            raise ValueError("Opacity must be between 0 and 100")
        
        trigger = self.create_trigger(enum.ObjectID.ALPHA, util.time_to_dist(time), target)
        
        trigger[ppt.OPACITY] = opacity / 100.0
        trigger[ppt.DURATION] = t
        
        self.triggers.append(trigger)
        return self
    
    def _stop_trigger_common(self, time: float, target: int, option: int, useControlID: bool):
        """Common logic for Stop, Pause, Resume triggers (internal use, made bc DRY principle)"""
        self._validate_params(target=target)
        
        trigger = self.create_trigger(enum.ObjectID.STOP, util.time_to_dist(time), target)
        
        trigger[ppt.STOP_OPTION] = option # 0=Stop, 1=Pause, 2=Resume
        trigger[ppt.STOP_USE_CONTROL_ID] = useControlID
        
        self.triggers.append(trigger)
    
    def Stop(self, time: float, target: int, *, useControlID: bool = False):
        """
        Stop target's active triggers (Move, Rotate, Follow, Pulse, Alpha, Scale, Spawn)
        
        Optional: useControlID
        """
        self._stop_trigger_common(time, target, 0, useControlID)
        return self
    
    def Pause(self, time: float, target: int, *, useControlID: bool = False):
        """
        Pause target's active triggers (Move, Rotate, Follow, Pulse, Alpha, Scale, Spawn)
        
        Optional: useControlID
        """
        self._stop_trigger_common(time, target, 1, useControlID)
        return self
    
    def Resume(self, time: float, target: int, *, useControlID: bool = False):
        """
        Resume target's paused triggers (Move, Rotate, Follow, Pulse, Alpha, Scale, Spawn)
        
        Optional: useControlID
        """
        self._stop_trigger_common(time, target, 2, useControlID)
        return self


# ===========================================================
# 
# MULTITARGET CLASS
# 
# ===========================================================

class Multitarget:
    """
    Make triggers effect multiple targets using precise component remapping.
    
    Works by creating components with many spawn triggers, and remap chaining to execute at once.
    """

    _powers: list[int] = [1, 2, 4, 8, 16, 32, 64]
    """List of binary powers; each component has 2^n targets"""
    _initialized: bool = False
    """Private registration flag"""
    _binary_bases: dict[int, Component] = {}
    """Private storage for binary base components (powers of 2)"""
    
    @classmethod
    def get_binary_components(cls, num_targets: int, comp: Component) -> list[Component]:
        """Get the binary components needed to represent num_of_targets."""
        
        for trigger in comp.triggers:
            if trigger[ppt.OBJ_ID] == enum.ObjectID.SPAWN:
                warn(f"Spawn limit: [{comp.name}] Multitarget components cannot have Spawn triggers", stacklevel=2)

        if not cls._initialized: cls._initialize_binary_bases()
        
        if num_targets < 1: raise ValueError("num_of_targets must be at least 1")
        
        max_targets: int = 2 ** len(cls._powers) - 1
        if num_targets <= 0 or num_targets > max_targets:
            raise ValueError(f"num_of_targets must be between 1 and {max_targets}")
        
        comps: list[Component] = []
        remaining = num_targets
        for power in cls._powers[::-1]:
            if remaining >= power:
                comps.append(cls._binary_bases[power])
                remaining -= power
        
        return comps
    
    @classmethod
    def _initialize_binary_bases(cls):
        """
        Initialize all binary base components (1, 2, 4, 8, 16, 32, 64).
        Called automatically on first use of get_binary_components.
        """
        if cls._initialized: raise RuntimeError("Multitarget binary bases already initialized")
        
        for power in cls._powers:
            component = Component(f"BinaryBase_{power}", util.unknown_g(), 4)
            component.assert_spawn_order(False)
            # To add support for more parameters, add a new empty group and follow the pattern
            num_emptys = 4
            for i in range(0, power * num_emptys, num_emptys):
                rb = (util.Remap()
                    .pair(enum.EMPTY_BULLET, i + 6001)
                    .pair(enum.EMPTY_TARGET_GROUP, i + 6002)
                    .pair(enum.EMPTY1, i + 6003)
                    .pair(enum.EMPTY2, i + 6004))
                component.Spawn(0, enum.EMPTY_MULTITARGET, True, remap=rb.build())
            cls._binary_bases[power] = component
        
        cls._initialized = True
        max_targets: int = 2 ** len(cls._powers) - 1
        print(f"Multitarget: Initialized {len(cls._powers)} binary components, {max_targets} targets supported)")


# ===========================================================
# 
# PATTERN CLASSES
# 
# ===========================================================

class InstantPatterns:
    """Instant pattern methods - spawn bullets in a single frame."""
    def __init__(self, component: Component):
        self._component = component

    
    def Arc(self, time: float, comp: Component, 
        gc: lib.GuiderCircle, bullet: lib.BulletPool, *, 
        numBullets: int, spacing: int, centerAt: float = 0, radialBypass: bool = False):
        """Arc pattern - partial circle of bullets"""
        
        util.enforce_component_targets("Instant Arc", comp,
            requires={enum.EMPTY_BULLET, enum.EMPTY_TARGET_GROUP },
            excludes={enum.EMPTY_MULTITARGET}
        )
        
        # Arc logic checks
        if not radialBypass:
            if numBullets % 2 != 0 and not centerAt.is_integer():
                raise ValueError("Arc: odd bullets requires integer centerAt")
            if numBullets % 2 == 0 and spacing % 2 != 0 and centerAt.is_integer():
                raise ValueError("Arc: even bullets with odd spacing requires .5 centerAt")
            if numBullets % 2 == 0 and spacing % 2 == 0 and not centerAt.is_integer():
                raise ValueError("Arc: even bullets with even spacing requires integer centerAt")
        # data restriction checks
        if not centerAt.is_integer() and not (centerAt * 2).is_integer():
            raise ValueError("Arc: centerAt must be an integer or integer.5")
        if spacing < 1 or spacing > 360:
            raise ValueError("Arc: spacing must be between 1 and 360 degrees")
        if numBullets < 1 or numBullets > 360:
            raise ValueError("Arc: numBullets must be between 1 and 360")
        if numBullets * spacing > 360:
            raise ValueError(f"Arc: numBullets {numBullets} times spacing {spacing} exceeds 360°")
        if numBullets * spacing == 360 and not radialBypass:
            warn(f"Arc: numBullets {numBullets} times spacing {spacing} is 360°, making a circle. \nFIX: Use instant.Radial() instead")
        
        # Calculate Arc positioning
        arclength = (numBullets - 1) * spacing
        
        startpos = 0
        if radialBypass: startpos = centerAt
        else: startpos = centerAt - arclength / 2
        if not startpos.is_integer():
            raise ValueError(f"Arc: Internal error! startpos {startpos} not an integer. centerAt={centerAt}, arclength={arclength}")
        
        # normalize startpos to [0, 360) range
        startpos = startpos % 360
        if startpos < 0: startpos += 360
        
        comps = Multitarget.get_binary_components(numBullets, comp)
        
        bulletPos = int(startpos)
        for mt_comp in comps:
            remap = util.Remap()
            
            for spawn_trigger in mt_comp.triggers:
                remap_string = spawn_trigger.get(ppt.REMAP_STRING, None)
                if not isinstance(remap_string, str): continue # to appease type checker
                    
                remap_pairs, _ = util.translate_remap_string(remap_string)
                
                for source, target in remap_pairs.items():
                    if source == enum.EMPTY_BULLET:
                        bullet_group, _ = bullet.next()
                        remap.pair(target, bullet_group)
                    elif source == enum.EMPTY_TARGET_GROUP:
                        # Convert 0-359 range to 1-360 for GuiderCircle indexing
                        angle_index = bulletPos if bulletPos > 0 else 360
                        remap.pair(target, gc.groups[angle_index])
                    else:
                        remap.pair(target, enum.EMPTY_MULTITARGET) # any empty works
                
                bulletPos += spacing
                if bulletPos >= 360: bulletPos -= 360
            
            remap.pair(enum.EMPTY_MULTITARGET, comp.callerGroup) # final remap
            self._component.Spawn(time, mt_comp.callerGroup, False, remap=remap.build())
        
        return self._component
    
    
    def Radial(self, time: float, comp: Component, 
        gc: lib.GuiderCircle, bullet: lib.BulletPool, *, 
        numBullets: int | None = None, spacing: int | None = None, centerAt: float = 0):
        """
        Radial pattern - full 360° circle of bullets
        
        Optional: spacing or numBullets, centerAt
        """
        
        util.enforce_component_targets("Instant Radial",comp,
            requires={enum.EMPTY_BULLET, enum.EMPTY_TARGET_GROUP },
            excludes={enum.EMPTY_MULTITARGET}
        )
        
        if spacing and numBullets:
            if numBullets != int(360 / spacing):
                raise ValueError("Radial: spacing and numBullets don't match!\n\n"+
                f"(numOfBullets should be {int(360 / spacing)}, \n" +
                f"or spacing should be {int(360 / numBullets)}, \n\n" +
                "or just use one or the other")
        elif spacing: numBullets = int(360 / spacing)
        elif numBullets: spacing = int(360 / numBullets)
        else: raise ValueError("Radial: must provide either spacing or numBullets")

        if 360 % spacing != 0:
            raise ValueError(f"Radial: spacing must be a factor of 360 for perfect circles. Received: {spacing}")
        elif 360 % numBullets != 0:
            raise ValueError(f"Radial: numBullets must be a factor of 360 for perfect circles. Received: {numBullets}")
            
        self.Arc(time, comp, gc, bullet, 
            numBullets=numBullets, spacing=spacing, centerAt=centerAt, radialBypass=True)
        
        return self._component
    
    def Line(self, time: float, comp: Component, 
        targetDir: int, bullet: lib.BulletPool, *, 
        numBullets: int, fastestTime: float, slowestTime: float, dist: int,
        type: int = 0, rate: float = 1.0):
        """
        Line pattern - builds MoveTowards triggers at different speeds, forming a line.
        
        Optional: type, rate
        """
        
        util.enforce_component_targets("Instant Line", comp,
            requires={ enum.EMPTY_BULLET },
            excludes={ enum.EMPTY_TARGET_GROUP, enum.EMPTY_MULTITARGET, 
                enum.EMPTY1, enum.EMPTY2, enum.EMPTY3 }
        )
        
        if fastestTime <= 0:
            raise ValueError(f"Instant.Line: fastestTime must be a positive number. Received: {fastestTime}")
        if slowestTime <= 0:
            raise ValueError(f"Instant.Line: slowestTime must be a positive number. Received: {slowestTime}")
        if slowestTime <= fastestTime:
            raise ValueError(f"Instant.Line: slowestTime {slowestTime} must be greater than fastestTime {fastestTime}")
        if numBullets < 3:
            raise ValueError("Instant.Line: numBullets must be at least 3")
        
        bullet_groups: list[int] = []
        mt_comps = Multitarget.get_binary_components(numBullets, comp)
        for mt_comp in mt_comps:
            remap = util.Remap()
            for spawn_trigger in mt_comp.triggers:
                remap_string = spawn_trigger.get(ppt.REMAP_STRING, None)
                if not isinstance(remap_string, str): continue # to appease type checker
                
                remap_pairs, _ = util.translate_remap_string(remap_string)
                for source, target in remap_pairs.items():
                    if source == enum.EMPTY_BULLET:
                        bullet_group, _ = bullet.next()
                        bullet_groups.append(bullet_group)
                        remap.pair(target, bullet_group)
                    else:
                        remap.pair(target, enum.EMPTY_MULTITARGET) # any empty works
            
            remap.pair(enum.EMPTY_MULTITARGET, comp.callerGroup)
            self._component.Spawn(time, mt_comp.callerGroup, False, remap=remap.build())
        
        step = (slowestTime - fastestTime) / (numBullets - 1)
        for i, bullet_group in enumerate(bullet_groups):
            travel_time = fastestTime + step * i
            self._component.MoveTowards(
                time, bullet_group, targetDir, 
                t=travel_time, dist=dist, type=type, rate=rate 
            )
        
        return self._component
    
    # More pattern methods will be added here


class TimedPatterns:
    """
    Timed pattern methods - spawn bullets over multiple frames.
    
    Built on top of instant patterns by calling them repeatedly with time offsets.
    """
    
    def __init__(self, component: Component):
        self._component = component
    
    def RadialWave(self, time: float, comp: Component, 
        gc: lib.GuiderCircle, bullet: lib.BulletPool, *, 
        waves: int, interval: float = 0, numBullets: int | None = None, spacing: int | None = None, centerAt: float = 0):
        """
        Radial Wave pattern - multiple waves of radial bullets over time
        
        Optional: spacing or numBullets, centerAt
        """
        if waves < 1:
            raise ValueError("RadialWave: waves must be at least 1")
        elif waves == 1:
            raise ValueError("RadialWave: for single wave, use instant.Radial() instead")
        if interval < 0:
            raise ValueError("RadialWave: interval must be non-negative")
        
        for wave_number in range(waves):
            self._component.instant.Radial(
                time + (wave_number * interval),
                comp, gc, bullet, numBullets=numBullets, spacing=spacing, centerAt=centerAt
            )
        
        return self._component
    
    def Line(self, time: float, comp: Component, targetDir: int, bullet: lib.BulletPool, *,
        numBullets: int, spacing: float, t: float, dist: int, type: int = 0, rate: float = 1.0):
        """
        Line pattern - bullets in a line over time with equal gaps between them
        
        Optional: type, rate
        """
        util.enforce_component_targets("Instant Line", comp,
            requires={ enum.EMPTY_BULLET },
            excludes={ enum.EMPTY_TARGET_GROUP, enum.EMPTY_MULTITARGET, 
                enum.EMPTY1, enum.EMPTY2, enum.EMPTY3 }
        )
        
        if numBullets < 2:
            raise ValueError("Timed.Line: numBullets must be at least 2")
        if spacing < 0:
            raise ValueError("Timed.Line: spacing must be non-negative")
        if t < 0:
            raise ValueError("Timed.Line: t must be non-negative")
        
        for i in range(0, numBullets):
            b, _ = bullet.next()
            self._component.Spawn(
                time + (i * spacing), comp.callerGroup, True, remap=f"{enum.EMPTY_BULLET}:{b}")
            self._component.MoveTowards(
                time + (i * spacing), b, targetDir, t=t, dist=dist, type=type, rate=rate
            )
        return self._component
        
    # More pattern methods will be added here
