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
        error("Radial: component must not require spawn order; seperate by x for order, but no time gaps. \nRecommended to use assertSpawnOrder(false) in component and keep in mind guiderCircle is only there for the first 1-2 ticks of activation.")
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
    if options.spacing < 1 or options.spacing > 360 then 
        error("Radial: spacing must be between 1 and 360")
    end
    if 360 % options.spacing ~= 0 then 
        error("Radial: spacing must be a factor of 360 for perfect circles")
    end
    --#endregion

    local remap_string = ""
    for i = 1, 360 do
        if (i - 1) % options.spacing == 0 then
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
    spawnSettings.spawnOrdered = false -- bullets are shot at once, 0 delay or order
    return spawnSettings
end



--- Creates an arc pattern spawn setting, to shoot bullets in a partial circular pattern
---@param component Component ; must have EMPTY1 and EMPTY2 as targets but not EMPTY5. requires assertSpawnOrder(false)
---@param guiderCircle GuiderCircle ; circle to aim at and spawn from
---@param options table, requires 'numOfBullets', 'spacing' angle, optional 'centerAt' angle (clockwise from guidercircle pointer), defaults to 0
---@return SpawnSettings ; includes 'callerGroup', 'remapString', 'spawnOrdered'
function sb.Arc(component, guiderCircle, nextBullet, options)
    util.validateArgs("Arc", component, guiderCircle, nextBullet, options.spacing, options.numOfBullets)
    options.centerAt = options.centerAt or 0 -- 0 represents pointer

    --#region Component Validation (same as Radial)
    if component.requireSpawnOrder ~= false then
        error("Arc: component must not require spawn order; seperate by x for order, but no time gaps. \nRecommended to use assertSpawnOrder(false) in component and keep in mind guiderCircle is only there for the first 1-2 ticks of activation.")
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
        error("Arc: component must have at least one trigger targeting EMPTY1 (" .. enum.EMPTY1 .. ")")
    elseif not hasEmpty2 then
        error("Arc: component must have at least one trigger targeting EMPTY2 (" .. enum.EMPTY2 .. ")")
    elseif hasEmpty5 then
        error("Arc: component must not have any triggers targeting EMPTY5 (" ..
        enum.EMPTY5 .. ") - reserved for arc system")
    end
    --#endregion

    
    local totalArcSpan = (options.numOfBullets - 1) * options.spacing
    --#region Arc-specific Validation
    if not util.isInteger(options.centerAt) or not util.isInteger(options.centerAt*2) then
        error("Arc: centerAt must be an integer or integer.5")
    end
    if not util.isInteger(options.centerAt - totalArcSpan/2) then
        error()
    end
    if options.spacing < 1 or options.spacing > 360 then 
        error("Arc: spacing must be between 1 and 360")
    end
    if options.numOfBullets <= 1 or options.numOfBullets > 360 then
        error("Arc: number of bullets must be between 1 and 360, excluding 1")
    end
    if options.numOfBullets * options.spacing > 360 then
        error("Arc: Number of bullets " .. options.numOfBullets .. " times spacing " .. options.spacing .. " exceeds 360 degrees")
    end
    if options.numOfBullets * options.spacing == 360 then
        error("Arc: Number of bullets " .. options.numOfBullets .. " times spacing " .. options.spacing .. " is 360 degrees, making a circle.\n FIX: Use Radial instead.")
    end
    --#endregion

    local remap_string = ""

    -- Calculate arc positioning
    local totalArcSpan = (options.numOfBullets - 1) * options.spacing
    local centerOffset = totalArcSpan / 2
    local startAngle = (options.centerAt - centerOffset + 360) % 360

    -- Calculate where the arc is actually centered for user feedback
    local actualCenter = (options.centerAt + centerOffset) % 360
    local centeredAtGroup = guiderCircle.pointer + options.centerAt

    for i = 1, 360 do 
        local currentAngle = (i - 1) % 360
        local relativeAngle = (currentAngle - startAngle + 360) % 360
        
        -- Check if within arc and on spacing boundary
        local isInArc = relativeAngle <= totalArcSpan
        local isOnSpacing = relativeAngle % options.spacing == 0
        
        if isInArc and isOnSpacing then
            -- Apply centerAt offset to guider circle mapping
            local guiderIndex = ((currentAngle + options.centerAt) % 360) + 1
            remap_string = remap_string .. (i + 500) .. '.' .. nextBullet() .. '.'
                .. (i + 1000) .. '.' .. guiderCircle.groups[guiderIndex] .. '.'
        else
            remap_string = remap_string .. (i + 500) .. '.' .. enum.EMPTY4 .. '.'
                .. (i + 1000) .. '.' .. enum.EMPTY4 .. '.'
        end
    end

    -- Final mapping: EMPTY5 -> baseRadialComponent caller group
    remap_string = remap_string .. enum.EMPTY5 .. '.' .. component.callerGroup

    local spawnSettings = {}
    spawnSettings.centeredAt = centeredAtGroup -- if e.g 2.5, between groups 2 & 3
    spawnSettings.callerGroup = baseRadialComponent.callerGroup
    spawnSettings.remapString = util.validateRemapString("Arc", remap_string)
    spawnSettings.spawnOrdered = false -- bullets are all shot at once without delay or order
    return spawnSettings
end

return sb
