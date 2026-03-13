--- @class SLUI
local SLUI = select(2, ...)
--- @class CombatTimer: AceModule, AceEvent-3.0
local CombatTimer = SLUI:NewModule("CombatTimer", "AceEvent-3.0")
local Media = LibStub("LibSharedMedia-3.0")
local fonts = Media:List(Media.MediaType.FONT)
local sldb

-- Defaults
SLUI.defaults.global.timer = {
    enabled = false,
    lock = true,
    font = "PT Sans Narrow",
    fontSize = 28,
    showBrackets = true,
    positions = {
        [1] = { point = "CENTER", x = 0, y = -100 }, -- Tank
        [2] = { point = "CENTER", x = 0, y = -100 }, -- Healer
        [3] = { point = "CENTER", x = 0, y = -100 }, -- DPS
    }
}

local function TimerDisabled()
    return not SLUI.db.global.timer.enabled
end

SLUI.options.args.timer = {
    name = "Combat Timer",
    type = "group",
    args = {
        enabled = {
            name = "Enabled",
            type = "toggle",
            get = function() return SLUI.db.global.timer.enabled end,
            set = function(_, value) SLUI.db.global.timer.enabled = value end,
            width = "normal",
            order = 0,
        },
        lock = {
            name = "Lock",
            type = "toggle",
            get = function() return SLUI.db.global.timer.lock end,
            set = function(_, value)
                CombatTimer:SetLocked(value)
            end,
            width = "double",
            disabled = TimerDisabled,
            order = 1,
        },
        font = {
            type = "select",
            name = "Font",
            values = fonts,
            get = function()
                for i, v in ipairs(fonts) do
                    if v == SLUI.db.global.timer.font then
                        return i
                    end
                end
            end,
            set = function(_, value)
                SLUI.db.global.timer.font = fonts[value]
                CombatTimer:ApplySettings()
            end,
            width = 1.2,
            disabled = TimerDisabled,
            order = 2,
        },
        textSize = {
            name = "Text Size",
            type = "range",
            min = 5,
            max = 60,
            bigStep = 1,
            get = function() return SLUI.db.global.timer.fontSize end,
            set = function(_, value)
                SLUI.db.global.timer.fontSize = value
                CombatTimer:ApplySettings()
            end,
            width = "normal",
            disabled = TimerDisabled,
            order = 3,
        },
        showBrackets = {
            name = "Brackets",
            type = "toggle",
            get = function() return SLUI.db.global.timer.showBrackets end,
            set = function(_, value)
                SLUI.db.global.timer.showBrackets = value
                CombatTimer:ApplySettings()
            end,
            width = "normal",
            disabled = TimerDisabled,
            order = 4,
        },
    }
}

-- Addon Messages
local function AddonPrint(...)
    print("|cff1e90ff[SLCT]|r", ...)
end

-- locals
local timerFrame, timerText, timerBg
local timerRefresh
local state = {
    combatStart = nil,
    combatEnd = nil,
    moveMode = false,
    currentSpec = 3 -- Default to DPS
}

local function CreateCombatTimer()
    -- Main timer frame
    timerFrame = CreateFrame("Frame", "SLCTFrame", UIParent)
    timerFrame:EnableMouse(false)
    timerFrame:Hide()

    -- Timer text
    timerText = timerFrame:CreateFontString(nil, "OVERLAY")
    timerText:SetPoint("CENTER")

    -- Background for visibility during unlock
    timerBg = timerFrame:CreateTexture(nil, "BACKGROUND")
    timerBg:SetAllPoints()
    timerBg:SetColorTexture(0, 0, 0, 0)
end

-- Show timer in combat and when unlocked if enabled
local function UpdateVisibility()
    if not timerFrame then return end
    if state.moveMode or (sldb.enabled and PlayerIsInCombat()) then
        timerFrame:Show()
    else
        timerFrame:Hide()
    end
end

-- Format time as M:SS
local function FormatTime(sec)
    return string.format("%d:%02d", sec / 60, sec % 60)
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

-- Determine role
local function GetCurrentSpecRole()
    local specIndex = GetSpecialization()
    if not specIndex then return 3 end -- Default to DPS. this should never happen, just a fallback

    local role = GetSpecializationRole(specIndex)

    if role == "TANK" then
        return 1
    elseif role == "HEALER" then
        return 2
    else
        return 3 -- DPS
    end
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

function CombatTimer:ApplySettings()
    if not timerFrame then return end

    -- Font
    local fontPath = Media:Fetch(Media.MediaType.FONT, sldb.font) or "Fonts\\FRIZQT__.TTF"
    timerText:SetFont(fontPath, sldb.fontSize, "OUTLINE")
    timerFrame:SetSize(sldb.fontSize * 3, sldb.fontSize + 4)

    -- Brackets change affects display text
    UpdateTimerText()
end

-- Entering combat
function CombatTimer:PLAYER_REGEN_DISABLED()
    if state.moveMode == true then
        CombatTimer:SetLocked(true)
    end
    state.combatStart = GetTime()
    state.combatEnd = nil
    UpdateTimerText()
    UpdateVisibility()

    if sldb.enabled and not timerRefresh then
        timerRefresh = C_Timer.NewTicker(1, UpdateTimerText)
    end
end

-- Leaving combat
function CombatTimer:PLAYER_REGEN_ENABLED()
    state.combatEnd = GetTime()

    if timerRefresh then
        timerRefresh:Cancel()
        timerRefresh = nil
    end

    UpdateVisibility()
end

-- Spec changed, save old position and load new one
function CombatTimer:PLAYER_SPECIALIZATION_CHANGED(_, unit)
    if unit ~= "player" then return end
    SavePosition()
    state.currentSpec = GetCurrentSpecRole()
    LoadPosition()
end

-- Register DB and Events
function CombatTimer:OnInitialize()
    sldb = SLUI.db.global.timer
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

    AddonPrint("loaded. Type |cffffcc00/slct help|r for commands.")
end

-- Initial Load. We have to slightly delay this so that talent information is available
function CombatTimer:OnEnable()
    CreateCombatTimer()
    CombatTimer:ApplySettings()
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
function CombatTimer:SetLocked(locked)
    sldb.lock = locked
    state.moveMode = not locked

    if state.moveMode then
        timerFrame:EnableMouse(true)
        timerFrame:SetMovable(true)
        timerFrame:RegisterForDrag("LeftButton")
        timerBg:SetColorTexture(0, 0, 0, 0.5)
        UpdateVisibility()
    else
        timerFrame:EnableMouse(false)
        timerFrame:SetMovable(false)
        timerBg:SetColorTexture(0, 0, 0, 0)
        SavePosition()
        UpdateVisibility()
    end

    UpdateTimerText()
    LibStub("AceConfigRegistry-3.0"):NotifyChange("SLUI")
end

-- Slash command handler
local function SlashCommandHandler(msg)
    local command = msg:match("^(%S*)%s*(.-)$")
    command = command:lower()

    if command == "move" then
        CombatTimer:SetLocked(not sldb.lock)
    elseif command == "help" or command == "" then
        ShowHelp()
    else
        AddonPrint("Unknown command. Type /slct help for options.")
    end
end

-- Register slash commands
SLASH_SLCT1 = "/slct"
SlashCmdList["SLCT"] = SlashCommandHandler
