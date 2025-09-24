local addon = select(2, ...)

--- @class SLUI: AceAddon, AceEvent-3.0, AceHook-3.0
local SLUI = LibStub("AceAddon-3.0"):NewAddon(addon, "SLUI", "AceEvent-3.0", "AceHook-3.0")
setglobal("SLUI", SLUI)

SLUI.defaults = {
    global = {
        nicknames = {
            cell = true,
            customnames = false,
            elvui = true,
            grid2 = true,
            mrt = {
                cooldowns = true,
                note = false,
            },
            omnicd = true,
            vuhdo = true,
            weakauras = true,
            roster = {
                --
                -- G1 Roster
                --
                ["Faulks"] = "Faulks",
                --
                ["Notdravus"] = "Dravus",
                ["Eldravus"] = "Dravus",
                ["Kiñgdravus"] = "Dravus",
                ["Dwavus"] = "Dravus",
                ["Likelydravus"] = "Dravus",
                --
                ["Biopriest"] = "Bio",
                ["Biomediocre"] = "Bio",
                --
                ["Treemotron"] = "Tree",
                ["Treelectron"] = "Tree",
                --
                ["Feritos"] = "Feritos",
                ["Feritossham"] = "Feritos",
                ["Feritosshamm"] = "Feritos",
                --
                ["Shukio"] = "Shuk",
                ["Shuwuk"] = "Shuk",
                ["Scaleywaley"] = "Shuk",
                ["Shuky"] = "Shuk",
                --
                ["Deathdraco"] = "Draco",
                --
                ["Lavernius"] = "Lav",
                ["Lavrogue"] = "Lav",
                ["Lavdk"] = "Lav",
                --
                ["Shirly"] = "Shirly",
                --
                ["Deathcen"] = "Death",
                --
                ["Snoopxd"] = "Snoop",
                --
                ["Rykouu"] = "Ry",
                --
                ["Vyndendril"] = "Vyn",
                --
                ["Onewthmoney"] = "Voodoo",
                --
                ["Víkk"] = "Vikk",
                --
                ["Bevyn"] = "Bevyn",
                ["Kymie"] = "Bevyn",
                --
                ["Chøoch"] = "Chooch",
                --
                ["Terrapher"] = "Thomas",
                --
                ["Zvonock"] = "Tao",
                ["Podooshka"] = "Tao",
                ["Taoroinai"] = "Tao",
                --
                ["Calemi"] = "Cal",
                --
                ["Dubsauce"] = "Dub",
                --
                ["Druidboy"] = "DB",
                --
                ["Maifu"] = "Mai",
                ["Maidruid"] = "Mai",
                --
                ["Narkobear"] = "Narko",
                ["Narkobare"] = "Narko",
                --
                ["Stuckpoor"] = "Stuck",
                --
                ["Schlank"] = "Schlank",
                --
                ["Impoopdollar"] = "Poopdollar",

                --
                -- G2 Roster
                --
                ["Gamerwords"] = "Drethus",
                --
                ["Jvsn"] = "Jussn",
                --
                ["Kayzle"] = "Kayzle",
                ["Kayzl"] = "Kayzle",
                --
                ["Squidword"] = "Squid",
                ["Squided"] = "Squid",
                ["Squidragosa"] = "Squid",
                ["Squidwings"] = "Squid",
                ["Squidkid"] = "Squid",
                ["Squidmist"] = "Squid",
                --
                ["Ocharithm"] = "Ryan",
                ["Pyrorithm"] = "Ryan",
                ["Phytorithm"] = "Ryan",
                ["Sanctorithm"] = "Ryan",
                ["Matcharithm"] = "Ryan",
                --
                ["Dreeks"] = "Dreeks",
                ["Dreekssham"] = "Dreeks",
                --
                ["Daenehrys"] = "Daenehrys",
                --
                ["Plazaa"] = "Plaza",
                --
                ["Azurepaly"] = "Azure",
                ["Azuresham"] = "Azure",
                ["Azuresdk"] = "Azure",
                ["Azurewar"] = "Azure",
                ["Azuredru"] = "Azure",
                --
                ["Tompally"] = "Tom",
                ["Tomxpally"] = "Tom",
                ["Tomsdh"] = "Tom",
                ["Tomsdk"] = "Tom",
                ["Tomspriestt"] = "Tom",
                ["Tomshunterr"] = "Tom",
                ["Tomxrogue"] = "Tom",
                ["Tomshaman"] = "Tom",
                ["Tomwarlockk"] = "Tom",
                ["Tomdruid"] = "Tom",
                ["Tomswarrior"] = "Tom",
                ["Tomsmonk"] = "Tom",
                ["Tommage"] = "Tom",
                --
                ["Fôrtune"] = "Fortune",
                --
                ["Låyne"] = "Layne",
                --
                ["Lilstiffsock"] = "Matt",
                ["Skrimppeener"] = "Matt",
                ["Pisspotpete"] = "Matt",
                --
                ["Lebeak"] = "Leblond",
                ["Leblond"] = "Leblond",
                --
                ["Gantark"] = "Gantark",
                ["Gartrank"] = "Gantark",
                ["Morescribers"] = "Gantark",
                --
                ["Grizzye"] = "Grizzye",
                --
                ["Asimage"] = "Asimage",
                --
                ["Whittzy"] = "Whittzy",
                ["Whiittzz"] = "Whittzy",
                --
                ["Ceravex"] = "Crux",
                ["Cruxia"] = "Crux",
                ["Faelyndra"] = "Crux",
                --
                ["Tlbs"] = "Telbi",
                ["Telbi"] = "Telbi",
                --
                ["Beilce"] = "Beilce",
                ["Glaivebeilce"] = "Beilce",
                --
                ["Reese"] = "Lincoln",
            }
        }
    }
}

function SLUI:OptionsTable()
    --- @type AceConfig.OptionsTable
    SLUI.options = {
        name = format("|cff00ff98%s|r v%s", "SLUI", C_AddOns.GetAddOnMetadata("SLUI", "Version")),
        type = "group",
        handler = SLUI,
        get = function(info) return SLUI.db.global[info[#info]] end,
        set = function(info, val) SLUI.db.global[info[#info]] = val end,
        args = {
            nicknames = {
                name = "Nicknames",
                type = "group",
                inline = true,
                args = {
                    cell = {
                        type = "group",
                        name = "Cell",
                        args = {
                            desc = {
                                order = 0,
                                name = "To enable Cell nicknames, open \"/cell options\":\n" ..
                                    "  General > Nickname > Custom Nicknames\n" ..
                                    "  Enable the \"Custom Nicknames\" checkbox",
                                type = "description",
                                fontSize = "medium",
                            },
                            toggle = {
                                name = "Add nicknames",
                                desc = "Synchronize our nicknames with Cell's nickname database.",
                                type = "toggle",
                                width = "full",
                                get = function() return SLUI.db.global.nicknames.cell end,
                                set = function(_, val) SLUI.db.global.nicknames.cell = val end,
                            },
                        },
                    },
                    customnames = {
                        name = "CustomNames",
                        type = "group",
                        desc = "testing",
                        args = {
                            desc = {
                                order = 0,
                                name = "You probably want to disable our nickname functionality " ..
                                    "for addons which use CustomNames in order to avoid conficts.",
                                type = "description",
                                fontSize = "medium",
                            },
                            toggle = {
                                name = "Add nicknames",
                                desc = "Synchronize our nicknames with CustomNames's nickname database.",
                                type = "toggle",
                                width = "full",
                                get = function() return SLUI.db.global.nicknames.customnames end,
                                set = function(_, val) SLUI.db.global.nicknames.customnames = val end,
                            },
                        },
                    },
                    elvui = {
                        name = "ElvUI",
                        type = "group",
                        args = {
                            desc = {
                                order = 0,
                                name = "To enable ElvUI nicknames, open \"/elvui\":\n" ..
                                    "  Unit Frames > Group Units > Party, Raid 2, Raid 2, or Raid 3 > Name\n" ..
                                    "  Replace \"[name]\" with \"[name:alias]\" in the \"Text Format\" input box.\n" ..
                                    "  See Available Tags > Names for the available length options.",
                                type = "description",
                                fontSize = "medium",
                            },
                            toggle = {
                                name = "Add tags",
                                desc = "Adds [name:alias] tags to ElvUI.",
                                type = "toggle",
                                width = "full",
                                get = function() return SLUI.db.global.nicknames.elvui end,
                                set = function(_, val) SLUI.db.global.nicknames.elvui = val end,
                            },
                        },
                    },
                    grid2 = {
                        name = "Grid2",
                        type = "group",
                        args = {
                            desc = {
                                order = 0,
                                name = "To enable Grid2 nicknames, open \"/grid2\":\n" ..
                                    "  Statuses > Miscellaneous > name > Indicators\n" ..
                                    "  Disable the default name indicator\n" ..
                                    "  Statuses > Miscellaneous > nickname > Indicators\n" ..
                                    "  Enable the text indicator where \"name\" was previously enabled",
                                type = "description",
                                fontSize = "medium",
                            },
                            toggle = {
                                name = "Add nickname status",
                                desc = "Add \"nickname\" status to Grid2.",
                                type = "toggle",
                                width = "full",
                                get = function() return SLUI.db.global.nicknames.grid2 end,
                                set = function(_, val) SLUI.db.global.nicknames.grid2 = val end,
                            },
                        },
                    },
                    mrt = {
                        name = "MRT",
                        type = "group",
                        inline = true,
                        args = {
                            desc = {
                                order = 0,
                                name = "When enabled, MRT nicknames are automatically applied.",
                                type = "description",
                                fontSize = "medium",
                            },
                            cooldowns = {
                                name = "Raid Cooldowns",
                                desc = "Replace names in MRT Raid Cooldowns tracker.",
                                type = "toggle",
                                get = function() return SLUI.db.global.nicknames.mrt.cooldowns end,
                                set = function(_, val) SLUI.db.global.nicknames.mrt.cooldowns = val end,
                            },
                            note = {
                                name = "Note",
                                desc = "Replace names in MRT notes. " ..
                                    "This should not change the actual note text as parsed by WeakAuras.",
                                type = "toggle",
                                get = function() return SLUI.db.global.nicknames.mrt.note end,
                                set = function(_, val) SLUI.db.global.nicknames.mrt.note = val end,
                            },
                        },
                    },
                    omnicd = {
                        name = "OmniCD",
                        type = "group",
                        args = {
                            desc = {
                                order = 0,
                                name = "When enabled, OmniCD nicknames are automatically applied.",
                                type = "description",
                                fontSize = "medium",
                            },
                            toggle = {
                                name = "Replace names",
                                desc = "Replace names in OmniCD bars and icons.",
                                type = "toggle",
                                width = "full",
                                get = function() return SLUI.db.global.nicknames.omnicd end,
                                set = function(_, val) SLUI.db.global.nicknames.omnicd = val end,
                            },
                        },
                    },
                    vuhdo = {
                        name = "VuhDo",
                        type = "group",
                        args = {
                            desc = {
                                order = 0,
                                name = "When enabled, VuhDo nicknames are automatically applied.",
                                type = "description",
                                fontSize = "medium",
                            },
                            toggle = {
                                name = "Replace names",
                                desc = "Replace names in VuhDo bars.",
                                type = "toggle",
                                width = "full",
                                get = function() return SLUI.db.global.nicknames.vuhdo end,
                                set = function(_, val) SLUI.db.global.nicknames.vuhdo = val end,
                            },
                        },
                    },
                    weakauras = {
                        name = "WeakAuras",
                        type = "group",
                        args = {
                            desc = {
                                order = 0,
                                name = "When enabled, WeakAura nicknames are automatically applied to *most* WeakAuras.",
                                type = "description",
                                fontSize = "medium",
                            },
                            toggle = {
                                name = "Replace names",
                                desc = "Replace the default name handlers in WeakAuras.",
                                type = "toggle",
                                width = "full",
                                get = function() return SLUI.db.global.nicknames.weakauras end,
                                set = function(_, val) SLUI.db.global.nicknames.weakauras = val end,
                            },
                        },
                    },
                    roster = {
                        order = -1,
                        name = "Roster",
                        type = "group",
                        args = {
                            new = {
                                order = -1,
                                name = "New nickname",
                                type = "input",
                                width = "full",
                                validate = function(_, val)
                                    local name, nickname = val:trim():match("([^:]+):([^:]+)")
                                    if not name or not nickname then
                                        return "Enter a nickname in the format \"Name:Nickname\""
                                    elseif SLUI.defaults.global.nicknames.roster[name] then
                                        return "You cannot override the existing Sacred Lotus roster nicknames."
                                    else
                                        return true
                                    end
                                end,
                                set = function(_, val)
                                    local name, nickname = val:trim():match("([^:]+):([^:]+)")
                                    SLUI:AddNickname(name, nickname)
                                end,
                            }
                        }
                    }
                }
            },
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

    for k, v in pairs(SLUI.db.global.nicknames.roster) do
        local isDefault = SLUI.defaults.global.nicknames.roster[k] ~= nil
        SLUI.options.args.nicknames.args.roster.args[k] = {
            order = isDefault and 1 or 100,
            name = format("%s:%s", k, v),
            type = "toggle",
            width = "full",
            disabled = isDefault,
            get = function() return true end,
            set = function(_, val)
                if val == false then
                    SLUI.db.global.nicknames.roster[k] = nil
                end
            end,
            confirm = true,
            confirmText = format("Delete the configured nickname for %s?", k),
        }
    end

    return SLUI.options
end

function SLUI:OnInitialize()
    SLUI.db = LibStub("AceDB-3.0"):New("SLUIDB", SLUI.defaults, DEFAULT)
    -- overwrite any old custom nicknames with defaults that may have been added.
    for k, v in pairs(SLUI.defaults.global.nicknames.roster) do
        SLUI.db.global.nicknames.roster[k] = v
    end
    SLUI.roster = SLUI.db.global.nicknames.roster

    LibStub("AceConfig-3.0"):RegisterOptionsTable("SLUI", function() return SLUI:OptionsTable() end)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SLUI")
    LibStub("AceConsole-3.0"):RegisterChatCommand("slui", function(input)
        if not input or input:trim() == "" then
            Settings.OpenToCategory("SLUI")
        else
            LibStub("AceConfigCmd-3.0").HandleCommand(SLUI, "slui", "SLUI", input)
        end
    end)
end

function SLUI:OnEnable()
    SLUI:EnableNicknames()
end
