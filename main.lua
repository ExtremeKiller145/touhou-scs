
local lib = require("lib")

local spell = lib.SpellBuilder.new("Test Spell", { 1, 2, 3 }, 4)
spell:MoveTowards(0, 50, 100)
    :MoveTowards(0, 50, 100)
    :MoveTowards(0, 50, 100)

lib.SaveAll()