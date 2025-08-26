---@diagnostic disable: missing-parameter

local l = require("lib")
local e = require("enums")
local u = require("utils")
local sb = require("spellbuilder")
local misc = require("misc")
-- Create a test component with various triggers for testing property data
local MAIN = u.group(36)
local BOSS = u.group(110)
local EMITTER_1 = u.group(111)
local EMITTER_2 = u.group(112)
local EMITTER_3 = u.group(113)
local c1 = sb.GuiderCircle.circle1




misc.addPlayerCollision()
misc.addDisableAllBullets()
l.SaveAll()