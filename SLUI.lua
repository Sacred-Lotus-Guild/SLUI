local addon = select(2, ...)

---@class SLUI: AceAddon, AceHook-3.0
local SLUI = LibStub("AceAddon-3.0"):NewAddon(addon, "SLUI", "AceHook-3.0")
setglobal("SLUI", SLUI)

---@type AceDB.Schema
SLUI.defaults = {
    global = {}
}

---@type AceConfig.OptionsTable
SLUI.options = {
    name = format("|cff00ff98%s|r v%s", "SLUI", C_AddOns.GetAddOnMetadata("SLUI", "Version")),
    type = "group",
    childGroups = "tab",
    args = {
        apply = {
            order = 1000,
            name = "Apply changes",
            desc = "To apply changes, you might need to reload your UI.",
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
            end,
        },
    },
}

SLUI.ANCHOR_POINTS = {
    ["TOPLEFT"] = "TOPLEFT",
    ["TOP"] = "TOP",
    ["TOPRIGHT"] = "TOPRIGHT",
    ["LEFT"] = "LEFT",
    ["CENTER"] = "CENTER",
    ["RIGHT"] = "RIGHT",
    ["BOTTOMLEFT"] = "BOTTOMLEFT",
    ["BOTTOM"] = "BOTTOM",
    ["BOTTOMRIGHT"] = "BOTTOMRIGHT",
}

--- Log data to DevTool if it's available. Useful for debugging without spamming
--- the chat.
---@param data any
---@param dataName? string
function SLUI:Debug(data, dataName)
    if DevTool and data then
        DevTool:AddData(data, format("[SLUI] %s", dataName or "Debug"))
    end
end

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
