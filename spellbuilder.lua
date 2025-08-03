local lib = require("lib")
local enum = require("enums")
local util = require("utils")

local sb = {}

---@class SpawnSettings
---@field callerGroup number The caller group for the spawn trigger
---@field remapString string The validated remap string for group remapping
---@field spawnOrdered boolean Whether bullets are spawned in order with delay
---@class GuiderCircle
---@field center number The center of the circle
---@field all number The group that contains all bullets in the circle
---@field pointer number The first group in the circle, reference for aiming
---@field groups table<number, number> The groups that contain each bullet in the circle

-- GuiderCircle definitions for radial patterns
local GuiderCircles = {
    ---@type GuiderCircle
    circle1 = {
        center = 2221,
        all = 2222,
        pointer = 2101, -- First group in circle, reference for aiming
        groups = {}     -- Will be populated with 360 groups starting from pointer
    }
    -- Additional circles can be added here for simultaneous patterns
}

for i = 1, 360 do
    GuiderCircles.circle1.groups[i] = GuiderCircles.circle1.pointer + (i - 1)
end

-- Base radial component (to be created once and reused)
-- This will contain 360 spawn triggers, remapping empty1 => 501- UNASSIGNED , empty2 => 1001-UNASSIGNED
local baseRadialComponent = lib.Component.new("BaseRadialComponent", util.unknown_g(), 4)
for i = 1, 360 do
    local remap_string = enum.EMPTY1 .. '.' .. (i + 500) .. '.' .. enum.EMPTY2 .. '.' .. (i + 1000)
    baseRadialComponent:Spawn(0, enum.EMPTY5, false, remap_string):assertSpawnOrder(false)
end

--- Creates a radial pattern spawn setting, to shoot all at once in a circular pattern
---@param component Component ; must have EMPTY1 and EMPTY2 as targets but not EMPTY5. requires assertSpawnOrder(false)
---@param guiderCircle GuiderCircle ; circle to aim at and spawn from
---@param options table, requires 'spacing' angle in degrees
---@return SpawnSettings ; includes 'callerGroup', 'remapString', 'spawnOrdered'
function sb.Radial(component, guiderCircle, nextBullet, options)
    util.validateArgs("Radial", component, guiderCircle, nextBullet, options.spacing)

    --#region Component Validation
    if component.requireSpawnOrder ~= false then
        error("Radial: component must not require spawn order; seperate by x for order, but no time gaps. Recommended to and use assertSpawnOrder(false) in component and keep in mind guiderCircle is only there for the first 1-2 ticks of activation.")
    end

    local hasEmpty1, hasEmpty2, hasEmpty5 = false, false, false
    for _, trigger in pairs(component.triggers) do
        for _, field in pairs(enum.Properties.TargetFields) do
            if trigger[field] == enum.EMPTY1 then hasEmpty1 = true end
            if trigger[field] == enum.EMPTY2 then hasEmpty2 = true end
            if trigger[field] == enum.EMPTY5 then hasEmpty5 = true end
        end
    end

    if not hasEmpty1 then
        error("Radial: component must have at least one trigger targeting EMPTY1 (" .. enum.EMPTY1 .. ")")
    elseif not hasEmpty2 then
        error("Radial: component must have at least one trigger targeting EMPTY2 (" .. enum.EMPTY2 .. ")")
    elseif hasEmpty5 then
        error("Radial: component must not have any triggers targeting EMPTY5 (" ..
        enum.EMPTY5 .. ") - reserved for radial system")
    end
    --#endregion

    --#region Spacing Validation
    if options.spacing < 1 or options.spacing > 360 then error("Radial: spacing must be between 1 and 360") end
    if 360 % options.spacing ~= 0 then error("Radial: spacing must be a factorof 360") end

    local perfectCircleSpacings = { 1, 2, 3, 4, 5, 6, 8, 9, 10, 12, 15, 18, 20, 24, 30, 36, 40, 45, 60, 72, 90, 120, 180 }
    local isPerfectCircleSpacing = false
    for _, spacing in pairs(perfectCircleSpacings) do
        if spacing == options.spacing then
            isPerfectCircleSpacing = true
            break
        end
    end

    if not isPerfectCircleSpacing then
        warn("Radial: WARNING! Spacing of " .. options.spacing .. " will not create a perfect circle.")
        warn("Consider the alternatives: [ " .. table.concat(perfectCircleSpacings, ", ") .. " ]")
    end
    --#endregion

    local remap_string = ""

    for i = 1, 360 do
        if (i - 1) % (options.spacing) == 0 then
            -- Active bullet: map to real targets
            remap_string = remap_string .. (i + 500) .. '.' .. nextBullet() .. '.'
                .. (i + 1000) .. '.' .. guiderCircle.groups[i] .. '.'
        else
            -- Inactive bullet: map to safe empty groups
            remap_string = remap_string .. (i + 500) .. '.' .. enum.EMPTY4 .. '.'
                .. (i + 1000) .. '.' .. enum.EMPTY4 .. '.'
        end
    end

    -- Final mapping: EMPTY5 -> baseRadialComponent caller group
    remap_string = remap_string .. enum.EMPTY5 .. '.' .. component.callerGroup

    local spawnSettings = {}
    spawnSettings.callerGroup = baseRadialComponent.callerGroup
    spawnSettings.remapString = util.validateRemapString("Radial", remap_string)
    spawnSettings.spawnOrdered = false -- bullets are all shot at once without delay or order
    return spawnSettings
end

return sb