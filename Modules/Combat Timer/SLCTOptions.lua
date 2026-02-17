--[[ local SLUI = select(2,...)

SLUI.options.args.timer = {
    name = "Combat Timer",
    type = "group",
}
local timerOptions {
    font = {
        type = "select",
        name = "Font",
        get = function(info)
            for i, v in next, SLUI.media:List(SLUI.media.MediaType.FONT) do
                if v == SLUI.db.global.timer.common.font then
                    return i
                end
            end
        end,
        set = function(info, value) SLUI.db.global.timer.common.font = SLUI.media:List(SLUI.media.MediaType.FONT)[value] end,
        values = SLUI.media:List(SLUI.media.MediaType.FONT),
        width = "double",
        order = 0,
    },
}

SLUI.options.args.timer.args = timerOptions ]]