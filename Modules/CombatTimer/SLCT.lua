local SLUI = select(2,...)

--- @class SLCT: AceModule, AceEvent-3.0
local SLCT = SLUI:NewModule("SLCT", "AceEvent-3.0")
SLUI.SLCT = SLCT
local sldb

-- Addon Messages
local function AddonPrint(...)
    print("|cff1e90ff[SLCT]|r", ...)
end

-- locals
local timerFrame
local timerText
local timerBg
local timerRefresh
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown

local state = {
    combatStart = nil,
    combatEnd = nil,
    moveMode = false,
    currentSpec = 3  -- Default to DPS
}

local function DrawFrame()
    -- Main timer frame
    timerFrame = CreateFrame("Frame", "SLCTFrame", UIParent)
    timerFrame:SetSize(sldb.fontSize * 3, sldb.fontSize + 4)
    timerFrame:SetPoint("CENTER", 0, -100)
    timerFrame:Hide()

    -- Timer text
    local fontPath = SLUI.media:Fetch(SLUI.media.MediaType.FONT, sldb.font) or "Fonts\\FRIZQT__.TTF"
    timerText = timerFrame:CreateFontString(nil, "OVERLAY")
    timerText:SetFont(fontPath, sldb.fontSize, "OUTLINE")
    timerText:SetPoint("CENTER")
    timerText:SetTextColor(1, 1, 1)
    timerText:SetText("[0:00]")

    -- Background for visibility during move mode
    timerBg = timerFrame:CreateTexture(nil, "BACKGROUND")
    timerBg:SetAllPoints()
    timerBg:SetColorTexture(0, 0, 0, 0)
end

-- Determine role
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
    if not timerText then return end
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

function SLCT:ApplySettings()
    if not timerText then return end

    -- Font
    local fontPath = SLUI.media:Fetch(SLUI.media.MediaType.FONT, sldb.font) or "Fonts\\FRIZQT__.TTF"
    timerText:SetFont(fontPath, sldb.fontSize, "OUTLINE")
    timerFrame:SetSize(sldb.fontSize * 3, sldb.fontSize + 4)

    -- Brackets change affects display text
    UpdateTimerText()
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
        timerRefresh = C_Timer.NewTicker(1, UpdateTimerText)
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
function SLCT:PLAYER_SPECIALIZATION_CHANGED(_, unit)
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
    DrawFrame()
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
    LibStub("AceConfigRegistry-3.0"):NotifyChange("SLUI")
    
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

-- Toggle lock mode
function SLCT:SetLocked(locked)
    sldb.lock = locked
    state.moveMode = not locked

    if state.moveMode then
        timerFrame:EnableMouse(true)
        timerFrame:SetMovable(true)
        timerFrame:RegisterForDrag("LeftButton")
        timerBg:SetColorTexture(0,0,0,0.5)
        timerFrame:Show()
    else
        timerFrame:EnableMouse(false)
        timerFrame:SetMovable(false)
        timerBg:SetColorTexture(0,0,0,0)
        SavePosition()

        if not sldb.enabled or not InCombatLockdown() then
            timerFrame:Hide()
        end
    end

    UpdateTimerText()
    LibStub("AceConfigRegistry-3.0"):NotifyChange("SLUI")
end


-- Toggle brackets
local function ToggleBrackets()
    sldb.showBrackets = not sldb.showBrackets
    LibStub("AceConfigRegistry-3.0"):NotifyChange("SLUI")
    
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
        SLCT:SetLocked(not sldb.lock)
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