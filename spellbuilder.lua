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

--- Creates a radial pattern spawn setting, to shoot all at once in a circular pattern
---@param component Component ; requires assertSpawnOrder(false), represents cycle of a single bullet
--- EMPTY_BULLET must represent 'bullet'
--- 
--- EMPTY_TARGET_GROUP must represent 'targetGroup'
---@param guiderCircle GuiderCircle ; circle to aim at and spawn from
---@param callerComponent Component ; the component that will call the radial pattern
---@param bulletType Bullet ; the bullet type to use for spawning
---@param args table, requires either 'spacing' OR 'numOfBullets', optional 'centerAt' angle (clockwise from guidercircle pointer), defaults to 0
function sb.Radial(time, callerComponent, component, guiderCircle, bulletType, args)
    util.validateArgs("Radial", component, guiderCircle, bulletType, args)
    util.validateRadialComponent(component, "Radial")

    args.centerAt = args.centerAt or 0 -- 0 represents pointer

    --#region Parameter and Argument Validation
    if args.spacing and args.numOfBullets then
        -- Both provided: validate they match
        if args.numOfBullets ~= 360 / args.spacing then
            error("Radial: spacing and numOfBullets don't match (numOfBullets should be " .. (360 / args.spacing) .. ") or just use one or the other")
        end
    elseif args.spacing then
        args.numOfBullets = 360 / args.spacing
    elseif args.numOfBullets then
        args.spacing = 360 / args.numOfBullets
    else
        error("Radial: must provide either 'spacing' or 'numOfBullets'")
    end

    if not util.isInteger(args.spacing) then
        error("Radial: spacing is not an integer (numOfBullets " .. args.numOfBullets .. " doesn't divide 360 evenly)")
    elseif not util.isInteger(args.numOfBullets) then
        error("Radial: numOfBullets is not an integer (spacing " .. args.spacing .. " doesn't divide 360 evenly)")
    elseif args.spacing < 1 or args.spacing > 360 then
        error("Radial: spacing must be an integer between 1 and 360")
    elseif 360 % args.spacing ~= 0 then
        error("Radial: spacing must be a factor of 360 for perfect circles")
    elseif 360 % args.numOfBullets ~= 0 then
        error("Radial: numOfBullets must divide 360 evenly (got " .. args.numOfBullets .. ")")
    end
    --#endregion

    -- Use Arc implementation with radial bypass
    args.radialBypass = true
    return sb.Arc(time, callerComponent, component, guiderCircle, bulletType, args)
end


--- Creates an arc pattern spawn setting, to shoot bullets in a partial circular pattern
---@param component Component ; requires assertSpawnOrder(false), represents cycle of a single bullet
--- EMPTY_BULLET must represent 'bullet'
--- 
--- EMPTY_TARGET_GROUP must represent 'targetGroup'
---@param guiderCircle GuiderCircle ; circle to aim at and spawn from
---@param callerComponent Component ; the component that will call the arc pattern
---@param bulletType Bullet ; the bullet type to use for spawning
---@param args table, requires 'numOfBullets', 'spacing' angle, optional 'centerAt' angle (clockwise from guidercircle pointer), defaults to 0
function sb.Arc(time, callerComponent, component, guiderCircle, bulletType, args)
    util.validateArgs("Arc", component, guiderCircle, bulletType, args.spacing, args.numOfBullets)
    util.validateRadialComponent(component, "Arc")

    args.centerAt = args.centerAt or 0 -- 0 represents pointer

    --#region Arc-specific Validation
    -- arc logic checks
    local centerAtisInt = util.isInteger(args.centerAt)
    if not args.radialBypass then
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
    if args.numOfBullets * args.spacing == 360 and not args.radialBypass then
        error("Arc: numOfBullets " .. args.numOfBullets .. " times spacing " .. args.spacing .. " is 360 degrees, making a circle.\n FIX: Use Radial instead.")
    end
    --#endregion

    -- Calculate arc positioning
    local arclength = (args.numOfBullets - 1) * args.spacing
    local startpos

    if args.radialBypass then
        -- For radials: start directly at centerAt and place bullets sequentially
        startpos = args.centerAt
    else
        -- For arcs: center the arc around centerAt
        startpos = args.centerAt - (arclength/2)
        if not util.isInteger(startpos) then
            error("Arc: Startpos validation is faulty! review conditions.")
        end
    end

    -- Normalize startpos to 0-359 range
    startpos = startpos % 360
    if startpos < 0 then startpos = 360 + startpos end

    -- Get binary components for the number of bullets we need
    ---@type Component
    local comps = lib.MultitargetRegistry:getBinaryComponents(args.numOfBullets)

    local remapStringProperty = enum.Properties.REMAP_STRING
    local bulletPosition = startpos
    for _, comp in ipairs(comps) do
        local empties = util.createNumberCycler(6001, 6064)
        local remap_string = ""
        for _, spawnTrigger in ipairs(comp.triggers) do
            local remapPairs = util.translateRemapString(spawnTrigger[remapStringProperty])
            for source, target in pairs(remapPairs) do
                remap_string = remap_string .. target .. '.'

                local sourceNum = tonumber(source) -- Convert string to number
                if sourceNum == enum.EMPTY_BULLET then
                    remap_string = remap_string .. bulletType.nextBullet()
                elseif sourceNum == enum.EMPTY_TARGET_GROUP then
                    remap_string = remap_string .. guiderCircle.groups[bulletPosition + 1]
                else
                    remap_string = remap_string .. empties()
                end

                remap_string = remap_string .. '.'
            end
            bulletPosition = bulletPosition + args.spacing
            if bulletPosition >= 360 then bulletPosition = bulletPosition - 360 end
        end
        -- Final mapping: EMPTY_MULTITARGET -> component caller group
        remap_string = remap_string .. enum.EMPTY_MULTITARGET .. '.' .. component.callerGroup
        callerComponent:Spawn(time, comp.callerGroup, false, remap_string)
    end
end

local radialWaveCount = 0
---@param callerComponent Component ; the component that will call the wave pattern
---@param component Component ; requires assertSpawnOrder(false), represents cycle of a single bullet
--- EMPTY_BULLET must represent 'bullet'
--- 
--- EMPTY_TARGET_GROUP must represent 'targetGroup'
---@param guiderCircle GuiderCircle ; circle to aim at and spawn from
---@param bulletType Bullet ; the bullet type to use for spawning
---@param args table, requires either 'spacing' OR 'numOfBullets', 'waves', 'interval', optional 'centerAt'
function sb.RadialWave(time, callerComponent, component, guiderCircle, bulletType, args)
    util.validateArgs("RadialWave", component, guiderCircle, bulletType, args)
    util.validateRadialComponent(component, "RadialWave")

    -- Validate wave-specific parameters
    if not args.waves or not util.isInteger(args.waves) or args.waves < 1 then
        error("RadialWave: waves must be a positive integer")
    end
    if not args.interval or args.interval <= 0 then
        error("RadialWave: interval must be a positive number")
    end

    radialWaveCount = radialWaveCount + 1

    for i = 1, args.waves do
        sb.Radial(time + (i - 1) * args.interval, callerComponent, component, guiderCircle, bulletType, args)
    end
end

return sb