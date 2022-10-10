rednet.open("top")

package.path = "../?.lua;" .. package.path

local sync_client = require("sync_client")

local data = sync_client:connect("data_server", "data")

local function loop()
    local inner = data.inner

    while true do
        inner[#inner + 1] = "Test"
        print("Data: ".. textutils.serialize(inner))
        os.pullEvent("key")
    end
end

local _, error = pcall(parallel.waitForAll, loop, sync_client.receive)
printError(error)
sync_client:unregisterAll()
