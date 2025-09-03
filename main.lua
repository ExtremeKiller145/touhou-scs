---@diagnostic disable: missing-parameter

local l = require("lib")
local e = require("enums")
local u = require("utils")
local sb = require("spellbuilder")
local misc = require("misc")

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
    :Pulse(2.1, e.EMPTY_BULLET, 
        {h = 54, s = 124, b = 156}, { fadeIn = 0.1, t = 0.1, fadeOut = 0.3 })
    :MoveTowards(2.1, e.EMPTY_BULLET, e.EMPTY_TARGET_GROUP,
        { t = 5, type = e.Easing.EASE_IN, rate = 2.01, dist = 500 })

local emitter2 = 110
local test2 = l.Component.new("TestRadial2", u.unknown_g(), 4)
test2
    :assertSpawnOrder(true)
    :GotoGroup(0, e.EMPTY_BULLET, emitter2, { t = 0 })
    :Scale(0, e.EMPTY_BULLET, 4, { t = 0 })
    :Scale(e.TICK*2, e.EMPTY_BULLET, 4, { t = 0.3 }, true)
    :Toggle(e.TICK, e.EMPTY_BULLET, true)
    :Alpha(0, e.EMPTY_BULLET, { t = 0, opacity = 0})
    :Alpha(e.TICK, e.EMPTY_BULLET, { t = 1, opacity = 1.00})
    :PointToGroup(e.TICK, e.EMPTY_BULLET, e.EMPTY_TARGET_GROUP)
    :PointToGroup(0.3, e.EMPTY_BULLET, e.EMPTY_TARGET_GROUP)
    :MoveTowards(0.3, e.EMPTY_BULLET, e.EMPTY_TARGET_GROUP,
        { t = 1.8, type = e.Easing.EASE_IN_OUT, rate = 2.01, dist = 70 })
    :Pulse(0, e.EMPTY_BULLET,
        {h = -64, s = 124, b = 255}, { fadeIn = 0, t = 10, fadeOut = 0 })
    :Pulse(2.1, e.EMPTY_BULLET,
        {h = 64, s = 24, b = 156}, { fadeIn = 0.1, t = 0.1, fadeOut = 0.4 })
    :MoveTowards(2.5, e.EMPTY_BULLET, e.PLR,
        { t = 6, type = e.Easing.EASE_IN, rate = 2.01, dist = 400 })
    :PointToGroup(2.4, e.EMPTY_BULLET, e.PLR, { t = 0.3 })

local callerComponent = l.Component.new("CallerComponent", u.group(36), 4)
callerComponent:assertSpawnOrder(true)
    :GotoGroup(0, c1.all, emitter, { t = 0 })
    :MoveBy(0.2, emitter, u.vector2(-150, 30), { t = 10, type = e.Easing.EASE_IN, rate = 1.5 })
    :MoveBy(0.2, c1.all, u.vector2(-150, 30), { t = 10, type = e.Easing.EASE_IN, rate = 1.5 })

    sb.Arc(0, callerComponent, testRadialComp, c1, l.Bullet.Bullet1,
        { numOfBullets = 16, spacing = 20, centerAt = 0 })
    sb.Arc(2, callerComponent, testRadialComp, c1, l.Bullet.Bullet2,
        { numOfBullets = 10, spacing = 14, centerAt = 0 })

callerComponent
    :GotoGroup(0.9, c1.all, emitter2, { t = 0 })
    :MoveBy(0.8, emitter2, u.vector2(80, -20), { t = 8, type = e.Easing.BOUNCE_IN_OUT, rate = 1 })
    sb.Radial(1, callerComponent, test2, c1, l.Bullet.Bullet4,
        { numOfBullets = 18, centerAt = 0 })
callerComponent
    :GotoGroup(2.9, c1.all, emitter2, { t = 0 })
    sb.RadialWave(3, callerComponent, test2, c1, l.Bullet.Bullet3,
        { numOfBullets = 24, centerAt = 10, waves = 10, interval = 0.3 })

misc.addPlayerCollision()
misc.addDisableAllBullets()
l.SaveAll()