-- Dravus #1 Beta Tester
--- @class SLUI
local SLUI = select(2, ...)
--- @class ReadyCheck: AceModule, AceEvent-3.0
local ReadyCheck = SLUI:NewModule("ReadyCheck", "AceEvent-3.0")

-- Default settings
SLUI.defaults.global.ready = {
    position = {
        point = "CENTER",
        relativeTo = "UIParent",
        relativePoint = "CENTER",
        xOfs = 0,
        yOfs = 0,
    },
    width = 460,
    height = 400,
    debug = false,
    show = false,
}

-- Debug
local function DebugPrint(...)
    if SLUI.db.global.ready.debug then
        print("|cff00ff00[SLRC Debug]|r", ...)
    end
end

-- Addon Messages
local function AddonPrint(...)
    print("|cff1e90ff[SLRC]|r", ...)
end

-- Locals
local mainFrame
local playerData = {}
local unitIndexMap = {}
local strsub = string.sub
local readyCheckEndTime = 0
local readyCheckActive = false
local closeTimer
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
local function ShowWindow()
    local isLeader = UnitIsGroupLeader("player")
    local isAssistant = UnitIsGroupAssistant("player")
    local isShow = SLUI.db.global.ready.show

    DebugPrint("Leader:", isLeader, "Assistant:", isAssistant, "Showing Window", isShow)

    return isLeader or isAssistant or isShow
end

-- Function to get player buffs
local function GetPlayerBuffs(unit)
    DebugPrint("Getting buffs for unit:", unit)

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
    local buffCount = 0
    while true do
        local auraData = C_UnitAuras.GetAuraDataByIndex(unit, index, "HELPFUL")

        if not auraData then break end
        buffCount = buffCount + 1

        local name = auraData.name
        local icon = auraData.icon
        local spellId = auraData.spellId
        local expirationTime = auraData.expirationTime

        -- Check for Well Fed
        if name and name == "Well Fed" and not buffs.Food then
            buffs.Food = { icon = icon, expirationTime = expirationTime }
        end

        -- Check for Food (eating)
        if name and name == "Food" and not buffs.Food then
            buffs.Food = { icon = icon, expirationTime = expirationTime }
        end

        -- Check for Flask
        if name and name:match("^Flask of") and not buffs.Flask then
            buffs.Flask = { icon = icon, expirationTime = expirationTime }
        end

        -- Check for Vantus Rune
        if name and name:match("^Vantus Rune:") and not buffs.Vantus then
            buffs.Vantus = { icon = icon, expirationTime = expirationTime }
        end

        -- Check spell IDs
        if spellId then
            if runeLookup[spellId] and not buffs.Rune then
                buffs.Rune = { icon = icon, expirationTime = expirationTime }
            elseif intLookup[spellId] and not buffs.Int then
                buffs.Int = { icon = icon, expirationTime = expirationTime }
            elseif atkLookup[spellId] and not buffs.Atk then
                buffs.Atk = { icon = icon, expirationTime = expirationTime }
            elseif versLookup[spellId] and not buffs.Vers then
                buffs.Vers = { icon = icon, expirationTime = expirationTime }
            elseif stamLookup[spellId] and not buffs.Stam then
                buffs.Stam = { icon = icon, expirationTime = expirationTime }
            elseif masteryLookup[spellId] and not buffs.Mastery then
                buffs.Mastery = { icon = icon, expirationTime = expirationTime }
            elseif moveLookup[spellId] and not buffs.Move then
                buffs.Move = { icon = icon, expirationTime = expirationTime }
            elseif ssLookup[spellId] and not buffs.SS then
                buffs.SS = { icon = icon, expirationTime = expirationTime }
            end
        end

        index = index + 1
    end

    DebugPrint("  Total buffs scanned for", unit, ":", buffCount)

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
local function CreateMainFrame()
    DebugPrint("Creating main ready check frame")

    local frame = CreateFrame("Frame", "SLRCFrame", UIParent, "BackdropTemplate")
    frame:SetSize(SLUI.db.global.ready.width, SLUI.db.global.ready.height)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:Hide()

    -- Set to last known position
    local pos = SLUI.db.global.ready.position
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
    titleBar:SetScript("OnDragStart", function(self)
        frame:StartMoving()
    end)
    titleBar:SetScript("OnDragStop", function(self)
        frame:StopMovingOrSizing()
        -- Save position
        local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
        SLUI.db.global.ready.position = {
            point = point,
            relativeTo = "UIParent",
            relativePoint = relativePoint,
            xOfs = xOfs,
            yOfs = yOfs,
        }
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

    closeButton:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0, 0.9, 0.9, 1)
    end)
    closeButton:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(1, 1, 1, 0.1)
    end)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
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
    local columnHeaders = {
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

    frame.columnHeaders = columnHeaders
    frame.rows = {}

    -- Create header row
    -- name is left justified
    local nameText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("TOPLEFT", content, "TOPLEFT", 5, 0)
    nameText:SetText("Name")
    nameText:SetTextColor(1, 1, 1, 1)
    --rest of the headers
    local xOffset = 100
    for i, header in ipairs(columnHeaders) do
        local headerText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        headerText:SetPoint("CENTER", content, "TOPLEFT", xOffset, -5)
        headerText:SetText(header.name)
        headerText:SetTextColor(1, 1, 1, 1)
        xOffset = xOffset + header.width
    end

    DebugPrint("Main frame created successfully")

    return frame
end

-- Create Row
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

    -- Add player first
    local playerName = UnitName("player")
    if playerName then
        local readyStatus = GetReadyCheckStatus("player")
        playerData[1] = {
            name = playerName,
            unit = "player",
            ready = true,
            buffs = GetPlayerBuffs("player"),
        }
        unitIndexMap["player"] = 1
        DebugPrint(playerName, "ReadyStatus:", readyStatus)
    end

    if not IsInGroup() then
        DebugPrint("Not in group, skipping player data update")
        return
    else
        local isRaid = IsInRaid()
        local numMembers = GetNumGroupMembers()
        DebugPrint("Updating player data for", numMembers, isRaid and "raid" or "party", "members")

        -- Add group members
        local startIndex = 2
        if isRaid then
            -- In raid, iterate through raid units
            for i = 1, numMembers do
                local unit = "raid" .. i
                local name = UnitName(unit)

                if name and name ~= playerName then
                    local readyStatus = GetReadyCheckStatus(unit)

                    playerData[startIndex] = {
                        name = name,
                        unit = unit,
                        ready = readyStatus == READY_CHECK_READY,
                        buffs = GetPlayerBuffs(unit),
                    }
                    unitIndexMap[unit] = startIndex
                    DebugPrint(name, "ReadyStatus:", readyStatus)
                    startIndex = startIndex + 1
                end
            end
        else
            -- In party, iterate through party units
            for i = 1, numMembers - 1 do
                local unit = "party" .. i
                local name = UnitName(unit)

                if name then
                    local readyStatus = GetReadyCheckStatus(unit)

                    playerData[startIndex] = {
                        name = name,
                        unit = unit,
                        ready = readyStatus == READY_CHECK_READY,
                        buffs = GetPlayerBuffs(unit),
                    }
                    unitIndexMap[unit] = startIndex
                    DebugPrint(name, "ReadyStatus:", readyStatus)
                    startIndex = startIndex + 1
                end
            end
        end

        DebugPrint("Total players added to data:", #playerData)
    end
end

-- Update data for a single player
local function UpdatePlayer(unit)
    local index = unitIndexMap[unit]
    if not index then return end

    local data = playerData[index]
    if not data then return end

    data.buffs = GetPlayerBuffs(unit)

    local row = mainFrame and mainFrame.rows[index]
    if row then
        UpdateRow(row, data)
    end
end

-- Update the frame
local function UpdateFrame()
    if readyCheckActive == false then return end
    if not mainFrame or not mainFrame:IsShown() then
        DebugPrint("Frame not shown, skipping update")
        return
    end

    DebugPrint("Updating frame display")

    UpdateAllPlayers()

    -- Update title with remaining time
    local timeLeft = math.max(0, readyCheckEndTime - GetTime())
    mainFrame.titleText:SetFormattedText("<SL> Ready Check: %.0fs", timeLeft)

    -- Update ready count
    local readyCount = CountReadyPlayers()
    local totalCount = #playerData -- was GetNumGroupMembers()
    mainFrame.readyCount:SetFormattedText("%d/%d", readyCount, totalCount)

    -- Ensure we have enough rows
    local numPlayers = #playerData
    while #mainFrame.rows < numPlayers do
        local row = CreateRow(mainFrame.content, #mainFrame.rows + 1)
        table.insert(mainFrame.rows, row)
    end

    -- Update rows
    for i = 1, numPlayers do
        if not mainFrame.rows[i] then
            mainFrame.rows[i] = CreateRow(mainFrame.content, i)
        end
        UpdateRow(mainFrame.rows[i], playerData[i])
    end

    -- Hide unused rows
    for i = numPlayers + 1, #mainFrame.rows do
        mainFrame.rows[i]:Hide()
    end

    -- Resize frame based on number of players
    local contentHeight = 30 + numPlayers * 28 -- Header (30) + rows (28 each)
    mainFrame.content:SetHeight(contentHeight)

    -- Adjust main frame height to fit content
    local frameHeight = math.max(200, 40 + contentHeight + 10) -- Title bar (40) + content + padding (10)
    mainFrame:SetHeight(frameHeight)
end

-- reset frame states
local function ResetFrame()
    if not mainFrame then return end
    mainFrame:Hide()
    mainFrame.failTexture:Hide()
    mainFrame.readyTexture:Hide()
    mainFrame.notReadyText:Hide()
    mainFrame.content:Show()
end


-- Event handlers
function ReadyCheck:READY_CHECK(event, initiator, duration)
    DebugPrint("READY_CHECK event triggered by", initiator, "for", duration, "seconds")

    if not IsInGroup() then
        DebugPrint("Not in group, ignoring ready check")
        return
    end

    -- Check if player is showing window
    if not ShowWindow() then
        DebugPrint("Show Window is off")
        return
    end

    readyCheckActive = true
    readyCheckEndTime = GetTime() + (duration or 40)

    DebugPrint("Ready check will end at:", readyCheckEndTime)

    -- Create frame, show it, then update it
    if not mainFrame then
        mainFrame = CreateMainFrame()
    end

    mainFrame:Show()
    DebugPrint("Frame shown")
    UpdateFrame()

    -- Register events for updates
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("READY_CHECK_CONFIRM")

    -- Cancel previous timer if it exists
    if closeTimer then
        closeTimer:Cancel()
    end
end

function ReadyCheck:READY_CHECK_CONFIRM(_, unit)
    local index = unitIndexMap[unit]
    if not index then return end

    local data = playerData[index]
    if not data then return end

    local readyStatus = GetReadyCheckStatus(unit)
    data.ready = readyStatus == READY_CHECK_READY

    local row = mainFrame and mainFrame.rows[index]
    if row then
        UpdateRow(row, data)
    end

    -- update count display
    local readyCount = CountReadyPlayers()
    if mainFrame and mainFrame.readyCount then
        mainFrame.readyCount:SetFormattedText("%d/%d", readyCount, #playerData)
    end
end

function ReadyCheck:READY_CHECK_FINISHED()
    DebugPrint("READY_CHECK_FINISHED")

    -- Check if everyone is ready
    local readyCount = CountReadyPlayers()
    local totalCount = #playerData -- was GetNumGroupMembers()
    local allReady = (readyCount == totalCount)

    DebugPrint("Ready check finished - Ready:", readyCount, "Total:", totalCount, "All Ready:", allReady)
    readyCheckActive = false

    if not mainFrame or not mainFrame:IsShown() then
        DebugPrint("Frame closed early, skipping display complete")
        return
    end

    -- Update main frame
    mainFrame.titleText:SetFormattedText("Ready Check Complete")
    mainFrame.content:Hide()

    if allReady then
        -- Everyone is ready - show pass texture
        DebugPrint("Everyone is ready - showing pass texture")
        mainFrame.readyTexture:Show()
    else
        -- Not everyone is ready - show fail texture and list of not ready players
        DebugPrint("Not everyone ready - showing fail texture and player list")
        mainFrame.failTexture:Show()

        -- Who isnt ready
        local notReadyPlayers = {}
        for _, data in ipairs(playerData) do
            if not data.ready then
                table.insert(notReadyPlayers, data.name)
            end
        end

        -- Display the list
        local notReadyList = table.concat(notReadyPlayers, "\n")
        mainFrame.notReadyText:SetText(notReadyList)
        mainFrame.notReadyText:Show()

        DebugPrint("Not ready players:", notReadyList)
    end

    -- Cancel previous timer if it exists
    if closeTimer then
        closeTimer:Cancel()
    end

    DebugPrint("Starting 5 second timer to close window")
    -- Close window 5 seconds after ready check completes
    closeTimer = C_Timer.NewTimer(5, function()
        DebugPrint("5 second timer expired, hiding frame")
        ResetFrame()
        ReadyCheck:UnregisterEvent("UNIT_AURA")
        ReadyCheck:UnregisterEvent("READY_CHECK_CONFIRM")
    end)
end

function ReadyCheck:ENCOUNTER_START()
    DebugPrint("ENCOUNTER_START")

    -- Stop everything, someone pulled early
    readyCheckActive = false

    if mainFrame then
        mainFrame:Hide()
        mainFrame.failTexture:Hide()
        mainFrame.readyTexture:Hide()
        mainFrame.notReadyText:Hide()
        mainFrame.content:Show()
    end

    ReadyCheck:UnregisterEvent("UNIT_AURA")
    ReadyCheck:UnregisterEvent("READY_CHECK_CONFIRM")

    if closeTimer then
        closeTimer:Cancel()
    end
end

function ReadyCheck:UNIT_AURA(event, unit)
    if not readyCheckActive then return end
    if not mainFrame or not mainFrame:IsShown() then return end

    if unit == "player"
        or strsub(unit, 1, 4) == "raid"
        or strsub(unit, 1, 5) == "party" then
        UpdatePlayer(unit)
    end
end

-- Module initialization
function ReadyCheck:OnInitialize()
    DebugPrint("SLRC module initializing")
    self:SetEnabledState(SLUI.db.global.ready.show)
end

function ReadyCheck:OnEnable()
    DebugPrint("SLRC module enabled")

    -- Register events
    self:RegisterEvent("READY_CHECK")
    self:RegisterEvent("READY_CHECK_FINISHED")
    self:RegisterEvent("ENCOUNTER_START")
    DebugPrint("Events registered")

    -- Module loaded message
    AddonPrint("loaded. Type |cffffcc00/slrc help|r for commands")
    if SLUI.db.global.ready.debug then
        AddonPrint("  |cffff9900Debug mode is ENABLED|r")
    end
end

function ReadyCheck:OnDisable()
    AddonPrint("module disabled.")
    if mainFrame then
        mainFrame:Hide()
    end
    self:UnregisterAllEvents()
end

-- Update timer
local timerUpdateThrottle = 0
local updateFrame = CreateFrame("Frame")
updateFrame:SetScript("OnUpdate", function(self, elapsed)
    if not readyCheckActive or not mainFrame or not mainFrame:IsShown() then
        return
    end

    timerUpdateThrottle = timerUpdateThrottle + elapsed
    if timerUpdateThrottle >= 0.5 then
        timerUpdateThrottle = 0

        local timeLeft = math.max(0, readyCheckEndTime - GetTime())
        mainFrame.titleText:SetFormattedText("<SL> Ready Check: %.0fs", timeLeft)
    end
end)

-- Slash commands
local function ShowHelp()
    AddonPrint("Available commands:")
    print("  |cffffcc00/slrc debug|r - Toggle debug mode on/off")
    print("  |cffffcc00/slrc show|r - Toggle ready check window")
    print("  |cffffcc00/slrc test|r - Test Window")
    print("  |cffffcc00/slrc help|r - Show this help message")
end

local function ToggleDebug()
    SLUI.db.global.ready.debug = not SLUI.db.global.ready.debug
    if SLUI.db.global.ready.debug then
        AddonPrint("|cff00ff00Debug mode ENABLED|r")
    else
        AddonPrint("|cffff0000Debug mode DISABLED|r")
    end
end

local function ToggleShow()
    SLUI.db.global.ready.show = not SLUI.db.global.ready.show
    if SLUI.db.global.ready.show then
        ReadyCheck:Enable()
    else
        ReadyCheck:Disable()
    end
end

local function ToggleTest()
    AddonPrint("|cff00ff00Test Window ENABLED|r")
    readyCheckActive = true
    readyCheckEndTime = GetTime() + 35

    -- Create frame, show it, then update it
    if not mainFrame then
        mainFrame = CreateMainFrame()
    end

    mainFrame:Show()
    DebugPrint("Frame shown")
    UpdateFrame()

    -- Register events for updates
    ReadyCheck:RegisterEvent("UNIT_AURA")

    -- Cancel previous timer if it exists
    if closeTimer then
        closeTimer:Cancel()
    end

    closeTimer = C_Timer.NewTimer(35, function()
        ResetFrame()
        ReadyCheck:UnregisterEvent("UNIT_AURA")
        ReadyCheck:UnregisterEvent("READY_CHECK_CONFIRM")
    end)
end

-- Slash command handler
local function SlashCommandHandler(msg)
    local command, arg = msg:match("^(%S*)%s*(.-)$")
    command = command:lower()
    if command == "debug" then
        ToggleDebug()
    elseif command == "show" then
        ToggleShow()
    elseif command == "test" then
        ToggleTest()
    elseif command == "help" or command == "" then
        ShowHelp()
    else
        AddonPrint("|cffff0000Unknown command:|r " .. command)
        ShowHelp()
    end
end

-- Register slash commands
SLASH_SLRC1 = "/SLReadyCheck"
SLASH_SLRC2 = "/SLRC"
SlashCmdList["SLRC"] = SlashCommandHandler
