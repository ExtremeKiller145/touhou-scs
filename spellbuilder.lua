local lib = require("lib")
local enum = require("enums")
local util = require("utils")

local sb = {}

---@class SpawnSettings
---@field callerGroup string|number The caller group for the spawn trigger
---@field remapString string The validated remap string for group remapping
---@field spawnOrdered boolean Whether bullets are spawned in order with delay
---@class GuiderCircle
---@field all number Contains entire circle, Center is group parent
---@field center number The center group of the circle, used for positioning
---@field pointer number The first group in the circle, reference for aiming
---@field groups table<number, number> The groups that contain each bullet in the circle

-- GuiderCircle definitions for radial patterns
sb.GuiderCircle = {
    ---@type GuiderCircle
    circle1 = {
        all = 5061,
        center = 5061, -- parent
        pointer = 4701, -- First group in circle, reference for aiming
        groups = {}     -- Will be populated with 360 groups starting from pointer
    }
    -- Additional circles can be added here for simultaneous patterns
}

---@param circle GuiderCircle
local function populateGuiderCircle(circle)
    for i = 1, 360 do
        circle.groups[i] = circle.pointer + (i - 1)
    end
end
populateGuiderCircle(sb.GuiderCircle.circle1)

-- Base radial component (to be created once and reused)
-- This will contain 360 spawn triggers, remapping empty1 => 501- UNASSIGNED , empty2 => 1001-UNASSIGNED
local baseRadialComponent = lib.Component.new("BaseRadialComponent", util.unknown_g(), 4)
baseRadialComponent:assertSpawnOrder(false)
for i = 1, 360 do
    local remap_string = enum.EMPTY1 .. '.' .. (i + 500) .. '.'
                      .. enum.EMPTY2 .. '.' .. (i + 1000)
    baseRadialComponent:Spawn(0, enum.EMPTY5, true, remap_string)
end

--- Creates a radial pattern spawn setting, to shoot all at once in a circular pattern
---@param component Component ; requires assertSpawnOrder(false), represents cycle of a single bullet
--- EMPTY1 must represent 'bullet'
--- 
--- EMPTY2 must represent 'targetGroup'
---@param guiderCircle GuiderCircle ; circle to aim at and spawn from
---@param spacing number, angle distance between bullets in degrees, must be a factor of 360
---@param bulletType Bullet ; the bullet type to use for spawning
---@return SpawnSettings ; includes 'callerGroup', 'remapString', 'spawnOrdered'
function sb.Radial(component, guiderCircle, bulletType, spacing)
    util.validateArgs("Radial", component, guiderCircle, bulletType, spacing)
    util.validateRadialComponent(component, "Radial")

    --#region Spacing Validation
    if spacing < 1 or spacing > 360 or not util.isInteger(spacing) then
        error("Radial: spacing must be an integer between 1 and 360")
    end
    if 360 % spacing ~= 0 then
        error("Radial: spacing must be a factor of 360 for perfect circles")
    end
    --#endregion

    local empties = util.createNumberCycler(6000,7000)
    local remap_string = ""
    for i = 1, 360 do
        if (i - 1) % spacing == 0 then
            -- Active bullet: map to real targets
            remap_string = remap_string .. (i + 500) .. '.' .. bulletType.nextBullet() .. '.'
                .. (i + 1000) .. '.' .. guiderCircle.groups[i] .. '.'
        else
            -- Inactive bullet: map to safe empty groups
            remap_string = remap_string .. (i + 500) .. '.' .. empties() .. '.'
                .. (i + 1000) .. '.' .. empties() .. '.'
        end
    end

    -- Final mapping: EMPTY5 -> baseRadialComponent caller group
    remap_string = remap_string .. enum.EMPTY5 .. '.' .. component.callerGroup

    ---@type SpawnSettings
    local spawnSettings = {
        callerGroup = baseRadialComponent.callerGroup,
        remapString = util.validateRemapString("Radial", remap_string),
        spawnOrdered = false -- bullets are shot at once, 0 delay or order
    }
    return spawnSettings
end


--- Creates an arc pattern spawn setting, to shoot bullets in a partial circular pattern
---@param component Component ; requires assertSpawnOrder(false), represents cycle of a single bullet
--- EMPTY1 must represent 'bullet'
--- 
--- EMPTY2 must represent 'targetGroup'
---@param guiderCircle GuiderCircle ; circle to aim at and spawn from
---@param bulletType Bullet ; the bullet type to use for spawning
---@param args table, requires 'numOfBullets', 'spacing' angle, optional 'centerAt' angle (clockwise from guidercircle pointer), defaults to 0
---@return SpawnSettings ; includes 'callerGroup', 'remapString', 'spawnOrdered'
function sb.Arc(component, guiderCircle, bulletType, args)
    util.validateArgs("Arc", component, guiderCircle, bulletType, args.spacing, args.numOfBullets)
    util.validateRadialComponent(component, "Arc")

    args.centerAt = args.centerAt or 0 -- 0 represents pointer

    --#region Arc-specific Validation
    -- arc logic checks
    local centerAtisInt = util.isInteger(args.centerAt)
    -- case 1: numOfBullets is odd, centerAt must be integer
    if args.numOfBullets % 2 ~= 0 and not centerAtisInt then
        error("Arc: odd bullets requires integer centerAt")
    end
    -- case 2
    if args.numOfBullets % 2 == 0 and args.spacing % 2 ~= 0 and centerAtisInt then
        error("Arc: even bullets with odd spacing requires .5 centerAt")
    end
    -- case 3
    if args.numOfBullets % 2 == 0 and args.spacing % 2 == 0 and not centerAtisInt then
        error("Arc: even bullets with even spacing requires integer centerAt")
    end

    -- Data restriction checks
    if not centerAtisInt and not util.isInteger(args.centerAt*2) then
        error("Arc: centerAt must be an integer or integer.5")
    end
    if not util.isInteger(args.spacing) then
        error("Arc: spacing must be an integer")
    end
    if args.spacing < 1 or args.spacing > 360 then 
        error("Arc: spacing must be between 1 and 360")
    end
    if not util.isInteger(args.numOfBullets) then
        error("Arc: numOfBullets must be an integer")
    end
    if args.numOfBullets < 1 or args.numOfBullets > 360 then
        error("Arc: numOfBullets must be between 1 and 360")
    end
    if args.numOfBullets * args.spacing > 360 then
        error("Arc: numOfBullets " .. args.numOfBullets .. " times spacing " .. args.spacing .. " exceeds 360 degrees")
    end
    if args.numOfBullets * args.spacing == 360 then
        error("Arc: numOfBullets " .. args.numOfBullets .. " times spacing " .. args.spacing .. " is 360 degrees, making a circle.\n FIX: Use Radial instead.")
    end
    --#endregion

    local remap_string = ""
    local arclength = (args.numOfBullets - 1) * args.spacing
    local startpos = args.centerAt - (arclength/2)
    if not util.isInteger(startpos) then
        error("Arc: Startpos validation is faulty! review conditions.")
    end
    local guiderCycler = util.createNumberCycler(1, 360)
    if startpos < 0 then startpos = 360 + startpos end
    for _ = 1, startpos do guiderCycler() end -- offset num cycler

    for i = 1, 360 do
        local index = guiderCycler() -- advance even if unused
        if (i - 1) % args.spacing == 0 and (i - 1) < args.numOfBullets * args.spacing then
            -- Active bullet: map to real targets
            remap_string = remap_string .. (i + 500) .. '.' .. bulletType.nextBullet() .. '.'
                .. (i + 1000) .. '.' .. guiderCircle.groups[index] .. '.'
        else
            -- Inactive bullet: map to safe empty groups
            remap_string = remap_string .. (i + 500) .. '.' .. enum.EMPTY4 .. '.'
                .. (i + 1000) .. '.' .. enum.EMPTY4 .. '.'
        end
    end

    -- Final mapping: EMPTY5 -> baseRadialComponent caller group
    remap_string = remap_string .. enum.EMPTY5 .. '.' .. component.callerGroup

    local spawnSettings = {}
    if util.isInteger(args.centerAt) then
        spawnSettings.centeredAt = guiderCircle.pointer + startpos
    end
    spawnSettings.callerGroup = baseRadialComponent.callerGroup
    spawnSettings.remapString = util.validateRemapString("Arc", remap_string)
    spawnSettings.spawnOrdered = false -- bullets are all shot at once without delay or order
    return spawnSettings
end

local radialWaveCount = 0
---@param component Component ; requires assertSpawnOrder(false), represents cycle of a single bullet
--- EMPTY1 must represent 'bullet'
--- 
--- EMPTY2 must represent 'targetGroup'
---@param guiderCircle GuiderCircle ; circle to aim at and spawn from
---@param args table, requires 'spacing' angle, 'bulletsPerWave', 'waves', 'interval'
---@param bulletType Bullet ; the bullet type to use for spawning
---@return Component ; calls the pattern
function sb.RadialWave(component, guiderCircle, bulletType, args)
    util.validateArgs("RadialWave", component, guiderCircle, bulletType, args.spacing, args.bulletsPerWave, args.waves, args.interval)
    util.validateRadialComponent(component, "RadialWave")
    radialWaveCount = radialWaveCount + 1
    local waveComponent = lib.Component.new("WaveComponent" .. radialWaveCount, util.unknown_g(), 4)

    for i = 1, args.waves do
        local spawnSettings = sb.Radial(component, guiderCircle, bulletType, args.spacing)
        waveComponent:Spawn(i * args.interval, spawnSettings.callerGroup, false, spawnSettings.remapString)
    end
    waveComponent:assertSpawnOrder(true)
    return waveComponent
end

return sb