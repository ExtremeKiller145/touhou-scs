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

lib.EasingDefault = EasingSetting.new(0,enum.Easing.NONE,0)

---@class SpellBuilder
---@field groups table
---@field editorLayer number
---@field spellName string
---@field triggers table
local SpellBuilder = {}
SpellBuilder.__index = SpellBuilder
lib.SpellBuilder = SpellBuilder

---Constructor
---@param groups table
---@param editorLayer number
---@param spellName string
---@return SpellBuilder
function SpellBuilder.new(spellName, groups, editorLayer)
    local self = setmetatable({}, SpellBuilder)
    self.groups = groups or {}
    self.editorLayer = editorLayer or 4
    self.spellName = spellName or "unnamed"
    self.triggers = {}
    table.insert(AllSpells, self)
    return self
end

function SpellBuilder:SetGroups(groups)
    self.groups = groups
end

--- Moves a group towards another group
---@param target number
---@param targetDir number
---@param easing EasingSetting
---@return SpellBuilder
function SpellBuilder:MoveTowards(x, target, targetDir, easing)
    print("Easing metatable:", getmetatable(easing))
    print("SpellBuilder metatable:", getmetatable(SpellBuilder))
    util.validateArgs("MoveTowards", x, target, targetDir)
    easing = easing or lib.EasingDefault
    table.insert(self.triggers, {
        [ppt.X] = x,
        [ppt.Y] = 0,
        [ppt.TARGET] = target,
        [ppt.TARGET_DIR] = targetDir,
        [ppt.OBJ_ID] = enum.ObjectID.Move,
        [ppt.EASING] = easing.easingType,
        [ppt.EASING_RATE] = easing.easingRate,
    })
    return self
end

function lib.SaveAll()
    local json = require("dkjson")
    local filename = "triggers.json"
    
    local allTriggers = {
        triggers = {}
    }
    
    for _, spell in ipairs(AllSpells) do
        for _, trigger in ipairs(spell.triggers) do
            table.insert(allTriggers.triggers, trigger)
        end
    end
    
    local file = io.open(filename, "w")
    file:write(json.encode(allTriggers, { indent = "\t" }))
    file:close()
end

return lib