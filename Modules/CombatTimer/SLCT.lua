local SLUI = select(2,...)

--- @class SLCT: AceModule, AceEvent-3.0
local SLCT = SLUI:NewModule("SLCT", "AceEvent-3.0")
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
    timerFrame:EnableMouse(false)
    timerFrame:Hide()

    -- Timer text
    timerText = timerFrame:CreateFontString(nil, "OVERLAY")
    timerText:SetPoint("CENTER")

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
local function FormatTime(sec)
    sec = math.floor(sec)
    return string.format("%d:%02d", math.floor(sec/60), sec%60)
end

-- Update timer display
local function UpdateTimerText()
    if not timerText then return end
    local combatTime = 0

    if state.combatStart then
        if state.combatEnd then
            combatTime = state.combatEnd - state.combatStart
        else
            combatTime = GetTime() - state.combatStart
        end
    end

    local text = state.moveMode and "0:00" or FormatTime(combatTime)

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
    if state.moveMode == true then
        SLCT:SetLocked(true)
    end
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

-- Register DB and Events
function SLCT:OnInitialize()
    sldb = SLUI.db.global.timer
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

    AddonPrint("loaded. Type |cffffcc00/slct help|r for commands.")
end

-- Initial Load. We have to slightly delay this so that talent information is available
function SLCT:OnEnable()
    DrawFrame()
    SLCT:ApplySettings()
    state.currentSpec = GetCurrentSpecRole()
    LoadPosition()

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
end

-- Slash commands
local function ShowHelp()
    AddonPrint("Available commands:")
    print("  |cffffffff/slct move|r - Toggle move mode")
    print("  |cffffffff/slct help|r - Show this help")
end

-- Lock/Unlock
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

-- Slash command handler
local function SlashCommandHandler(msg)
    local command = msg:match("^(%S*)%s*(.-)$")
    command = command:lower()

    if command == "move" then
        SLCT:SetLocked(not sldb.lock)
    elseif command == "help" or command == "" then
        ShowHelp()
    else
        AddonPrint("Unknown command. Type /slct help for options.")
    end
end

-- Register slash commands
SLASH_SLCT1 = "/slct"
SlashCmdList["SLCT"] = SlashCommandHandler