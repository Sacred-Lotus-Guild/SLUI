---@class SLUI: AceAddon, AceConsole-3.0, AceEvent-3.0, AceHook-3.0
local SLUI = LibStub("AceAddon-3.0"):NewAddon("SLUI", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
setglobal("SLUI", SLUI)

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigCmd = LibStub("AceConfigCmd-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")

local defaults = {
    global = {
        nicknames = {
            cell = true,
            customnames = false,
            elvui = true,
            mrt = {
                cooldowns = true,
                note = false,
            },
            omnicd = true,
            weakauras = true,
        }
    }
}

function SLUI:OnInitialize()
    self.db = AceDB:New("SLUIDB", defaults)

    local options = {
        name = "SLUI",
        type = "group",
        args = {
            nicknames = {
                name = "Nicknames",
                type = "group",
                inline = true,
                args = {
                    description = {
                        order = 1,
                        type = "description",
                        fontSize = "medium",
                        name = "Enable nickname functionality for your AddOns.",
                    },
                    cell = {
                        name = "Cell",
                        desc = "Add our nicknames to Cell's nickname database.",
                        type = "toggle",
                        width = "full",
                        get = function() return self.db.global.nicknames.cell end,
                        set = function(_, val) self.db.global.nicknames.cell = val end,
                    },
                    customnames = {
                        name = "CustomNames",
                        desc =
                        "Add our nicknames to CustomNames nickname database. If using this functionality, you probably want to disable our nickname functionality for those addons which use CustomNames to avoid conficts.",
                        type = "toggle",
                        width = "full",
                        get = function() return self.db.global.nicknames.customnames end,
                        set = function(_, val) self.db.global.nicknames.customnames = val end,
                    },
                    elvui = {
                        name = "ElvUI",
                        desc =
                        "Add [name:alias] tags to ElvUI. See Available Tags > Names for the available length options.",
                        type = "toggle",
                        width = "full",
                        get = function() return self.db.global.nicknames.elvui end,
                        set = function(_, val) self.db.global.nicknames.elvui = val end,
                    },
                    mrt = {
                        name = "MRT",
                        type = "group",
                        inline = true,
                        args = {
                            cooldowns = {
                                name = "Raid Cooldowns",
                                desc = "Replace names in MRT Raid Cooldowns tracker.",
                                type = "toggle",
                                get = function() return self.db.global.nicknames.mrt.cooldowns end,
                                set = function(_, val) self.db.global.nicknames.mrt.cooldowns = val end,
                            },
                            note = {
                                name = "Note (NYI)",
                                desc = "Replace names in MRT notes -- THIS COULD HAVE SIDE EFFECTS!",
                                type = "toggle",
                                get = function() return self.db.global.nicknames.mrt.note end,
                                set = function(_, val) self.db.global.nicknames.mrt.note = val end,
                            },
                        },
                    },
                    omnicd = {
                        name = "OmniCD",
                        desc = "Replace names in OmniCD bars and icons.",
                        type = "toggle",
                        width = "full",
                        get = function() return self.db.global.nicknames.omnicd end,
                        set = function(_, val) self.db.global.nicknames.omnicd = val end,
                    },
                    weakauras = {
                        name = "WeakAuras",
                        desc =
                        "Replace the default name handlers in WeakAuras. This will effect most WeakAuras by default, but some might have custom code for displaying names.",
                        type = "toggle",
                        width = "full",
                        get = function() return self.db.global.nicknames.weakauras end,
                        set = function(_, val) self.db.global.nicknames.weakauras = val end,
                    },
                }
            },
            apply = {
                order = 1000,
                name = "Apply changes",
                desc = "To apply changes, you need to reload your UI.",
                type = "execute",
                func = function() return ReloadUI() end,
            }
        }
    }

    AceConfig:RegisterOptionsTable("SLUI", options)
    AceConfigDialog:AddToBlizOptions("SLUI", "SLUI")
    self:RegisterChatCommand("slui", function(input)
        if not input or input:trim() == "" then
            Settings.OpenToCategory("SLUI")
        else
            AceConfigCmd.HandleCommand(self, "slui", "SLUI", input)
        end
    end)
end

function SLUI:OnEnable()
    self:EnableNicknames()
end
