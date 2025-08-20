-- Utility functions for Lua scripts

local util = {}


---@param remapString string The remap string to parse
---@return table pairs ; where  'i' is paired with pairs[i]
function util.translateRemapString(remapString)
    local pairs = {}
    if type(remapString) ~= "string" then
        error("translateRemapString: remapString must be a string")
    end

    local parts = {}
    for part in remapString:gmatch("[^.]+") do table.insert(parts, part) end

    if #parts == 0 then
        error("translateRemapString: remapString must contain at least one valid pair")
    elseif #parts % 2 ~= 0 then
        error("translateRemapString: remapString must contain an even number of parts:\n" .. remapString)
    end

    -- pairs[source] = target
    for i = 1, #parts, 2 do pairs[parts[i]] = parts[i + 1] end

    return pairs
end

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

--- Creates a bullet cycler for the bullet type. Consult spreadsheet for values.
---@param min number The minimum group (inclusive)
---@param max number The maximum group (inclusive)
---@return function cycler returns the next group in sequence, cycling back to min after max. Also returns optional collision group
function util.createBulletCycler(min, max)
    local cycler = util.createNumberCycler(min, max)
    return function()
        local bullet = cycler()
        return bullet, max + bullet -- bullet, collision
    end
end

--- Includes type checking w/ 'math.floor' function
function util.isInteger(num) return math.floor(num) == num end

--- Semantic wrapper for group tables or individual values for 'self-documenting code'
function util.group(val) return val end

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

--- Converts distance in studs to time in seconds
function util.distToTime(dist) return dist / 311.58 end

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

-- Extract to utility function
---@param component Component
---@param functionName string
function util.validateRadialComponent(component, functionName)
    if component.requireSpawnOrder ~= true then
        error(functionName .. ": component must require spawn order...")
    end
    local enum = require("enums")
    local hasEmpty1, hasEmpty2, hasEmpty5 = false, false, false
    for _, trigger in pairs(component.triggers) do
        for _, field in pairs(enum.Properties.TargetFields) do
            if trigger[field] == enum.EMPTY1 then hasEmpty1 = true end
            if trigger[field] == enum.EMPTY2 then hasEmpty2 = true end
            if trigger[field] == enum.EMPTY5 then hasEmpty5 = true end
        end
    end
    
    if not hasEmpty1 then
        error(functionName .. ": component must target EMPTY1 (bullet visual)")
    elseif not hasEmpty2 then
        error(functionName .. ": component must target EMPTY2 (guidercircle target)")
    elseif hasEmpty5 then
        error(functionName .. ": component must not have any triggers targeting EMPTY5")
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
    util.validateArgs(methodName, remapString)
    if type(remapString) ~= "string" then error("Invalid remap string: not a string") end

    local remapPairs = util.translateRemapString(remapString)

    -- Re-register pairs to catch duplicate sources
    local sourceCheck = {}
    local targetCheck = {}

    for source, target in pairs(remapPairs) do
        -- Check for duplicate source
        if sourceCheck[source] then
            error(methodName .. ": Duplicate source '" .. source .. "' in remap string - cannot remap one group to multiple targets")
        end
        sourceCheck[source] = true

        -- Check for duplicate target  
        if targetCheck[target] then
            error(methodName .. ": Duplicate target '" .. target .. "' in remap string - cannot remap multiple groups to same target")
        end
        targetCheck[target] = true
    end

    -- Rebuild clean remap string (removing redundant mappings like 10 => 10)
    local cleanPairs = {}
    for source, target in pairs(remapPairs) do
        if source ~= target then
            table.insert(cleanPairs, source .. "." .. target)
        end
    end

    local cleanString = table.concat(cleanPairs, ".")
    if cleanString ~= remapString then
        warn(methodName .. ": WARNING! Remap string " .. remapString .. " had redundant mappings")
    end

    return cleanString
end

---@param AllSpells table
---@param AllComponents table  
---@param allTriggers table The triggers array to analyze
---@param objectBudget number Maximum object count (default: 200000)
function util.generateStatistics(AllSpells, AllComponents, allTriggers, objectBudget)
    objectBudget = objectBudget or 200000
    local totalTriggers = allTriggers and #allTriggers.triggers or 0

    local spellStats = {}
    local componentStats = {}

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

    -- Count triggers by spell (excluding shared components)
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

    -- Component stats
    for _, component in ipairs(AllComponents) do
        componentStats[component.componentName] = #component.triggers
    end

    -- Budget analysis
    local usagePercent = totalTriggers > 0 and (totalTriggers / objectBudget) * 100 or 0
    local remainingBudget = objectBudget - totalTriggers

    local stats = {
        spellStats = spellStats,
        componentStats = componentStats,
        sharedTriggerCount = sharedTriggerCount,
        budget = {
            totalTriggers = totalTriggers,
            objectBudget = objectBudget,
            usagePercent = usagePercent,
            remainingBudget = remainingBudget
        }
    }
    return stats
end

---@param stats table Statistics from generateStatistics
function util.printBudgetAnalysis(stats)
    print(string.format("\n=== BUDGET ANALYSIS ==="))
    print(string.format("Total triggers: %d (%.3f%%)", 
        stats.budget.totalTriggers, stats.budget.usagePercent))
    print(string.format("Remaining budget: %d triggers", stats.budget.remainingBudget))

    print(' Spells:')
    for spellName, count in pairs(stats.spellStats) do
        print(string.format("   %s: %d triggers", spellName, count))
    end

    print(' Components:')
    for componentName, count in pairs(stats.componentStats) do
        print(string.format("   %s: %d triggers", componentName, count))
    end

    print(' Triggers in shared components: ' .. stats.sharedTriggerCount)
end

return util