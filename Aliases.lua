---@class SLUI
local SLUI = select(2, ...)

local roster = {
    --
    -- Sacred Lotus Roster
    -- TODO: UPDATE WITH BTAGS
    --
    ["Faulks"] = "Faulks",
    --
    ["Notdravus"] = "Dravus",
    ["Kiñgdravus"] = "Dravus",
    ["Quesõ"] = "Dravus",
    ["Eldravus"] = "Dravus",
    ["Likelydravus"] = "Dravus",
    --
    ["Biopriest"] = "Bio",
    ["Biopriesty"] = "Bio",
    ["Biomediocre"] = "Bio",
    --
    ["Treemotron"] = "Tree",
    ["Treelectron"] = "Tree",
    --
    ["Shukio"] = "Shuk",
    ["Shuwuk"] = "Shuk",
    ["Scaleywaley"] = "Shuk",
    ["Shuky"] = "Shuk",
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
    ["Bigpoopyhaha"] = "Bor",
    --
    ["Tonkachonka"] = "Tonka",
    --
    ["Rykouu"] = "Ry",
    ["Vanillascoop"] = "Ry",
    --
    ["Vyndendril"] = "Vyn",
    --
    ["Onewthmoney"] = "Voodoo",
    --
    ["Fukli"] = "Fuk",
    ["Fuklii"] = "Fuk",
    ["Fukliie"] = "Fuk",
    --
    ["Bevyn"] = "Bevyn",
    ["Kymie"] = "Bevyn",
    ["Shannye"] = "Bevyn",
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
    ["Ffxivbadgame"] = "Mai",
    ["Maidruid"] = "Mai",
    --
    ["Narkobear"] = "Narko",
    ["Narkobare"] = "Narko",
    --
    ["Stuckpoor"] = "Stuck",

    -- 
    -- GROUP 2 
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
    ["Ocharithm"] = "Pyro",
    ["Pyrorithm"] = "Pyro",
    ["Phytorithm"] = "Pyro",
    ["Sanctorithm"] = "Pyro",
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

---
---@param unit string UnitID
---@return string
function SLUI:GetNickname(unit)
    if not unit then return end
    if not UnitExists(unit) then return end

    local name = UnitName(unit)
    local guid = UnitGUID(unit)

    if name then
        local bnetInfo = C_BattleNet.GetAccountInfoByGUID(guid)
        local btag = bnetInfo and bnetInfo.battleTag or nil

        if btag and roster[btag] then
            name = roster[btag]
        elseif roster[name] then
            name = roster[name]
        end

        return name
    end
end

-- Provide our Nickname functionality to LiquidWeakAuras
function AuraUpdater:GetNickname(unit)
    return SLUI:GetNickname(unit)
end

if C_AddOns.IsAddOnLoaded("ElvUI") then
    local E = unpack(ElvUI)

    E:AddTag('name:alias', 'UNIT_NAME_UPDATE INSTANCE_ENCOUNTER_ENGAGE_UNIT', function(unit)
        return SLUI:GetNickname(unit)
    end)
    E:AddTagInfo('name:alias', 'Names', format('Nickname from the |cff00ff98%s|r', "SLUI"))

    for textFormat, length in pairs({ veryshort = 5, short = 10, medium = 15, long = 20 }) do
        local tag = format('name:alias:%s', textFormat)
        E:AddTag(tag, 'UNIT_NAME_UPDATE INSTANCE_ENCOUNTER_ENGAGE_UNIT', function(unit)
            local name = SLUI:GetNickname(unit)
            if name then
                return E:ShortenString(name, length)
            end
        end)
        E:AddTagInfo(tag, 'Names',
            format('Nickname from the |cff00ff98%s|r (limited to %d letters)', "SLUI", length))
    end
end
