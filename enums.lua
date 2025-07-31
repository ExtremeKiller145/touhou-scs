-- Contains definitions for all enums

local enum = {
    PLR_SPEED = 311.58,
    PLR = 2,
    EDITOR_LAYER = 4,
    UNKNOWN_G = "unknown_g", -- Gets parsed at compile time
    REMAP_G = 10, -- Empty group for remapping 10 -> whatever
    OFFSCREEN_DIST = 480, -- Minimum distance to get bullet to offscreen
    MIN_ANGLE = 3, -- Minimum angle for GuiderCircles
    ROTATE_INFINITE_DURATION = -1,

    DEFAULT_EASING = {
        t = 0,
        type = 0,
        rate = 1,
        dist = 480,
        angle = 90,
        dynamic = false
    },

    Properties = {
        OBJ_ID = 1,
        X = 2,
        Y = 3,
        DURATION = 10,
        EDITOR_LAYER = 20,
        EASING = 30,
        TARGET = 51, -- General target for triggers
        GROUPS = 57, -- Requires JS-side translation
        EDITOR_LAYER_2 = 61,
        SPAWN_TRIGGERED = 62,
        ACTIVATE_GROUP = 56, -- For Toggle triggers
        FOLLOW_GROUP = 71, -- For Follow triggers
        EASING_RATE = 85,
        MULTI_TRIGGERED = 87,
        DYNAMIC = 397,

        -- Pulse trigger properties
        PULSE_FADE_IN = 45,
        PULSE_HOLD = 46,
        PULSE_FADE_OUT = 47,
        PULSE_HSV = 48, -- hsv mode
        PULSE_HSV_STRING = 49, -- 'a' seperated string like 'HaSaBa0a0'
        PULSE_TARGET_TYPE = 52, -- false = color channel, true = group ID
        PULSE_EXCLUSIVE = 86,

        -- Scale trigger properties
        SCALE_X = 150,
        SCALE_Y = 151,
        SCALE_CENTER = 71,
        SCALE_DIV_BY_X = 153,
        SCALE_DIV_BY_Y = 154,

        -- Rotate trigger properties
        ROTATE_ANGLE = 68, -- In degrees, clockwise is +
        ROTATE_CENTER = 71, -- For Rotate triggers, type group
        ROTATE_TARGET = 401,
        ROTATE_AIM_MODE = 100,
        ROTATE_DYNAMIC_EASING = 403,

        -- Spawn trigger properties
        REMAP_STRING = 442, -- dot seperated. e.g. '1.2.3.4' remaps 1 -> 2 and 3 -> 4
        RESET_REMAP = 581, -- blocks other spawn triggers from remapping the spawn trigger's remap string
        SPAWN_ORDERED = 441, -- boolean
        SPAWN_DELAY = 63,

        -- Move trigger properties
        MOVE_X = 28,
        MOVE_Y = 29,
        MOVE_TARGET_CENTER = 395, -- target's center for Direction/Goto
        MOVE_TARGET_DIR = 71, -- target for Direction mode
        MOVE_TARGET_LOCATION = 71, -- target for Goto mode
        MOVE_TARGET_MODE = 100, -- 'Goto' mode boolean
        MOVE_DIRECTION_MODE = 394, -- Direction mode boolean
        MOVE_DIRECTION_MODE_DISTANCE = 396,
        MOVE_SILENT = 544, -- Platformer mode 'silent' boolean. activate if t = 0. unsure if more efficent
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

return enum