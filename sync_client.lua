--[[
    This module represents the client side of the sync protocol.
    
    The returned table represents the client.
]]

-- Rednet protocol names
local SYNC_REQUEST = "SYNC_REQUEST" -- Client -> Server
local SYNC_RESPOND = "SYNC_RESPOND" -- Server -> Client

local expect = require("cc.expect").expect
local utilities = require("ccutil.utilities")

local SyncClient = {}
local cache_key, host_key, port_key, keys_key = {}, {}, {}, {}

local sync_table

-- Meta functions for the synchronized table
local function synchronizedPairs(table)
    return pairs(table[cache_key])
end

local function synchronizedLen(table)
    return #table[cache_key]
end

--[[ 
    Create a synchronized table
    tbl - The cache
    host - The ID of the host computer
    port - The name of the synchronized root table
    keys - A chain of keys to reach the current table from the root table
]]
local function synchronizedTable(tbl, host, port, keys)
    expect(1, tbl, "table")
    expect(2, host, "number")
    expect(3, port, "string")
    expect(4, keys, "table")

    return setmetatable({
        [cache_key] = tbl,
        [host_key] = host,
        [port_key] = port,
        [keys_key] = keys,
    }, sync_table)
end

-- Update a value in the synchronized table and notify the server
local function synchronizedSet(tbl, key, value)
    expect(1, tbl, "table")

    tbl[cache_key][key] = value

    rednet.send(tbl[host_key], {
        port = tbl[port_key],
        keys = tbl[keys_key],
        key = key,
        value = value,
    }, SYNC_REQUEST)

    local successful, message = rednet.receive(SYNC_RESPOND, 1)

    if not successful or type(message) == "string" then
        error("Could not update object: "..message)
    end
end

-- Get a value from a synchronized table and synchronize it if it is also a table
local function synchronizedGet(tbl, key)
    expect(1, tbl, "table")

    local value = tbl[cache_key][key]
    if type(value) == "table" then
        value = synchronizedTable(value, tbl[host_key], tbl[port_key], utilities.cloneInsert(tbl[keys_key], key))
    end

    return value
end

-- sync metatable
sync_table = {
    __index = synchronizedGet,
    __newindex = synchronizedSet,
    __pairs = synchronizedPairs,
    __len = synchronizedLen
}

--[[
    Connect to a remote root table
    host - The host ID or hostname
    port - The name of the synchronized root table
    timeout? - Optional timeout in seconds, function won't return without a value until the timeout passed

    Returns either a synchronized table or nil 
]]
function SyncClient:connect(host, port, timeout)
    expect(1, self, "table")
    expect(2, host, "string", "number")
    expect(3, port, "string")

    if type(host) == "string" then
        local end_time = os.clock() + timeout
        while os.clock() < end_time do
            host = rednet.lookup(SYNC_REQUEST, host)
            if host ~= nil then
                break
            end
        end

        if host == nil then
            error("Lookup failed")
        end
    end

    rednet.send(host, {
        port = port,
        keys = {},
    }, SYNC_REQUEST)

    local successful, value = rednet.receive(SYNC_RESPOND, timeout)

    if not successful then
        error("Could not retrieve object")
    elseif type(value) ~= "table" then
        error("Server didn't return a table")
    end

    self.tables[host] = self.tables[host] or {}
    self.tables[host][port] = value

    value = synchronizedTable(value, host, port, {})

    return value
end


-- Event loop to receive table updates, needs to run (in a coroutine) and never returns
local function receive(self)
    while true do
        other_host, request = rednet.receive(SYNC_RESPOND)
        if self.tables[other_host] and type(request) == "table" and request.keys ~= nil and request.port ~= nil and request.key ~= nil and request.value ~= nil then
            local object = self.tables[other_host][request.port]

            for _, key in ipairs(request.keys) do
                if object == nil then
                    break
                end

                object = object[key]
            end

            if type(object) == "table" then
                object[request.key] = request.value
            end
        end
    end
end

--[[ 
    Unregisters all tables from updates and releases all resources.
    Using tables after unregistering them is undefined behavior.
]]
function SyncClient:unregisterAll()
    for host, ports in pairs(self.tables) do
        for port, table in pairs(ports) do
            rednet.send(host, {
                port = port,
                unregister = true,
            }, SYNC_REQUEST)
        end
    end

    self.tables = {}
end

-- Technically not required but a sane default
if not rednet.isOpen() then
    error("Rednet needs to be opened before this module can be loaded")
end

local sync_client = setmetatable({
    tables = {},
},{
    __index = SyncClient,
})
sync_client.receive = utilities.bindSelf(sync_client, receive)

return sync_client