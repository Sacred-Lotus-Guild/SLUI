---@class SLUI
local SLUI = LibStub("AceAddon-3.0"):GetAddon("SLUI")
local CustomNames = C_AddOns.IsAddOnLoaded("CustomNames") and LibStub("CustomNames")

SLUI.roster = {
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
    ["Schlank"] = "Schlank",
    -- <3
    ["Shukio"] = "Shuk",
    ["Shuwuk"] = "Shuk",
    ["Scaleywaley"] = "Shuk",
    ["Shuky"] = "Shuk",

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

--- Retrieve a unit's configured nickname, given UnitID or character name.
--- @param unit string UnitID
--- @return string|nil
function SLUI:GetNickname(unit)
    if not unit or not UnitExists(unit) then return end
    local name = UnitNameUnmodified(unit)
    return self.roster[name] or name
end

--- Add a nickname to the existing roster.
--- @param name string
--- @param nickname string
function SLUI:AddNickname(name, nickname)
    self.roster[name] = nickname
    self:AddCellNickname(name, nickname)
    self:AddCustomName(name, nickname)
end

--- Provide our Nickname functionality to LiquidWeakAuras
function AuraUpdater:GetNickname(unit)
    return SLUI:GetNickname(unit)
end

--- Add a nickname to Cell's nickname database.
--- @param name string
--- @param nickname string
function SLUI:AddCellNickname(name, nickname)
    if self.db.global.nicknames.cell and C_AddOns.IsAddOnLoaded("Cell") and Cell and CellDB then
        if tInsertUnique(CellDB.nicknames.list, string.format("%s:%s", name, nickname)) then
            Cell.Fire("UpdateNicknames", "list-update", name, nickname)
        end
    end
end

--- Add a nickname to the CustomNames database.
--- @param name string
--- @param nickname string
function SLUI:AddCustomName(name, nickname)
    if self.db.global.nicknames.customnames and CustomNames then
        CustomNames.Set(name, nickname)
    end
end

--- Add ElvUI tags
function SLUI:EnableElvUI()
    if self.db.global.nicknames.elvui and C_AddOns.IsAddOnLoaded("ElvUI") and ElvUI then
        local E = unpack(ElvUI)

        E:AddTag('name:alias', 'UNIT_NAME_UPDATE INSTANCE_ENCOUNTER_ENGAGE_UNIT', function(unit)
            return SLUI:GetNickname(unit)
        end)
        E:AddTagInfo('name:alias', 'Names', format('Nickname from |cff00ff98%s|r', "SLUI"))

        for textFormat, length in pairs({ veryshort = 5, short = 10, medium = 15, long = 20 }) do
            local tag = format('name:alias:%s', textFormat)
            E:AddTag(tag, 'UNIT_NAME_UPDATE INSTANCE_ENCOUNTER_ENGAGE_UNIT', function(unit)
                local name = SLUI:GetNickname(unit)
                if name then
                    return E:ShortenString(name, length)
                end
            end)
            E:AddTagInfo(tag, 'Names', format('Nickname from |cff00ff98%s|r (limited to %d letters)', "SLUI", length))
        end
    end
end

--- Enable (the enabled) MRT overrides
function SLUI:EnableMRT()
    if C_AddOns.IsAddOnLoaded("MRT") and GMRT then
        -- Replace names in MRT cooldown bars.
        if self.db.global.nicknames.mrt.cooldowns then
            GMRT.F:RegisterCallback("RaidCooldowns_Bar_TextName", function(_, bar, gsubData, barData)
                local name = SLUI:GetNickname(barData.name)
                gsubData.name = name
                if gsubData.name_time == barData.name then
                    gsubData.name_time = name
                end
                if gsubData.name_stime == barData.name then
                    gsubData.name_stime = name
                end
            end)
        end

        if self.db.global.nicknames.mrt.note then
            GMRT.F:RegisterCallback("Note_UpdateText", function(_, noteFrame)
                local text = noteFrame.text:GetText()
                if not text then return end

                local replacements = {}
                for name in text:gmatch("|c%x%x%x%x%x%x%x%x(.-)|r") do -- match all color coded phrases
                    if not replacements[name] then
                        local nickname = SLUI:GetNickname(name)
                        if nickname ~= name then
                            replacements[name] = nickname
                        end
                    end
                end

                for name, nickname in pairs(replacements) do
                    text = text:gsub("|c(%x%x%x%x%x%x%x%x)" .. name .. "|r", "|c%1" .. nickname .. "|r")
                end

                if text ~= noteFrame.text:GetText() then
                    noteFrame.text:SetText(text)
                end
            end)
        end
    end
end

--- Replace OmniCD Names
function SLUI:EnableOmniCD()
    if self.db.global.nicknames.omnicd and C_AddOns.IsAddOnLoaded("OmniCD") and OmniCD then
        local P = OmniCD[1].Party

        -- Patch the existing `UpdateUnitBar` function to overwrite `name` and
        -- `nameWithoutRealm` before it executes.
        local UpdateUnitBar = P.UpdateUnitBar
        function P:UpdateUnitBar(guid, isUpdateBarsOrGRU)
            local info = self.groupInfo[guid]
            info.name = SLUI:GetNickname(info.unit)
            info.nameWithoutRealm = info.name

            return UpdateUnitBar(self, guid, isUpdateBarsOrGRU)
        end
    end
end

--- Override WeakAura functions if CustomNames is not already installed and doing the same.
function SLUI:EnableWeakAuras()
    if self.db.global.nicknames.weakauras and WeakAuras and not CustomNames then
        function WeakAuras.GetName(name)
            return SLUI:GetNickname(name)
        end

        function WeakAuras.UnitName(unit)
            local _, realm = UnitName(unit)
            return SLUI:GetNickname(unit), realm
        end

        function WeakAuras.GetUnitName(unit, showServerName)
            local name = SLUI:GetNickname(unit)
            local _, realm = UnitName(unit);
            local relationship = UnitRealmRelationship(unit);
            if (realm and realm ~= "") then
                if (showServerName) then
                    return name .. "-" .. realm;
                else
                    if (relationship == LE_REALM_RELATION_VIRTUAL) then
                        return name;
                    else
                        return name .. FOREIGN_SERVER_LABEL;
                    end
                end
            else
                return name;
            end
        end

        function WeakAuras.UnitFullName(unit)
            local _, realm = UnitFullName(unit)
            return SLUI:GetNickname(unit), realm
        end
    end
end

function SLUI:EnableNicknames()
    for name, nickname in pairs(self.roster) do
        self:AddCellNickname(name, nickname)
        self:AddCustomName(name, nickname)
    end

    self:EnableElvUI()
    self:EnableMRT()
    self:EnableOmniCD()
    self:EnableWeakAuras()
end
