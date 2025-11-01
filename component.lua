--[[
    Component class for Touhou Shattered Crystal Shards
    Provides the trigger methods and pattern API for building bullet patterns
]]--

local util = require("utils")
local enum = require("enums")
local lib = require("lib")
local ppt = enum.Properties

local m = {}

---@return table<number, any>
local function createTrigger(comp)
    return {
        [ppt.Y] = 0,
        [ppt.GROUPS] = comp.callerGroup,
        [ppt.EDITOR_LAYER] = comp.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true,
        [ppt.MULTI_TRIGGERED] = true,
    }
end

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
m.Component = Component



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
function m.GetAllComponents() return AllComponents end

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

---@param remapID string | nil Remap string, dot-seperated list, e.g. '1.2.3.4' remaps 1 -> 2 and 3 -> 4
--- Nested remaps: outer remap must remap the inner, e.g. if inner is '1.2', other should be '2.3' not '1.3'.
--- inner must not have reset_remap on.
---@param spawnOrdered boolean Execute from left to right w/ gap time
function Component:Spawn(time, target, spawnOrdered, remapID, spawnDelay)
    util.validateArgs("Spawn", time, target, spawnOrdered)
    if type(remapID) == "string" then
        remapID = util.validateRemapString("Spawn", remapID)
    end

    if type(target) ~= "number" and type(target) ~= "string" then
        error("Spawn: target must be a number or string, not component/table")
    end
    
    local trigger = createTrigger(self)
    trigger[ppt.OBJ_ID] = enum.ObjectID.Spawn
    trigger[ppt.X] = util.timeToDist(time)
    trigger[ppt.TARGET] = target

    if remapID then trigger[ppt.REMAP_STRING] = remapID end
    trigger[ppt.RESET_REMAP] = false
    trigger[ppt.SPAWN_ORDERED] = spawnOrdered
    trigger[ppt.SPAWN_DELAY] = spawnDelay or 0

    table.insert(self.triggers, trigger)
    return self
end

--- WARNING: A deactivated object cannot be reactivated by a different group
--- (collision triggers might be different)
---@param activateGroup boolean Activate or deactivate group
function Component:Toggle(time, target, activateGroup)
    util.validateArgs("Toggle", time, target, activateGroup)
    util.validateGroups("Toggle", target)

    local trigger = createTrigger(self)
    trigger[ppt.OBJ_ID] = enum.ObjectID.Toggle
    trigger[ppt.X] = util.timeToDist(time)

    trigger[ppt.TARGET] = target
    trigger[ppt.ACTIVATE_GROUP] = activateGroup

    table.insert(self.triggers, trigger)
    return self
end

---@param targetDir number Group to move towards
---@param easing table Requires 'dist', 'time', 'type', 'rate' fields
function Component:MoveTowards(time, target, targetDir, easing)
    util.validateArgs("MoveTowards", time, target, targetDir, easing)
    util.validateEasing("MoveTowards", easing)
    util.validateGroups("MoveTowards", target, targetDir)

    local trigger = createTrigger(self)

    trigger[ppt.OBJ_ID] = enum.ObjectID.Move
    trigger[ppt.X] = util.timeToDist(time)

    trigger[ppt.TARGET] = target
    trigger[ppt.MOVE_TARGET_CENTER] = target
    trigger[ppt.MOVE_TARGET_DIR] = targetDir
    trigger[ppt.MOVE_DIRECTION_MODE] = true
    trigger[ppt.MOVE_DIRECTION_MODE_DISTANCE] = easing.dist

    trigger[ppt.DURATION] = easing.t
    trigger[ppt.EASING] = easing.type
    trigger[ppt.EASING_RATE] = easing.rate
    trigger[ppt.DYNAMIC] = easing.dynamic or false

    trigger[ppt.MOVE_SMALL_STEP] = true
    trigger[ppt.MOVE_SILENT] = (easing.t == 0)

    table.insert(self.triggers, trigger)
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

    local trigger = createTrigger(self)
    trigger[ppt.OBJ_ID] = enum.ObjectID.Move
    trigger[ppt.X] = util.timeToDist(time)

    trigger[ppt.MOVE_X] = vector2.X
    trigger[ppt.MOVE_Y] = vector2.Y
    trigger[ppt.TARGET] = target

    trigger[ppt.DURATION] = easing.t
    trigger[ppt.EASING] = easing.type
    trigger[ppt.EASING_RATE] = easing.rate

    trigger[ppt.MOVE_SILENT] = (easing.t == 0)
    trigger[ppt.MOVE_SMALL_STEP] = true

    table.insert(self.triggers, trigger)
    return self
end

--- Moves a group to a group in a certain amount of time
---@param location number Group location to move to
---@param easing table Requires 'time' fields, defaults 'type', 'rate' and 'dynamic' to 0
function Component:GotoGroup(time, target, location, easing)
    util.validateArgs("GotoGroup", time, target, location, easing)
    util.validateGroups("GotoGroup", target, location)
    if not easing.t then error("GotoGroup: 'easing' missing required field 't'") end

    local trigger = createTrigger(self)
    trigger[ppt.OBJ_ID] = enum.ObjectID.Move
    trigger[ppt.X] = util.timeToDist(time)

    trigger[ppt.TARGET] = target
    trigger[ppt.MOVE_TARGET_CENTER] = target
    trigger[ppt.MOVE_TARGET_MODE] = true
    trigger[ppt.MOVE_TARGET_LOCATION] = location

    trigger[ppt.DURATION] = easing.t
    trigger[ppt.EASING] = easing.type or 0
    trigger[ppt.EASING_RATE] = easing.rate or 0
    trigger[ppt.DYNAMIC] = easing.dynamic or false

    trigger[ppt.MOVE_SILENT] = (easing.t == 0)

    table.insert(self.triggers, trigger)
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

    local trigger = createTrigger(self)
    trigger[ppt.OBJ_ID] = enum.ObjectID.Rotate
    trigger[ppt.X] = util.timeToDist(time)

    trigger[ppt.TARGET] = targets.target
    trigger[ppt.ROTATE_CENTER] = targets.center
    trigger[ppt.ROTATE_ANGLE] = easing.angle -- degrees, clockwise is +

    trigger[ppt.DURATION] = easing.t or 0
    trigger[ppt.EASING] = easing.type or 0
    trigger[ppt.EASING_RATE] = easing.rate or 1

    table.insert(self.triggers, trigger)
    return self
end

---@param targetDir number Group to point towards
---@param easing? table Optional easing configuration, defaults to DEFAULT_EASING
function Component:PointToGroup(time, target, targetDir, easing)
    util.validateArgs("PointToGroup", time, target, targetDir)
    util.validateGroups("PointToGroup", target, targetDir)
    easing = easing or enum.DEFAULT_EASING

    local trigger = createTrigger(self)
    trigger[ppt.OBJ_ID] = enum.ObjectID.Rotate
    trigger[ppt.X] = util.timeToDist(time)

    trigger[ppt.TARGET] = target
    trigger[ppt.ROTATE_CENTER] = target
    trigger[ppt.ROTATE_TARGET] = targetDir
    trigger[ppt.ROTATE_AIM_MODE] = true

    trigger[ppt.DYNAMIC] = easing.dynamic or false
    trigger[ppt.ROTATE_DYNAMIC_EASING] = easing.rate or 0 -- range from 0 to 100, only if dynamic is true

    trigger[ppt.DURATION] = easing.t or 0
    trigger[ppt.EASING] = easing.type or 0
    trigger[ppt.EASING_RATE] = easing.rate or 1

    table.insert(self.triggers, trigger)
    return self
end

--- Scales a group by a certain amount.
---@param scaleFactor number to scale down to, e.g. 0.5 is half size
---@param easing? table not required, defaults to none
---@param divideMode? boolean whether to divide by the scaleFactor instead of multiply
function Component:Scale(time, target, scaleFactor, easing, divideMode)
    util.validateArgs("Scale", time, target, scaleFactor)
    util.validateGroups("Scale", target)
    easing = easing or enum.DEFAULT_EASING

    local trigger = createTrigger(self)
    trigger[ppt.OBJ_ID] = enum.ObjectID.Scale
    trigger[ppt.X] = util.timeToDist(time)

    trigger[ppt.TARGET] = target
    trigger[ppt.SCALE_CENTER] = target
    trigger[ppt.SCALE_X] = scaleFactor
    trigger[ppt.SCALE_Y] = scaleFactor

    trigger[ppt.DURATION] = easing.t
    trigger[ppt.EASING] = easing.type
    trigger[ppt.EASING_RATE] = easing.rate

    trigger[ppt.SCALE_DIV_BY_X] = divideMode or false
    trigger[ppt.SCALE_DIV_BY_Y] = divideMode or false

    table.insert(self.triggers, trigger)
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

    local trigger = createTrigger(self)
    trigger[ppt.OBJ_ID] = enum.ObjectID.Pulse
    trigger[ppt.X] = util.timeToDist(time)

    trigger[ppt.TARGET] = target
    trigger[ppt.PULSE_TARGET_TYPE] = true
    trigger[ppt.PULSE_HSV] = true
    trigger[ppt.PULSE_HSV_STRING] = string.format("%da%da%da0a0", hsb.h, hsb.s, hsb.b)
    trigger[ppt.PULSE_EXCLUSIVE] = hsb.exclusive

    trigger[ppt.PULSE_HOLD] = fading.t
    trigger[ppt.PULSE_FADE_IN] = fading.fadeIn
    trigger[ppt.PULSE_FADE_OUT] = fading.fadeOut

    table.insert(self.triggers, trigger)
    return self
end


---Follow a target group's movement for a duration
---@param targetDir number Group to follow
function Component:Follow(time, target, targetDir, duration)
    util.validateArgs("Follow", time, target, targetDir, duration)
    util.validateGroups("Follow", target, targetDir)

    local trigger = createTrigger(self)
    trigger[ppt.OBJ_ID] = enum.ObjectID.Follow
    trigger[ppt.X] = util.timeToDist(time)

    trigger[ppt.TARGET] = target
    trigger[ppt.FOLLOW_GROUP] = targetDir
    trigger[ppt.DURATION] = duration

    table.insert(self.triggers, trigger)
    return self
end

--- Change the opacity of a target group
---@param args table requires 'opacity' field, optional 't' field
function Component:Alpha(time, target, args)
    util.validateArgs("Alpha", time, target, args.opacity)
    util.validateGroups("Alpha", target)
    if args.opacity < 0 or args.opacity > 1 then error("Alpha: 'opacity' must be between 0 and 1") end

    local trigger = createTrigger(self)
    trigger[ppt.OBJ_ID] = enum.ObjectID.Alpha
    trigger[ppt.X] = util.timeToDist(time)

    trigger[ppt.TARGET] = target
    trigger[ppt.OPACITY] = args.opacity
    trigger[ppt.DURATION] = args.t or 0

    table.insert(self.triggers, trigger)
    return self
end


--- Stop a target group.
---
--- Only stops: Move, Rotate, Follow, Pulse, Alpha, Scale, Spawn
---@param useControlID boolean Control ID checkbox option
function Component:Stop(time, target, useControlID)
    util.validateArgs("Stop", time, target)
    util.validateGroups("Stop", target)

    local trigger = createTrigger(self)
    trigger[ppt.OBJ_ID] = enum.ObjectID.Stop
    trigger[ppt.X] = util.timeToDist(time)

    trigger[ppt.TARGET] = target
    trigger[ppt.STOP_OPTION] = 0
    trigger[ppt.STOP_USE_CONTROL_ID] = useControlID or false

    table.insert(self.triggers, trigger)
    return self
end

--- Pause a target group.
---
--- Only pauses: Move, Rotate, Follow, Pulse, Alpha, Scale, Spawn
---@param useControlID boolean Control ID checkbox option
function Component:Pause(time, target, useControlID)
    util.validateArgs("Pause", time, target)
    util.validateGroups("Pause", target)

    local trigger = createTrigger(self)
    trigger[ppt.OBJ_ID] = enum.ObjectID.Stop
    trigger[ppt.X] = util.timeToDist(time)

    trigger[ppt.TARGET] = target
    trigger[ppt.STOP_OPTION] = 1
    trigger[ppt.STOP_USE_CONTROL_ID] = useControlID or false

    table.insert(self.triggers, trigger)
    return self
end

--- Resumes a target group that is paused.
---
--- Only resumes: Move, Rotate, Follow, Pulse, Alpha, Scale, Spawn
---@param useControlID boolean Control ID checkbox option
function Component:Resume(time, target, useControlID)
    util.validateArgs("Resume", time, target)
    util.validateGroups("Resume", target)

    local trigger = createTrigger(self)
    trigger[ppt.OBJ_ID] = enum.ObjectID.Stop
    trigger[ppt.X] = util.timeToDist(time)

    trigger[ppt.TARGET] = target
    trigger[ppt.STOP_OPTION] = 2 -- Resume option
    trigger[ppt.STOP_USE_CONTROL_ID] = useControlID or false

    table.insert(self.triggers, trigger)
    return self
end

--[[

    MULTITARGET INITIALIZATION:

]]

lib.MultitargetRegistry:initializeBinaryComponents(Component)

--[[

    PATTERN COMPONENT METHODS:

    Organized by naming convention:
    - Component:instant_* - Instantaneous patterns (single tick, single emitter)
    - Component:timed_* - Timed patterns (multiple waves/phases)

]]

--#region Instant Patterns

--- Creates a radial pattern spawn setting, to shoot all at once in a circular pattern
---@param component Component ; requires assertSpawnOrder(true), represents cycle of a single bullet
---@param guiderCircle GuiderCircle ; circle to aim at and spawn from
---@param bulletType Bullet ; the bullet type to use for spawning
---@param args table, requires either 'spacing' OR 'numOfBullets', optional 'centerAt' angle (clockwise from guidercircle pointer), defaults to 0
function Component:instant_Radial(time, component, guiderCircle, bulletType, args)
    util.validateArgs("Radial", component, guiderCircle, bulletType, args)
    util.validateRadialComponent("Radial", component)

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
    self:instant_Arc(time, component, guiderCircle, bulletType, args)
    return self
end

--- Creates an arc pattern spawn setting, to shoot bullets in a partial circular pattern
---@param component Component ; requires assertSpawnOrder(true), represents cycle of a single bullet
---@param guiderCircle GuiderCircle ; circle to aim at and spawn from
---@param bulletType Bullet ; the bullet type to use for spawning
---@param args table, requires 'numOfBullets', 'spacing' angle, optional 'centerAt' angle (clockwise from guidercircle pointer), defaults to 0
function Component:instant_Arc(time, component, guiderCircle, bulletType, args)
    util.validateArgs("Arc", component, guiderCircle, bulletType, args.spacing, args.numOfBullets)
    util.validateRadialComponent("instant_Arc", component)

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

--- Creates a line pattern spawn setting, where bullets burst from emitter at different speeds to form a line
--- 
---@param component Component ; requires assertSpawnOrder(true), represents cycle of a single bullet
---@param targetDir number ; target group bullets move towards
---@param bulletType Bullet ; the bullet type to use for spawning
---@param args table ; requires 'fastestTime', 'slowestTime', 'dist'    optional 'easingType', 'easingRate', 'moveDelay'
function Component:instant_Line(time, component, targetDir, bulletType, numOfBullets, args)
    util.validateArgs("instant_Line", time, component, bulletType, numOfBullets)
    util.validateArgs("instant_Line", args.fastestTime, args.slowestTime, args.dist)
    util.validateGroups("instant_Line", targetDir)
    util.validateRadialComponent("instant_Line", component, false)

    args.easingType = args.easingType or enum.Easing.LINEAR
    args.easingRate = args.easingRate or 1
    args.moveDelay = args.moveDelay or enum.TICK * 2
    
    if not util.isInteger(numOfBullets) then
        error("instant_Line: numOfBullets must be an integer")
    elseif numOfBullets < 3 then
        error("instant_Line: numOfBullets must be at least 3")
    end
    
    if args.fastestTime <= 0 then
        error("instant_Line: fastestTime must be positive number")
    elseif args.slowestTime <= 0 then
        error("instant_Line: slowestTime must be a positive number")
    elseif args.slowestTime < args.fastestTime then
        error("instant_Line: slowestTime must be greater than or equal to fastestTime")
    end
    
    if type(args.dist) ~= "number" then error("instant_Line: dist must be a number") end
    
    local bulletGroups = {}
    local comps = lib.MultitargetRegistry:getBinaryComponents(numOfBullets)
    
    for _, comp in ipairs(comps) do
        local empties = util.createNumberCycler(6001, 6128)
        local remap_string = ""
        for _, spawnTrigger in ipairs(comp.triggers) do
            local remapPairs = util.translateRemapString(spawnTrigger[enum.Properties.REMAP_STRING])
            for source, target in pairs(remapPairs) do
                remap_string = remap_string .. target .. '.'
                
                local sourceNum = tonumber(source)
                if sourceNum == enum.EMPTY_BULLET then
                    local nextBullet = bulletType.nextBullet()
                    remap_string = remap_string .. nextBullet
                    table.insert(bulletGroups, nextBullet)
                else
                    remap_string = remap_string .. empties()
                end
                
                remap_string = remap_string .. '.'
            end
        end
        -- Final mapping: EMPTY_MULTITARGET -> component caller group
        remap_string = remap_string .. enum.EMPTY_MULTITARGET .. '.' .. component.callerGroup
        self:Spawn(time, comp.callerGroup, false, remap_string)
    end
    
    for i, bullet in pairs(bulletGroups) do
        -- Calculate travel time for each bullet
        local travelTime = args.fastestTime + ((args.slowestTime - args.fastestTime) / (numOfBullets - 1)) * (i - 1)
        local easing = {
            t = travelTime,
            type = args.easingType,
            rate = args.easingRate,
            dist = args.dist
        }
        
        self:MoveTowards(time + args.moveDelay, bullet, targetDir, easing)
    end
    
    return self
end

--#endregion

--#region Timed Patterns

--[[
    Timed Patterns are built on top of Instant Patterns by calling them multiple times
    with time offsets to create waves or sequences.
    
    These do not contain multiple emitters.
]]

--- Creates a radial wave pattern - repeated radials over time
---@param time number
---@param component Component ; requires assertSpawnOrder(true), represents cycle of a single bullet
---@param guiderCircle GuiderCircle ; circle to aim at and spawn from
---@param bulletType Bullet ; the bullet type to use for spawning
---@param args table, requires either 'spacing' OR 'numOfBullets', 'waves', 'interval', optional 'centerAt'
function Component:timed_RadialWave(time, component, guiderCircle, bulletType, args)
    util.validateArgs("RadialWave", component, guiderCircle, bulletType, args)
    util.validateRadialComponent("RadialWave", component)

    -- Validate wave-specific parameters
    if not args.waves or not util.isInteger(args.waves) or args.waves < 1 then
        error("RadialWave: waves must be a positive integer")
    end
    if not args.interval or args.interval <= 0 then
        error("RadialWave: interval must be a positive number")
    end

    for i = 1, args.waves do
        self:instant_Radial(time + (i - 1) * args.interval, component, guiderCircle, bulletType, args)
    end

    return self
end

--#endregion


return m
