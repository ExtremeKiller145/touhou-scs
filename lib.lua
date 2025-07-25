--[[
    Library for Touhou Shattered Crystal Shards
    I did document it somewhat but I am kinda a trash programmer, gl on modifying it
    rewriting ts cuz the first js version was ass 
]]--

local lib = {}

local enum = require("Enums")
local ppt = enum.Properties
local easing = enum.Easing


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


function SpellBuilder:Spawn(x, target, spawnOrdered, remapString)
    local trigger = {
        [ppt.X] = x,
        [ppt.Y] = 0,
        [ppt.TARGET] = target,
        [ppt.SPAWN_ORDERED] = spawnOrdered or false,
        [ppt.REMAP_STRING] = remapString or "",
        [ppt.OBJ_ID] = enum.ObjectID.Spawn,
        [ppt.RESET_REMAPS] = false
    }
    table.insert(self.triggers, trigger)
    return self
end

function SpellBuilder:Move(x,target)
    table.insert(self.triggers, {})
    return self
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