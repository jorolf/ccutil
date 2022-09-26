--[[
    This module contains short functions that don't need their own module.
]]

local expect = require("cc.expect").expect

local utilities = {}

-- Clone a list and insert a new value
function utilities.cloneInsert(list, item)
    expect(1, list, "table")

    local cloned = {}
    for k, v in pairs(list) do cloned[k] = v end
    table.insert(cloned, item)

    return cloned
end

--[[
    Returns a function which calls a function with self.

    func_name - either a function where the first argument is self or a string of the function name in self
]]
function utilities.bindSelf(self, func)
    expect(1, self, "table")
    expect(2, func, "function", "string")

    if type(func) == "string" then
        return function(...) self[func](self, ...) end
    else
        return function(...) func(self, ...) end
    end
end

--[[
    Removes all occurences of a value from a list
]]
function utilities.removeAllValues(list, value)
    expect(1, list, "table")

    local overwrite_index = 1
    for current_index, current_value in ipairs(list) do
        if current_value ~= value then
            if overwrite_index ~= current_index then
                list[overwrite_index] = list[current_index]
            end

            overwrite_index = overwrite_index + 1
        end
    end

    for index = overwrite_index, #list do
        list[index] = nil
    end
end

return utilities