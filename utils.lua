-- Utility functions for Lua scripts

local util = {}

function util.readonly(tbl)
    local proxy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            proxy[k] = util.readonly(v)
        else
            proxy[k] = v
        end
    end
    return setmetatable(proxy, {
        __index = tbl,
        __newindex = function() error("Attempt to modify read-only table") end,
        __metatable = false
    })
end

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