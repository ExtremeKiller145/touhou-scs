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
        [ppt.TARGET_CENTER] = target,
        [ppt.TARGET_DIR] = targetDir,
        [ppt.DIRECTION_MODE_DISTANCE] = easing.dist,
        [ppt.DURATION] = easing.t,
        [ppt.EASING] = easing.type,
        [ppt.EASING_RATE] = easing.rate,
        [ppt.EDITOR_LAYER] = self.editorLayer,
        [ppt.GROUPS] = self.callerGroups,
        [ppt.DIRECTION_MODE] = true,
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
    table.insert(self.triggers, {
        [ppt.OBJ_ID] = enum.ObjectID.Move,
        [ppt.X] = x,
        [ppt.Y] = 0,
        [ppt.TARGET] = target,
        [ppt.DURATION] = easing.t,
        [ppt.EASING] = easing.type,
        [ppt.EASING_RATE] = easing.rate,
        [ppt.MOVE_X] = vector2.X,
        [ppt.MOVE_Y] = vector2.Y,
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
    
    local allTriggers = {
        triggers = {}
    }
    
    for _, spell in pairs(AllSpells) do
        for _, trigger in pairs(spell.triggers) do
            table.insert(allTriggers.triggers, trigger)
        end
    end
    
    local file = io.open(filename, "w")
    file:write(json.encode(allTriggers, { indent = "\t" }))
    file:close()
    print("Saved to " .. filename .. " successfully!")
end

return lib