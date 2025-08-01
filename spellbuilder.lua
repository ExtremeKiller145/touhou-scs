local lib = require("lib")
local enum = require("enums")
local util = require("utils")

local sb = {}

local AllRadials = {}
sb.AllRadials = AllRadials

---@class Radial
---@field component Component
---@field info table
local Radial = {}
Radial.__index = Radial
sb.Radial = Radial

---Constructor for Radial
---@param component Component type, must only target empty groups.
---@param info table, must contain 'emitter', 'numOfBullets', 'nextBullet'
function Radial.new(component, info)
    util.validateArgs("Radial.new", component, info)
    if not info.emitter then error("Radial: 'info' missing required field 'emitter'") end
    if not info.numOfBullets then error("Radial: 'info' missing required field 'numOfBullets'") end
    if not info.nextBullet then error("Radial: 'info' missing required field 'nextBullet'") end
    local self = setmetatable({}, Radial)
    self.component = component
    self.emitter = info.emitter
    self.numOfBullets = info.numOfBullets
    self.nextBullet = info.nextBullet
    table.insert(AllRadials, self)
    return self
end

-- Call a pre-existing radial at a new emitter location
---@param newEmitter number, New emitter group
---@param radial Radial, must be
---@param nextBullet function, optional; defaults to using the radials nextBullet
---@return Component, contains a spawn trigger w/ correct remaps
function sb.spawnRadial(x, newEmitter, radial, nextBullet)
    util.validateArgs("sb.spawnRadial", x, newEmitter, radial)

    return 
end

return sb