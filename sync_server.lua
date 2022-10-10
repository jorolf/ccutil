--[[
    This module represents the server side of the sync protocol.

    The returned table represents the server.
]]

-- Rednet protocol names
local SYNC_REQUEST = "SYNC_REQUEST" -- Client -> Server
local SYNC_RESPOND = "SYNC_RESPOND" -- Server -> Client

local expect = require("cc.expect").expect
local utilities = require("utilities")

local SyncServer = {}
local cache_key, port_key, keys_key = {}, {}, {}

local sync_table, sync_server

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
    port - The name of the synchronized root table
    keys - A chain of keys to reach the current table from the root table
]]
local function synchronizedTable(tbl, port, keys)
    expect(1, tbl, "table")
    expect(2, port, "string")
    expect(3, keys, "table")

    return setmetatable({
        [cache_key] = tbl,
        [port_key] = port,
        [keys_key] = keys,
    }, sync_table)
end

-- Update a value in the synchronized table and notify the all clients
local function synchronizedSet(tbl, key, value)
    expect(1, tbl, "table")

    tbl[cache_key][key] = value

    local response = {
        port = tbl[port_key],
        keys = tbl[keys_key],
        key = key,
        value = value,
    }

    for host, _ in pairs(sync_server.connected_clients[tbl[port_key]]) do
        rednet.send(host, response, SYNC_RESPOND)
    end
end

-- Get a value from a synchronized table and synchronize it if it is also a table
local function synchronizedGet(tbl, key)
    expect(1, tbl, "table")

    local value = tbl[cache_key][key]
    if type(value) == "table" then
        value = synchronizedTable(value, tbl[port_key], utilities.cloneInsert(tbl[keys_key], key))
    end

    return value
end

-- sync metatable
sync_table = {
    __index = synchronizedGet,
    __newindex = synchronizedSet,
    __pairs = synchronizedPairs,
    __len = synchronizedLen,
}

-- Event loop to receive table updates and distribute them, needs to run (in a coroutine) and never returns
local function serve(self)
    while true do
        local other_host, request = rednet.receive(SYNC_REQUEST)
        if request.keys ~= nil and request.port ~= nil then
            local object = self.ports[request.port]

            for _, key in ipairs(request.keys) do
                if object == nil then
                    break
                end

                object = object[key]
            end

            if request.key ~= nil and request.value ~= nil then
                if type(object) == "table" then
                    object[request.key] = request.value

                    for host, _ in pairs(self.connected_clients[request.port]) do
                        if host == other_host then
                            rednet.send(host, nil, SYNC_RESPOND)
                        else
                            rednet.send(host, request, SYNC_RESPOND)
                        end
                    end
                else
                    rednet.send(other_host, "Object not a table", SYNC_RESPOND)
                end
            else
                rednet.send(other_host, object, SYNC_RESPOND)
                self.connected_clients[request.port][other_host] = true
            end
        elseif request.port ~= nil and request.unregister then
            self.connected_clients[request.port][other_host] = nil
        else
            rednet.send(other_host, nil, SYNC_RESPOND)
        end
    end
end

-- register a table under a specific port
function SyncServer:register(port, tbl)
    expect(1, port, "string")
    expect(2, tbl, "table")

    if self.ports[port] then
        error("Port already in use!")
    end
    self.ports[port] = tbl
    self.connected_clients[port] = {}
    return synchronizedTable(tbl, port, {})
end

-- unregister a table from a port
function SyncServer:unregister(port)
    expect(1, port, "string")

    self.ports[port] = nil
    self.connected_clients[port] = nil
end

-- host this server under a specific hostname
function SyncServer:host(hostname)
    expect(1, hostname, "string")

    rednet.host(SYNC_REQUEST, hostname)
    table.insert(self.hostnames, hostname)
end

-- remove a hostname of this server
function SyncServer:unhost(hostname)
    expect(1, hostname, "string")

    rednet.unhost(SYNC_REQUEST, hostname)
    utilities.removeAllValues(self.hostnames, hostname)
end

--[[ 
    Unregisters all tables and hostnames.
    Using tables after unregistering them is undefined behavior.
]]
function SyncServer:unregisterAll()
    self.ports = {}
    self.connected_clients = {}
    for hostname, _ in pairs(self.hostnames) do
        rednet.unhost(SYNC_REQUEST, hostname)
    end
    self.hostnames = {}
end

-- Technically not required but a sane default
if not rednet.isOpen() then
    error("Rednet needs to be opened before this module can be loaded")
end

sync_server = setmetatable({
    hostnames = {},
    ports = {},
    connected_clients = {},
},{
    __index = SyncServer,
})
sync_server.serve = utilities.bindSelf(sync_server, serve)
return sync_server
