local addon = select(2, ...)

--- @class SLUI: AceAddon, AceEvent-3.0, AceHook-3.0
local SLUI = LibStub("AceAddon-3.0"):NewAddon(addon, "SLUI", "AceEvent-3.0", "AceHook-3.0")
setglobal("SLUI", SLUI)

--- @type AceDB.Schema
SLUI.defaults = {
    global = {
    }
}

--- @type AceConfig.OptionsTable
SLUI.options = {
    name = format("|cff00ff98%s|r v%s", "SLUI", C_AddOns.GetAddOnMetadata("SLUI", "Version")),
    type = "group",
    handler = SLUI,
    get = function(info) return SLUI.db.global[info[#info]] end,
    set = function(info, val) SLUI.db.global[info[#info]] = val end,
    args = {
        apply = {
            order = 1000,
            name = "Apply changes",
            desc = "To apply changes, you need to reload your UI.",
            type = "execute",
            func = function() return ReloadUI() end,
        },
        reset = {
            order = 1001,
            name = "Reset defaults",
            desc = "Reset configuration to the defaults.",
            type = "execute",
            confirm = true,
            confirmText = "Reset your configuration and reload UI?",
            func = function()
                SLUI.db:ResetDB(DEFAULT)
                return ReloadUI()
            end
        }
    }
}

function SLUI:OnInitialize()
    SLUI.db = LibStub("AceDB-3.0"):New("SLUIDB", SLUI.defaults, DEFAULT)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("SLUI", SLUI.options)
    local _, category = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SLUI")
    LibStub("AceConsole-3.0"):RegisterChatCommand("slui", function(input)
        if not input or input:trim() == "" then
            Settings.OpenToCategory(category)
        else
            LibStub("AceConfigCmd-3.0").HandleCommand(SLUI, "slui", "SLUI", input)
        end
    end)
end
