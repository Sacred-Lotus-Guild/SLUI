---@class SLUI
local SLUI = select(2, ...)

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

-- Provide our Nickname functionality to LiquidWeakAuras
function AuraUpdater:GetNickname(unit)
    return SLUI:GetNickname(unit)
end

local isCellInstalled = C_AddOns.IsAddOnLoaded("Cell") and Cell and CellDB and CellDB.nicknames
local CustomNames = C_AddOns.IsAddOnLoaded("CustomNames") and LibStub("CustomNames")
for name, nickname in pairs(SLUI.roster) do
    -- Add nickname to Cell's nickname database.
    if isCellInstalled then
        if tInsertUnique(CellDB.nicknames.list, string.format("%s:%s", name, nickname)) then
            Cell:Fire("UpdateNicknames", "list-update", name, nickname)
        end
    end

    if CustomNames then
        CustomNames.Set(name, nickname)
    end
end

-- Add ElvUI tags
if C_AddOns.IsAddOnLoaded("ElvUI") and ElvUI then
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

-- Replace names in MRT cooldown bars.
if C_AddOns.IsAddOnLoaded("MRT") and GMRT and GMRT.F then
    GMRT.F:RegisterCallback("RaidCooldowns_Bar_TextName", function(_, _, data)
        if data and data.name then
            data.name = SLUI:GetNickname(data.name) or data.name
        end
    end)
end

-- Override WeakAura functions if CustomNames is not already installed and doing the same.
if WeakAuras and not CustomNames then
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
