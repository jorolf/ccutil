package.path = "../?.lua;" .. package.path

local Concurrent = require("concurrent")
local coroutine_pool = Concurrent()

local function countdown(steps)
    while steps > 0 do
        print(steps)
        steps = steps - 1
        sleep(1)
    end
end

for i = 1, 5 do
    coroutine_pool:add(function ()
        countdown(i)
    end)
end

coroutine_pool:run()