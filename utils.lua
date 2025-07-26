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
        __index = proxy,
        __newindex = function() error("Attempt to modify read-only table") end,
        __metatable = false
    })
end

function util.validateArgs(methodName, args)
    for name, value in pairs(args) do
        if value == nil then
            error(string.format("%s: missing required argument '%s'", methodName, name))
        end
    end
end
return util