--- @class SLUI
local SLUI = select(2, ...)
--- @class CombatTimer: AceModule, AceEvent-3.0
local CombatTimer = SLUI:NewModule("CombatTimer", "AceEvent-3.0")
local Media = LibStub("LibSharedMedia-3.0")
local fonts = Media:List(Media.MediaType.FONT)

-- Defaults
SLUI.defaults.global.timer = {
    enabled = false,
    lock = true,
    font = "PT Sans Narrow",
    fontSize = 28,
    showBrackets = true,
    positions = {
        [1] = { "CENTER", "UIParent", "CENTER", 0, -100 }, -- Tank
        [2] = { "CENTER", "UIParent", "CENTER", 0, -100 }, -- Healer
        [3] = { "CENTER", "UIParent", "CENTER", 0, -100 }, -- DPS
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
            set = function(_, value) CombatTimer:SetLocked(value) end,
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

-- Format time as M:SS
local function FormatTime(sec)
    return string.format("%d:%02d", sec / 60, sec % 60)
end

-- Update timer display
function CombatTimer:UpdateTimerText()
    if not self.text then return end
    local combatTime = 0

    if self.combatStart then
        if self.combatEnd then
            combatTime = self.combatEnd - self.combatStart
        else
            combatTime = GetTime() - self.combatStart
        end
    end

    local text = not self.db.lock and "0:00" or FormatTime(combatTime)

    if self.db.showBrackets then
        text = "[" .. text .. "]"
    end

    self.text:SetText(text)
end

function CombatTimer:ApplySettings()
    if not self.frame then return end

    self.frame:SetSize(self.db.fontSize * 3, self.db.fontSize + 4)
    self.frame:ClearAllPoints()
    self.frame:SetPoint(unpack(self.db.positions[self.currentSpec]))

    -- Font
    local fontPath = Media:Fetch(Media.MediaType.FONT, self.db.font) or "Fonts\\FRIZQT__.TTF"
    self.text:SetFont(fontPath, self.db.fontSize, "OUTLINE")
    -- Brackets change affects display text
    self:UpdateTimerText()
end

function CombatTimer:CreateFrame()
    if self.frame then return end

    -- Main timer frame
    local frame = CreateFrame("Frame", "SLCTFrame", UIParent)
    frame:EnableMouse(false)
    frame:Hide()

    frame:SetScript("OnDragStart", function(f)
        if not self.db.lock then
            f:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(f)
        if not self.db.lock then
            f:StopMovingOrSizing()
            self:SavePosition()
        end
    end)

    -- Timer text
    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    frame.text = text

    -- Background for visibility during unlock
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0)
    frame.bg = bg

    self.frame = frame
    self.text = text
    self.bg = bg
end

-- Show timer in combat and when unlocked if enabled
function CombatTimer:UpdateVisibility()
    if not self.frame then return end

    if not self.db.lock or (self.db.enabled and PlayerIsInCombat()) then
        self.frame:Show()
    else
        self.frame:Hide()
    end
end

-- Save current position
function CombatTimer:SavePosition()
    self.db.positions[self.currentSpec] = { self.frame:GetPoint() }
    LibStub("AceConfigRegistry-3.0"):NotifyChange("SLUI")
end

-- Load position for current spec
function CombatTimer:LoadPosition()
    self.frame:ClearAllPoints()
    self.frame:SetPoint(unpack(self.db.positions[self.currentSpec]))
end

-- Lock/Unlock
function CombatTimer:SetLocked(locked)
    self.db.lock = locked
    LibStub("AceConfigRegistry-3.0"):NotifyChange("SLUI")

    if not self.db.lock then
        self.frame:EnableMouse(true)
        self.frame:SetMovable(true)
        self.frame:RegisterForDrag("LeftButton")
        self.bg:SetColorTexture(0, 0, 0, 0.5)
        self:UpdateVisibility()
    else
        self.frame:EnableMouse(false)
        self.frame:SetMovable(false)
        self.bg:SetColorTexture(0, 0, 0, 0)
        self:SavePosition()
        self:UpdateVisibility()
    end

    self:UpdateTimerText()
end

-- Entering combat
function CombatTimer:PLAYER_REGEN_DISABLED()
    if not self.db.lock == true then
        CombatTimer:SetLocked(true)
    end
    self.combatStart = GetTime()
    self.combatEnd = nil
    self:UpdateTimerText()
    self:UpdateVisibility()

    if self.db.enabled and not self.timerRefresh then
        self.timerRefresh = C_Timer.NewTicker(1, function() self:UpdateTimerText() end)
    end
end

-- Leaving combat
function CombatTimer:PLAYER_REGEN_ENABLED()
    self.combatEnd = GetTime()

    if self.timerRefresh then
        self.timerRefresh:Cancel()
        self.timerRefresh = nil
    end

    self:UpdateVisibility()
end

-- Spec changed, save old position and load new one
function CombatTimer:PLAYER_SPECIALIZATION_CHANGED(_, unit)
    if unit ~= "player" then return end
    self:SavePosition()
    self.currentSpec = GetCurrentSpecRole()
    self:LoadPosition()
end

-- Addon Messages
local function AddonPrint(...)
    print("|cff1e90ff[SLCT]|r", ...)
end

-- Slash commands
local function ShowHelp()
    AddonPrint("Available commands:")
    print("  |cffffffff/slct move|r - Toggle move mode")
    print("  |cffffffff/slct help|r - Show this help")
end

-- Slash command handler
function CombatTimer:SlashCommandHandler(msg)
    local command = msg:match("^(%S*)%s*(.-)$")
    command = command:lower()
end

function CombatTimer:OnInitialize()
    self.db = SLUI.db.global.timer
    LibStub("AceConsole-3.0"):RegisterChatCommand("slct", function(msg)
        msg = msg:trim()
        if msg == "move" then
            self:SetLocked(not self.db.lock)
        elseif msg == "help" or msg == "" then
            ShowHelp()
        else
            AddonPrint("Unknown command. Type /slct help for options.")
        end
    end)
    AddonPrint("loaded. Type |cffffcc00/slct help|r for commands.")
end

-- Initial Load. We have to slightly delay this so that talent information is available
function CombatTimer:OnEnable()
    self.currentSpec = GetCurrentSpecRole()

    self:CreateFrame()
    self:ApplySettings()
    self:SetLocked(self.db.lock)

    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
end
