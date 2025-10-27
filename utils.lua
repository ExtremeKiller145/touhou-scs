-- Utility functions for Lua scripts

local enum = require("enums")

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
    local enum = require("enums")
    local args = {...}

    -- Lookup table for faster checking
    local restrictedLookup = {}
    for _, groupId in pairs(enum.RESTRICTED_GROUPS) do
        restrictedLookup[groupId] = true
    end

    for _, arg in pairs(args) do
        if type(arg) == "number" and arg >= 0 and arg <= 9999 then
            if restrictedLookup[arg] then
                error(methodName .. ": Group " .. arg .. " is restricted due to known conflicts.")
            end
        elseif type(arg) == "string" and arg:match("^unknown_g%d+$") then
            -- Allow unknown groups as targets
        else
            error(methodName .. ": Invalid group type: " .. type(arg))
        end
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
    local hasBullet, hasTargetGroup, hasMultiTarget = false, false, false
    for _, trigger in pairs(component.triggers) do
        for _, field in pairs(enum.Properties.TargetFields) do
            if trigger[field] == enum.EMPTY_BULLET then hasBullet = true end
            if trigger[field] == enum.EMPTY_TARGET_GROUP then hasTargetGroup = true end
            if trigger[field] == enum.EMPTY_MULTITARGET then hasMultiTarget = true end
        end
    end

    if not hasBullet then
        error(functionName .. ": component must target EMPTY_BULLET (bullet visual)")
    elseif not hasTargetGroup then
        error(functionName .. ": component must target EMPTY_TARGET_GROUP (guidercircle target)")
    elseif hasMultiTarget then
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

    if easing.rate == nil then easing.rate = 1 end

    -- Optional speedProfile field handling
    if easing.speedProfile then
        local speed = enum.SpeedProfiles[easing.speedProfile]
        if not speed then
            error(methodName .. ": easing has invalid speedProfile '" .. tostring(easing.speedProfile) .. "'")
        end
        -- include user-specified dist in calculation (as an optional offset)
        local speedFactor = speed / enum.OFFSCREEN_DIST
        if easing.dist then easing.dist = easing.dist + enum.OFFSCREEN_DIST
        else easing.dist = enum.OFFSCREEN_DIST end
        easing.t = easing.dist / speedFactor
    end

    -- Required fields
    -- only easing types 1-6 use ease rate field
    if easing.type > 6 or easing.type < 1 then easing.rate = 1 end

    local required = { "t", "type", "rate" }
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

    if not hsb["h"] or not hsb["s"] or not hsb["b"] or hsb["exclusive"] == nil then
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

--- Remap builder: chainable helper to assemble dot-separated remap strings safely.
-- Example:
-- local b = util.remap()
-- b:pair(10, 6001):pair(20, 6002)
-- local s = b:toString() -- "10.6001.20.6002"
function util.remap()
    local builder = {}
    builder._pairs = {}

    --- Append a source->target pair (both number or string). Chainable.
    function builder:pair(source, target)
        if source == nil or target == nil then error("remap: source and target required") end
        table.insert(self._pairs, { source = tostring(source), target = tostring(target) })
        return self
    end

    --- Append a source->target where target is generated by a function at toString time.
    -- Useful for dynamic cyclers: targetFn should return a string/number when called.
    function builder:pairFunc(source, targetFn)
        if source == nil or type(targetFn) ~= "function" then error("remap: pairFunc requires source and function") end
        table.insert(self._pairs, { source = tostring(source), targetFn = targetFn })
        return self
    end

    --- Build the final remap string (no leading/trailing dot). Validates duplicates and
    -- removes identity mappings (source==target).
    function builder:toString()
        local parts = {}
        local seenSources = {}
        local seenTargets = {}

        for _, p in ipairs(self._pairs) do
            local src = p.source
            local tgt = p.target
            if not tgt and p.targetFn then tgt = tostring(p.targetFn()) end
            if not tgt then error("remap: unresolved target for source " .. tostring(src)) end

            if seenSources[src] then error("remap: duplicate source '" .. src .. "'") end
            if seenTargets[tgt] then error("remap: duplicate target '" .. tgt .. "'") end

            seenSources[src] = true
            seenTargets[tgt] = true

            if src ~= tgt then
                table.insert(parts, src)
                table.insert(parts, tgt)
            end
        end

        return table.concat(parts, ".")
    end

    return builder
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
