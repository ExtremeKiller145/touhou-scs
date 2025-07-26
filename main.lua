
local lib = require("lib")

local spell = lib.SpellBuilder.new({1,2},4,"Test Spell")
spell:MoveTowards(0, 50, 100)

lib.SaveAll()