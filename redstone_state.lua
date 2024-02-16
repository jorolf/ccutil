local expect_m = require("cc.expect")
local expect, field = expect_m.expect, expect_m.field

-- Empty objects to create unique keys
local SINGLE_TYPE = {}
local BUNDLED_TYPE = {}

local function getLane(side)
    expect(1, side, "string")

    return {
        type = SINGLE_TYPE,
        side = side,
        previously = redstone.getInput(side)
    }
end

local function getColorLane(side, color)
    expect(1, side, "string")
    expect(2, color, "number")

    return {
        type = BUNDLED_TYPE,
        side = side,
        color = color,
        previously = redstone.getBundledInput(side)
    }
end

local function setOutput(lane)
    expect(1, lane, "table")
    field(lane, "type", "table")

    if lane.type == SINGLE_TYPE then
        redstone.setOutput(lane.side, true)
    elseif lane.type == BUNDLED_TYPE then
        redstone.setBundledOutput(lane.side, colors.combine(redstone.getBundledOutput(lane.side), lane.color))
    end
end

local function unsetOutput(lane)
    expect(1, lane, "table")
    field(lane, "type", "table")

    if lane.type == SINGLE_TYPE then
        redstone.setOutput(lane.side, false)
    elseif lane.type == BUNDLED_TYPE then
        redstone.setBundledOutput(lane.side, colors.subtract(redstone.getBundledOutput(lane.side), lane.color))
    end
end

local function switchOutput(lane)
    expect(1, lane, "table")
    field(lane, "type", "table")

    if lane.type == SINGLE_TYPE then
        redstone.setOutput(lane.side, not redstone.getOutput())
    elseif lane.type == BUNDLED_TYPE then
        redstone.setBundledOutput(lane.side, bit32.bxor(redstone.getBundledOutput(lane.side), lane.color))
    end
end

local function getInput(lane)
    expect(1, lane, "table")
    field(lane, "type", "table")

    if lane.type == SINGLE_TYPE then
        return redstone.getInput(lane.side)
    elseif lane.type == BUNDLED_TYPE then
        return colors.test(redstone.getBundledInput(lane.side), lane.color)
    end
end

local function testInputSwitch(lane)
    expect(1, lane, "table")
    field(lane, "type", "table")

    if lane.type == SINGLE_TYPE then
        local current = redstone.getInput(lane.side)
        
        if lane.previously ~= current then
            lane.previously = current
            return true
        end
    elseif lane.type == BUNDLED_TYPE then
        local current = redstone.getBundledInput(lane.side)

        if bit32.band(lane.previously, lane.color) ~= bit32.band(current, lane.color) then
            lane.previously = current
            return true
        end
    end

    return false
end

return {
    getLane = getLane,
    getColorLane = getColorLane,
    setOutput = setOutput,
    unsetOutput = unsetOutput,
    switchOutput = switchOutput,
    getInput = getInput,
    testInputSwitch = testInputSwitch,
}
