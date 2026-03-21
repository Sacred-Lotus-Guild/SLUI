-- Dravus #1 Beta Tester
--- @class SLUI
local SLUI = select(2, ...)
--- @class ReadyCheck: AceModule, AceEvent-3.0
local ReadyCheck = SLUI:NewModule("ReadyCheck", "AceEvent-3.0")

-- Default settings
SLUI.defaults.global.ready = {
    enable = false,
    position = {
        point = "CENTER",
        relativeTo = "UIParent",
        relativePoint = "CENTER",
        xOfs = 0,
        yOfs = 0,
    },
    width = 500,
    height = 220,
}

local ANCHOR_POINTS = {
    ["TOPLEFT"] = "TOPLEFT",
    ["TOP"] = "TOP",
    ["TOPRIGHT"] = "TOPRIGHT",
    ["LEFT"] = "LEFT",
    ["CENTER"] = "CENTER",
    ["RIGHT"] = "RIGHT",
    ["BOTTOMLEFT"] = "BOTTOMLEFT",
    ["BOTTOM"] = "BOTTOM",
    ["BOTTOMRIGHT"] = "BOTTOMRIGHT"
}

local function Disabled()
    return not SLUI.db.global.ready.enable
end

SLUI.options.args.ready = {
    type = "group",
    name = "Ready Check",
    args = {
        enable = {
            name = "Enable",
            type = "toggle",
            get = function() return SLUI.db.global.ready.enable end,
            set = function(_, value)
                SLUI.db.global.ready.enable = value
                if value then ReadyCheck:Enable() else ReadyCheck:Disable() end
            end,
            width = "full",
            order = 0,
        },
        test = {
            order = 1,
            name = "Test",
            type = "execute",
            func = function() ReadyCheck:READY_CHECK("READY_CHECK", UnitName("player"), 40) end,
            disabled = Disabled,
        },
        position = {
            order = 2,
            name = "Position",
            type = "group",
            inline = true,
            disabled = Disabled,
            args = {
                point = {
                    order = 2,
                    name = "Anchor from",
                    type = "select",
                    values = ANCHOR_POINTS,
                    get = function() return SLUI.db.global.ready.position.point end,
                    set = function(_, value)
                        SLUI.db.global.ready.position.point = value
                        ReadyCheck:UpdateFrameOptions()
                    end,
                },
                relativeTo = {
                    order = 1,
                    name = "Anchored to",
                    type = "input",
                    get = function() return SLUI.db.global.ready.position.relativeTo end,
                    set = function(_, value)
                        SLUI.db.global.ready.position.relativeTo = value
                        ReadyCheck:UpdateFrameOptions()
                    end,
                },
                relativePoint = {
                    order = 3,
                    name = "to frame's",
                    type = "select",
                    values = ANCHOR_POINTS,
                    get = function() return SLUI.db.global.ready.position.relativePoint end,
                    set = function(_, value)
                        SLUI.db.global.ready.position.relativePoint = value
                        ReadyCheck:UpdateFrameOptions()
                    end,
                },
                offsetX = {
                    order = 4,
                    name = "X Offset",
                    type = "range",
                    min = -1000,
                    max = 1000,
                    bigStep = 1,
                    get = function() return SLUI.db.global.ready.position.xOfs end,
                    set = function(_, value)
                        SLUI.db.global.ready.position.xOfs = value
                        ReadyCheck:UpdateFrameOptions()
                    end,
                },
                offsetY = {
                    order = 5,
                    name = "Y Offset",
                    type = "range",
                    min = -1000,
                    max = 1000,
                    bigStep = 1,
                    get = function() return SLUI.db.global.ready.position.yOfs end,
                    set = function(_, value)
                        SLUI.db.global.ready.position.yOfs = value
                        ReadyCheck:UpdateFrameOptions()
                    end,
                },
            },
        },
        --[[ changing the size isn't really a good idea
        frameWidth = {
            order = 3,
            name = "Width",
            type = "range",
            min = 0,
            max = 1000,
            bigStep = 1,
            get = function() return SLUI.db.global.ready.width end,
            set = function(_, value)
                SLUI.db.global.ready.width = value
                ReadyCheck:UpdateFrameOptions()
            end,
            disabled = Disabled,
        },
        frameHeight = {
            order = 4,
            name = "Height",
            type = "range",
            min = 0,
            max = 1000,
            bigStep = 1,
            get = function() return SLUI.db.global.ready.height end,
            set = function(_, value)
                SLUI.db.global.ready.height = value
                ReadyCheck:UpdateFrameOptions()
            end,
            disabled = Disabled,
        },
        --]]
    },
}

-- Locals
local playerData = {}
local unitIndexMap = {}
local READY_CHECK_READY = "ready"

-- Spell IDs to monitor
local SPELL_IDS = {
    Rune = { 1234969, 1242347 },
    Int = { 1459 },
    Atk = { 6673 },
    Vers = { 1126 },
    Stam = { 21562 },
    Mastery = { 462854 },
    Move = { 381758, 381732, 381746, 381748, 381750, 381749, 381751, 381752, 381753, 381754, 381756, 381757, 381741 },
    SS = { 20707 },
}

-- Spell lookup functions
local function CreateSpellLookup(spellList)
    local lookup = {}
    for _, spellID in ipairs(spellList) do
        lookup[spellID] = true
    end
    return lookup
end

-- Create lookup tables for faster checks
local runeLookup = CreateSpellLookup(SPELL_IDS.Rune)
local intLookup = CreateSpellLookup(SPELL_IDS.Int)
local atkLookup = CreateSpellLookup(SPELL_IDS.Atk)
local versLookup = CreateSpellLookup(SPELL_IDS.Vers)
local stamLookup = CreateSpellLookup(SPELL_IDS.Stam)
local masteryLookup = CreateSpellLookup(SPELL_IDS.Mastery)
local moveLookup = CreateSpellLookup(SPELL_IDS.Move)
local ssLookup = CreateSpellLookup(SPELL_IDS.SS)

-- Determine if window should be shown
function ReadyCheck:ShowWindow(initiatorName)
    return self.db.enable and
        (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") or UnitName("player") == initiatorName)
end

-- Function to get player buffs
local function GetPlayerBuffs(unit)
    local buffs = {
        Food = nil,
        Flask = nil,
        Rune = nil,
        Vantus = nil,
        Int = nil,
        Atk = nil,
        Vers = nil,
        Stam = nil,
        Mastery = nil,
        Move = nil,
        SS = nil,
        Durability = 100,
    }

    -- Check auras
    local index = 1
    while true do
        local auraData = C_UnitAuras.GetAuraDataByIndex(unit, index, "HELPFUL")

        if not auraData then break end

        local name = auraData.name
        local icon = auraData.icon
        local spellId = auraData.spellId
        local expirationTime = auraData.expirationTime

        if not buffs.Food and name and name:match("Well Fed") then
            buffs.Food = { icon = icon, expirationTime = expirationTime }
        elseif not buffs.Food and name and name == "Food" then -- Eating
            buffs.Food = { icon = icon, expirationTime = expirationTime }
        elseif not buffs.Flask and name and name:match("^Flask of") then
            buffs.Flask = { icon = icon, expirationTime = expirationTime }
        elseif not buffs.Vantus and name and name:match("^Vantus Rune:") then
            buffs.Vantus = { icon = icon, expirationTime = expirationTime }
        elseif not buffs.Rune and spellId and runeLookup[spellId] then
            buffs.Rune = { icon = icon, expirationTime = expirationTime }
        elseif not buffs.Int and spellId and intLookup[spellId] then
            buffs.Int = { icon = icon, expirationTime = expirationTime }
        elseif not buffs.Atk and spellId and atkLookup[spellId] then
            buffs.Atk = { icon = icon, expirationTime = expirationTime }
        elseif not buffs.Vers and spellId and versLookup[spellId] then
            buffs.Vers = { icon = icon, expirationTime = expirationTime }
        elseif not buffs.Stam and spellId and stamLookup[spellId] then
            buffs.Stam = { icon = icon, expirationTime = expirationTime }
        elseif not buffs.Mastery and spellId and masteryLookup[spellId] then
            buffs.Mastery = { icon = icon, expirationTime = expirationTime }
        elseif not buffs.Move and spellId and moveLookup[spellId] then
            buffs.Move = { icon = icon, expirationTime = expirationTime }
        elseif not buffs.SS and spellId and ssLookup[spellId] then
            buffs.SS = { icon = icon, expirationTime = expirationTime }
        end

        index = index + 1
    end

    -- Calculate durability (only for player)
    if UnitIsUnit(unit, "player") then
        local totalDurability = 0
        local totalMaxDurability = 0
        local slots = { 1, 3, 5, 6, 7, 8, 9, 10, 16, 17 } -- Equipment slots

        for _, slot in ipairs(slots) do
            local current, max = GetInventoryItemDurability(slot)
            if current and max then
                totalDurability = totalDurability + current
                totalMaxDurability = totalMaxDurability + max
            end
        end

        if totalMaxDurability > 0 then
            buffs.Durability = (totalDurability / totalMaxDurability) * 100
        end
    end

    return buffs
end

-- Create the main frame
function ReadyCheck:CreateFrame()
    local frame = CreateFrame("Frame", "SLRCFrame", UIParent, "BackdropTemplate")
    frame:SetSize(self.db.width, self.db.height)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:Hide()

    -- Set to last known position
    local pos = self.db.position
    frame:SetPoint(pos.point, pos.relativeTo, pos.relativePoint, pos.xOfs, pos.yOfs)

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    titleBar:SetSize(frame:GetWidth() - 2, 30)
    titleBar:SetPoint("TOP", frame, "TOP", 0, -2)
    titleBar:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    titleBar:SetBackdropColor(0.1, 0.1, 0.1, 1)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    titleBar:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        -- Save position
        local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
        self.db.position = {
            point = point,
            relativeTo = relativeTo and relativeTo:GetName() or "UIParent",
            relativePoint = relativePoint,
            xOfs = xOfs,
            yOfs = yOfs,
        }
        LibStub("AceConfigRegistry-3.0"):NotifyChange("SLUI")
    end)
    frame.titleBar = titleBar

    -- Title text
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
    titleText:SetText("<SL> Ready Check: 0s")
    titleText:SetTextColor(0, 0.9, 0.9, 1)
    frame.titleText = titleText

    -- Ready count text
    local readyCount = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    readyCount:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
    readyCount:SetText("0/0")
    readyCount:SetTextColor(1, 1, 1, 1)
    frame.readyCount = readyCount

    -- Close button with fancy skinning because why not
    local closeButton = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    closeButton:SetSize(18, 18)
    closeButton:SetPoint("RIGHT", titleBar, "RIGHT", -6, 0)
    closeButton:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    closeButton:SetBackdropColor(0.1, 0.1, 0.1, 1)
    closeButton:SetBackdropBorderColor(1, 1, 1, 0.1)
    local closeX = closeButton:CreateTexture(nil, "OVERLAY")
    closeX:SetPoint("CENTER")
    closeX:SetSize(12, 12)
    closeX:SetTexture("Interface\\AddOns\\SLUI\\Media\\Textures\\Ready\\Close")

    closeButton:SetScript("OnEnter", function(f)
        f:SetBackdropBorderColor(0, 0.9, 0.9, 1)
    end)
    closeButton:SetScript("OnLeave", function(f)
        f:SetBackdropBorderColor(1, 1, 1, 0.1)
    end)
    closeButton:SetScript("OnClick", function()
        frame:SetScript("OnUpdate", nil)
        frame:Hide()
        frame.notReadyText:Hide()
    end)
    frame.closeButton = closeButton

    -- Content frame
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 5, -5)
    content:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", -5, -5)
    content:SetHeight(200) -- Initial height, will be adjusted
    frame.content = content

    -- Ready texture (shown when everyone is ready at check finish)
    local readyTexture = frame:CreateTexture(nil, "ARTWORK")
    readyTexture:SetTexture("Interface\\Addons\\SLUI\\Media\\Textures\\Ready\\Pass")
    readyTexture:SetAlpha(0.25)
    readyTexture:SetPoint("CENTER", frame, "CENTER", 0, 0)
    readyTexture:SetSize(200, 200)
    readyTexture:Hide() -- Hidden by default
    frame.readyTexture = readyTexture

    -- Fail texture (shown when not everyone is ready at check finish)
    local failTexture = frame:CreateTexture(nil, "ARTWORK")
    failTexture:SetTexture("Interface\\Addons\\SLUI\\Media\\Textures\\Ready\\Fail")
    failTexture:SetAlpha(0.25)
    failTexture:SetPoint("CENTER", frame, "CENTER", 0, 0)
    failTexture:SetSize(200, 200)
    failTexture:Hide() -- Hidden by default
    frame.failTexture = failTexture

    -- Not ready players text (shown over fail texture)
    local notReadyText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    notReadyText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    notReadyText:SetTextColor(1, 1, 1, 1) -- White text
    notReadyText:SetJustifyH("CENTER")
    notReadyText:SetJustifyV("MIDDLE")
    notReadyText:SetWidth(frame:GetWidth() - 40)
    notReadyText:Hide() -- Hidden by default
    frame.notReadyText = notReadyText

    -- Column headers
    frame.columnHeaders = {
        { name = "Food",   width = 30 },
        { name = "Flask",  width = 30 },
        { name = "Rune",   width = 30 },
        { name = "Int",    width = 30 },
        { name = "Atk",    width = 30 },
        { name = "Vers",   width = 30 },
        { name = "Stam",   width = 30 },
        { name = "Mast",   width = 30 },
        { name = "Move",   width = 32 },
        { name = "Vantus", width = 30 },
        { name = "SS",     width = 30 },
        { name = "Repair", width = 40 },
    }
    frame.rows = {}

    -- Create header row
    -- name is left justified
    local nameText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("TOPLEFT", content, "TOPLEFT", 5, 0)
    nameText:SetText("Name")
    nameText:SetTextColor(1, 1, 1, 1)
    --rest of the headers
    local xOffset = 100
    for _, header in ipairs(frame.columnHeaders) do
        local headerText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        headerText:SetPoint("CENTER", content, "TOPLEFT", xOffset, -5)
        headerText:SetText(header.name)
        headerText:SetTextColor(1, 1, 1, 1)
        xOffset = xOffset + header.width
    end

    self.frame = frame
    self:UpdateFrameOptions()
end

function ReadyCheck:UpdateFrameOptions()
    if not self.frame then return end

    self.frame:SetWidth(self.db.width)
    self.frame:SetHeight(self.db.height)

    local pos = self.db.position
    self.frame:ClearAllPoints()
    self.frame:SetPoint(pos.point, pos.relativeTo, pos.relativePoint, pos.xOfs, pos.yOfs)

    self.frame.titleBar:SetSize(self.frame:GetWidth() - 2, 30)
    self.frame.notReadyText:SetWidth(self.frame:GetWidth() - 40)

    for _, row in ipairs(self.frame.rows) do
        row:SetWidth(self.frame.content:GetWidth())
    end
end

--- Create Row
---@param parent Frame
---@param index number
local function CreateRow(parent, index)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetSize(parent:GetWidth(), 28)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -20 - (index - 1) * 28)
    row:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = nil,
    })

    if index % 2 == 0 then
        row:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
    else
        row:SetBackdropColor(0.15, 0.15, 0.15, 0.5)
    end

    -- Name text
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", row, "LEFT", 5, 0)
    nameText:SetWidth(80)
    nameText:SetJustifyH("LEFT")
    row.nameText = nameText

    -- Icons
    local xOffset = 100
    row.icons = {}
    local iconOrder = { "Food", "Flask", "Rune", "Int", "Atk", "Vers", "Stam", "Mastery", "Move", "Vantus", "SS" }

    for _, buffName in ipairs(iconOrder) do
        ---@type Texture|table
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(24, 24)
        icon:SetPoint("CENTER", row, "LEFT", xOffset, 0)
        icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        icon:Hide()

        -- Red overlay for low duration
        local overlay = row:CreateTexture(nil, "OVERLAY")
        overlay:SetSize(24, 24)
        overlay:SetPoint("CENTER", icon, "CENTER")
        overlay:SetColorTexture(1, 0, 0, 0.5)
        overlay:Hide()
        icon.overlay = overlay

        row.icons[buffName] = icon
        xOffset = xOffset + 30
    end

    -- Durability text
    local durText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    durText:SetPoint("CENTER", row, "LEFT", xOffset, 0)
    durText:SetWidth(40)
    durText:SetJustifyH("CENTER")
    row.durText = durText

    return row
end

-- Count readied players
local function CountReadyPlayers()
    local count = 0
    for _, data in ipairs(playerData) do
        if data.ready then
            count = count + 1
        end
    end
    return count
end

-- Update row for each player
local function UpdateRow(row, data)
    if not data then
        row:Hide()
        return
    end

    row:Show()
    row.nameText:SetText(data.name)

    -- Update ready status color
    if data.ready then
        row.nameText:SetTextColor(0, 1, 0, 1)
    else
        row.nameText:SetTextColor(1, 1, 1, 1)
    end

    -- Update buff icons
    local currentTime = GetTime()
    for buffName, icon in pairs(row.icons) do
        local buff = data.buffs[buffName]
        if buff and buff.icon then
            icon:SetTexture(buff.icon)
            icon:Show()

            -- Check if buff expires in less than 10 minutes
            if buff.expirationTime and buff.expirationTime > 0 then
                local timeLeft = buff.expirationTime - currentTime
                if timeLeft < 600 then -- 10 minutes
                    icon.overlay:Show()
                else
                    icon.overlay:Hide()
                end
            else
                icon.overlay:Hide()
            end
        else
            icon:Hide()
            icon.overlay:Hide()
        end
    end

    -- Update durability
    if data.buffs.Durability then
        row.durText:SetFormattedText("%.0f%%", data.buffs.Durability)
        if data.buffs.Durability < 25 then
            row.durText:SetTextColor(1, 0, 0, 1)
        elseif data.buffs.Durability < 50 then
            row.durText:SetTextColor(1, 1, 0, 1)
        else
            row.durText:SetTextColor(1, 1, 1, 1)
        end
    else
        row.durText:SetText("-")
        row.durText:SetTextColor(1, 1, 1, 1)
    end
end

-- Update data for all players
local function UpdateAllPlayers()
    -- Clear old data
    wipe(playerData)
    wipe(unitIndexMap)

    -- Always add player first
    local playerName = UnitName("player")
    playerData[1] = {
        name = playerName,
        unit = "player",
        ready = true,
        buffs = GetPlayerBuffs("player"),
    }
    unitIndexMap["player"] = 1

    if not IsInGroup() then return end

    -- Add group members
    local startIndex = 2
    if IsInRaid() then
        -- It's discouraged to use GetNumGroupMembers() since there can be "holes"
        -- between raid1 to raid40.
        -- see: https://warcraft.wiki.gg/wiki/API_GetRaidRosterInfo
        for i = 1, MAX_RAID_MEMBERS do
            local unit = "raid" .. i
            local name = UnitName(unit)

            if name and name ~= playerName then
                playerData[startIndex] = {
                    name = name,
                    unit = unit,
                    ready = GetReadyCheckStatus(unit) == READY_CHECK_READY,
                    buffs = GetPlayerBuffs(unit),
                }
                unitIndexMap[unit] = startIndex
                startIndex = startIndex + 1
            end
        end
    else
        for i = 1, MAX_PARTY_MEMBERS do
            local unit = "party" .. i
            local name = UnitName(unit)

            if name then
                playerData[startIndex] = {
                    name = name,
                    unit = unit,
                    ready = GetReadyCheckStatus(unit) == READY_CHECK_READY,
                    buffs = GetPlayerBuffs(unit),
                }
                unitIndexMap[unit] = startIndex
                startIndex = startIndex + 1
            end
        end
    end

    SLUI:Debug(playerData, "ReadyCheck.UpdateAllPlayers")
end

-- Update the frame
function ReadyCheck:UpdateFrame()
    if not self.frame or not self.frame:IsShown() then return end

    UpdateAllPlayers()

    -- Update title with remaining time
    local timeLeft = math.max(0, self.endTime - GetTime())
    self.frame.titleText:SetFormattedText("<SL> Ready Check: %ds", timeLeft)

    -- Update ready count
    local numReady = CountReadyPlayers()
    local numPlayers = #playerData -- was GetNumGroupMembers()
    self.frame.readyCount:SetFormattedText("%d/%d", numReady, numPlayers)

    -- Ensure we have enough rows
    while #self.frame.rows < numPlayers do
        local row = CreateRow(self.frame.content, #self.frame.rows + 1)
        table.insert(self.frame.rows, row)
    end

    -- Update rows
    for i = 1, numPlayers do
        if not self.frame.rows[i] then
            self.frame.rows[i] = CreateRow(self.frame.content, i)
        end
        UpdateRow(self.frame.rows[i], playerData[i])
    end

    -- Hide unused rows
    for i = numPlayers + 1, #self.frame.rows do
        self.frame.rows[i]:Hide()
    end

    -- Resize frame based on number of players
    local contentHeight = 30 + numPlayers * 28 -- Header (30) + rows (28 each)
    self.frame.content:SetHeight(contentHeight)

    -- Adjust main frame height to fit content
    local frameHeight = math.max(200, 40 + contentHeight + 10) -- Title bar (40) + content + padding (10)
    self.frame:SetHeight(frameHeight)
end

-- Update data for a single player
function ReadyCheck:UpdatePlayer(unit)
    local index = unitIndexMap[unit]
    if not index then return end

    local data = playerData[index]
    if not data then return end

    data.buffs = GetPlayerBuffs(unit)

    local row = self.frame and self.frame.rows[index]
    if row then
        UpdateRow(row, data)
    end
end

function ReadyCheck:UNIT_AURA(_, unit)
    if not self.frame or not self.frame:IsShown() then return end

    if unit == "player" or strsub(unit, 1, 4) == "raid" or strsub(unit, 1, 5) == "party" then
        self:UpdatePlayer(unit)
    end
end

function ReadyCheck:READY_CHECK_CONFIRM(_, unitTarget, isReady)
    if not self.frame or not self.frame:IsShown() then return end

    local index = unitIndexMap[unitTarget]
    if not index then return end

    local data = playerData[index]
    if not data then return end

    local readyStatus = GetReadyCheckStatus(unitTarget)
    data.ready = readyStatus == READY_CHECK_READY

    local row = self.frame.rows[index]
    if row then UpdateRow(row, data) end

    -- update count display
    local readyCount = CountReadyPlayers()
    self.frame.readyCount:SetFormattedText("%d/%d", readyCount, #playerData)
end

function ReadyCheck:HideFrame()
    if self.frame then
        self.frame:SetScript("OnUpdate", nil)
        self.frame:Hide()
    end

    -- Cancel previous timer if it exists
    if self.closeTimer then
        self.closeTimer:Cancel()
        self.closeTimer = nil
    end

    self:UnregisterEvent("UNIT_AURA")
    self:UnregisterEvent("READY_CHECK_CONFIRM")
end

-- Event handlers
function ReadyCheck:READY_CHECK(_, initiatorName, readyCheckTimeLeft)
    if not self.frame or not self:ShowWindow(initiatorName) then return end

    if not readyCheckTimeLeft then readyCheckTimeLeft = 40 end
    self.endTime = GetTime() + readyCheckTimeLeft

    self.frame:Show()
    self.frame.content:Show()
    self.frame.readyTexture:Hide()
    self.frame.failTexture:Hide()
    self.frame.notReadyText:Hide()
    self:UpdateFrame()

    self.frame:SetScript("OnUpdate", function(_, elapsed)
        if not self.frame or not self.frame:IsShown() then return end

        -- Throttle updates
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 0.5 then return end
        self.elapsed = self.elapsed - 0.5

        local timeLeft = math.max(0, self.endTime - GetTime())
        self.frame.titleText:SetFormattedText("<SL> Ready Check: %ds", timeLeft)
    end)

    -- Register events for updates
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("READY_CHECK_CONFIRM")

    -- Cancel previous timer if it exists
    if self.closeTimer then self.closeTimer:Cancel() end
    self.closeTimer = C_Timer.NewTimer(readyCheckTimeLeft, function()
        self:HideFrame()
    end)
end

function ReadyCheck:READY_CHECK_FINISHED()
    if not self.frame or not self.frame:IsShown() then return end

    -- Check if everyone is ready
    local readyCount = CountReadyPlayers()
    local numPlayers = #playerData -- was GetNumGroupMembers()
    local allReady = readyCount == numPlayers

    -- Update main frame
    self.frame.titleText:SetFormattedText("Ready Check Complete")
    self.frame:SetScript("OnUpdate", nil) -- stop updating the timer text
    self.frame.content:Hide()

    if allReady then
        -- Everyone is ready - show pass texture
        self.frame.readyTexture:Show()
    else
        -- Not everyone is ready - show fail texture and list of not ready players
        self.frame.failTexture:Show()

        -- Who isnt ready
        local notReadyPlayers = {}
        for _, data in ipairs(playerData) do
            if not data.ready then
                table.insert(notReadyPlayers, data.name)
            end
        end

        -- Display the list
        local notReadyList = table.concat(notReadyPlayers, "\n")
        self.frame.notReadyText:SetText(notReadyList)
        self.frame.notReadyText:Show()
    end

    -- Close window 5 seconds after ready check completes
    if self.closeTimer then self.closeTimer:Cancel() end
    self.closeTimer = C_Timer.NewTimer(5, function()
        self:HideFrame()
    end)
end

function ReadyCheck:ENCOUNTER_START()
    self:HideFrame()
end

-- Module initialization
function ReadyCheck:OnInitialize()
    self.db = SLUI.db.global.ready
    self:SetEnabledState(self.db.enable)
end

function ReadyCheck:OnEnable()
    self:CreateFrame()

    -- Register events
    self:RegisterEvent("READY_CHECK")
    self:RegisterEvent("READY_CHECK_FINISHED")
    self:RegisterEvent("ENCOUNTER_START")
end

function ReadyCheck:OnDisable()
    self:HideFrame()
    self:UnregisterAllEvents()
end
