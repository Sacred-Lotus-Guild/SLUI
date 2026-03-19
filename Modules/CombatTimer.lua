--- @class SLUI
local SLUI = select(2, ...)
--- @class CombatTimer: AceModule, AceEvent-3.0
local CombatTimer = SLUI:NewModule("CombatTimer", "AceEvent-3.0")
local Media = LibStub("LibSharedMedia-3.0")

-- Defaults
SLUI.defaults.global.timer = {
    enabled = false,
    lock = true,
    font = "PT Sans Narrow",
    fontSize = 28,
    showBrackets = true,
    positions = {
        ["TANK"] = { "CENTER", "UIParent", "CENTER", 0, -100 },
        ["HEALER"] = { "CENTER", "UIParent", "CENTER", 0, -100 },
        ["DAMAGER"] = { "CENTER", "UIParent", "CENTER", 0, -100 },
    }
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

local function TimerDisabled()
    return not SLUI.db.global.timer.enabled
end

local fonts = Media:List(Media.MediaType.FONT)

-- Options
SLUI.options.args.timer = {
    name = "Combat Timer",
    type = "group",
    args = {
        enabled = {
            name = "Enabled",
            type = "toggle",
            get = function() return SLUI.db.global.timer.enabled end,
            set = function(_, value)
                SLUI.db.global.timer.enabled = value
                if value then CombatTimer:Enable() else CombatTimer:Disable() end
            end,
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
        position = {
            name = "Position",
            type = "group",
            inline = true,
            args = {
                description = {
                    order = 0,
                    name = function()
                        return format("Set the position for your %s specializations.", CombatTimer.currentSpec:lower())
                    end,
                    type = "description",

                },
                point = {
                    order = 2,
                    name = "Anchor from",
                    type = "select",
                    values = ANCHOR_POINTS,
                    get = function() return SLUI.db.global.timer.positions[CombatTimer.currentSpec][1] end,
                    set = function(_, value)
                        SLUI.db.global.timer.positions[CombatTimer.currentSpec][1] = value
                        CombatTimer:ApplySettings()
                    end,
                },
                relativeTo = {
                    order = 1,
                    name = "Anchored to",
                    type = "input",
                    get = function() return SLUI.db.global.timer.positions[CombatTimer.currentSpec][2] end,
                    set = function(_, value)
                        SLUI.db.global.timer.positions[CombatTimer.currentSpec][2] = value
                        CombatTimer:ApplySettings()
                    end,
                },
                relativePoint = {
                    order = 3,
                    name = "to frame's",
                    type = "select",
                    values = ANCHOR_POINTS,
                    get = function() return SLUI.db.global.timer.positions[CombatTimer.currentSpec][3] end,
                    set = function(_, value)
                        SLUI.db.global.timer.positions[CombatTimer.currentSpec][3] = value
                        CombatTimer:ApplySettings()
                    end,
                },
                offsetX = {
                    order = 4,
                    name = "X Offset",
                    type = "range",
                    min = -1000,
                    max = 1000,
                    bigStep = 1,
                    get = function() return SLUI.db.global.timer.positions[CombatTimer.currentSpec][4] end,
                    set = function(_, value)
                        SLUI.db.global.timer.positions[CombatTimer.currentSpec][4] = value
                        CombatTimer:ApplySettings()
                    end,
                },
                offsetY = {
                    order = 5,
                    name = "Y Offset",
                    type = "range",
                    min = -1000,
                    max = 1000,
                    bigStep = 1,
                    get = function() return SLUI.db.global.timer.positions[CombatTimer.currentSpec][5] end,
                    set = function(_, value)
                        SLUI.db.global.timer.positions[CombatTimer.currentSpec][5] = value
                        CombatTimer:ApplySettings()
                    end,
                },
            }
        }
    }
}

-- Determine role
local function GetCurrentSpecRole()
    return GetSpecializationRole(GetSpecialization())
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

    local text = FormatTime(combatTime)

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

    self.text:SetFont(Media:Fetch(Media.MediaType.FONT, self.db.font), self.db.fontSize, "OUTLINE")

    -- Brackets change affects display text
    self:UpdateTimerText()
    self:UpdateVisibility()
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
    local text = frame:CreateFontString("SCLTText", "OVERLAY")
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

    self.bg:SetColorTexture(0, 0, 0, self.db.lock and 0 or 0.5)
end

-- Save current position
function CombatTimer:SavePosition()
    local position = { self.frame:GetPoint() }
    position[2] = position[2] and position[2]:GetName() or "UIParent"
    self.db.positions[self.currentSpec] = position
    LibStub("AceConfigRegistry-3.0"):NotifyChange("SLUI")
end

-- Lock/Unlock
function CombatTimer:SetLocked(locked)
    self.db.lock = locked
    LibStub("AceConfigRegistry-3.0"):NotifyChange("SLUI")

    if self.db.lock then
        self.frame:EnableMouse(false)
        self.frame:SetMovable(false)
        self.bg:SetColorTexture(0, 0, 0, 0)
        self:SavePosition()
    else
        self.frame:EnableMouse(true)
        self.frame:SetMovable(true)
        self.frame:RegisterForDrag("LeftButton")
        self.bg:SetColorTexture(0, 0, 0, 0.5)
    end

    self:UpdateTimerText()
    self:UpdateVisibility()
end

-- Entering combat
function CombatTimer:PLAYER_REGEN_DISABLED()
    self.prevLockedState = self.db.lock
    self:SetLocked(true)

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
    self:SetLocked(self.prevLockedState or true)
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
    self:ApplySettings()
end

-- Addon Messages
local function AddonPrint(...)
    print(format("|cff00ff98%s|r", "SLUI Combat Timer"), ...)
end

local function HelpPrint(cmd, helptext)
    print(format("  |cffffcc00%s|r - %s", cmd, helptext))
end

-- Slash command handler
function CombatTimer:SlashCommandHandler(msg)
    msg = msg:trim()

    if msg == "move" then
        self:SetLocked(not self.db.lock)
    elseif msg == "help" or msg == "" then
        AddonPrint("Available commands:")
        HelpPrint("/slct move", "Toggle move mode")
        HelpPrint("/slct help", "Show this help")
    else
        AddonPrint("Unknown command. Type |cffffcc00/slct help|r for commands.")
    end
end

function CombatTimer:OnInitialize()
    self.db = SLUI.db.global.timer
    self:SetEnabledState(self.db.enabled)
    LibStub("AceConsole-3.0"):RegisterChatCommand("slct", function(msg) self:SlashCommandHandler(msg) end)
end

-- Initial Load. We have to slightly delay this so that talent information is available
function CombatTimer:OnEnable()
    AddonPrint("loaded. Type |cffffcc00/slct help|r for commands.")

    self.currentSpec = GetCurrentSpecRole()

    self:CreateFrame()
    -- Apply settings after frame is created
    C_Timer.After(0.1, function() self:ApplySettings() end)

    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
end

function CombatTimer:OnDisable()
    if self.timerRefresh then
        self.timerRefresh:Cancel()
        self.timerRefresh = nil
    end

    if self.frame then
        self.frame:Hide()
    end

    self:UnregisterAllEvents()
end
