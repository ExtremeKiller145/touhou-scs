
local l = require("lib")
local e = require("enums")
local u = require("utils")

local tests = l.SpellBuilder.new("TriggerTests", u.group({ 100, 200, 300 }), 5)

tests:MoveTowards(15, 1001, e.PLR, { t = 3.01, type = e.Easing.EASE_IN, rate = 2.01, dist = 500, dynamic = true })
:MoveBy(45, 1002, u.vector2(200, -150), { t = 2.51, type = e.Easing.EASE_OUT, rate = 1.81 })
:GotoGroup(75, 1003, 1004, { t = 4.05, type = e.Easing.EASE_IN_OUT, rate = 2.54, dist = 999, dynamic = true })
:Rotate(105, { target = 1005, center = 1006 }, { angle = 90, t = 1.51, type = e.Easing.ELASTIC_IN, rate = 1.23 })
:PointToGroup(135, 1006, 1007, { t = 2.03, type = e.Easing.ELASTIC_OUT, rate = 1.51, dynamic = true })
:Toggle(165, 1008, true)
:Scale(195, 1010, 0.51, 3.01)
:Spawn(225, 1011, true, "1001.2001.1002.2002", 0.11)
:Pulse(255, 1012, { h = 54, s = 124, b = 156, exclusive = true }, { t = 1.2, fadeIn = 0.51, fadeOut = 0.53 })




l.SaveAll()