--[[
    Returns a function to create a human readable unique identifier

    local makeid = require("id")

    local first = makeid()

    local second = makeid()

    assert(first ~= second)
]]

local id = 0

-- Splits the id into its parts: the global computer id and the specific local id
local function splitId(id)
    return string.match(id, "([^:]+):([^:]+)")
end

local function makeId()
    id = id + 1
    return os.getComputerID() .. ":" .. id
end

return {
    makeId = makeId,
    splitId = splitId,
}
