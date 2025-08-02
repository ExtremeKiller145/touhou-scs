local lib = require("lib")
local enum = require("enums")
local util = require("utils")

local sb = {}

---@class SpawnSettings
---@field callerGroup number The caller group for the spawn trigger
---@field remapString string The validated remap string for group remapping
---@field spawnOrdered boolean Whether bullets are spawned in order with delay


-- GuiderCircle definitions for radial patterns
local GuiderCircles = {
    circle1 = {
        center = 2221,
        all = 2222,
        pointer = 2101, -- First group in circle, reference for aiming
        groups = {} -- Will be populated with 120 groups starting from pointer
    }
    -- Additional circles can be added here for simultaneous patterns
}

for i = 1, 120 do
    GuiderCircles.circle1.groups[i] = GuiderCircles.circle1.pointer + (i - 1)
end

-- Base radial component (to be created once and reused)
-- This will contain 120 spawn triggers, remapping empty1 => 501-621, empty2 => 1001-1121
local baseRadialComponent = lib.Component.new("BaseRadialComponent", util.unknown_g(), 4)
for i = 1, 120 do
    local remap_string = enum.EMPTY1 .. '.' .. (i+500) .. '.' .. enum.EMPTY2 .. '.' .. (i + 1000)
    baseRadialComponent:Spawn(0, enum.EMPTY5, true, remap_string)
end

---@param options table, requires 'spacing' angle in degrees
---@return SpawnSettings
function sb.Radial(component, guiderCircle, nextBullet, options)
    util.validateArgs("Radial", component, guiderCircle, nextBullet, options.spacing)

    -- Validate component has EMPTY1 and EMPTY2 as targets but not EMPTY5
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
    end
    if not hasEmpty2 then
        error("Radial: component must have at least one trigger targeting EMPTY2 (" .. enum.EMPTY2 .. ")")
    end
    if hasEmpty5 then
        error("Radial: component must not have any triggers targeting EMPTY5 (" .. enum.EMPTY5 .. ") - reserved for radial system")
    end

    if options.spacing % 3 ~= 0 then error("Radial: spacing must be a multiple of 3") end

    local remap_string = ""
    for i = 1, 120, (options.spacing/3) do
        remap_string = remap_string .. (i+500) .. '.' .. nextBullet() .. '.' 
            .. (i + 1000) .. '.' .. guiderCircle.groups[i] .. '.'
    end
    remap_string = remap_string:sub(1, -2) -- remove trailing dot, UNTESTED!
    local spawnSettings = {}
    spawnSettings.callerGroup = baseRadialComponent.callerGroup
    spawnSettings.remapString = util.validateRemapString("Radial", remap_string)
    spawnSettings.spawnOrdered = false -- bullets are all shot at once without delay or order
    return spawnSettings
end

return sb