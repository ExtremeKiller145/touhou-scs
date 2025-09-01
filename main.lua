
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


local testRadialComp = l.Component.new("TestRadial", u.unknown_g(), 4)
local emitter = 30
testRadialComp
    :assertSpawnOrder(true)
    :GotoGroup(0, e.EMPTY_BULLET, emitter, { t = 0 })
    :Toggle(e.TICK, e.EMPTY_BULLET, true)
    :Alpha(0, e.EMPTY_BULLET, { t = 0, opacity = 0})
    :Alpha(e.TICK, e.EMPTY_BULLET, { t = 1, opacity = 1.00})
    :Scale(0, e.EMPTY_BULLET, 2, { t = 0 })
    :Scale(e.TICK*2, e.EMPTY_BULLET, 2, { t = 0.3 }, true)
    :PointToGroup(e.TICK, e.EMPTY_BULLET, e.EMPTY_TARGET_GROUP)
    :PointToGroup(0.3, e.EMPTY_BULLET, e.EMPTY_TARGET_GROUP)
    :MoveTowards(0.3, e.EMPTY_BULLET, e.EMPTY_TARGET_GROUP,
        { t = 1.8, type = e.Easing.EASE_IN_OUT, rate = 2.01, dist = 70 })
    -- :PointToGroup(2.1, e.EMPTY_BULLET, e.PLR, { t = 0.2 })
    :Pulse(2.1, e.EMPTY_BULLET, 
        {h = 54, s = 124, b = 156}, { fadeIn = 0.1, t = 0.1, fadeOut = 0.3 })
    :MoveTowards(2.1, e.EMPTY_BULLET, e.EMPTY_TARGET_GROUP,
        { t = 5, type = e.Easing.EASE_IN, rate = 2.01, dist = 500 })
    -- :MoveTowards(2.1, e.EMPTY_BULLET, e.PLR, { t = 500/100, type = e.Easing.EASE_IN, rate = 2.01, dist = 500 })

local callerComponent = l.Component.new("CallerComponent", u.group(36), 4)
callerComponent:assertSpawnOrder(true)
    :GotoGroup(0, c1.all, emitter, { t = 0 })
    :MoveBy(0.2, emitter, u.vector2(-150, 30), { t = 10, type = e.Easing.EASE_IN, rate = 1.5 })
    :MoveBy(0.2, c1.all, u.vector2(-150, 30), { t = 10, type = e.Easing.EASE_IN, rate = 1.5 })

    -- sb.Radial(4, callerComponent, testRadialComp, c1, l.Bullet.Bullet3,
    --     { spacing = 5 })
    sb.Arc(0, callerComponent, testRadialComp, c1, l.Bullet.Bullet1,
        { numOfBullets = 127, spacing = 1, centerAt = 0 })
    sb.Arc(2, callerComponent, testRadialComp, c1, l.Bullet.Bullet2,
        { numOfBullets = 10, spacing = 14, centerAt = 0 })

-- for i = 1, 3 do
--     sb.Radial(4+i*0.5, callerComponent, testRadialComp, c1, l.Bullet.Bullet3,
--         { spacing = 5 })
-- end


misc.addPlayerCollision()
misc.addDisableAllBullets()
l.SaveAll()