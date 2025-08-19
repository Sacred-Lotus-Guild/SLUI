--- @class SLUI
local SLUI = select(2, ...)
local CustomNames = C_AddOns.IsAddOnLoaded("CustomNames") and LibStub("CustomNames")

--- Retrieve a unit's configured nickname, given UnitID or character name.
--- @param unit string UnitID
--- @return string|nil
function SLUI:GetNickname(unit)
    if unit and UnitExists(unit) then
        local name = UnitNameUnmodified(unit)
        return name and SLUI.roster[name] or name
    else
        return SLUI.roster[unit] or unit
    end
end

--- Add a nickname to the existing roster.
--- @param name string
--- @param nickname string
function SLUI:AddNickname(name, nickname)
    SLUI.roster[name] = nickname
    SLUI:AddCellNickname(name, nickname)
    SLUI:AddCustomName(name, nickname)
end

--- Remove duplicate nicknames from the Cell database.
function SLUI:PruneCellNicknames()
    if SLUI.db.global.nicknames.cell and C_AddOns.IsAddOnLoaded("Cell") and CellDB then
        for i, entry in pairs(CellDB.nicknames.list) do
            local name, nickname = entry:match("([^:]+):([^:]+)")

            if nickname ~= SLUI.roster[name] then
                table.remove(CellDB.nicknames.list, i)
            end
        end
    end
end

--- Add a nickname to Cell's nickname database.
--- @param name string
--- @param nickname string
function SLUI:AddCellNickname(name, nickname)
    if SLUI.db.global.nicknames.cell and C_AddOns.IsAddOnLoaded("Cell") and Cell and CellDB then
        if tInsertUnique(CellDB.nicknames.list, format("%s:%s", name, nickname)) then
            Cell.Fire("UpdateNicknames", "list-update", name, nickname)
        end
    end
end

--- Add a nickname to the CustomNames database.
--- @param name string
--- @param nickname string
function SLUI:AddCustomName(name, nickname)
    if SLUI.db.global.nicknames.customnames and CustomNames then
        CustomNames.Set(name, nickname)
    end
end

--- Add ElvUI tags
function SLUI:EnableElvUI()
    if SLUI.db.global.nicknames.elvui and C_AddOns.IsAddOnLoaded("ElvUI") and ElvUI then
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

---
function SLUI:EnableGrid2()
    if SLUI.db.global.nicknames.grid2 and C_AddOns.IsAddOnLoaded("Grid2") and Grid2 then
        local Nickname = Grid2.statusPrototype:new("nickname")
        Nickname.IsActive = Grid2.statusLibrary.IsActive

        function Nickname:UNIT_NAME_UPDATE(_, unit)
            self:UpdateIndicators(unit)
        end

        function Nickname:OnEnable()
            self:RegisterEvent("UNIT_NAME_UPDATE")
        end

        function Nickname:OnDisable()
            self:UnregisterEvent("UNIT_NAME_UPDATE")
        end

        function Nickname:GetText(unit)
            return SLUI:GetNickname(unit)
        end

        function Nickname:GetTooltip(unit, tip)
            tip:SetUnit(unit)
        end

        Grid2.setupFunc["nickname"] = function(baseKey, dbx)
            Grid2:RegisterStatus(Nickname, { "text", "tooltip" }, baseKey, dbx)
            return Nickname
        end

        Grid2:DbSetStatusDefaultValue("nickname", { type = "nickname" })

        -- this doesn't seem to be called automatically, maybe we're running too late?
        Grid2.setupFunc["nickname"]("nickname", { type = "nickname" })

        SLUI:RegisterEvent("ADDON_LOADED", function(_, addOnName)
            if addOnName == "Grid2Options" and Grid2Options then
                Grid2Options:RegisterStatusOptions("nickname", "misc", function() end, {
                    titleIcon = "Interface\\AddOns\\SLUI\\Media\\Textures\\logo.blp",
                })
            end
        end)
    end
end

local oldText, newText
function SLUI:MRTNoteUpdateText(noteFrame)
    local text = noteFrame and noteFrame.text and noteFrame.text:GetText()
    if not text or not SLUI.db.global.nicknames.mrt.note then return end
    if oldText and text == oldText and newText then
        noteFrame.text:SetText(newText)
        return
    end

    oldText = text
    local replacements = {}

    -- match all color-coded name strings
    for name in text:gmatch("|c%x%x%x%x%x%x%x%x(.-)|r") do
        local nickname = SLUI:GetNickname(name)
        if nickname ~= name then
            replacements[name] = nickname
        end
    end

    for name, nickname in pairs(replacements) do
        text = text:gsub("|c(%x%x%x%x%x%x%x%x)" .. name .. "|r", "|c%1" .. nickname .. "|r")
    end

    newText = text
    if text ~= oldText then
        noteFrame.text:SetText(text)
    end
end

--- Enable (the enabled) MRT overrides
function SLUI:EnableMRT()
    if C_AddOns.IsAddOnLoaded("MRT") and GMRT then
        -- Replace names in MRT cooldown bars.
        if SLUI.db.global.nicknames.mrt.cooldowns then
            GMRT.F:RegisterCallback("RaidCooldowns_Bar_TextName", function(_, _, gsubData, barData)
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

        if SLUI.db.global.nicknames.mrt.note then
            SLUI:MRTNoteUpdateText(MRTNote)
            GMRT.F:RegisterCallback("Note_UpdateText", function(_, noteFrame)
                SLUI:MRTNoteUpdateText(noteFrame)
            end)
        end
    end
end

--- Replace OmniCD Names
function SLUI:EnableOmniCD()
    if SLUI.db.global.nicknames.omnicd and C_AddOns.IsAddOnLoaded("OmniCD") and OmniCD then
        local P = OmniCD[1].Party
        SLUI:RawHook(P, "CreateUnitInfo", function(_self, unit, guid, _, level, class, raceID, _)
            local name = SLUI:GetNickname(unit)
            return SLUI.hooks[P]["CreateUnitInfo"](_self, unit, guid, name, level, class, raceID, name)
        end)
    end
end

--- @param unit string
--- @param nameText FontString
--- @param buttonName string
function SLUI:UpdateVuhDoName(unit, nameText, buttonName)
    local name = SLUI:GetNickname(unit)

    -- Respect the max character option (if set)
    local panelNumber = buttonName and buttonName:match("^Vd(%d+)")
    panelNumber = tonumber(panelNumber)

    local maxChars = panelNumber and SLUI.vuhDoPanelSettings[panelNumber] and
        SLUI.vuhDoPanelSettings[panelNumber].maxChars
    if name and maxChars and maxChars > 0 then
        name = name:sub(1, maxChars)
    end

    nameText:SetFormattedText(name or "") -- SetText is hooked, so we use this instead
end

--- Hook VUHDO_getBarText function to apply our nicknames.
function SLUI:EnableVuhDo()
    if SLUI.db.global.nicknames.vuhdo and C_AddOns.IsAddOnLoaded("VuhDo") and VUHDO_PANEL_SETUP then
        SLUI.vuhDoPanelSettings = {}

        if VUHDO_PANEL_SETUP then
            for i, settings in pairs(VUHDO_PANEL_SETUP) do
                SLUI.vuhDoPanelSettings[i] = settings.PANEL_COLOR and settings.PANEL_COLOR.TEXT
            end
        end

        SLUI:SecureHook("VUHDO_getBarText", function(unitHealthBar)
            local unitFrameName = unitHealthBar and unitHealthBar.GetName and unitHealthBar:GetName()
            if not unitFrameName then return end

            local nameText = _G[unitFrameName .. "TxPnlUnN"]
            if not nameText then return end
            if SLUI:IsHooked(nameText, "SetText") then return end

            local unitButton = _G[unitFrameName:match("(.+)BgBarIcBarHlBar")]
            if not unitButton then return end

            SLUI:SecureHook(nameText, "SetText", function(_self)
                SLUI:UpdateVuhDoName(unitButton.raidid, _self, unitFrameName)
            end)
        end)
    end
end

--- Override WeakAura functions if CustomNames is not already installed and doing the same.
function SLUI:EnableWeakAuras()
    if SLUI.db.global.nicknames.weakauras and WeakAuras and not CustomNames then
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
    --- Provide our Nickname functionality to LiquidWeakAuras
    function AuraUpdater:GetNickname(unit)
        return SLUI:GetNickname(unit)
    end

    SLUI:PruneCellNicknames()
    for name, nickname in pairs(SLUI.roster) do
        SLUI:AddCellNickname(name, nickname)
        SLUI:AddCustomName(name, nickname)
    end

    SLUI:EnableElvUI()
    SLUI:EnableGrid2()
    SLUI:EnableMRT()
    SLUI:EnableOmniCD()
    SLUI:EnableVuhDo()
    SLUI:EnableWeakAuras()
end
