rednet.open("top")

package.path = "../?.lua;" .. package.path

local sync_server = require("sync_server")
sync_server:host("data_server")

local data = {
    inner = {}
}

data = sync_server:register("data", data)

local function loop()
    local inner = data.inner

    while true do
        inner[#inner + 1] = "Test"
        print("Data: ".. textutils.serialize(inner))
        os.pullEvent("key")
    end
end

local _, error = pcall(parallel.waitForAll, loop, sync_server.serve)
printError(error)
sync_server:unregisterAll()
