-- Utility functions for Lua scripts

local util = {}

--- To nil-check function arguments
---@param methodName string The name of the method for error messages.
---@param ... any The arguments to check.
function util.validateArgs(methodName, ...)
    local args = {...}
    for name, value in ipairs(args) do
        if value == nil then
            error(string.format("%s: missing required argument '%s'", methodName, name))
        end
    end
end

--- Creates a number cycler that returns sequential numbers in a range.
---@param min number The minimum value (inclusive)
---@param max number The maximum value (inclusive)
---@return function A function that returns the next number in sequence, cycling back to min after max
function util.createNumberCycler(min, max)
    if not util.isInteger(min) or not util.isInteger(max) then
        error("createNumberCycler: min and max must be integers")
    end

    if min > max then
        error("createNumberCycler: min cannot be greater than max")
    end

    local current = min - 1
    return function()
        current = current + 1
        if current > max then
            current = min
        end
        return current
    end
end

--- Includes type checking w/ 'math.floor' function
function util.isInteger(num) return math.floor(num) == num end

--- Semantic wrapper for group tables or individual values for 'self-documenting code'
function util.group(val) return val end

-- Unknown group management
local unknownGroupCycler = util.createNumberCycler(1, 9998) -- Max 9999 unknown groups

--- Creates a unique unknown group string for automatic remapping
--- @return string Unique unknown group identifier
function util.unknown_g()
    local id = unknownGroupCycler()
    if id > 2000 then print("\nWARNING: High unknown group usage (" .. id .. "/9998)\n") end
    return "unknown_g" .. id
end

function util.validateGroups(methodName, ...)
    local args = {...}
    for _, arg in pairs(args) do
        if type(arg) == "number" and arg >= 0 and arg <= 9999 then goto continue
        elseif type(arg) == "string" and arg:match("^unknown_g%d+$") then
            error(methodName .. ": Unknown groups are only allowed in Spawn triggers")
        else
            error(methodName .. ": Invalid group type: " .. type(arg))
        end
        ::continue::
    end
end

--- Converts time in seconds to distance in studs
function util.timeToDist(time) return 311.58 * time end

--- Convert block studs & projectile speed to projectile spacing.
---@param speedOfProjectile number in studs/second
---@param studsOfSpacing number in studs/second
function util.spacingBullet(speedOfProjectile, studsOfSpacing)
    return studsOfSpacing / speedOfProjectile * 311.58
end

--- Creates a vector2 table for MoveBy w/ simple type checking
---@param x number X value of vector2
---@param y number Y value of vector2
---@return table Vector2
function util.vector2(x, y)
    if not (type(x) == "number" and type(y) == "number") then
        error("Invalid args for 'vector2': x and y must be numbers")
    end
    return { X = x, Y = y }
end

--- Validates vector2 table structure
---@param vector2 table The vector2 table to validate
---@param methodName string Function name for error messages
function util.validateVector2(methodName, vector2)
    if type(vector2) ~= "table" then
        error(methodName .. ": vector2 must be a table")
    end

    if vector2["X"] == nil or vector2["Y"] == nil then
        error(methodName .. ": vector2 missing required field 'X' or 'Y'")
    end
end

--- Validates easing table structure
---@param easing table The easing table to validate
---@param methodName string Function name for error messages
function util.validateEasing(methodName, easing)
    if type(easing) ~= "table" then
        error(methodName .. ": easing must be a table")
    end

    -- Required fields
    -- only easing types 1-6 use ease rate field
    if easing.type > 6 or easing.type < 1 then easing.rate = 1 end

    local required = {"t", "type", "rate"}
    for _, field in pairs(required) do
        if easing[field] == nil then
            error(methodName .. ": easing missing required field '" .. field .. "'")
        end
    end

    if not util.isInteger(easing.type) then
        error(methodName .. ": easing 'type' must be an integer")
    end
    if easing.type < 0 or easing.type > 18 then
        error(methodName .. ": easing 'type' must be between 0 and 18")
    end

    -- Must have either 'dist' or 'angle' or 'MoveBy'
    local hasDist = easing.dist ~= nil
    local hasAngle = easing.angle ~= nil
    local hasMoveBy = easing.MoveBy ~= nil

    if not hasDist and not hasAngle and not hasMoveBy then
        error(methodName .. ": easing must have either 'dist' or 'angle' field")
    end
end

--- Validates pulse param table structures
---@param hsb table The pulse table to validate
---@param fading table The fading table to validate
function util.validatePulse(hsb, fading)
    if type(hsb) ~= "table" then
        error("Pulse: 'hsb' must be a table")
    end

    if type(fading) ~= "table" then
        error("Pulse: 'fading' must be a table")
    end

    if not hsb["h"] or not hsb["s"] or not hsb["b"] or not hsb["exclusive"] then
        error("Pulse: 'hsb' missing required field 'h', 's', 'b', or 'exclusive'")
    end

    if not fading["t"] or not fading['fadeIn'] then
        error("Pulse: 'fading' missing required field 't' or 'fadeIn'")
    end

    fading['fadeOut'] = fading['fadeOut'] or 0
end

--- Cleans up remap strings by removing redundant mappings (e.g., "10.10")
--- @param methodName string, Name of the method for error messages.
--- @param remapString string, Dot-separated remap string
--- @return string Cleaned remap string with redundant mappings removed
function util.validateRemapString(methodName, remapString)
    if type(remapString) ~= "string" then error("Invalid remap string: not a string") end

    local parts = {}
    for part in remapString:gmatch("[^.]+") do table.insert(parts, part) end
    if #parts % 2 ~= 0 then error("Invalid remap string: must have even number of parts") end

    local cleanParts = {}
    for i = 1, #parts, 2 do
        local source = parts[i]
        local target = parts[i + 1]
        -- Only include non-redundant mappings
        if source ~= target then table.insert(cleanParts, source) table.insert(cleanParts, target) end
    end
    local cleanString = table.concat(cleanParts, ".")
    if cleanString ~= remapString then
        warn(methodName .. ": WARNING! Remap string " .. remapString ..  " had redundant mappings")
    end
    return cleanString
end

function util.generateStatistics(AllSpells, AllComponents)
    local spellStats = {}

    -- Find shared components (used in multiple spells)
    local componentUsage = {}
    for _, spell in pairs(AllSpells) do
        for _, component in pairs(spell.components) do
            componentUsage[component] = (componentUsage[component] or 0) + 1
        end
    end

    local sharedComponents = {}
    for component, usageCount in pairs(componentUsage) do
        if usageCount > 1 then sharedComponents[component] = true end
    end

    -- Count triggers by category
    for _, spell in pairs(AllSpells) do
        local spellTriggerCount = 0
        for _, component in pairs(spell.components) do
            if not sharedComponents[component] then
                spellTriggerCount = spellTriggerCount + #component.triggers
            end
        end
        spellStats[spell.spellName] = spellTriggerCount
    end

    -- Count shared triggers
    local sharedTriggerCount = 0
    for component in pairs(sharedComponents) do
        sharedTriggerCount = sharedTriggerCount + #component.triggers
    end

    local componentStats = {}
    for _, component in ipairs(AllComponents) do
        componentStats[component.componentName] = #component.triggers
    end

    local stats = {}
    stats.spellStats = spellStats
    stats.sharedTriggerCount = sharedTriggerCount
    stats.componentStats = componentStats
    return stats
end

return util