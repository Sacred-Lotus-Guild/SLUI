local addon = select(2, ...)

--- @class SLUI: AceAddon, AceEvent-3.0, AceHook-3.0
local SLUI = LibStub("AceAddon-3.0"):NewAddon(addon, "SLUI", "AceEvent-3.0", "AceHook-3.0", "AceComm-3.0")
SLUI.media = LibStub("LibSharedMedia-3.0")
setglobal("SLUI", SLUI)

SLUI.defaults = {
    global = {}
}

SLUI.options = {
    name = format("|cff00ff98%s|r v%s", "SLUI", C_AddOns.GetAddOnMetadata("SLUI", "Version")),
    type = "group",
    childGroups = "tab",
    handler = SLUI,
    get = function(info) return SLUI.db.global[info[#info]] end,
    set = function(info, val) SLUI.db.global[info[#info]] = val end,
    args = {}
}

function SLUI:OnInitialize()
    SLUI.db = LibStub("AceDB-3.0"):New("SLUIDB", SLUI.defaults, DEFAULT)

    LibStub("AceConfig-3.0"):RegisterOptionsTable("SLUI", function() return SLUI.options end)
    local _, id = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SLUI")
    LibStub("AceConsole-3.0"):RegisterChatCommand("slui", function(input)
        if not input or input:trim() == "" then
            Settings.OpenToCategory(id)
        else
            LibStub("AceConfigCmd-3.0").HandleCommand(SLUI, "slui", "SLUI", input)
        end
    end)
end

