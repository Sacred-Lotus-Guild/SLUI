local SLUI = select(2, ...)

local reminderDefinitions = {
    { 
        name = "Feast",
        defaultMessage = "Feast Down",
        ids = {160914},
    },
    {
        name = "Hover",
        defaultMessage = "Hover Up",
        ids = {358267},
    }
}

----------------------------------------------------------------------------------------

local CHANNELS = {"Master", "Music", "SFX", "Ambience", "Dialog"}
SLUI.reminders = {}
SLUI.reminders.idToName = {}
for _, reminder in ipairs(reminderDefinitions) do
    for _, id in ipairs(reminder.ids) do
        SLUI.reminders.idToName[id] = reminder.name
    end
end

function SLUI.reminders:GetReminderData(name)
    return SLUI.defaults.global.reminders[name]
end

SLUI.defaults.global.reminders = {
    common = {
        sound = "",
        soundChannel = "Master",
        font = "PT Sans Narrow",
        fontSize = 30,
        timeOnScreen = 5,
    } 
}

SLUI.options.args.reminders = {
    name = "Reminders",
    type = "group",
}

local reminderOptions = {
    sound = {
        type = "select",
        name = "Sound",
        get = function(info)
            for i, v in next, SLUI.media:List("sound") do
                if v == SLUI.db.global.reminders.common.sound then
                    return i
                end
            end
        end,
        set = function(info, value) SLUI.db.global.reminders.common.sound = SLUI.media:List("sound")[value] end,
        values = SLUI.media:List("sound"),
        width = "double",
        order = 0,
    },

    soundChannel = {
        name = "Sound Channel",
        type = "select",
        set = function(info,value) SLUI.db.global.reminders.common.soundChannel = CHANNELS[value] end,
        get = function(info) 
            for i, c in ipairs(CHANNELS) do
                if c == SLUI.db.global.reminders.common.soundChannel then
                    return i
                end
            end
        end,
        values = CHANNELS,
        width = "normal",
        order = 1
    },

    font = {
        type = "select",
        name = "Font",
        get = function(info)
            for i, v in next, SLUI.media:List("font") do
                if v == SLUI.db.global.reminders.common.font then
                    return i
                end
            end
        end,
        set = function(info, value) SLUI.db.global.reminders.common.font = SLUI.media:List("font")[value] end,
        values = SLUI.media:List("font"),
        width = "double",
        order = 5,
    },

    textSize = {
        name = "Text Size",
        type = "range",
        min = 5,
        max = 60,
        bigStep = 1,
        set = function(info,value) SLUI.db.global.reminders.common.fontSize = value end,
        get = function(info) return SLUI.db.global.reminders.common.fontSize end,
        width = "normal",
        order = 6
    },

    timeOnScreen = {
        name = "Time On Screen",
        type = "range",
        min = 0,
        max = 10,
        bigStep = 0.1,
        set = function(info,value) SLUI.db.global.reminders.common.timeOnScreen = value end,
        get = function(info) return SLUI.db.global.reminders.common.timeOnScreen end,
        width = "normal",
        order = 10
    },

    resetDefaultsButton = {
        name = "Reset to Defaults",
        type = "execute",
        width = "normal",
        func = function() SLUI.db:ResetProfile() end,
        order = 90
    },

    previewButton = {
        name = "Test",
        type = "execute",
        width = "normal",
        func = function() TimeSpiralTracker:ShowPreview() end,
        order = 91
    },
}

for i, reminder in ipairs(reminderDefinitions) do
    SLUI.defaults.global.reminders[reminder.name] = {
        message = reminder.defaultMessage or "<empty>",
    }

    reminderOptions[reminder.name] = {
        type = "group",
        name = reminder.name,
        args = {
            message = {
                name = "Message",
                type = "input",
                set = function(info,value) SLUI.db.global.reminders[reminder.name].message = value  end,
                get = function(info) return SLUI.db.global.reminders[reminder.name].message end,
                width = "normal",
                order = 0
            },
        },
        order = 10 + i * 5
    }
end
SLUI.options.args.reminders.args = reminderOptions