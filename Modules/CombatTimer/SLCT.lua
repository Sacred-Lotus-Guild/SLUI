local SLUI = select(2,...)

--- @class SLCT: AceModule, AceEvent-3.0
local SLCT = SLUI:NewModule("SLCT", "AceEvent-3.0")
local sldb

-- Defaults
SLUI.defaults.global.timer = {
    enabled = false,
    showBrackets = true,
    positions = {
        [1] = { point = "CENTER", x = 0, y = -100 },  -- Tank
        [2] = { point = "CENTER", x = 0, y = -100 },  -- Healer
        [3] = { point = "CENTER", x = 0, y = -100 },  -- DPS
    }
}

-- Addon Messages
local function AddonPrint(...)
    print("|cff1e90ff[SLCT]|r", ...)
end

-- locals
local LSM = LibStub("LibSharedMedia-3.0")
local fontPath = LSM:Fetch("font", "PT Sans Narrow")
local timerRefresh
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown

local state = {
    combatStart = nil,
    combatEnd = nil,
    moveMode = false,
    currentSpec = 3  -- Default to DPS
}

-- Main timer frame
local timerFrame = CreateFrame("Frame", "SLCTFrame", UIParent)
timerFrame:SetSize(80, 36)
timerFrame:SetPoint("CENTER", 0, -100)
timerFrame:Hide()

-- Timer text
local timerText = timerFrame:CreateFontString(nil, "OVERLAY")
timerText:SetFont(fontPath, 28, "OUTLINE")
timerText:SetPoint("CENTER")
timerText:SetTextColor(1, 1, 1)
timerText:SetText("[0:00]")

-- Background for visibility during move mode
local timerBg = timerFrame:CreateTexture(nil, "BACKGROUND")
timerBg:SetAllPoints()
timerBg:SetColorTexture(0, 0, 0, 0)

-- Helper function to get current spec role
local function GetCurrentSpecRole()
    local specIndex = GetSpecialization()
    if not specIndex then return 3 end  -- Default to DPS. this should never happen, just a fallback
    
    local role = GetSpecializationRole(specIndex)

    if role == "TANK" then
        return 1
    elseif role == "HEALER" then
        return 2
    else
        return 3  -- DPS
    end
end

-- Format time as M:SS
local function FormatTime(seconds)
    seconds = math.floor(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%d:%02d", minutes, secs)
end

-- Update timer display
local function UpdateTimerText()
    local timeSec = 0

    if state.combatStart then
        if state.combatEnd then
            timeSec = state.combatEnd - state.combatStart
        else
            timeSec = GetTime() - state.combatStart
        end
    end

    local text = state.moveMode and "0:00" or FormatTime(timeSec)

    if sldb.showBrackets then
        text = "[" .. text .. "]"
    end

    timerText:SetText(text)
end

-- Save current position
local function SavePosition()
    local point, _, _, x, y = timerFrame:GetPoint()
    
    sldb.positions[state.currentSpec] = {
        point = point,
        x = x,
        y = y
    }
end

-- Load position for current spec
local function LoadPosition()
    local pos = sldb.positions[state.currentSpec]
    
    if pos then
        timerFrame:ClearAllPoints()
        timerFrame:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    end
end

-- Update loop
local function OnUpdate()
    if timerFrame:IsShown() then
        UpdateTimerText()
    end
end

-- Entering combat
function SLCT:PLAYER_REGEN_DISABLED()
    state.combatStart = GetTime()
    state.combatEnd = nil
    UpdateTimerText()

    if sldb.enabled then
        timerFrame:Show()
    end

    if sldb.enabled and not timerRefresh then
        timerRefresh = C_Timer.NewTicker(1, OnUpdate)
    end

end

-- Leaving combat
function SLCT:PLAYER_REGEN_ENABLED()
    state.combatEnd = GetTime()

    if timerRefresh then
        timerRefresh:Cancel()
        timerRefresh = nil
    end

    if not state.moveMode then
        timerFrame:Hide()
    end
end

-- Spec changed, save old position and load new one
function SLCT:PLAYER_SPECIALIZATION_CHANGED(event, unit)
    if unit ~= "player" then return end
    SavePosition()
    state.currentSpec = GetCurrentSpecRole()
    LoadPosition()
end

-- Initialize addon
function SLCT:OnInitialize()
    sldb = SLUI.db.global.timer
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

    AddonPrint("loaded. Type |cffffcc00/slct help|r for commands.")
end

function SLCT:OnEnable()
    -- Load initial position. we have to slightly delay this so that talent information is available
    state.currentSpec = GetCurrentSpecRole()
    LoadPosition()
    -- Start timer if we logged in midcombat 
    if InCombatLockdown() and sldb.enabled then
        SLCT:PLAYER_REGEN_DISABLED()
    end
        
    timerFrame:SetScript("OnDragStart", function(self)
        if state.moveMode then
            self:StartMoving()
        end
    end)
    
    timerFrame:SetScript("OnDragStop", function(self)
        if state.moveMode then
            self:StopMovingOrSizing()
            SavePosition()
        end
    end)
    
    -- Make clickthrough by default
    timerFrame:EnableMouse(false)
end

-- Slash commands
local function ShowHelp()
    AddonPrint("Available commands:")
    print("  |cffffffff/slct show|r - Toggle timer on/off")
    print("  |cffffffff/slct move|r - Toggle move mode")
    print("  |cffffffff/slct brackets|r - Toggle bracket display")
    print("  |cffffffff/slct help|r - Show this help")
end

-- Toggle timer visibility
local function ToggleTimer()
    sldb.enabled = not sldb.enabled
    
    if sldb.enabled then
        AddonPrint("Timer enabled")
        if InCombatLockdown() or state.moveMode then
            timerFrame:Show()
        end
    else
        AddonPrint("Timer disabled")
        timerFrame:Hide()
    end
end

-- Toggle move mode
local function ToggleMoveMode()
    state.moveMode = not state.moveMode
    
    if state.moveMode then
        timerFrame:EnableMouse(true)
        timerFrame:SetMovable(true)
        timerFrame:RegisterForDrag("LeftButton")
        timerBg:SetColorTexture(0, 0, 0, 0.5)
        timerFrame:Show()
        UpdateTimerText()
        AddonPrint("Move mode enabled. Drag to reposition.")
    else
        timerFrame:EnableMouse(false)
        timerFrame:SetMovable(false)
        timerBg:SetColorTexture(0, 0, 0, 0)
        SavePosition()
        UpdateTimerText()
        
        if not sldb.enabled or not InCombatLockdown() then
            timerFrame:Hide()
        end
        
        AddonPrint("Move mode disabled. Position saved.")
    end
end

-- Toggle brackets
local function ToggleBrackets()
    sldb.showBrackets = not sldb.showBrackets
    
    if sldb.showBrackets then
        AddonPrint("Brackets enabled")
    else
        AddonPrint("Brackets disabled")
    end
    
    UpdateTimerText()
end

-- Slash command handler
local function SlashCommandHandler(msg)
    local command, arg = msg:match("^(%S*)%s*(.-)$")
    command = command:lower()
    if command == "show" then
        ToggleTimer()
    elseif command == "move" then
        ToggleMoveMode()
    elseif command == "brackets" then
        ToggleBrackets()
    elseif command == "help" or command == "" then
        ShowHelp()
    else
        AddonPrint("Unknown command. Type /slct help for options.")
    end
end

-- Register slash commands
    SLASH_SLCT1 = "/slct"
    SlashCmdList["SLCT"] = SlashCommandHandler