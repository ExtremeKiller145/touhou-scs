--[[
    Component class for Touhou Shattered Crystal Shards
    Provides the trigger methods and pattern API for building bullet patterns
]]--

local util = require("utils")
local enum = require("enums")
local lib = require("lib")
local ppt = enum.Properties

local component_module = {}

-- Registry for all created components (used by export module)
local AllComponents = {}

---@class Component
---@field callerGroup number | string
---@field editorLayer number
---@field componentName string
---@field requireSpawnOrder boolean | nil
---@field triggers table
local Component = {}
Component.__index = Component
component_module.Component = Component

---Constructor for Component
---@param componentName string
---@param callerGroup number | string
---@param editorLayer number
---@return Component
function Component.new(componentName, callerGroup, editorLayer)
    util.validateArgs("Component.new", componentName, callerGroup)
    local self = setmetatable({}, Component)
    self.componentName = componentName
    self.callerGroup = callerGroup
    self.editorLayer = editorLayer or 4
    self.requireSpawnOrder = nil -- 3 settings: nil (any), true (required), false (forbidden)
    self.triggers = {}
    table.insert(AllComponents, self)
    return self
end

--- Get all registered components (for export module)
---@return Component[]
function component_module.GetAllComponents()
    return AllComponents
end

--- Set the requirement for spawn ordering
--- @param bool boolean True to require, false to forbid, nil to allow either
function Component:assertSpawnOrder(bool)
    if type(bool) ~= "boolean" then error("assertSpawnOrder: argument must be boolean") end
    if self.requireSpawnOrder ~= nil and self.requireSpawnOrder ~= bool then
        error("assertSpawnOrder: Conflicting spawn order requirements, originally set to " .. tostring(self.requireSpawnOrder) .. ", attempted to set to " .. tostring(bool))
    end
    self.requireSpawnOrder = bool
    return self
end

---@param remapID string Remap string, dot-seperated list, e.g. '1.2.3.4' remaps 1 -> 2 and 3 -> 4
--- Nested remaps: outer remap must remap the inner, e.g. if inner is '1.2', other should be '2.3' not '1.3'.
--- inner must not have reset_remap on.
---@param spawnOrdered boolean Execute from left to right w/ gap time
function Component:Spawn(time, target, spawnOrdered, remapID, spawnDelay)
    util.validateArgs("Spawn", time, target, spawnOrdered, remapID)
    remapID = util.validateRemapString("Spawn", remapID)
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Spawn,
        [ppt.X] = util.timeToDist(time), [ppt.Y] = 0,
        [ppt.TARGET] = target,

        [ppt.REMAP_STRING] = remapID,
        [ppt.RESET_REMAP] = false,
        [ppt.SPAWN_ORDERED] = spawnOrdered,
        [ppt.SPAWN_DELAY] = spawnDelay or 0,

        [ppt.GROUPS] = self.callerGroup, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

--- WARNING: A deactivated object cannot be reactivated by a different group
--- (collision triggers might be different)
---@param activateGroup boolean Activate or deactivate group
function Component:Toggle(time, target, activateGroup)
    util.validateArgs("Toggle", time, target, activateGroup)
    util.validateGroups("Toggle", target)
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Toggle,
        [ppt.X] = util.timeToDist(time), [ppt.Y] = 0,

        [ppt.TARGET] = target,
        [ppt.ACTIVATE_GROUP] = activateGroup,

        [ppt.GROUPS] = self.callerGroup, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

---@param targetDir number Group to move towards
---@param easing table Requires 'dist', 'time', 'type', 'rate' fields
function Component:MoveTowards(time, target, targetDir, easing)
    util.validateArgs("MoveTowards", time, target, targetDir, easing)
    util.validateEasing("MoveTowards", easing)
    util.validateGroups("MoveTowards", target, targetDir)
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Move,
        [ppt.X] = util.timeToDist(time), [ppt.Y] = 0,

        [ppt.TARGET] = target, [ppt.MOVE_TARGET_CENTER] = target,
        [ppt.MOVE_TARGET_DIR] = targetDir,
        [ppt.MOVE_DIRECTION_MODE] = true, [ppt.MOVE_DIRECTION_MODE_DISTANCE] = easing.dist,
        [ppt.DURATION] = easing.t,
        [ppt.EASING] = easing.type, [ppt.EASING_RATE] = easing.rate,
        [ppt.DYNAMIC] = easing.dynamic or false,
        [ppt.MOVE_SMALL_STEP] = true,
        [ppt.MOVE_SILENT] = (easing.t == 0),

        [ppt.GROUPS] = self.callerGroup, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

---@param vector2 table X and Y change in studs
---@param easing table Requires 'time', 'type', 'rate' fields
function Component:MoveBy(time, target, vector2, easing)
    util.validateArgs("MoveBy", time, target, vector2, easing)
    util.validateGroups("MoveBy", target)
    easing.MoveBy = true -- passes check for dist/angle
    util.validateEasing("MoveBy", easing)
    util.validateVector2("MoveBy", vector2)
    if easing.dynamic then error("MoveBy does not support dynamic mode") end
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Move,
        [ppt.X] = util.timeToDist(time), [ppt.Y] = 0,

        [ppt.MOVE_X] = vector2.X, [ppt.MOVE_Y] = vector2.Y,
        [ppt.TARGET] = target,
        [ppt.DURATION] = easing.t,
        [ppt.EASING] = easing.type, [ppt.EASING_RATE] = easing.rate,
        [ppt.MOVE_SILENT] = (easing.t == 0),
        [ppt.MOVE_SMALL_STEP] = true,

        [ppt.GROUPS] = self.callerGroup, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

--- Moves a group to a group in a certain amount of time
---@param location number Group location to move to
---@param easing table Requires 'time' fields, defaults 'type', 'rate' and 'dynamic' to 0
function Component:GotoGroup(time, target, location, easing)
    util.validateArgs("GotoGroup", time, target, location, easing)
    util.validateGroups("GotoGroup", target, location)
    if not easing.t then error("GotoGroup: 'easing' missing required field 't'") end
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Move,
        [ppt.X] = util.timeToDist(time), [ppt.Y] = 0,

        [ppt.TARGET] = target, [ppt.MOVE_TARGET_CENTER] = target,
        [ppt.MOVE_TARGET_MODE] = true, [ppt.MOVE_TARGET_LOCATION] = location,
        [ppt.DURATION] = easing.t,
        [ppt.EASING] = easing.type or 0,
        [ppt.EASING_RATE] = easing.rate or 0,
        [ppt.DYNAMIC] = easing.dynamic or false,
        [ppt.MOVE_SILENT] = (easing.t == 0),

        [ppt.GROUPS] = self.callerGroup, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

--- Rotates a group by a certain angle (+, in degrees)
---@param easing table Must contain 'angle' field
---@param targets table Must contain 'target' and 'center' fields
function Component:Rotate(time, targets, easing)
    util.validateArgs("Rotate", time, targets, easing)
    if not easing.angle then error("Rotate: 'easing' missing required field 'angle'") end
    if not targets.target then error("Rotate: 'targets' missing required field 'target'") end
    if not targets.center then error("Rotate: 'targets' missing required field 'center'") end
    util.validateGroups("Rotate", targets.target, targets.center)
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Rotate,
        [ppt.X] = util.timeToDist(time), [ppt.Y] = 0,

        [ppt.TARGET] = targets.target, [ppt.ROTATE_CENTER] = targets.center,
        [ppt.ROTATE_ANGLE] = easing.angle, -- degrees, clockwise is +
        [ppt.DURATION] = easing.t or 0,
        [ppt.EASING] = easing.type or 0,
        [ppt.EASING_RATE] = easing.rate or 1,

        [ppt.GROUPS] = self.callerGroup, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

---@param targetDir number Group to point towards
---@param easing table not required, defaults to none
function Component:PointToGroup(time, target, targetDir, easing)
    util.validateArgs("PointToGroup", time, target, targetDir)
    util.validateGroups("PointToGroup", target, targetDir)
    easing = easing or enum.DEFAULT_EASING
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Rotate,
        [ppt.X] = util.timeToDist(time), [ppt.Y] = 0,

        [ppt.TARGET] = target, [ppt.ROTATE_CENTER] = target,
        [ppt.ROTATE_TARGET] = targetDir,
        [ppt.ROTATE_AIM_MODE] = true,
        [ppt.DYNAMIC] = easing.dynamic or false,
        [ppt.ROTATE_DYNAMIC_EASING] = easing.rate or 0, -- range from 0 to 100, only if dynamic is true
        [ppt.DURATION] = easing.t or 0,
        [ppt.EASING] = easing.type or 0, [ppt.EASING_RATE] = easing.rate or 1,

        [ppt.GROUPS] = self.callerGroup, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

--- Scales a group by a certain amount.
---@param easing table not required, defaults to none
---@param scaleFactor number to scale down to, e.g. 0.5 is half size
---@param divideMode boolean whether to divide by the scaleFactor instead of multiply
function Component:Scale(time, target, scaleFactor, easing, divideMode)
    util.validateArgs("Scale", time, target, scaleFactor)
    util.validateGroups("Scale", target)
    easing = easing or enum.DEFAULT_EASING
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Scale,
        [ppt.X] = util.timeToDist(time), [ppt.Y] = 0,

        [ppt.TARGET] = target, [ppt.SCALE_CENTER] = target,
        [ppt.SCALE_X] = scaleFactor, [ppt.SCALE_Y] = scaleFactor,
        [ppt.DURATION] = easing.t,
        [ppt.EASING] = easing.type, [ppt.EASING_RATE] = easing.rate,
        [ppt.SCALE_DIV_BY_X] = divideMode or false,
        [ppt.SCALE_DIV_BY_Y] = divideMode or false,

        [ppt.GROUPS] = self.callerGroup, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

--- Pulses a group by a certain amount, resets after some duration
--- DOES NOT INCLUDE: Saturation & Brightness check boxes
--- Hue: [-180 to +180]
--- Saturation: [x0.0 to x2.0], x1.0 is default
--- Brightness: [x0.0 to x2.0], x1.0 is default
---@param fading table requires 't', 'fadeIn', 'fadeOut' fields
function Component:Pulse(time, target, hsb, fading)
    util.validateArgs("Pulse", time, target, hsb, fading)
    hsb.exclusive = hsb.exclusive or false
    util.validatePulse(hsb, fading)
    util.validateGroups("Pulse", target)
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Pulse,
        [ppt.X] = util.timeToDist(time), [ppt.Y] = 0,

        [ppt.TARGET] = target,
        [ppt.PULSE_TARGET_TYPE] = true,
        [ppt.PULSE_HSV] = true,
        [ppt.PULSE_HSV_STRING] = string.format("%da%da%da0a0", hsb.h, hsb.s, hsb.b),
        [ppt.PULSE_EXCLUSIVE] = hsb.exclusive,
        [ppt.PULSE_HOLD] = fading.t,
        [ppt.PULSE_FADE_IN] = fading.fadeIn, [ppt.PULSE_FADE_OUT] = fading.fadeOut,

        [ppt.GROUPS] = self.callerGroup, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end


---Follow a target group's movement for a duration
---@param targetDir number Group to follow
function Component:Follow(time, target, targetDir, duration)
    util.validateArgs("Follow", time, target, targetDir, duration)
    util.validateGroups("Follow", target, targetDir)
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Follow,
        [ppt.X] = util.timeToDist(time), [ppt.Y] = 0,

        [ppt.TARGET] = target,
        [ppt.FOLLOW_GROUP] = targetDir,
        [ppt.DURATION] = duration,

        [ppt.GROUPS] = self.callerGroup, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

--- Change the opacity of a target group
---@param args table requires 'opacity' field, optional 't' field
function Component:Alpha(time, target, args)
    util.validateArgs("Alpha", time, target, args.opacity)
    util.validateGroups("Alpha", target)
    if args.opacity < 0 or args.opacity > 1 then error("Alpha: 'opacity' must be between 0 and 1") end
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Alpha,
        [ppt.X] = util.timeToDist(time), [ppt.Y] = 0,

        [ppt.TARGET] = target,
        [ppt.OPACITY] = args.opacity,
        [ppt.DURATION] = args.t or 0,

        [ppt.GROUPS] = self.callerGroup, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end


--- Stop a target group.
---
--- Only stops: Move, Rotate, Follow, Pulse, Alpha, Scale, Spawn
---@param useControlID boolean Control ID checkbox option
function Component:Stop(time, target, useControlID)
    util.validateArgs("Stop", time, target)
    util.validateGroups("Stop", target)
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Stop,
        [ppt.X] = util.timeToDist(time), [ppt.Y] = 0,

        [ppt.TARGET] = target,
        [ppt.STOP_OPTION] = 0,
        [ppt.STOP_USE_CONTROL_ID] = useControlID or false,

        [ppt.GROUPS] = self.callerGroup, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

--- Pause a target group.
---
--- Only pauses: Move, Rotate, Follow, Pulse, Alpha, Scale, Spawn
---@param useControlID boolean Control ID checkbox option
function Component:Pause(time, target, useControlID)
    util.validateArgs("Pause", time, target)
    util.validateGroups("Pause", target)
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Stop,
        [ppt.X] = util.timeToDist(time), [ppt.Y] = 0,

        [ppt.TARGET] = target,
        [ppt.STOP_OPTION] = 1,
        [ppt.STOP_USE_CONTROL_ID] = useControlID or false,

        [ppt.GROUPS] = self.callerGroup, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

--- Resumes a target group that is paused.
---
--- Only resumes: Move, Rotate, Follow, Pulse, Alpha, Scale, Spawn
---@param useControlID boolean Control ID checkbox option
function Component:Resume(time, target, useControlID)
    util.validateArgs("Resume", time, target)
    util.validateGroups("Resume", target)
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Stop,
        [ppt.X] = util.timeToDist(time), [ppt.Y] = 0,

        [ppt.TARGET] = target,
        [ppt.STOP_OPTION] = 2, -- Resume option
        [ppt.STOP_USE_CONTROL_ID] = useControlID or false,

        [ppt.GROUPS] = self.callerGroup, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

--[[

    MULTITARGET INITIALIZATION:

]]

lib.MultitargetRegistry:initializeBinaryComponents(Component)

--[[

    PATTERN COMPONENT METHODS:

    Organized into:
    - Component.pattern.instant - Instantaneous patterns (single tick, single emitter)
    - Component.pattern.timed - Timed patterns (multiple waves/phases)

]]

Component.pattern = {}
Component.pattern.instant = {}
Component.pattern.timed = {}

--#region Instant Patterns

--- Creates a radial pattern spawn setting, to shoot all at once in a circular pattern
---@param time number
---@param component Component ; requires assertSpawnOrder(true), represents cycle of a single bullet
---@param guiderCircle GuiderCircle ; circle to aim at and spawn from
---@param bulletType Bullet ; the bullet type to use for spawning
---@param args table, requires either 'spacing' OR 'numOfBullets', optional 'centerAt' angle (clockwise from guidercircle pointer), defaults to 0
function Component:Radial(time, component, guiderCircle, bulletType, args)
    util.validateArgs("Radial", component, guiderCircle, bulletType, args)
    util.validateRadialComponent(component, "Radial")

    args.centerAt = args.centerAt or 0 -- 0 represents pointer

    --#region Parameter and Argument Validation
    if args.spacing and args.numOfBullets then
        -- Both provided: validate they match
        if args.numOfBullets ~= 360 / args.spacing then
            error("Radial: spacing and numOfBullets don't match (numOfBullets should be " ..
                (360 / args.spacing) .. ") or just use one or the other")
        end
    elseif args.spacing then
        args.numOfBullets = 360 / args.spacing
    elseif args.numOfBullets then
        args.spacing = 360 / args.numOfBullets
    else
        error("Radial: must provide either 'spacing' or 'numOfBullets'")
    end

    if not util.isInteger(args.spacing) then
        error("Radial: spacing is not an integer (numOfBullets " .. args.numOfBullets .. " doesn't divide 360 evenly)")
    elseif not util.isInteger(args.numOfBullets) then
        error("Radial: numOfBullets is not an integer (spacing " .. args.spacing .. " doesn't divide 360 evenly)")
    elseif args.spacing < 1 or args.spacing > 360 then
        error("Radial: spacing must be an integer between 1 and 360")
    elseif 360 % args.spacing ~= 0 then
        error("Radial: spacing must be a factor of 360 for perfect circles")
    elseif 360 % args.numOfBullets ~= 0 then
        error("Radial: numOfBullets must divide 360 evenly (got " .. args.numOfBullets .. ")")
    end
    --#endregion

    -- Use Arc implementation with radial bypass
    args.radialBypass = true
    return self:Arc(time, component, guiderCircle, bulletType, args)
end

--- Creates an arc pattern spawn setting, to shoot bullets in a partial circular pattern
---@param time number
---@param component Component ; requires assertSpawnOrder(true), represents cycle of a single bullet
---@param guiderCircle GuiderCircle ; circle to aim at and spawn from
---@param bulletType Bullet ; the bullet type to use for spawning
---@param args table, requires 'numOfBullets', 'spacing' angle, optional 'centerAt' angle (clockwise from guidercircle pointer), defaults to 0
function Component:Arc(time, component, guiderCircle, bulletType, args)
    util.validateArgs("Arc", component, guiderCircle, bulletType, args.spacing, args.numOfBullets)
    util.validateRadialComponent(component, "Arc")

    args.centerAt = args.centerAt or 0 -- 0 represents pointer

    --#region Arc-specific Validation
    -- arc logic checks
    local centerAtisInt = util.isInteger(args.centerAt)
    if not args.radialBypass then
        -- case 1: numOfBullets is odd, centerAt must be integer
        if args.numOfBullets % 2 ~= 0 and not centerAtisInt then
            error("Arc: odd bullets requires integer centerAt")
        end
        -- case 2
        if args.numOfBullets % 2 == 0 and args.spacing % 2 ~= 0 and centerAtisInt then
            error("Arc: even bullets with odd spacing requires .5 centerAt")
        end
        -- case 3
        if args.numOfBullets % 2 == 0 and args.spacing % 2 == 0 and not centerAtisInt then
            error("Arc: even bullets with even spacing requires integer centerAt")
        end
    end
    -- Data restriction checks
    if not centerAtisInt and not util.isInteger(args.centerAt * 2) then
        error("Arc: centerAt must be an integer or integer.5")
    end
    if not util.isInteger(args.spacing) then
        error("Arc: spacing must be an integer")
    end
    if args.spacing < 1 or args.spacing > 360 then
        error("Arc: spacing must be between 1 and 360")
    end
    if not util.isInteger(args.numOfBullets) then
        error("Arc: numOfBullets must be an integer")
    end
    if args.numOfBullets < 1 or args.numOfBullets > 360 then
        error("Arc: numOfBullets must be between 1 and 360")
    end
    if args.numOfBullets * args.spacing > 360 then
        error("Arc: numOfBullets " .. args.numOfBullets .. " times spacing " .. args.spacing .. " exceeds 360 degrees")
    end
    if args.numOfBullets * args.spacing == 360 and not args.radialBypass then
        error("Arc: numOfBullets " ..
            args.numOfBullets ..
            " times spacing " .. args.spacing .. " is 360 degrees, making a circle.\n FIX: Use Radial instead.")
    end
    --#endregion

    -- Calculate arc positioning
    local arclength = (args.numOfBullets - 1) * args.spacing
    local startpos

    if args.radialBypass then
        -- For radials: start directly at centerAt and place bullets sequentially
        startpos = args.centerAt
    else
        -- For arcs: center the arc around centerAt
        startpos = args.centerAt - (arclength / 2)
        if not util.isInteger(startpos) then
            error("Arc: Startpos validation is faulty! review conditions.")
        end
    end

    -- Normalize startpos to 0-359 range
    startpos = startpos % 360
    if startpos < 0 then startpos = 360 + startpos end

    -- Get binary components for the number of bullets we need
    local comps = lib.MultitargetRegistry:getBinaryComponents(args.numOfBullets)

    local remapStringProperty = enum.Properties.REMAP_STRING
    local bulletPosition = startpos
    for _, comp in ipairs(comps) do
        local empties = util.createNumberCycler(6001, 6128)
        local remap_string = ""
        for _, spawnTrigger in ipairs(comp.triggers) do
            local remapPairs = util.translateRemapString(spawnTrigger[remapStringProperty])
            for source, target in pairs(remapPairs) do
                remap_string = remap_string .. target .. '.'

                local sourceNum = tonumber(source)
                if sourceNum == enum.EMPTY_BULLET then
                    remap_string = remap_string .. bulletType.nextBullet()
                elseif sourceNum == enum.EMPTY_TARGET_GROUP then
                    remap_string = remap_string .. guiderCircle.groups[bulletPosition + 1]
                else
                    remap_string = remap_string .. empties()
                end

                remap_string = remap_string .. '.'
            end
            bulletPosition = bulletPosition + args.spacing
            if bulletPosition >= 360 then bulletPosition = bulletPosition - 360 end
        end
        -- Final mapping: EMPTY_MULTITARGET -> component caller group
        remap_string = remap_string .. enum.EMPTY_MULTITARGET .. '.' .. component.callerGroup
        self:Spawn(time, comp.callerGroup, false, remap_string)
    end

    return self
end

--#endregion

--#region Timed Patterns

--- Creates a radial wave pattern - repeated radials over time
---@param time number
---@param component Component ; requires assertSpawnOrder(true), represents cycle of a single bullet
---@param guiderCircle GuiderCircle ; circle to aim at and spawn from
---@param bulletType Bullet ; the bullet type to use for spawning
---@param args table, requires either 'spacing' OR 'numOfBullets', 'waves', 'interval', optional 'centerAt'
function Component:RadialWave(time, component, guiderCircle, bulletType, args)
    util.validateArgs("RadialWave", component, guiderCircle, bulletType, args)
    util.validateRadialComponent(component, "RadialWave")

    -- Validate wave-specific parameters
    if not args.waves or not util.isInteger(args.waves) or args.waves < 1 then
        error("RadialWave: waves must be a positive integer")
    end
    if not args.interval or args.interval <= 0 then
        error("RadialWave: interval must be a positive number")
    end

    for i = 1, args.waves do
        self:Radial(time + (i - 1) * args.interval, component, guiderCircle, bulletType, args)
    end

    return self
end

--#endregion


return component_module
