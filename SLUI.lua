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
                ["Holypud"] = "Pud",
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
                ["Shukio"] = "Shuk",
                ["Shuwuk"] = "Shuk",
                ["Scaleywaley"] = "Shuk",
                ["Shuky"] = "Shuk",
                --
                ["Bevyn"] = "Bevyn",
                ["Kymie"] = "Bevyn",
                --
                ["Chøoch"] = "Chooch",
                --
                ["Terrapher"] = "Thomas",
                --
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
    self.options = {
        name = "SLUI",
        type = "group",
        -- icon = [[Interface\AddOns\SLUI\Media\Textures\logo.blp]],
        handler = self,
        get = function(info) return self.db.global[info[#info]] end,
        set = function(info, val) self.db.global[info[#info]] = val end,
        args = {
            nicknames = {
                name = "Nicknames",
                type = "group",
                inline = true,
                args = {
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
                        desc = "Add our nicknames to CustomNames.\n\n" ..
                            "When doing so you probably want to disable our nickname functionality for those addons which use CustomNames in order to avoid conficts.",
                        type = "toggle",
                        width = "full",
                        get = function() return self.db.global.nicknames.customnames end,
                        set = function(_, val) self.db.global.nicknames.customnames = val end,
                    },
                    elvui = {
                        name = "ElvUI",
                        desc = "Add [name:alias] tags to ElvUI. " ..
                            "See Available Tags > Names for the available length options.",
                        type = "toggle",
                        width = "full",
                        get = function() return self.db.global.nicknames.elvui end,
                        set = function(_, val) self.db.global.nicknames.elvui = val end,
                    },
                    grid2 = {
                        name = "Grid2",
                        desc = "Add \"nickname\" status to Grid2.",
                        type = "toggle",
                        width = "full",
                        get = function() return self.db.global.nicknames.grid2 end,
                        set = function(_, val) self.db.global.nicknames.grid2 = val end,
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
                                name = "Note",
                                desc = "Replace names in MRT notes. " ..
                                    "Should not change the actual note text as read by WeakAuras.",
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
                    vuhdo = {
                        name = "VuhDo",
                        desc = "Replace names in VuhDo bars.",
                        type = "toggle",
                        width = "full",
                        get = function() return self.db.global.nicknames.vuhdo end,
                        set = function(_, val) self.db.global.nicknames.vuhdo = val end,
                    },
                    weakauras = {
                        name = "WeakAuras",
                        desc = "Replace the default name handlers in WeakAuras. " ..
                            "This will effect most WeakAuras by default, but some might have custom code for displaying names.",
                        type = "toggle",
                        width = "full",
                        get = function() return self.db.global.nicknames.weakauras end,
                        set = function(_, val) self.db.global.nicknames.weakauras = val end,
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
                                    local name, nickname = val:trim():match("(%a+):(%a+)")
                                    if not name or not nickname then
                                        return "Enter a nickname in the format \"Name:Nickname\""
                                    elseif self.defaults.global.nicknames.roster[name] then
                                        return "You cannot override the existing Sacred Lotus roster nicknames."
                                    else
                                        return true
                                    end
                                end,
                                set = function(_, val)
                                    local name, nickname = val:trim():match("(%a+):(%a+)")
                                    self:AddNickname(name, nickname)
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
                    self.db:ResetDB(DEFAULT)
                    return ReloadUI()
                end
            }
        }
    }

    for k, v in pairs(self.db.global.nicknames.roster) do
        local isDefault = self.defaults.global.nicknames.roster[k] ~= nil
        self.options.args.nicknames.args.roster.args[k] = {
            order = isDefault and 1 or 100,
            name = string.format("%s:%s", k, v),
            type = "toggle",
            width = "full",
            disabled = isDefault,
            get = function() return true end,
            set = function(_, val)
                if val == false then
                    self.db.global.nicknames.roster[k] = nil
                end
            end,
            confirm = true,
            confirmText = string.format("Delete the configured nickname for %s?", k),
        }
    end

    return self.options
end

function SLUI:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("SLUIDB", self.defaults, DEFAULT)
    -- overwrite any old custom nicknames with defaults that may have been added.
    for k, v in pairs(self.defaults.global.nicknames.roster) do
        self.db.global.nicknames.roster[k] = v
    end
    self.roster = self.db.global.nicknames.roster

    LibStub("AceConfig-3.0"):RegisterOptionsTable("SLUI", function() return self:OptionsTable() end)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SLUI", "SLUI")
    LibStub("AceConsole-3.0"):RegisterChatCommand("slui", function(input)
        if not input or input:trim() == "" then
            Settings.OpenToCategory("SLUI")
        else
            LibStub("AceConfigCmd-3.0").HandleCommand(self, "slui", "SLUI", input)
        end
    end)
end

function SLUI:OnEnable()
    self:EnableNicknames()
end
