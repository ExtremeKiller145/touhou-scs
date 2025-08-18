local lib = require("lib")
local util = require("utils")
local enum = require("enums")

local ppt = enum.Properties

--#region DisableAllBullets function
local disableAllBullets = lib.Component.new("DisableAllBullets", util.group(32), 4)
disableAllBullets:assertSpawnOrder(false)
for i = 501, 1000 do
    disableAllBullets:Toggle(0, i, false)
end
for i = 1501, 2200 do
    disableAllBullets:Toggle(0, i, false)
end
for i = 2901, 3600 do
    disableAllBullets:Toggle(0, i, false)
end
for i = 4301, 4700 do
    disableAllBullets:Toggle(0, i, false)
end
--#endregion

-- --#region Player Collision triggers
-- local playerCollisionFunction = lib.Component.new("PlayerCollisionFunction", util.group(37),4)
-- playerCollisionFunction:assertSpawnOrder(false)
-- local function addCollisionTriggers(min, max)
--     for i = min, max + 1 do
--         -- despawn for boundary collision
--         table.insert(playerCollisionFunction.triggers, {
--             [ppt.OBJ_ID] = enum.ObjectID.Collision,
--             [51] = i + max - min + 1, -- target
--             [80] = i, -- block A
--             [95] = 1, -- block B (border)
--             [56] = true, -- activate group
--             [ppt.GROUPS] = 19,
--             [ppt.X] = 0, [ppt.Y] = 0,
--             [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
--         })
--         -- despawn for playerhit
--         table.insert(playerCollisionFunction.triggers, {
--             [ppt.OBJ_ID] = enum.ObjectID.Collision,
--             [51] = i + max - min + 1, -- target
--             [80] = i, -- block A
--             [95] = enum.PLR, -- block B
--             [56] = true, -- activate group
--             [ppt.GROUPS] = 18,
--             [ppt.X] = 0, [ppt.Y] = 0,
--             [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
--         })
--         table.insert(playerCollisionFunction.triggers, {
--             [ppt.OBJ_ID] = enum.ObjectID.Collision,
--             [51] = 35, -- target player hit function
--             [80] = i, -- block A
--             [95] = enum.PLR, -- block B
--             [56] = true, -- activate group
--             [ppt.GROUPS] = 18,
--             [ppt.X] = 0, [ppt.Y] = 0,
--             [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
--         })
--         -- no despawn, simple graze func activation
--         table.insert(playerCollisionFunction.triggers, {
--             [ppt.OBJ_ID] = enum.ObjectID.Collision,
--             [51] = 34, -- targets graze function
--             [80] = i, -- block A
--             [95] = 3, -- block B (graze hitbox)
--             [56] = true, -- activate group
--             [ppt.GROUPS] = 17,
--             [ppt.X] = 0, [ppt.Y] = 0,
--             [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
--         })
--     end
-- end
-- addCollisionTriggers(501, 1000)
-- addCollisionTriggers(1501, 2200)
-- addCollisionTriggers(2901, 3600)
-- addCollisionTriggers(4301, 4700)

--#endregion