-- Contains definitions for all enums

-- Utility function for making enum readonly
local function readonly(tbl)
    local proxy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            proxy[k] = readonly(v)
        else
            proxy[k] = v
        end
    end
    return setmetatable(proxy, {
        __index = proxy,
        __newindex = function() error("Attempt to modify read-only table") end,
        __metatable = false -- Prevent further changes to the metatable
    })
end

local enum = {
    PLR_SPEED = 311.58,
    PLR_GROUP = 2,
    EDITOR_LAYER = 4,

    Properties = {
        TOGGLE_ACTIVATE_GROUP = 56,
        RESET_REMAPS = 581,
        SPAWN_ORDERED = 441,
    },

    ObjectID = {
        Toggle = 1049,
        Spawn = 1268,
        Pulse = 1006,
        Scale = 2067,
        Move = 901,
        Rotate = 1346,
        Collision = 1815,
    },

    Easing = {
        NONE = 1,
        EASE_IN_OUT = 2,
        EASE_IN = 3,
        EASE_OUT = 4,
        ELASTIC_IN_OUT = 5,
        ELASTIC_IN = 6,
        ELASTIC_OUT = 7,
        BOUNCE_IN_OUT = 8,
        BOUNCE_IN = 9,
        BOUNCE_OUT = 10,
        EXPONENTIAL_IN_OUT = 11,
        EXPONENTIAL_IN = 12,
        EXPONENTIAL_OUT = 13,
        SINE_IN_OUT = 14,
        SINE_IN = 15,
        SINE_OUT = 16,
        BACK_IN_OUT = 17,
        BACK_IN = 18,
        BACK_OUT = 19,
    },
}

return readonly(enum)