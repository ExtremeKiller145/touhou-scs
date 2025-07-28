-- Contains definitions for all enums

local util = require('utils')

local enum = {
    PLR_SPEED = 311.58,
    PLR_GROUP = 2,
    EDITOR_LAYER = 4,
    UNKNOWN_GROUP = "unknown_g", -- Gets parsed at compile time
    REMAP_GROUP = 10, -- Empty group for remapping 10 > whatever
    OFFSCREEN_DIST = 480, -- Minimum distance to get bullet to offscreen
    MIN_ANGLE = 3, -- Minimum angle for GuiderCircles

    DEFAULT_EASING = {
        t = 0,
        type = 0,
        rate = 1,
        dist = 480,
        angle = 90,
    },

    Properties = {
        -- Note to self: 
        -- MAKE ABSULUTELY SURE TO KEEP THESE IN ORDER WITH 0 MISTAKES: NO MISMATCHED NAMES

        OBJ_ID = 1,
        X = 2,
        Y = 3,
        DURATION = 10,
        EDITOR_LAYER = 20,
        MOVE_X = 28,
        MOVE_Y = 29,
        EASING = 30,
        TARGET = 51, -- General target for triggers
        GROUPS = 57, -- Requires JS-side translation
        EDITOR_LAYER_2 = 61,
        SPAWN_TRIGGERED = 62,
        ACTIVATE_GROUP = 56, -- For Toggle triggers
        ROTATE_CENTER = 71, -- For Rotate triggers, type group
        FOLLOW_GROUP = 71, -- For Follow triggers
        TARGET_DIR = 71, -- For Move Triggers
        EASING_RATE = 85,
        MULTI_TRIGGERED = 87,
        DIRECTION_MODE = 394, -- For Move triggers
        TARGET_CENTER = 395, -- For Move triggers, target's center
        DIRECTION_MODE_DISTANCE = 396, -- For Move triggers
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

return enum