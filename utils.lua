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
    if type(min) ~= "number" or type(max) ~= "number" then
        error("createNumberCycler: min and max must be numbers")
    end

    if min > max then
        error("createNumberCycler: min cannot be greater than max")
    end

    min = math.floor(min)
    max = math.floor(max)
    local current = min - 1
    return function()
        current = current + 1
        if current > max then
            current = min
        end
        return current
    end
end

--- Semantic wrapper for group tables or individual values for 'self-documenting code'
function util.group(val) return val end

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
    local required = {"t", "type", "rate"}
    if easing.type > 6 then easing.rate = 1 end -- only easing types 1-6 use ease rate field
    for _, field in pairs(required) do
        if easing[field] == nil then
            error(methodName .. ": easing missing required field '" .. field .. "'")
        end
    end

    -- Must have either 'dist' or 'angle' or 'MoveBy'
    local hasDist = easing.dist ~= nil
    local hasAngle = easing.angle ~= nil
    local hasMoveBy = easing.MoveBy ~= nil

    if not hasDist and not hasAngle and not hasMoveBy then
        error(methodName .. ": easing must have either 'dist' or 'angle' field")
    end
end

return util