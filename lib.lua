--[[
    Library for Touhou Shattered Crystal Shards
    I did document it somewhat but I am kinda a trash programmer, gl on modifying it
    rewriting ts cuz the first js version was ass 
]]--

local lib = {}

local enum = {}
enum.PLR_SPEED = 311.58
enum.PLR_GROUP = 2
enum.EDITOR_LAYER = 4
-- Easing Constants
enum.Easing = {}
enum.Easing.NONE = 1
enum.Easing.EASE_IN_OUT = 2
enum.Easing.EASE_IN = 3
enum.Easing.EASE_OUT = 4
enum.Easing.ELASTIC_IN_OUT = 5
enum.Easing.ELASTIC_IN = 6
enum.Easing.ELASTIC_OUT = 7
enum.Easing.BOUNCE_IN_OUT = 8
enum.Easing.BOUNCE_IN = 9
enum.Easing.BOUNCE_OUT = 10
enum.Easing.EXPONENTIAL_IN_OUT = 11
enum.Easing.EXPONENTIAL_IN = 12
enum.Easing.EXPONENTIAL_OUT = 13
enum.Easing.EXPONENTIAL_IN_OUT = 14
enum.Easing.EXPONENTIAL_IN = 15
enum.Easing.EXPONENTIAL_OUT = 16
enum.Easing.SINE_IN_OUT = 17
enum.Easing.SINE_IN = 18
enum.Easing.SINE_OUT = 19
enum.Easing.BACK_IN_OUT = 20
enum.Easing.BACK_IN = 21
enum.Easing.BACK_OUT = 22
-- Property Constants
enum.Properties = {}
enum.Properties.TOGGLE_ACTIVATE_GROUP = 56
enum.Properties.RESET_REMAPS = 581
enum.Properties.SPAWN_ORDERED = 441
-- Object ID Constants
enum.ObjectID = {}
enum.ObjectID.Toggle = 1049
enum.ObjectID.Spawn = 1268
enum.ObjectID.Pulse = 1006
enum.ObjectID.Scale = 2067
enum.ObjectID.Move = 901
enum.ObjectID.Rotate = 1346



local function readonly(tbl)
    local proxy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            proxy[k] = readonly(v)
        else
            proxy[k] = v
        end
    end
    return setmetatable(proxy, {
        __index = proxy,
        __newindex = function() error("Attempt to modify read-only table") end,
        __metatable = false -- Prevent further changes to the metatable
    })
end

-- Only expose the immutable version
lib.enum = readonly(enum)
lib.enum.Easing = readonly(enum.Easing)
lib.enum.Properties = readonly(enum.Properties)
lib.enum.ObjectID = readonly(enum.ObjectID)

local SpellBuilder = {}
SpellBuilder.__index = SpellBuilder
local AllSpells = {}

function SpellBuilder.new(groups, editorLayer, spellName)
    local self = setmetatable({}, SpellBuilder)
    self.groups = groups or {}
    self.editorLayer = editorLayer or 4
    self.spellName = spellName or "unnamed"
    self.triggers = {}
    table.insert(AllSpells, self)
    return self
end

function SpellBuilder:Spawn(x, group, ...)
    table.insert(self.triggers, {type="Spawn", x=x, group=group, args={...}})
    return self
end

function SpellBuilder:Move(...)
    table.insert(self.triggers, {type="Move", args={...}})
    return self
end

function lib.SaveAll()
    local filename = "triggers.json"
    -- Loop through all spells and save them to a file
    -- Write the logic to save the spell configuration to json
end

lib.enum = {}

return lib