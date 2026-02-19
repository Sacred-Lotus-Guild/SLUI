local SLUI = select(2,...)

-- Defaults
SLUI.defaults.global.timer = {
    enabled = false,
    lock = true,
    font = "PT Sans Narrow",
    fontSize = 28,
    showBrackets = true,
    positions = {
        [1] = { point = "CENTER", x = 0, y = -100 },  -- Tank
        [2] = { point = "CENTER", x = 0, y = -100 },  -- Healer
        [3] = { point = "CENTER", x = 0, y = -100 },  -- DPS
    }
}

SLUI.options.args.timer = {
    name = "Combat Timer",
    type = "group",
}

local fonts = SLUI.media:List(SLUI.media.MediaType.FONT)

local function RefreshTimer()
    local module = SLUI:GetModule("SLCT", true)
    if module and module.ApplySettings then
        module:ApplySettings()
    end
end

local function TimerDisabled()
    return not SLUI.db.global.timer.enabled
end

local timerOptions = {
    enabled = {
        name = "Enabled",
        type = "toggle",
        get = function() return SLUI.db.global.timer.enabled end,
        set = function(_,value) SLUI.db.global.timer.enabled = value end,
        width = "normal",
        order = 0,
    },
    lock = {
        name = "Lock",
        type = "toggle",
        get = function() return SLUI.db.global.timer.lock end,
        set = function(_, value)
            local module = SLUI:GetModule("SLCT", true)
            if module then
                module:SetLocked(value)
            end
        end,
        width = "double",
        disabled = TimerDisabled,
        order = 1,
    },
    font = {
        type = "select",
        name = "Font",
        values = fonts,
        get = function()
            for i, v in ipairs(fonts) do
                if v == SLUI.db.global.timer.font then
                    return i
                end
            end
        end,
        set = function(_, value)
            SLUI.db.global.timer.font = fonts[value]
            RefreshTimer()
        end,
        width = 1.2,
        disabled = TimerDisabled,
        order = 2,
    },
    textSize = {
        name = "Text Size",
        type = "range",
        min = 5,
        max = 60,
        bigStep = 1,
        get = function() return SLUI.db.global.timer.fontSize end,
        set = function(_, value) SLUI.db.global.timer.fontSize = value RefreshTimer() end,
        width = "normal",
        disabled = TimerDisabled,
        order = 3,
    },
    showBrackets = {
        name = "Brackets",
        type = "toggle",
        get = function() return SLUI.db.global.timer.showBrackets end,
        set = function(_,value) SLUI.db.global.timer.showBrackets = value RefreshTimer() end,
        width = "normal",
        disabled = TimerDisabled,
        order = 4,
    },
}

SLUI.options.args.timer.args = timerOptions