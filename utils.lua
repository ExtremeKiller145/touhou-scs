-- Utility functions for Lua scripts

local util = {}

--- READONLY FUNCTION REMOVED: 
--- was breaking intellisense from reading contents of the table, 
--- missing the point of having it as readonly

--- To nil-check function arguments
---@param methodName string The name of the method for error messages.
---@param ... any The arguments to check.
function util.validateArgs(methodName, ...)
    local args = {...}
    for name, value in pairs(args) do
        if value == nil then
            error(string.format("%s: missing required argument '%s'", methodName, name))
        end
    end
end

return util