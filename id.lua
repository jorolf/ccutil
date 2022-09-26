--[[
    Returns a function to create a human readable unique identifier

    local makeid = require("id")

    local first = makeid()

    local second = makeid()

    assert(first ~= second)
]]

local id = 0

if os.getComputerLabel() == nil then
    return function()
        id = id + 1
        return os.getComputerID() .. ":" .. id
    end
else
    return function()
        id = id + 1
        return os.getComputerLabel() .. ":" .. id
    end
end
