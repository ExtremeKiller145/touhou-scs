--[[
    Library for Touhou Shattered Crystal Shards
    Resources module: Bullet types, GuiderCircles, MultitargetRegistry, etc.
]]--

local lib = {}

require("luarocks.loader")
local enum = require("enums")
local util = require("utils")
local ppt = enum.Properties

local startTime = os.clock()

-- Area for spreading triggers out
local TriggerArea = {
    minX = 1350,
    minY = 1300,
    maxX = 30000,
    maxY = 10000
}

---@class Bullet
---@field minGroup number
---@field maxGroup number
---@field nextBullet fun(): number

lib.Bullet = {
    ---@type Bullet
    Bullet1 = {
        minGroup = 501,
        maxGroup = 1000,
        nextBullet = util.createBulletCycler(501, 1000)
    },
    ---@type Bullet
    Bullet2 = {
        minGroup = 1501,
        maxGroup = 2200,
        nextBullet = util.createBulletCycler(1501, 2200)
    },
    ---@type Bullet
    Bullet3 = {
        minGroup = 2901,
        maxGroup = 3600,
        nextBullet = util.createBulletCycler(2901, 3600)
    },
    ---@type Bullet
    Bullet4 = {
        minGroup = 4301,
        maxGroup = 4700,
        nextBullet = util.createBulletCycler(4301, 4700)
    }
}

---@class GuiderCircle
---@field all number Contains entire circle, Center is group parent
---@field center number The center group of the circle, used for positioning
---@field pointer number The first group in the circle, reference for aiming
---@field groups table<number, number> The groups that contain each bullet in the circle
lib.GuiderCircles = {
    ---@type GuiderCircle
    circle1 = {
        all = 5461,
        center = 5461,  -- parent
        pointer = 5101, -- First group in circle, reference for aiming
        groups = {}     -- Will be populated with 360 groups starting from pointer
    }
    -- Additional circles can be added here for simultaneous patterns
}

-- Populate GuiderCircle groups
local function populateGuiderCircle(circle)
    for i = 1, 360 do
        circle.groups[i] = circle.pointer + (i - 1)
    end
end
populateGuiderCircle(lib.GuiderCircles.circle1)

local AllSpells = {}

---@class Spell
---@field spellName string
---@field callerGroup number
---@field components table
local Spell = {}
Spell.__index = Spell
lib.Spell = Spell

---Constructor for Spell
---@param spellName string
---@param callerGroup number
---@return Spell
function Spell.new(spellName, callerGroup)
    util.validateArgs("Spell.new", spellName, callerGroup)
    local self = setmetatable({}, Spell)
    self.spellName = spellName
    self.callerGroup = callerGroup
    self.components = {}
    table.insert(AllSpells, self)
    return self
end

function Spell:AddComponent(component)
    table.insert(self.components, component)
    return self
end



---@class MultitargetRegistry
---@field _binaryBases table<number, Component> Private storage for binary base components (powers of 2)
local MultitargetRegistry = {}
MultitargetRegistry.__index = MultitargetRegistry
lib.MultitargetRegistry = MultitargetRegistry

-- Private storage for binary base components (powers of 2)
MultitargetRegistry._binaryBases = {}
MultitargetRegistry._initialized = false

--- Get the binary components needed to represent numBullets
--- All components are pre-created at startup for reliability
---@param numTargets number The number of bullets needed (1-127)
---@return table components; Array of Component objects that sum to numTargets
function MultitargetRegistry:getBinaryComponents(numTargets)
    if not self._initialized then
        error("MultitargetRegistry not initialized! Ensure component.lua is loaded.")
    end

    -- Input validation
    if not util.isInteger(numTargets) then
        error("getBinaryComponents: numTargets must be an integer")
    elseif numTargets <= 0 or numTargets > 127 then
        error("getBinaryComponents: numTargets must be between 1 and 127")
    end

    local components = {}
    local remaining = numTargets
    local powers = { 64, 32, 16, 8, 4, 2, 1 } -- Check largest powers first

    for _, power in ipairs(powers) do
        if remaining >= power then
            -- All components are pre-created, so just get from cache
            table.insert(components, self._binaryBases[power])
            remaining = remaining - power
        end
    end

    return components
end



--- Initialize all binary base components at startup (called once globally)
function MultitargetRegistry:initializeBinaryComponents(componentClass)
    if MultitargetRegistry._initialized then return end

    local powers = { 1, 2, 4, 8, 16, 32, 64 } -- All powers of 2 up to 64

    for _, power in ipairs(powers) do
        local component = componentClass.new("BinaryBase_" .. power, util.unknown_g(), 4)
        component:assertSpawnOrder(false) -- All binary bases shoot simultaneously

        -- To add support for more parameters, add a new empty group and follow the pattern
        for i = 1, power * 4, 4 do
            local rb = util.remap()
            rb:pair(enum.EMPTY_BULLET, i + 6000)
                :pair(enum.EMPTY_TARGET_GROUP, i + 6001)
                :pair(enum.EMPTY1, i + 6002)
                :pair(enum.EMPTY2, i + 6003)
            component:Spawn(0, enum.EMPTY_MULTITARGET, true, rb:toString())
        end
        MultitargetRegistry._binaryBases[power] = component
    end
    MultitargetRegistry._initialized = true
    print("MultitargetRegistry: Initialized all binary components (1-127 bullets supported)")
end

local function spreadTriggers(triggers, component)
    if #triggers < 1 then error("spreadTriggers: No triggers in component " .. component.componentName) end
    local area = TriggerArea

    if #triggers == 1 then
        triggers[1][ppt.X] = math.random(area.minX, area.maxX)
        triggers[1][ppt.Y] = math.random(area.minY, area.maxY)
        return
    end

    -- Detect pattern type
    local sameX = true
    local firstX = triggers[1][ppt.X]
    for i = 2, #triggers do
        if triggers[i][ppt.X] ~= firstX then sameX = false; break end
    end

    if sameX and component.requireSpawnOrder == false then
        -- Loose squares - random positions
        for _, trigger in ipairs(triggers) do
            trigger[ppt.X] = math.random(area.minX / 2, area.maxX / 2) * 2
        end
    elseif component.requireSpawnOrder == true then
        -- Rigid chain - shift whole group (only case that can fail)
        local minX, maxX = triggers[1][ppt.X], triggers[1][ppt.X]
        for _, trigger in ipairs(triggers) do
            minX = math.min(minX, trigger[ppt.X])
            maxX = math.max(maxX, trigger[ppt.X])
        end

        local chainWidth = maxX - minX
        -- Check if rigid chain fits
        if chainWidth > (area.maxX - area.minX) then
            error("spreadTriggers: Rigid chain too wide (" ..
                chainWidth .. ") to fit in trigger area for " .. component.componentName)
        end

        local shift = math.random(area.minX, math.floor(area.maxX - chainWidth)) - minX

        for _, trigger in ipairs(triggers) do trigger[ppt.X] = trigger[ppt.X] + shift end
    else
        -- Elastic chain - stretch as needed (no bounds checking)
        local startX = area.minX
        for i, trigger in ipairs(triggers) do
            if i == 1 then trigger[ppt.X] = startX goto continue end
            -- Just add random spacing, can extend beyond area.maxX
            local spacing = math.random(1, 10)
            trigger[ppt.X] = triggers[i - 1][ppt.X] + spacing
            ::continue::
        end
    end

    for _, trigger in ipairs(triggers) do
        trigger[ppt.Y] = math.random(area.minY, area.maxY)
    end
end



---@param allComponents Component[]
function lib.SaveAll(allComponents)
    local filename = "triggers.json"
    local allTriggers = { triggers = {} }
    
    ---@param AllComponents table
    ---@param objectBudget number Maximum object count (default: 200000)
    local function generateStatistics(AllComponents, objectBudget)
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
    local function printBudgetAnalysis(stats)
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

    -- Add all triggers to output, sorted by X position within each component
    for _, component in pairs(allComponents) do
        local sortedTriggers = { table.unpack(component.triggers) }

        -- Spread triggers before sorting (sorting is mainly for placement order)
        spreadTriggers(sortedTriggers, component)

        table.sort(sortedTriggers, function(a, b)
            return (a[ppt.X] or 0) < (b[ppt.X] or 0)
        end)

        -- Add sorted triggers to output
        local x = -10000
        for _, trigger in ipairs(sortedTriggers) do
            if trigger[ppt.GROUPS] == 9999 then
                error("CRITICAL ERROR: RESERVED GROUP 9999 DETECTED WITHIN " .. component.componentName)
            end
            -- according to info given by bombie (untested but better be safe)
            if trigger[ppt.X] - x < 1 and trigger[ppt.X] - x ~= 0 then
                error("CRITICAL ERROR: X POSITION IS WITHIN 1 UNIT OF PREVIOUS TRIGGER, ORDER NOT PRESERVED. DETECTED WITHIN " .. component.componentName)
            end
            x = trigger[ppt.X]
            table.insert(allTriggers.triggers, trigger)
        end
    end

    -- Budget analysis and output
    local stats = generateStatistics(allComponents, 200000)
    printBudgetAnalysis(stats)

    -- Save to file
    local file = io.open(filename, "w")
    if not file then error("Failed to open " .. filename .. " for writing!") end

    local json = require("dkjson")
    file:write(json.encode(allTriggers))
    file:close()
    print("\nSaved to " .. filename .. " successfully!")
    print("Total execution time: " .. (os.clock() - startTime) .. " seconds")
end

return lib
