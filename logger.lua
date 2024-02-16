
local logger = {
    level = -1,
    DISABLED = -1,
    ERROR = 0,
    WARNING = 1,
    INFO = 2,
    VERBOSE = 3,
    REPEAT = 4,

    DEFAULT_LEVEL = 2,
}

local log_color = {
    [logger.ERROR] = colors.red,
    [logger.WARNING] = colors.yellow,
    [logger.INFO] = colors.white,
    [logger.VERBOSE] = colors.lightGray,
    [logger.REPEAT] = colors.lightGray,
}

local function printColored(col, ...)
    local prevColor = term.getTextColor()
    term.setTextColor(col)

    print(...)

    term.setTextColor(prevColor)
end

function logger.log(msg, level)
    if level == nil then
        level = logger.DEFAULT_LEVEL
    end 

    if logger.level >= level then
        local col = log_color[level] or colors.white

        printColored(col, msg)
    end
end

return logger
