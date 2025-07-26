
local lib = require("lib")
local enum = require("enums")

local spell = lib.SpellBuilder.new("Test Spell", { 120, 200, enum.UNKNOWN_GROUP })
local easing = lib.EasingSetting.new(3.75, enum.Easing.BACK_IN,1.5)
spell:MoveTowards(30, 49, 69,250)
    :MoveTowards(60, 50, 70, 300, easing)
    :MoveTowards(90, 51, 71, 350, easing)

lib.SaveAll()