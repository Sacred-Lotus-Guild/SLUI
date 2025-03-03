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

if C_AddOns.IsAddOnLoaded("Cell") and CellDB and CellDB.nicknames then
    for name, nickname in pairs(SLUI.roster) do
        if tInsertUnique(CellDB.nicknames.list, string.format("%s:%s", name, nickname)) then
            Cell:Fire("UpdateNicknames", "list-update", name, nickname)
        end
    end
end

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

if C_AddOns.IsAddOnLoaded("MRT") and GMRT and GMRT.F then
    GMRT.F:RegisterCallback("RaidCooldowns_Bar_TextName", function(_, _, data)
        if data and data.name then
            data.name = SLUI:GetNickname(data.name) or data.name
        end
    end)
end

if WeakAuras and not C_AddOns.IsAddOnLoaded("CustomNames") then
    if WeakAuras.GetName then
        WeakAuras.GetName = function(name)
            if not name then return end

            return SLUI:GetNickname(name) or name
        end
    end

    if WeakAuras.UnitName then
        WeakAuras.UnitName = function(unit)
            if not unit then return end

            local name, realm = UnitName(unit)

            if not name then return end

            return SLUI:GetNickname(unit) or name, realm
        end
    end

    if WeakAuras.GetUnitName then
        WeakAuras.GetUnitName = function(unit, showServerName)
            if not unit then return end

            if not UnitIsPlayer(unit) then
                return GetUnitName(unit)
            end

            local name = UnitNameUnmodified(unit)
            local nameRealm = GetUnitName(unit, showServerName)
            local suffix = nameRealm:match(".+(%s%(%*%))") or nameRealm:match(".+(%-.+)") or ""

            return string.format("%s%s", SLUI:GetNickname(unit) or name, suffix)
        end
    end

    if WeakAuras.UnitFullName then
        WeakAuras.UnitFullName = function(unit)
            if not unit then return end

            local name, realm = UnitFullName(unit)

            if not name then return end

            return SLUI:GetNickname(unit) or name, realm
        end
    end
end
