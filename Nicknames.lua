--- @class SLUI
local SLUI = select(2, ...)
local CustomNames = C_AddOns.IsAddOnLoaded("CustomNames") and LibStub("CustomNames")

--- Retrieve a unit's configured nickname, given UnitID or character name.
--- @param unit string UnitID
--- @return string|nil
function SLUI:GetNickname(unit)
    if unit and UnitExists(unit) then
        local name = UnitNameUnmodified(unit)
        return name and self.roster[name] or name
    else
        return self.roster[unit] or unit
    end
end

--- Add a nickname to the existing roster.
--- @param name string
--- @param nickname string
function SLUI:AddNickname(name, nickname)
    self.roster[name] = nickname
    self:AddCellNickname(name, nickname)
    self:AddCustomName(name, nickname)
end

--- Remove duplicate nicknames from the Cell database.
function SLUI:PruneCellNicknames()
    if self.db.global.nicknames.cell and C_AddOns.IsAddOnLoaded("Cell") and CellDB then
        for i, entry in pairs(CellDB.nicknames.list) do
            local name, nickname = entry:match("([^:]+):([^:]+)")

            if nickname ~= self.roster[name] then
                table.remove(CellDB.nicknames.list, i)
            end
        end
    end
end

--- Add a nickname to Cell's nickname database.
--- @param name string
--- @param nickname string
function SLUI:AddCellNickname(name, nickname)
    if self.db.global.nicknames.cell and C_AddOns.IsAddOnLoaded("Cell") and Cell and CellDB then
        if tInsertUnique(CellDB.nicknames.list, format("%s:%s", name, nickname)) then
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
            return self:GetNickname(unit)
        end)
        E:AddTagInfo('name:alias', 'Names', format('Nickname from |cff00ff98%s|r', "SLUI"))

        for textFormat, length in pairs({ veryshort = 5, short = 10, medium = 15, long = 20 }) do
            local tag = format('name:alias:%s', textFormat)
            E:AddTag(tag, 'UNIT_NAME_UPDATE INSTANCE_ENCOUNTER_ENGAGE_UNIT', function(unit)
                local name = self:GetNickname(unit)
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
    if self.db.global.nicknames.grid2 and C_AddOns.IsAddOnLoaded("Grid2") and Grid2 then
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

        self:RegisterEvent("ADDON_LOADED", function(_, addOnName)
            if addOnName == "Grid2Options" and Grid2Options then
                Grid2Options:RegisterStatusOptions("nickname", "misc", function() end, {
                    titleIcon = "Interface\\AddOns\\SLUI\\Media\\Textures\\logo.blp",
                })
            end
        end)
    end
end

--- Enable (the enabled) MRT overrides
function SLUI:EnableMRT()
    if C_AddOns.IsAddOnLoaded("MRT") and GMRT then
        -- Replace names in MRT cooldown bars.
        if self.db.global.nicknames.mrt.cooldowns then
            GMRT.F:RegisterCallback("RaidCooldowns_Bar_TextName", function(_, bar, gsubData, barData)
                local name = self:GetNickname(barData.name)
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

                --[[ is this more or less efficient? how can i test?
                for name, nickname in pairs(SLUI.roster) do
                    text = text:gsub("([^%a])" .. name .. "([^%a])", "%1" .. nickname .. "%2")
                end
                --]]

                local replacements = {}
                for name in text:gmatch("|c%x%x%x%x%x%x%x%x(.-)|r") do -- match all color coded phrases
                    if not replacements[name] then
                        local nickname = self:GetNickname(name)
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
        self:RawHook(P, "CreateUnitInfo", function(_self, unit, guid, _, level, class, raceID, _)
            local name = self:GetNickname(unit)
            return self.hooks[P]["CreateUnitInfo"](_self, unit, guid, name, level, class, raceID, name)
        end)
    end
end

--- @param unit string
--- @param nameText FontString
--- @param buttonName string
function SLUI:UpdateVuhDoName(unit, nameText, buttonName)
    local name = self:GetNickname(unit)

    -- Respect the max character option (if set)
    local panelNumber = buttonName and buttonName:match("^Vd(%d+)")
    panelNumber = tonumber(panelNumber)

    local maxChars = panelNumber and self.vuhDoPanelSettings[panelNumber] and
        self.vuhDoPanelSettings[panelNumber].maxChars
    if name and maxChars and maxChars > 0 then
        name = name:sub(1, maxChars)
    end

    nameText:SetFormattedText(name or "") -- SetText is hooked, so we use this instead
end

--- Hook VUHDO_getBarText function to apply our nicknames.
function SLUI:EnableVuhDo()
    if self.db.global.nicknames.vuhdo and C_AddOns.IsAddOnLoaded("VuhDo") and VUHDO_PANEL_SETUP then
        self.vuhDoPanelSettings = {}

        if VUHDO_PANEL_SETUP then
            for i, settings in pairs(VUHDO_PANEL_SETUP) do
                self.vuhDoPanelSettings[i] = settings.PANEL_COLOR and settings.PANEL_COLOR.TEXT
            end
        end

        self:SecureHook("VUHDO_getBarText", function(unitHealthBar)
            local unitFrameName = unitHealthBar and unitHealthBar.GetName and unitHealthBar:GetName()
            if not unitFrameName then return end

            local nameText = _G[unitFrameName .. "TxPnlUnN"]
            if not nameText then return end
            if self:IsHooked(nameText, "SetText") then return end

            local unitButton = _G[unitFrameName:match("(.+)BgBarIcBarHlBar")]
            if not unitButton then return end

            self:SecureHook(nameText, "SetText", function(_self)
                self:UpdateVuhDoName(unitButton.raidid, _self, unitFrameName)
            end)
        end)
    end
end

--- Override WeakAura functions if CustomNames is not already installed and doing the same.
function SLUI:EnableWeakAuras()
    if self.db.global.nicknames.weakauras and WeakAuras and not CustomNames then
        function WeakAuras.GetName(name)
            return self:GetNickname(name)
        end

        function WeakAuras.UnitName(unit)
            local _, realm = UnitName(unit)
            return self:GetNickname(unit), realm
        end

        function WeakAuras.GetUnitName(unit, showServerName)
            local name = self:GetNickname(unit)
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
            return self:GetNickname(unit), realm
        end
    end
end

function SLUI:EnableNicknames()
    --- Provide our Nickname functionality to LiquidWeakAuras
    function AuraUpdater:GetNickname(unit)
        return SLUI:GetNickname(unit)
    end

    self:PruneCellNicknames()
    for name, nickname in pairs(self.roster) do
        self:AddCellNickname(name, nickname)
        self:AddCustomName(name, nickname)
    end

    self:EnableElvUI()
    self:EnableGrid2()
    self:EnableMRT()
    self:EnableOmniCD()
    self:EnableVuhDo()
    self:EnableWeakAuras()
end
