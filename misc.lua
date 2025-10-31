-- Miscellaneous functions for Touhou SCS
-- Things that need to be automated but dont fit into the regular component usage loop
local lib = require("lib")
local util = require("utils")
local enum = require("enums")
local comp = require("component")

local ppt = enum.Properties

local m = {}
--#region DisableAllBullets function
local addedDisableAllBullets = false
function m.addDisableAllBullets()
    if addedDisableAllBullets then
        warn('WARNING! Misc: addDisableAllBullets called twice!')
        return
    end

    local disableAllBullets = comp.Component.new("DisableAllBullets", util.group(32), 6)
    disableAllBullets:assertSpawnOrder(false)
    
    local function addDisableTriggers(min, max)
        for i = min, max do
            disableAllBullets:Toggle(0, i, true)
        end
    end
    
    local bt = lib.Bullet
    addDisableTriggers(bt.Bullet1.minGroup, bt.Bullet1.maxGroup)
    addDisableTriggers(bt.Bullet2.minGroup, bt.Bullet2.maxGroup)
    addDisableTriggers(bt.Bullet3.minGroup, bt.Bullet3.maxGroup)
    addDisableTriggers(bt.Bullet4.minGroup, bt.Bullet4.maxGroup)

    addedDisableAllBullets = true
end

--#endregion

-- --#region Player Collision triggers
local addedPlayerCollision = false

function m.addPlayerCollision()
    if addedPlayerCollision then
        warn('WARNING! Misc: addPlayerCollision called twice!')
        return
    end

    local mainDespawn = comp.Component.new("DespawnFunction", util.unknown_g(), 6)
    mainDespawn:assertSpawnOrder(true)

    local collisionFunction = comp.Component.new("PlayerCollisionFunction", util.group(37), 4)
    collisionFunction:assertSpawnOrder(false)
    local function addCollisionTriggers(min, max)
        for i = min, max do
            -- activate despawn function
            table.insert(collisionFunction.triggers, {
                [ppt.OBJ_ID] = enum.ObjectID.Spawn,
                [ppt.TARGET] = mainDespawn.callerGroup,
                [ppt.REMAP_STRING] = enum.EMPTY1 .. '.' .. i,
                [ppt.SPAWN_ORDERED] = true,
                [ppt.GROUPS] = i + max - min + 1,

                [ppt.X] = 0, [ppt.Y] = 0, [ppt.EDITOR_LAYER] = 7,
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

                [ppt.X] = 0, [ppt.Y] = 0, [ppt.EDITOR_LAYER] = 7,
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

                [ppt.X] = 0, [ppt.Y] = 0, [ppt.EDITOR_LAYER] = 7,
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
                [ppt.X] = 0, [ppt.Y] = 0, [ppt.EDITOR_LAYER] = 7,
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
                [ppt.X] = 0, [ppt.Y] = 0, [ppt.EDITOR_LAYER] = 7,
                [ppt.SPAWN_TRIGGERED] = true, [ppt.MULTI_TRIGGERED] = true,
            })
        end
    end

    local bt = lib.Bullet
    addCollisionTriggers(bt.Bullet1.minGroup, bt.Bullet1.maxGroup)
    addCollisionTriggers(bt.Bullet2.minGroup, bt.Bullet2.maxGroup)
    addCollisionTriggers(bt.Bullet3.minGroup, bt.Bullet3.maxGroup)
    addCollisionTriggers(bt.Bullet4.minGroup, bt.Bullet4.maxGroup)

    mainDespawn:Scale(0, enum.EMPTY1, 0.5, { t = 0.3 })
        :Toggle(0.3, enum.EMPTY1, false)
        :Scale(0.3, enum.EMPTY1, 2, { t = 0 })
        :Alpha(0, enum.EMPTY1, { t = 0.3, opacity = 0 })

    addedPlayerCollision = true
end

--#endregion
return m
