--[[
    This module can simplify working with independent bundle colors
]]

local read_redstone = {}
setmetatable(read_redstone, {__index=function() return 0 end})

-- Sets the specified bundle colors for a side while leave the others untouched
local function setColors(side, cols)
    local state = redstone.getBundledOutput(side)

    state = colors.combine(state, cols)

    redstone.setBundledOutput(side, state)
end

-- Clears the specified bundle colors for a side while leave the others untouched
local function unsetColors(side, cols)
    local state = redstone.getBundledOutput(side)

    state = colors.subtract(state, cols)

    redstone.setBundledOutput(side, state)
end

-- Flips the specified bundle colors for a side while leave the others untouched
local function switchColors(side, cols)
    local state = redstone.getBundledOutput(side)
    state = bit32.bxor(state, cols)

    redstone.setBundledOutput(side, state)
end

-- Returns bundle colors that changed since the last call masked by the second parameter
-- Useful in combination with the redstone event
local function testColorsOnce(side, cols)
    local new = redstone.getBundledInput(side)

    if bit32.band(read_redstone[side], cols) == bit32.band(new, cols) then
        return nil
    end

    read_redstone[side] = bit32.bor(bit32.band(read_redstone[side], bit32.bnot(cols)), bit32.band(new, cols))

    return colors.test(new, cols)
end

return {
    setColors = setColors,
    unsetColors = unsetColors,
    switchColors = switchColors,
    testColorsOnce = testColorsOnce,
}
