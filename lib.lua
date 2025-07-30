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

--- Moves a group towards another group
---@param target number Group to move
---@param targetDir number Group to move towards
---@param easing table
---@return SpellBuilder
function SpellBuilder:MoveTowards(x, target, targetDir, easing)
    util.validateArgs("MoveTowards", x, target, targetDir, easing)
    util.validateEasing("MoveTowards", easing)
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Move,
        [ppt.X] = x,
        [ppt.Y] = 0,
        [ppt.TARGET] = target,
        [ppt.MOVE_TARGET_CENTER] = target,
        [ppt.MOVE_TARGET_DIR] = targetDir,
        [ppt.MOVE_DIRECTION_MODE] = true,
        [ppt.MOVE_DIRECTION_MODE_DISTANCE] = easing.dist,
        [ppt.DURATION] = easing.t,
        [ppt.EASING] = easing.type,
        [ppt.EASING_RATE] = easing.rate,
        [ppt.DYNAMIC] = easing.dynamic or false,
        [ppt.MOVE_SILENT] = (easing.t == 0),
        [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.GROUPS] = self.callerGroups,
        [ppt.SPAWN_TRIGGERED] = true,
        [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

--- Moves a group by an X and Y change
---@param target number Group to move
---@param vector2 table X and Y change in studs
---@param easing table
---@return SpellBuilder
function SpellBuilder:MoveBy(x, target, vector2, easing)
    util.validateArgs("MoveBy", x, target, vector2, easing)
    easing.MoveBy = true -- passes check for dist/angle
    util.validateEasing("MoveBy", easing)
    util.validateVector2("MoveBy", vector2)
    if easing.dynamic then error("MoveBy does not support dynamic mode") end
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Move,
        [ppt.X] = x,
        [ppt.Y] = 0,
        [ppt.MOVE_X] = vector2.X,
        [ppt.MOVE_Y] = vector2.Y,
        [ppt.TARGET] = target,
        [ppt.DURATION] = easing.t,
        [ppt.EASING] = easing.type,
        [ppt.EASING_RATE] = easing.rate,
        [ppt.MOVE_SILENT] = (easing.t == 0),
        [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.GROUPS] = self.callerGroups,
        [ppt.SPAWN_TRIGGERED] = true,
        [ppt.MULTI_TRIGGERED] = true,
    })
    return self
end

--- Moves a group to a group in a certain amount of time
---@param target number Group to move
---@param location number Group location to move to
---@param easing table
---@return SpellBuilder
function SpellBuilder:GotoGroup(x, target, location, easing)
    util.validateArgs("GotoGroup", x, target, location, easing)
    util.validateEasing("GotoGroup", easing)
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Move,
        [ppt.X] = x,
        [ppt.Y] = 0,
        [ppt.TARGET] = target,
        [ppt.MOVE_TARGET_CENTER] = target,
        [ppt.MOVE_TARGET_MODE] = true,
        [ppt.MOVE_TARGET_LOCATION] = location,
        [ppt.DURATION] = easing.t,
        [ppt.EASING] = easing.type,
        [ppt.EASING_RATE] = easing.rate,
        [ppt.DYNAMIC] = easing.dynamic or false,
        [ppt.MOVE_SILENT] = (easing.t == 0),
        [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.GROUPS] = self.callerGroups,
        [ppt.SPAWN_TRIGGERED] = true,
        [ppt.MULTI_TRIGGERED] = true,
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