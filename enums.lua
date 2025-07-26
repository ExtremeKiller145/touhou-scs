-- Contains definitions for all enums

local util = require('utils')

local enum = {
    PLR_SPEED = 311.58,
    PLR_GROUP = 2,
    EDITOR_LAYER = 4,

    DEFAULT_EASING = {
        Time = 0,
        Easing_type = 0,
        Easing_rate = 1
    },

    Properties = {
        OBJ_ID = 1,
        X = 2,
        Y = 3,
        DURATION = 10,
        EDITOR_LAYER = 20,
        EASING = 30,
        GROUPS = 57,
        EDITOR_LAYER_2 = 61,
        SPAWN_TRIGGERED = 62,
        TOGGLE_ACTIVATE_GROUP = 56,
        ROTATE_CENTER = 71, -- for Rotate triggers
        FOLLOW_GROUP = 71, -- for Follow triggers
        TARGET_GROUP = 71, -- for Move Triggers
        EASING_RATE = 85,
        MULTI_TRIGGERED = 87,
        RESET_REMAP = 581,
        SPAWN_ORDERED = 441,
        REMAP_STRING = 442,
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
        NONE = 0,
        EASE_IN_OUT = 1,
        EASE_IN = 2,
        EASE_OUT = 3,
        ELASTIC_IN_OUT = 4,
        ELASTIC_IN = 5,
        ELASTIC_OUT = 6,
        BOUNCE_IN_OUT = 7,
        BOUNCE_IN = 8,
        BOUNCE_OUT = 9,
        EXPONENTIAL_IN_OUT = 10,
        EXPONENTIAL_IN = 11,
        EXPONENTIAL_OUT = 12,
        SINE_IN_OUT = 13,
        SINE_IN = 14,
        SINE_OUT = 15,
        BACK_IN_OUT = 16,
        BACK_IN = 17,
        BACK_OUT = 18,
    },
}

return util.readonly(enum)