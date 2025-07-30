
local l = require("lib")
local e = require("enums")
local u = require("utils")

local nextPointer = u.createNumberCycler(601, 1100)
local nextBullet2 = u.createNumberCycler(1101, 1600)
local nextBullet3 = u.createNumberCycler(1601, 2100)

local spell = l.SpellBuilder.new("Test Spell", u.group({ 120, 200, e.UNKNOWN_G }))
spell:MoveTowards(30, nextBullet2(), e.PLR,
    { t = 4, type = e.Easing.BACK_IN, rate = 1.5, dist = e.OFFSCREEN_DIST })
:MoveBy(30, nextBullet3(), u.vector2(10,10),
    { t = 4, type = e.Easing.BACK_IN, rate = 1.5 })


l.SaveAll()