
local lib = require("lib")
local enum = require("enums")
local u = require("utils")

local nextPointer = u.createNumberCycler(601,1100)
local nextBullet2 = u.createNumberCycler(1101,1600)
local nextBullet3 = u.createNumberCycler(1601,2100)

local spell = lib.SpellBuilder.new("Test Spell", u.group({ 120, 200, enum.UNKNOWN_GROUP }))
spell:MoveTowards(30, nextBullet2(), enum.PLR_GROUP, { t = 4, type = enum.Easing.BACK_IN, rate = 1.5, dist = enum.OFFSCREEN_DIST })

lib.SaveAll()