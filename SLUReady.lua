local SLUI = select(2, ...)

--- @class SLUReady: AceModule, AceEvent-3.0
local SLUReady = SLUI:NewModule("SLUReady", "AceEvent-3.0")

-- Libraries
local AceDB = LibStub("AceDB-3.0")

-- Debug mode
local debugMode = false

-- Debug print function
local function DebugPrint(...)
    if debugMode then
        print("|cff00ff98[SLUReady Debug]|r", ...)
    end
end

-- Local functions and upvalues
local GetTime = GetTime
local GetInventoryItemDurability = GetInventoryItemDurability
local IsInRaid = IsInRaid
local IsInGroup = IsInGroup
local GetNumGroupMembers = GetNumGroupMembers
local UnitName = UnitName
local GetReadyCheckStatus = GetReadyCheckStatus
local UnitIsUnit = UnitIsUnit
local READY_CHECK_READY = "ready"


-- Spell IDs for tracking
local SPELL_IDS = {
    Rune = {1234969, 1242347},
    Int = {1459},
    Atk = {6673},
    Vers = {1126},
    Stam = {21562},
    Mastery = {462854},
    Move = {381758, 381732, 381746, 381748, 381750, 381749, 381751, 381752, 381753, 381754, 381756, 381757},
    SS = {20707},
}

-- Default settings
SLUReady.defaults = {
    profile = {
        position = {
            point = "CENTER",
            relativeTo = "UIParent",
            relativePoint = "CENTER",
            xOfs = 0,
            yOfs = 0,
        },
        width = 480,
        height = 400,
    }
}

-- Frame and data storage
local mainFrame
local playerData = {}
local readyCheckEndTime = 0
local readyCheckActive = false
local closeTimer

-- Helper function to create spell ID lookup table
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
            buffs.Food = {icon = icon, expirationTime = expirationTime}
            DebugPrint("  Found Well Fed buff for", unit)
        end
        
        -- Check for Food (eating)
        if name and name == "Food" and not buffs.Food then
            buffs.Food = {icon = icon, expirationTime = expirationTime}
            DebugPrint("  Found Food buff for", unit)
        end
        
        -- Check for Flask
        if name and name:match("^Flask of") and not buffs.Flask then
            buffs.Flask = {icon = icon, expirationTime = expirationTime}
            DebugPrint("  Found Flask buff for", unit, ":", name)
        end
        
        -- Check for Vantus Rune
        if name and name:match("^Vantus Rune:") and not buffs.Vantus then
            buffs.Vantus = {icon = icon, expirationTime = expirationTime}
            DebugPrint("  Found Vantus Rune buff for", unit, ":", name)
        end
        
        -- Check spell IDs
        if spellId then
            if runeLookup[spellId] and not buffs.Rune then
                buffs.Rune = {icon = icon, expirationTime = expirationTime}
                DebugPrint("  Found Rune buff for", unit, "SpellID:", spellId)
            elseif intLookup[spellId] and not buffs.Int then
                buffs.Int = {icon = icon, expirationTime = expirationTime}
                DebugPrint("  Found Int buff for", unit)
            elseif atkLookup[spellId] and not buffs.Atk then
                buffs.Atk = {icon = icon, expirationTime = expirationTime}
                DebugPrint("  Found Atk buff for", unit)
            elseif versLookup[spellId] and not buffs.Vers then
                buffs.Vers = {icon = icon, expirationTime = expirationTime}
                DebugPrint("  Found Vers buff for", unit)
            elseif stamLookup[spellId] and not buffs.Stam then
                buffs.Stam = {icon = icon, expirationTime = expirationTime}
                DebugPrint("  Found Stam buff for", unit)
            elseif masteryLookup[spellId] and not buffs.Mastery then
                buffs.Mastery = {icon = icon, expirationTime = expirationTime}
                DebugPrint("  Found Mastery buff for", unit)
            elseif moveLookup[spellId] and not buffs.Move then
                buffs.Move = {icon = icon, expirationTime = expirationTime}
                DebugPrint("  Found Move buff for", unit)
            elseif ssLookup[spellId] and not buffs.SS then
                buffs.SS = {icon = icon, expirationTime = expirationTime}
                DebugPrint("  Found SS buff for", unit)
            end
        end
        
        index = index + 1
    end
    
    DebugPrint("  Total buffs scanned for", unit, ":", buffCount)
    
    -- Calculate durability (only for player)
    if UnitIsUnit(unit, "player") then
        local totalDurability = 0
        local totalMaxDurability = 0
        local slots = {1, 3, 5, 6, 7, 8, 9, 10, 16, 17} -- Equipment slots
        
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

-- Function to update player data
local function UpdatePlayerData()
    if not IsInGroup() then 
        DebugPrint("Not in group, skipping player data update")
        return 
    end
    
    local isRaid = IsInRaid()
    local numMembers = GetNumGroupMembers()
    DebugPrint("Updating player data for", numMembers, isRaid and "raid" or "party", "members")
    
    -- Clear old data
    wipe(playerData)
    
    -- Add player first
    local playerName = UnitName("player")
    if playerName then
        local readyStatus = GetReadyCheckStatus("player")
        playerData[1] = {
            name = playerName,
            unit = "player",
            ready = readyStatus == READY_CHECK_READY,
            buffs = GetPlayerBuffs("player"),
        }
        DebugPrint("Added player:", playerName, "Ready:", readyStatus == READY_CHECK_READY)
    end
    
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
                DebugPrint("Added raid member:", name, "Ready:", readyStatus == READY_CHECK_READY)
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
                DebugPrint("Added party member:", name, "Ready:", readyStatus == READY_CHECK_READY)
                startIndex = startIndex + 1
            end
        end
    end
    
    DebugPrint("Total players added to data:", #playerData)
end

-- Function to count ready players
local function CountReadyPlayers()
    local count = 0
    for _, data in pairs(playerData) do
        if data.ready then
            count = count + 1
        end
    end
    return count
end

-- Create the main frame
local function CreateMainFrame()
    DebugPrint("Creating main ready check frame")
    
    local frame = CreateFrame("Frame", "SLUReadyCheckFrame", UIParent, "BackdropTemplate")
    frame:SetSize(SLUReady.db.profile.width, SLUReady.db.profile.height)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        --edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        --tile = true,
        --tileSize = 32,
        --edgeSize = 32,
        --insets = {left = 11, right = 12, top = 12, bottom = 11},
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:Hide()
    
    -- Restore position
    local pos = SLUReady.db.profile.position
    frame:SetPoint(pos.point, pos.relativeTo, pos.relativePoint, pos.xOfs, pos.yOfs)
    
    -- Title bar
    local titleBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    titleBar:SetSize(frame:GetWidth() - 2, 30)
    titleBar:SetPoint("TOP", frame, "TOP", 0, -2)
    titleBar:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        --edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        --tile = true,
        --tileSize = 16,
        --edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4},
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
        SLUReady.db.profile.position = {
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
    titleText:SetText("<SL> U Ready: 0s")
    titleText:SetTextColor(0, 1, 0.6, 1)
    frame.titleText = titleText
    
    -- Ready count text
    local readyCount = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    readyCount:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
    readyCount:SetText("0/0")
    readyCount:SetTextColor(1, 1, 1, 1)
    frame.readyCount = readyCount
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeButton:SetSize(18, 18)
    closeButton:SetPoint("RIGHT", titleBar, "RIGHT", -6, 0)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    frame.closeButton = closeButton
    
    -- Content frame (no scrollbar needed since frame resizes based on players)
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 5, -5)
    content:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", -5, -5)
    content:SetHeight(200) -- Initial height, will be adjusted
    frame.content = content
    
    -- Column headers
    local columnHeaders = {
        --{name = "Name", width = 80},
        {name = "Food", width = 30},
        {name = "Flask", width = 30},
        {name = "Rune", width = 30},
        {name = "Vantus", width = 30},
        {name = "Int", width = 30},
        {name = "Atk", width = 30},
        {name = "Vers", width = 30},
        {name = "Stam", width = 30},
        {name = "Mast", width = 30},
        {name = "Move", width = 30},
        {name = "SS", width = 30},
        {name = "Dur%", width = 40},
    }
    
    frame.columnHeaders = columnHeaders
    frame.rows = {}
    
    -- Create header row
    -- name is left justified
    local nameText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("TOPLEFT", content, "TOPLEFT", 5, 0)
    nameText:SetText("Name")
    nameText:SetTextColor(1, 1, 0, 1)

    local xOffset = 100
    for i, header in ipairs(columnHeaders) do
        local headerText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        headerText:SetPoint("CENTER", content, "TOPLEFT", xOffset, -5)
        headerText:SetText(header.name)
        headerText:SetTextColor(1, 1, 0, 1)
        xOffset = xOffset + header.width
    end
    
    DebugPrint("Main frame created successfully")
    
    return frame
end

-- Function to create a row
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
    local iconOrder = {"Food", "Flask", "Rune", "Vantus", "Int", "Atk", "Vers", "Stam", "Mastery", "Move", "SS"}
    
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

-- Function to update row data
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
        if data.buffs.Durability < 50 then
            row.durText:SetTextColor(1, 0, 0, 1)
        elseif data.buffs.Durability < 75 then
            row.durText:SetTextColor(1, 1, 0, 1)
        else
            row.durText:SetTextColor(0, 1, 0, 1)
        end
    else
        row.durText:SetText("-")
        row.durText:SetTextColor(1, 1, 1, 1)
    end
end

-- Function to update the frame
local function UpdateFrame()
    if not mainFrame or not mainFrame:IsShown() then 
        DebugPrint("Frame not shown, skipping update")
        return 
    end
    
    DebugPrint("Updating frame display")
    
    UpdatePlayerData()
    
    -- Update title with remaining time
    local timeLeft = math.max(0, readyCheckEndTime - GetTime())
    mainFrame.titleText:SetFormattedText("<SL> U Ready: %.0fs", timeLeft)
    
    -- Update ready count
    local readyCount = CountReadyPlayers()
    local totalCount = GetNumGroupMembers()
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
    local frameHeight = 40 + contentHeight + 10 -- Title bar (40) + content + padding (10)
    mainFrame:SetHeight(frameHeight)
end

-- Event handlers
function SLUReady:READY_CHECK(event, initiator, duration)
    DebugPrint("READY_CHECK event triggered by", initiator, "for", duration, "seconds")
    
    if not IsInGroup() then 
        DebugPrint("Not in group, ignoring ready check")
        return 
    end
    
    readyCheckActive = true
    readyCheckEndTime = GetTime() + (duration or 40)
    
    DebugPrint("Ready check will end at:", readyCheckEndTime)
    
    if not mainFrame then
        mainFrame = CreateMainFrame()
    end
    
    mainFrame:Show()
    DebugPrint("Frame shown")
    UpdateFrame()
    
    -- Register events for updates
    self:RegisterEvent("UNIT_AURA", function(_, unit)
        if unit == "player" or unit:match("^raid%d+$") or unit:match("^party%d+$") then
            UpdateFrame()
        end
    end)
    
    self:RegisterEvent("READY_CHECK_CONFIRM", UpdateFrame)
    
    -- Cancel previous timer if it exists
    if closeTimer then
        closeTimer:Cancel()
    end
end

function SLUReady:READY_CHECK_FINISHED()
    DebugPrint("READY_CHECK_FINISHED event triggered")
    
    readyCheckActive = false
    
    -- Close window 5 seconds after ready check completes
    if closeTimer then
        closeTimer:Cancel()
    end
    
    DebugPrint("Starting 5 second timer to close window")
    
    closeTimer = C_Timer.NewTimer(5, function()
        DebugPrint("5 second timer expired, hiding frame")
        if mainFrame then
            mainFrame:Hide()
        end
        SLUReady:UnregisterEvent("UNIT_AURA")
        SLUReady:UnregisterEvent("READY_CHECK_CONFIRM")
    end)
end

-- Module initialization
function SLUReady:OnInitialize()
    DebugPrint("SLUReady module initializing")
    
    -- Initialize database
    self.db = AceDB:New("SLUReadyDB", self.defaults, true)
    
    DebugPrint("Database initialized")
    
    -- Register events
    self:RegisterEvent("READY_CHECK")
    self:RegisterEvent("READY_CHECK_FINISHED")
    
    DebugPrint("Events registered")
    
    -- Register slash command for debug
    SLASH_SLUR1 = "/slur"
    SlashCmdList["SLUR"] = function(msg)
        msg = msg:trim():lower()
        if msg == "debug" then
            debugMode = not debugMode
            if debugMode then
                print("|cff00ff98[SLUReady]|r Debug mode |cff00ff00ENABLED|r")
            else
                print("|cff00ff98[SLUReady]|r Debug mode |cffff0000DISABLED|r")
            end
        else
            print("|cff00ff98[SLUReady]|r Commands:")
            print("  /slur debug - Toggle debug mode")
        end
    end
    
    DebugPrint("Slash command registered")
    
    -- Module loaded message
    print("|cff00ff98[SLUReady]|r Module loaded successfully")
end

function SLUReady:OnEnable()
    DebugPrint("SLUReady module enabled")
end

function SLUReady:OnDisable()
    DebugPrint("SLUReady module disabled")
    if mainFrame then
        mainFrame:Hide()
    end
end

-- Update timer
local updateFrame = CreateFrame("Frame")
updateFrame:SetScript("OnUpdate", function(self, elapsed)
    if readyCheckActive and mainFrame and mainFrame:IsShown() then
        UpdateFrame()
    end
end)