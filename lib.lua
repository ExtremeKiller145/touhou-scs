--[[
    Library for Touhou Shattered Crystal Shards
    I did document it somewhat but I am kinda a trash programmer, gl on modifying it
    rewriting ts cuz the first js version was ass 
]]--

local lib = {}

local enum = require("Enums")
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

function SpellBuilder:Spawn(x, target, spawnOrdered, remapString)
    table.insert(self.triggers, {
        [ppt.X] = x,
        [ppt.Y] = 0,
        [ppt.TARGET] = target or error('Missing "target" arg'),
        [ppt.SPAWN_ORDERED] = spawnOrdered or false,
        [ppt.REMAP_STRING] = remapString or "",
        [ppt.OBJ_ID] = enum.ObjectID.Spawn,
        [ppt.RESET_REMAPS] = true
    })
    return self
end

function SpellBuilder:MoveTowards(x, target, targetDir, easing)
    table.insert(self.triggers, {
        [ppt.X] = x or error('missing argument "x"'),
        [ppt.Y] = 0,
        [ppt.TARGET] = target or error('missing argument "target"'),
        [ppt.TARGET_DIR] = targetDir or error('missing argument "targetDir"'),
        [ppt.OBJ_ID] = enum.ObjectID.Move,
    })
    return self
end

function lib.CreateEase(time, easingType, easingRate)
    return {
        [ppt.TIME] = time or 0,
        [ppt.EASING_TYPE] = easingType or enum.Easing.NONE,
        [ppt.EASING_RATE] = easingRate or 1
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