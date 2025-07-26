--[[
    Library for Touhou Shattered Crystal Shards
    I did document it somewhat but I am kinda a trash programmer, gl on modifying it
    rewriting ts cuz the first js version was ass 
]]--

local lib = {}

local enum = require("enums")
local util = require("utils")
local ppt = enum.Properties


local AllSpells = {}
local SpellBuilder = {}
SpellBuilder.__index = SpellBuilder

function SpellBuilder.new(groups, editorLayer, spellName)
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

function SpellBuilder:Spawn(x, target, spawnOrdered, delay, remapString)
    table.insert(self.triggers, {
        [ppt.X] = x,
        [ppt.Y] = 0,
        [ppt.DELAY] = delay or 0,
        [ppt.TARGET] = target or error('Missing "target" arg'),
        [ppt.SPAWN_ORDERED] = spawnOrdered or false,
        [ppt.REMAP_STRING] = remapString or "",
        [ppt.OBJ_ID] = enum.ObjectID.Spawn,
        [ppt.RESET_REMAP] = true
    })
    return self
end

function SpellBuilder:MoveTowards(x, target, targetDir, easing)
    util.validateArgs("MoveTowards", x, target, targetDir, easing)
    table.insert(self.triggers, {
        [ppt.X] = x,
        [ppt.Y] = 0,
        [ppt.TARGET] = target,
        [ppt.TARGET_DIR] = targetDir,
        [ppt.OBJ_ID] = enum.ObjectID.Move,
        [ppt.EASING] = easing or enum.Easing.defaultEasing,
    })
    return self
end

function lib.CreateEasing(time, easingType, easingRate)
    return {
        Time = time or 0,
        Easing_type = easingType or enum.Easing.NONE,
        Easing_rate = easingRate or 1
    }
end

function lib.SaveAll()
    -- local json = require("json")
    -- local filename = "triggers.json"
    
    -- local allTriggers = {
    --     triggers = {}
    -- }
    
    -- for _, spell in ipairs(AllSpells) do
    --     for _, trigger in ipairs(spell.triggers) do
    --         table.insert(allTriggers.triggers, trigger)
    --     end
    -- end
    
    -- local file = io.open(filename, "w")
    -- file:write(json.encode(allTriggers))
    -- file:close()
end

return lib