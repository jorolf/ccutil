--[[
    Provides a way to run a dynamic list of coroutines
]]

local utilities = require("utilities")

local Concurrent = {}

local function new()
    return setmetatable({
        coroutines = {},
        filters = {}
    },{
        __index = Concurrent,
    })

end

function Concurrent:runCoroutine(co, event)
    if self.filters[co] == nil or self.filters[co] == event[1] or event[1] == "terminate" then
        local ok, param = coroutine.resume(co, table.unpack(event))
        if ok then
            self.filters[co] = param
        else
            error(param, 0)
        end
    end
end

function Concurrent:runOnce()
    local event = {os.pullEventRaw()}

    for _, co in ipairs(self.coroutines) do
        self:runCoroutine(co, event)
    end

    local dead_coroutines = utilities.removeAllValueIf(self.coroutines, function(co) return coroutine.status(co) == "dead" end)
    for _, co in ipairs(dead_coroutines) do
        self.filters[co] = nil
    end
end

function Concurrent:run()
    while #self.coroutines > 0 do
        self:runOnce()
    end
end

function Concurrent:add(func)
    local co = coroutine.create(func)
    self.coroutines[#self.coroutines+1] = co
    self:runCoroutine(co, {})
end

return new
