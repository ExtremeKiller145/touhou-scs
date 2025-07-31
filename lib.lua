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

local AllSpells = {}

---@class EasingSetting
---@field time number
---@field easingType number
---@field easingRate number
local EasingSetting = {}
EasingSetting.__index = EasingSetting
lib.EasingSetting = EasingSetting

---Constructor for Easing
---@param time number
---@param easingType number
---@param easingRate number
---@return EasingSetting
function EasingSetting.new(time, easingType, easingRate)
    local self = setmetatable({}, EasingSetting)
    self.time = time or 0
    self.easingType = easingType or enum.Easing.NONE
    self.easingRate = easingRate or 1
    return self
end

---@class SpellBuilder
---@field callerGroups table
---@field editorLayer number
---@field spellName string
---@field triggers table
local SpellBuilder = {}
SpellBuilder.__index = SpellBuilder
lib.SpellBuilder = SpellBuilder

---Constructor
---@param callerGroups table
---@param editorLayer number
---@param spellName string
---@return SpellBuilder
function SpellBuilder.new(spellName, callerGroups, editorLayer)
    local self = setmetatable({}, SpellBuilder)
    self.callerGroups = callerGroups or {}
    self.editorLayer = editorLayer or 4
    self.spellName = spellName or "unnamed"
    self.triggers = {}
    table.insert(AllSpells, self)
    return self
end

function SpellBuilder:SetCallerGroups(callerGroups)
    self.callerGroups = callerGroups
end


--- Spawns a group
---@param remapID string Remap string, dot-seperated list, e.g. '1.2.3.4' remaps 1 -> 2 and 3 -> 4
---@param spawnOrdered boolean Execute from left to right w/ gap time
---@return SpellBuilder
function SpellBuilder:Spawn(x, target, spawnOrdered,  remapID, spawnDelay)
    util.validateArgs("Spawn", x, target, remapID)
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Spawn,
        [ppt.X] = x, [ppt.Y] = 0,
        [ppt.TARGET] = target,

        [ppt.REMAP_STRING] = remapID,
        [ppt.RESET_REMAP] = true,
        [ppt.SPAWN_ORDERED] = spawnOrdered,
        [ppt.SPAWN_DELAY] = spawnDelay,

        [ppt.GROUPS] = self.callerGroups, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

--- Toggles a group on or off. 
--- WARNING: A deactivated object cannot be reactivated by a different group 
--- (collision triggers might be different)
---@param activateGroup boolean Activate or deactivate group
function SpellBuilder:Toggle(x, target, activateGroup)
    util.validateArgs("Toggle", x, target, activateGroup)
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Toggle,
        [ppt.X] = x, [ppt.Y] = 0,

        [ppt.TARGET] = target,
        [ppt.ACTIVATE_GROUP] = activateGroup,

        [ppt.GROUPS] = self.callerGroups, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

--- Moves a group towards another group
---@param targetDir number Group to move towards
---@param easing table Requires 'dist', 'time', 'type', 'rate' fields
---@return SpellBuilder
function SpellBuilder:MoveTowards(x, target, targetDir, easing)
    util.validateArgs("MoveTowards", x, target, targetDir, easing)
    util.validateEasing("MoveTowards", easing)
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

        [ppt.GROUPS] = self.callerGroups, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

--- Moves a group by an X and Y change
---@param vector2 table X and Y change in studs
---@param easing table Requires 'time', 'type', 'rate' fields
---@return SpellBuilder
function SpellBuilder:MoveBy(x, target, vector2, easing)
    util.validateArgs("MoveBy", x, target, vector2, easing)
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

        [ppt.GROUPS] = self.callerGroups, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

--- Moves a group to a group in a certain amount of time
---@param location number Group location to move to
---@param easing table Requires 'time', 'type', 'rate' fields
---@return SpellBuilder
function SpellBuilder:GotoGroup(x, target, location, easing)
    util.validateArgs("GotoGroup", x, target, location, easing)
    util.validateEasing("GotoGroup", easing)
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Move,
        [ppt.X] = x, [ppt.Y] = 0,

        [ppt.TARGET] = target, [ppt.MOVE_TARGET_CENTER] = target,
        [ppt.MOVE_TARGET_MODE] = true, [ppt.MOVE_TARGET_LOCATION] = location,
        [ppt.DURATION] = easing.t,
        [ppt.EASING] = easing.type, [ppt.EASING_RATE] = easing.rate,
        [ppt.DYNAMIC] = easing.dynamic or false,
        [ppt.MOVE_SILENT] = (easing.t == 0),

        [ppt.GROUPS] = self.callerGroups, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

--- Rotates a group by a certain amount
---@param easing table Must contain angle field
---@return SpellBuilder
function SpellBuilder:Rotate(x, target, easing)
    util.validateArgs("Rotate", x, target, easing)
    if not easing.angle then error("Rotate: 'easing' missing required field 'angle'") end
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Rotate,
        [ppt.X] = x, [ppt.Y] = 0,

        [ppt.TARGET] = target, [ppt.ROTATE_CENTER] = target,
        [ppt.ROTATE_ANGLE] = easing.angle, -- degrees, clockwise is +
        [ppt.DURATION] = easing.t or 0,
        [ppt.EASING] = easing.type or 0,
        [ppt.EASING_RATE] = easing.rate or 1,

        [ppt.GROUPS] = self.callerGroups, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

--- Rotates a group to point towards another group
---@param targetDir number Group to point towards
---@param easing table not required, defaults to none
function SpellBuilder:PointToGroup(x, target, targetDir, easing)
    util.validateArgs("PointToGroup", x, target, targetDir)
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Rotate,
        [ppt.X] = x, [ppt.Y] = 0,

        [ppt.TARGET] = target,
        [ppt.ROTATE_TARGET] = targetDir,
        [ppt.ROTATE_AIM_MODE] = true,
        [ppt.DYNAMIC] = easing.dynamic or false,
        [ppt.ROTATE_DYNAMIC_EASING] = easing.rate or 0, -- range from 0 to 100, only if dynamic is true
        [ppt.DURATION] = easing.t or 0,
        [ppt.EASING] = easing.type or 0, [ppt.EASING_RATE] = easing.rate or 1,

        [ppt.GROUPS] = self.callerGroups, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

--- Scales a group by a certain amount, resets after some duration
---@param easing table not required, defaults to none
---@param scaleFactor number to scale down to, e.g. 0.5 is half size
---@param duration number time in seconds to scale for, instant resets after
function SpellBuilder:Scale(x, target, scaleFactor, duration, easing)
    util.validateArgs("Scale", x, target, scaleFactor, duration)
    easing = easing or enum.DEFAULT_EASING
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Scale,
        [ppt.X] = x, [ppt.Y] = 0,

        [ppt.TARGET] = target, [ppt.SCALE_CENTER] = target,
        [ppt.SCALE_X] = scaleFactor, [ppt.SCALE_Y] = scaleFactor,
        [ppt.DURATION] = easing.t,
        [ppt.EASING] = easing.type, [ppt.EASING_RATE] = easing.rate,

        [ppt.GROUPS] = self.callerGroups, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Scale,
        [ppt.X] = x + util.timeToDist(duration), [ppt.Y] = 0,

        [ppt.TARGET] = target, [ppt.SCALE_CENTER] = target,
        [ppt.SCALE_X] = scaleFactor, [ppt.SCALE_Y] = scaleFactor,
        [ppt.SCALE_DIV_BY_X] = true, [ppt.SCALE_DIV_BY_Y] = true,
        [ppt.DURATION] = 0, -- instant reset scale once offscreen

        [ppt.GROUPS] = self.callerGroups, [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end


function lib.SaveAll()
    local json = require("dkjson")
    local filename = "triggers.json"

    local allTriggers = { triggers = {} }
    local totalTriggers = 0
    local spellStats = {}

    for _, spell in pairs(AllSpells) do
        local spellTriggerCount = #spell.triggers
        spellStats[spell.spellName] = spellTriggerCount
        totalTriggers = totalTriggers + spellTriggerCount

        for _, trigger in pairs(spell.triggers) do
            for _, group in pairs(trigger[ppt.GROUPS]) do
                if group == 9999 then error("CRITICAL ERROR: 9999 GROUP DETECTED") end
            end
            table.insert(allTriggers.triggers, trigger)
        end
    end

    -- Budget analysis
    local objectBudget = 200000
    local usagePercent = (totalTriggers / objectBudget) * 100

    print(string.format("=== BUDGET ANALYSIS ==="))
    print(string.format("Total triggers: %d", totalTriggers))
    print(string.format("Budget usage: %.3f%% (%d/%d)", usagePercent, totalTriggers, objectBudget))
    print(string.format("Remaining budget: %d triggers", objectBudget - totalTriggers))

    for spellName, count in pairs(spellStats) do
        print(string.format("  %s: %d triggers", spellName, count))
    end

    local file = io.open(filename, "w")
    file:write(json.encode(allTriggers, { indent = "\t" }))
    file:close()
    print("Saved to " .. filename .. " successfully!")
end

return lib