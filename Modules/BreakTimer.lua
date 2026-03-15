---@class SLUI
local SLUI = select(2, ...)
---@class InviteTools: AceModule, AceEvent-3.0, AceHook-3.0
local BreakTimer = SLUI:NewModule("BreakTimer", "AceEvent-3.0", "AceHook-3.0")
local MEDIA = LibStub("LibSharedMedia-3.0")
local COMMS = LibStub("AceComm-3.0")
local EditMode = LibStub("LibEditMode")
local BASE_SIZE = 200
local TTS_LOW_TIME_WARNING = "Break ends in %d seconds"

local defaultPosition = {
    point = "CENTER",
    x = -200,
    y = 100
}

SLUI.options.args.breakTimer = {
    name = "Break Timer",
    type = "group",
    args = {
        enable = {
            order = 0,
            name = "Enable",
            desc = "Enable or disable the Break Timer module.",
            type = "toggle",
            get = function() return SLUI.db.global.breakTimer.enable end,
            set = function(_, val)
                SLUI.db.global.breakTimer.enable = val
                if val then BreakTimer:Enable() else BreakTimer:Disable() end
            end,
            width = "full",
        },
        lowTimeWarning = {
            order = 1,
            name = "60 Seconds Warning",
            desc = "TTS to play at 60 seconds",
            type = "input",
            get = function() return SLUI.db.global.breakTimer.lowWarning end,
            set = function(_, val)
                SLUI.db.global.breakTimer.lowWarning = val
            end,
            width = "double",
        },
        ttsVolume = {
            order = 3,
            name = "TTS Volume",
            desc = "Adds a TTS Message when the timer reaches. 0 disables the message.",
            type = "range",
            get = function() return SLUI.db.global.breakTimer.ttsVolume end,
            set = function(_, val)
                SLUI.db.global.breakTimer.ttsVolume = val
            end,
            min = 0,
            max = 100,
            bigStep = 1,
            width = "normal",
        },
        ttsTest = {
            order = 4,
            name = "Test",
            type = "execute",
            func = function() BreakTimer:PlayLowWarningMessage() end,
            width = "half",
        },
    }
}

local editModeSettings = {
    {
        name = 'Scale',
        kind = EditMode.SettingType.Slider,
        default = 1,
        get = function(layoutName)
            return SLUI.db.global.breakTimer.scale
        end,
        set = function(layoutName, value)
            SLUI.db.global.breakTimer.scale = value
            BreakTimer:UpdateUIFromSettings()
        end,
        minValue = 0.1,
        maxValue = 5,
        valueStep = 0.1,
        formatter = function(value)
            return FormatPercentage(value, true)
        end,
    }
}

SLUI.defaults.global.breakTimer = {
    enable = true,
    position = {-defaultPosition.x, defaultPosition.y},
    scale = 1,
    lowWarning = "",
    ttsVolume = 100,
}

function BreakTimer:OnInitialize()
    self:SetEnabledState(SLUI.db.global.breakTimer.enable)

    local function OnPositionChanged(frame, layoutName, point, x, y)
        SLUI.db.global.breakTimer.position = {x, y}
    end

    EditMode:RegisterCallback('layout', function(layoutName)
        BreakTimer:UpdatePosition()
    end)

    EditMode:AddFrame(BreakTimer.frame, OnPositionChanged, defaultPosition)

    EditMode:AddFrameSettings(BreakTimer.frame, editModeSettings)
    COMMS:RegisterComm("SLUI_BreakImage", function(_, index) 
        if BreakTimer:IsEnabled() then
            BreakTimer:SetImage(SLUI.breakImages[index]) 
        end
    end)
end

function BreakTimer:OnEnable()
    self:RegisterEvent("PLAYER_REGEN_ENABLED", function() BreakTimer:UpdateVisibility() end)
    self:RegisterEvent("PLAYER_REGEN_DISABLED", function() BreakTimer:UpdateVisibility() end)
    self:RegisterMessage("SLUI_BREAK_DEBUG", function(_, timer) BreakTimer:StartBreak(timer, false, true) end)
    BigWigsLoader.RegisterMessage(SLUI, "BigWigs_StartBreak", function(_, _, seconds, _, _, reboot) end)
    BigWigsLoader.RegisterMessage(SLUI, "BigWigs_StopBreak", function(_, _, seconds, _, _, reboot) end)

    self:UpdateUIFromSettings()
end

function BreakTimer:OnDisable()
    self:UnregisterAllEvents()
    self:UnregisterAllMessages()
    BigWigsLoader.UnregisterMessage(SLUI, "BigWigs_StartBreak")
    BigWigsLoader.UnregisterMessage(SLUI, "BigWigs_StopBreak")
end

local frame = CreateFrame("Frame", "Break Timer", UIParent)
frame:SetFrameLevel(80)
frame:SetSize(BASE_SIZE, BASE_SIZE)

frame.texture = frame:CreateTexture(nil, "ARTWORK")
frame.texture:SetAllPoints()

frame.titleText = frame:CreateFontString(nil, "OVERLAY")
frame.titleText:SetPoint("BOTTOM", frame, "TOP", 0, 2)

frame.timerText = frame:CreateFontString(nil, "OVERLAY")
frame.timerText:SetPoint("TOP", frame, "BOTTOM", 0, -4)
frame:Hide()

BreakTimer.frame = frame

function BreakTimer:UpdateUIFromSettings()
    local font = MEDIA:Fetch("font", "Expressway.ttf") or "fonts/frizqt__.ttf"
    self.frame.titleText:SetFont(font, BASE_SIZE * 0.15, "OUTLINE")
    self.frame.timerText:SetFont(font, BASE_SIZE * 0.2, "OUTLINE")
    self.frame.titleText:SetText("On Break!")
    self:UpdatePosition()
    self.frame:SetScale(SLUI.db.global.breakTimer.scale)
end

function BreakTimer:UpdateVisibility()
    self.frame:SetShown((self.editMode or self.frame.texture:GetTexture() ~= nil) and not PlayerIsInCombat())
end

function BreakTimer:GetRandomImageIndex()
    return math.random(#SLUI.breakImages)
end

function BreakTimer:SetImage(texture)
    self.frame.texture:SetTexture(texture or SLUI.breakBackupImage, "CLAMPTOBLACK", "CLAMPTOBLACK")
    self:UpdateVisibility()
end

function BreakTimer:ClearImage()
    self.frame.texture:SetTexture(nil)
    self:UpdateVisibility()
end

function BreakTimer:SetTimer(seconds)
    if seconds <= 0 then
        self:ClearTimer()
    else
        local duration = C_DurationUtil.CreateDuration()
        duration:SetTimeFromStart(GetTime(), seconds)
        self.lowWarningTriggered = false
        self.duration = duration
        self.timer = C_Timer.NewTicker(0.2, function() BreakTimer:UpdateTimer() end)
        self:UpdateTimer()
    end
end

function BreakTimer:UpdateTimer()
    if self.duration then
        local remaining = self.duration:GetRemainingDuration()
        if remaining <= 0 then
            self:StopBreak()
        else
            if remaining < 60 and not self.lowWarningTriggered then
                self.lowWarningTriggered = true
                BreakTimer:PlayLowWarningMessage()
            end
            local minute, seconds = math.floor(remaining/60), math.fmod(remaining, 60) 
            if minute > 0 then
                self.frame.timerText:SetFormattedText("%d:%02d", minute, seconds)
            else
                self.frame.timerText:SetFormattedText("%d", seconds)
            end
        end
    end
end

function BreakTimer:ClearTimer()
    self.duration = nil
    if self.timer then
        self.timer:Cancel()
        self.timer = nil
    end
end

function BreakTimer:StopBreak()
    self:ClearTimer()
    self:ClearImage()
end

function BreakTimer:StartBreak(seconds, reboot, debug)
    -- Backup if the lead doesn't have SLUI or a reload is done
    if not self.frame.texture:GetTexture() then
        if debug then
            self:SetImage(SLUI.breakImages[self:GetRandomImageIndex()])
        else
            C_Timer.After(1, function()
                if not self.frame:IsShown() then
                    self:SetImage(SLUI.breakImages[self:GetRandomImageIndex()])
                end
            end)

            if not reboot and UnitIsGroupLeader("player") then
                COMMS:SendCommMessage("SLUI_BreakImage", tostring(frame:GetRandomImageIndex()), UnitInRaid("player") and "RAID" or "PARTY")
            end
        end
    end

    self:SetTimer(seconds)
end

function BreakTimer:UpdatePosition()
    BreakTimer.frame:ClearAllPoints()
    BreakTimer.frame:SetPoint("CENTER", SLUI.db.global.breakTimer.position[1], SLUI.db.global.breakTimer.position[2])
end

function BreakTimer:PlayLowWarningMessage()
    if string.trim(SLUI.db.global.breakTimer.lowWarning) ~= "" then
        C_VoiceChat.SpeakText(0, SLUI.db.global.breakTimer.lowWarning, 1, SLUI.db.global.breakTimer.ttsVolume, false)
    end
end

EditMode:RegisterCallback('enter', function()
    if BreakTimer:IsEnabled() then
        BreakTimer.editMode = true
        BreakTimer:UpdateVisibility()
    end
end)

EditMode:RegisterCallback('exit', function()
    BreakTimer.editMode = false
    BreakTimer:UpdateVisibility()
end)