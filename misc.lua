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
local mainDespawn = lib.Component.new("DespawnFunction", util.unknown_g(), 4)
mainDespawn:assertSpawnOrder(true)

-- local collisionFunction = lib.Component.new("PlayerCollisionFunction", util.group(37),4)
-- collisionFunction:assertSpawnOrder(false)
local function addCollisionTriggers(min, max)
    for i = min, max do
        -- activate despawn function
        table.insert(collisionFunction.triggers, {
            [ppt.OBJ_ID] = enum.ObjectID.Spawn,
            [ppt.TARGET] = mainDespawn.callerGroup,
            [ppt.REMAP_STRING] = enum.EMPTY1 .. '.' .. i,
            [ppt.SPAWN_ORDERED] = true,
            [ppt.GROUPS] = i + max - min + 1,

            [ppt.X] = 0, [ppt.Y] = 0, [ppt.EDITOR_LAYER] = 4,
            [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
        })
        -- despawn for boundary collision
        table.insert(collisionFunction.triggers, {
            [ppt.OBJ_ID] = enum.ObjectID.Collision,
            [ppt.TARGET] = i + max - min + 1,
            [ppt.BLOCK_A] = i,
            [ppt.BLOCK_B] = 1, -- boundary hitbox
            [ppt.ACTIVATE_GROUP] = true,
            [ppt.GROUPS] = 19,

            [ppt.X] = 0, [ppt.Y] = 0, [ppt.EDITOR_LAYER] = 4,
            [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
        })
        -- despawn for playerhit
        table.insert(collisionFunction.triggers, {
            [ppt.OBJ_ID] = enum.ObjectID.Collision,
            [ppt.TARGET] = i + max - min + 1,
            [ppt.BLOCK_A] = i,
            [ppt.BLOCK_B] = enum.PLR,
            [ppt.ACTIVATE_GROUP] = true,
            [ppt.GROUPS] = 18,

            [ppt.X] = 0, [ppt.Y] = 0, [ppt.EDITOR_LAYER] = 4,
            [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
        })
        -- player hit register, no despawn
        table.insert(collisionFunction.triggers, {
            [ppt.OBJ_ID] = enum.ObjectID.Collision,
            [ppt.TARGET] = 35, -- player hit function
            [ppt.BLOCK_A] = i,
            [ppt.BLOCK_B] = enum.PLR,
            [ppt.ACTIVATE_GROUP] = true,
            [ppt.GROUPS] = 18,
            [ppt.X] = 0, [ppt.Y] = 0, [ppt.EDITOR_LAYER] = 4,
            [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
        })
        -- no despawn, simple graze func activation
        table.insert(collisionFunction.triggers, {
            [ppt.OBJ_ID] = enum.ObjectID.Collision,
            [ppt.TARGET] = 34, -- targets graze function
            [ppt.BLOCK_A] = i,
            [ppt.BLOCK_B] = 3, -- graze hitbox
            [ppt.ACTIVATE_GROUP] = true,
            [ppt.GROUPS] = 17,
            [ppt.X] = 0, [ppt.Y] = 0, [ppt.EDITOR_LAYER] = 4,
            [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
        })
    end
end
-- addCollisionTriggers(501, 1000)
-- addCollisionTriggers(1501, 2200)
-- addCollisionTriggers(2901, 3600)
-- addCollisionTriggers(4301, 4700)

mainDespawn:Scale(0, enum.EMPTY1, 0.5, { t = 0.5 })
    :Toggle(0.5, enum.EMPTY1, false)
    :Scale(0.5, enum.EMPTY1, 2, { t = 0 })

--#endregion