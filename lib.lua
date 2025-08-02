--[[
    Library for Touhou Shattered Crystal Shards
    I did document it somewhat but I am kinda a trash programmer, gl on modifying it
    rewriting ts cuz the first js version was ass 
]]--

local lib = {}

require("luarocks.loader")
local enum = require("enums")
local util = require("utils")
local ppt = enum.Properties

-- Area for spreading triggers out
local TriggerArea = {
    bottom_left = util.vector2(450,300),
    top_right = util.vector2(900,600)
}

local AllComponents = {}
local AllSpells = {}

---@class Spell
---@field spellName string
---@field callerGroup number
---@field components table
local Spell = {}
Spell.__index = Spell
lib.Spell = Spell

---Constructor for Spell
---@param spellName string
---@param callerGroup number
---@return Spell
function Spell.new(spellName, callerGroup)
    util.validateArgs("Spell.new", spellName, callerGroup)
    local self = setmetatable({}, Spell)
    self.spellName = spellName
    self.callerGroup = callerGroup
    self.components = {}
    table.insert(AllSpells, self)
    return self
end

function Spell:AddComponent(component)
    table.insert(self.components, component)
    return self
end


---@class Component
---@field callerGroup number
---@field editorLayer number
---@field componentName string
---@field triggers table
local Component = {}
Component.__index = Component
lib.Component = Component

---Constructor for Component
---@param componentName string
---@param callerGroup number
---@param editorLayer number
---@return Component
function Component.new(componentName, callerGroup, editorLayer)
    util.validateArgs("Component.new", componentName, callerGroup)
    local self = setmetatable({}, Component)
    self.componentName = componentName
    self.callerGroup = callerGroup
    self.editorLayer = editorLayer or 4
    self.triggers = {}
    table.insert(AllComponents, self)
    return self
end

---@param remapID string Remap string, dot-seperated list, e.g. '1.2.3.4' remaps 1 -> 2 and 3 -> 4
--- Nested remaps: outer remap must remap the inner, e.g. if inner is '1.2', other should be '2.3' not '1.3'. 
--- inner must not have reset_remap on.
---@param spawnOrdered boolean Execute from left to right w/ gap time
function Component:Spawn(x, target, spawnOrdered,  remapID, spawnDelay)
    util.validateArgs("Spawn", x, target, spawnOrdered, remapID)
    -- Validate group and remap string on JS side
    remapID = util.validateRemapString("Spawn", remapID) -- Cleans up redundant mappings
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Spawn,
        [ppt.X] = x, [ppt.Y] = 0,
        [ppt.TARGET] = target,

        [ppt.REMAP_STRING] = remapID,
        [ppt.RESET_REMAP] = true,
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
function Component:Toggle(x, target, activateGroup)
    util.validateArgs("Toggle", x, target, activateGroup)
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Toggle,
        [ppt.X] = x, [ppt.Y] = 0,

        [ppt.TARGET] = target,
        [ppt.ACTIVATE_GROUP] = activateGroup,

        [ppt.GROUPS] = self.callerGroup, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

---@param targetDir number Group to move towards
---@param easing table Requires 'dist', 'time', 'type', 'rate' fields
function Component:MoveTowards(x, target, targetDir, easing)
    util.validateArgs("MoveTowards", x, target, targetDir, easing)
    util.validateEasing("MoveTowards", easing)
    util.validateGroups("MoveTowards", target, targetDir)
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Move,
        [ppt.X] = x, [ppt.Y] = 0,

        [ppt.TARGET] = target, [ppt.MOVE_TARGET_CENTER] = target,
        [ppt.MOVE_TARGET_DIR] = targetDir,
        [ppt.MOVE_DIRECTION_MODE] = true, [ppt.MOVE_DIRECTION_MODE_DISTANCE] = easing.dist,
        [ppt.DURATION] = easing.t,
        [ppt.EASING] = easing.type, [ppt.EASING_RATE] = easing.rate,
        [ppt.DYNAMIC] = easing.dynamic or false,
        [ppt.MOVE_SILENT] = (easing.t == 0),

        [ppt.GROUPS] = self.callerGroup, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

---@param vector2 table X and Y change in studs
---@param easing table Requires 'time', 'type', 'rate' fields
function Component:MoveBy(x, target, vector2, easing)
    util.validateArgs("MoveBy", x, target, vector2, easing)
    util.validateGroups("MoveBy", target)
    easing.MoveBy = true -- passes check for dist/angle
    util.validateEasing("MoveBy", easing)
    util.validateVector2("MoveBy", vector2)
    if easing.dynamic then error("MoveBy does not support dynamic mode") end
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Move,
        [ppt.X] = x, [ppt.Y] = 0,

        [ppt.MOVE_X] = vector2.X, [ppt.MOVE_Y] = vector2.Y,
        [ppt.TARGET] = target,
        [ppt.DURATION] = easing.t,
        [ppt.EASING] = easing.type, [ppt.EASING_RATE] = easing.rate,
        [ppt.MOVE_SILENT] = (easing.t == 0),

        [ppt.GROUPS] = self.callerGroup, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

--- Moves a group to a group in a certain amount of time
---@param location number Group location to move to
---@param easing table Requires 'time', 'type', 'rate' fields
function Component:GotoGroup(x, target, location, easing)
    util.validateArgs("GotoGroup", x, target, location, easing)
    util.validateEasing("GotoGroup", easing)
    util.validateGroups("GotoGroup", target, location)
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Move,
        [ppt.X] = x, [ppt.Y] = 0,

        [ppt.TARGET] = target, [ppt.MOVE_TARGET_CENTER] = target,
        [ppt.MOVE_TARGET_MODE] = true, [ppt.MOVE_TARGET_LOCATION] = location,
        [ppt.DURATION] = easing.t,
        [ppt.EASING] = easing.type, [ppt.EASING_RATE] = easing.rate,
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
function Component:Rotate(x, targets, easing)
    util.validateArgs("Rotate", x, targets, easing)
    if not easing.angle then error("Rotate: 'easing' missing required field 'angle'") end
    if not targets.target then error("Rotate: 'targets' missing required field 'target'") end
    if not targets.center then error("Rotate: 'targets' missing required field 'center'") end
    util.validateGroups("Rotate", targets.target, targets.center)
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Rotate,
        [ppt.X] = x, [ppt.Y] = 0,

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
function Component:PointToGroup(x, target, targetDir, easing)
    util.validateArgs("PointToGroup", x, target, targetDir)
    util.validateGroups("PointToGroup", target, targetDir)
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Rotate,
        [ppt.X] = x, [ppt.Y] = 0,

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

--- Scales a group by a certain amount, resets after some duration
---@param easing table not required, defaults to none
---@param scaleFactor number to scale down to, e.g. 0.5 is half size
---@param duration number time in seconds to scale for, instant resets after
function Component:Scale(x, target, scaleFactor, duration, easing)
    util.validateArgs("Scale", x, target, scaleFactor, duration)
    util.validateGroups("Scale", target)
    easing = easing or enum.DEFAULT_EASING
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Scale,
        [ppt.X] = x, [ppt.Y] = 0,

        [ppt.TARGET] = target, [ppt.SCALE_CENTER] = target,
        [ppt.SCALE_X] = scaleFactor, [ppt.SCALE_Y] = scaleFactor,
        [ppt.DURATION] = easing.t,
        [ppt.EASING] = easing.type, [ppt.EASING_RATE] = easing.rate,

        [ppt.GROUPS] = self.callerGroup, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Scale,
        [ppt.X] = x + util.timeToDist(duration), [ppt.Y] = 0,

        [ppt.TARGET] = target, [ppt.SCALE_CENTER] = target,
        [ppt.SCALE_X] = scaleFactor, [ppt.SCALE_Y] = scaleFactor,
        [ppt.SCALE_DIV_BY_X] = true, [ppt.SCALE_DIV_BY_Y] = true,
        [ppt.DURATION] = 0, -- instant reset scale once offscreen

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
function Component:Pulse(x, target, hsb, fading)
    util.validateArgs("Pulse", x, target, hsb, fading)
    util.validatePulse(hsb, fading)
    util.validateGroups("Pulse", target)
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Pulse,
        [ppt.X] = x, [ppt.Y] = 0,

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

function lib.SaveAll()
    local json = require("dkjson")
    local filename = "triggers.json"
    local allTriggers = { triggers = {} }

    -- Find shared components (used in multiple spells)
    local componentUsage = {}
    for _, spell in pairs(AllSpells) do
        for _, component in pairs(spell.components) do
            componentUsage[component] = (componentUsage[component] or 0) + 1
        end
    end

    local sharedComponents = {}
    local spellStats = {}

    -- Separate shared components
    for component, usageCount in pairs(componentUsage) do
        if usageCount > 1 then sharedComponents[component] = true end
    end

    -- Process all triggers and count by category
    for _, spell in pairs(AllSpells) do
        local spellTriggerCount = 0
        for _, component in pairs(spell.components) do
            if not sharedComponents[component] then
                spellTriggerCount = spellTriggerCount + #component.triggers
            end
        end
        spellStats[spell.spellName] = spellTriggerCount
    end

    -- Count shared triggers
    local sharedTriggerCount = 0
    for component in pairs(sharedComponents) do
        sharedTriggerCount = sharedTriggerCount + #component.triggers
    end
    if sharedTriggerCount > 0 then spellStats["Shared"] = sharedTriggerCount end

    -- Add all triggers to output
    for _, component in pairs(AllComponents) do
        for _, trigger in pairs(component.triggers) do
            -- Wrap group in array (import fix)
            if trigger[ppt.GROUPS] == 9999 then
                error("CRITICAL ERROR: RESERVED GROUP 9999 DETECTED")
            end
            table.insert(allTriggers.triggers, trigger)
        end
    end

    -- Budget analysis
    local totalTriggers = #allTriggers.triggers
    local objectBudget = 200000
    local usagePercent = (totalTriggers / objectBudget) * 100

    print(string.format("\n=== BUDGET ANALYSIS ==="))
    print(string.format("Total triggers: %d (%.3f%%)", totalTriggers, usagePercent))
    print(string.format("Remaining budget: %d triggers\n", objectBudget - totalTriggers))

    for spellName, count in pairs(spellStats) do
        print(string.format("  %s: %d triggers", spellName, count))
    end

    local file = io.open(filename, "w")
    if not file then error("Failed to open " .. filename .. " for writing!") end

    file:write(json.encode(allTriggers, { indent = "\t" }))
    file:close()
    print("\nSaved to " .. filename .. " successfully!")
end

return lib
