---@class SLUI
local SLUI = select(2, ...)
---@class InviteTools: AceModule, AceEvent-3.0, AceHook-3.0
local BreakTimer = SLUI:NewModule("BreakTimer", "AceEvent-3.0", "AceComm-3.0")
local media = LibStub("LibSharedMedia-3.0")

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
        position = {
            order = 20,
            name = "Position",
            type = "group",
            inline = true,
            args = {
                point = {
                    order = 2,
                    name = "Point",
                    type = "select",
                    values = SLUI.ANCHOR_POINTS,
                    get = function() return SLUI.db.global.breakTimer.point end,
                    set = function(_, value)
                        SLUI.db.global.breakTimer.point = value
                        BreakTimer:ApplySettings()
                    end,
                },
                offsetX = {
                    order = 4,
                    name = "X Offset",
                    type = "range",
                    min = -1000,
                    max = 1000,
                    bigStep = 1,
                    get = function() return SLUI.db.global.breakTimer.offsetX end,
                    set = function(_, value)
                        SLUI.db.global.breakTimer.offsetX = value
                        BreakTimer:ApplySettings()
                    end,
                },
                offsetY = {
                    order = 5,
                    name = "Y Offset",
                    type = "range",
                    min = -1000,
                    max = 1000,
                    bigStep = 1,
                    get = function() return SLUI.db.global.breakTimer.offsetY end,
                    set = function(_, value)
                        SLUI.db.global.breakTimer.offsetY = value
                        BreakTimer:ApplySettings()
                    end,
                },
                size = {
                    order = 6,
                    name = "Size",
                    type = "range",
                    min = 10,
                    max = 1000,
                    bigStep = 1,
                    get = function() return SLUI.db.global.breakTimer.size end,
                    set = function(_, value)
                        SLUI.db.global.breakTimer.size = value
                        BreakTimer:ApplySettings()
                    end,
                },
            },
        }
    },
}

SLUI.defaults.global.breakTimer = {
    enable = true,
    point = "CENTER",
    offsetX = -400,
    offsetY = 100,
    size = 200,
    lowWarning = "",
    ttsVolume = 100,
}

function BreakTimer:OnInitialize()
    self:CreateBreakTimer()
    self:SetEnabledState(SLUI.db.global.breakTimer.enable)

    self:RegisterComm("SLUI_BreakImage", function(_, index) 
        if BreakTimer:IsEnabled() then
            BreakTimer:SetImage(SLUI.breakImages[index]) 
        end
    end)
end

function BreakTimer:OnEnable()
    self:RegisterEvent("PLAYER_REGEN_ENABLED", function() BreakTimer:UpdateVisibility() end)
    self:RegisterEvent("PLAYER_REGEN_DISABLED", function() BreakTimer:UpdateVisibility() end)
    if BigWigsLoader then
        BigWigsLoader.RegisterMessage(SLUI, "BigWigs_StartBreak", function(_, _, seconds, _, _, reboot) self:StartBreak(seconds, reboot) end)
        BigWigsLoader.RegisterMessage(SLUI, "BigWigs_StopBreak", function(_, _, seconds, _, _, reboot) self:StopBreak() end)
    end

    self:ApplySettings()
end

function BreakTimer:OnDisable()
    self:UnregisterAllEvents()
    self:UnregisterAllMessages()
    if BigWigsLoader then
        BigWigsLoader.UnregisterMessage(SLUI, "BigWigs_StartBreak")
        BigWigsLoader.UnregisterMessage(SLUI, "BigWigs_StopBreak")
    end
end

function BreakTimer:CreateBreakTimer()
   local frame = CreateFrame("Frame", "Break Timer", UIParent)
    frame:SetFrameLevel(80)

    frame.texture = frame:CreateTexture(nil, "ARTWORK")
    frame.texture:SetAllPoints()

    frame.titleText = frame:CreateFontString(nil, "OVERLAY")
    frame.titleText:SetPoint("BOTTOM", frame, "TOP", 0, 2)

    frame.timerText = frame:CreateFontString(nil, "OVERLAY")
    frame.timerText:SetPoint("TOP", frame, "BOTTOM", 0, -4)
    frame:Hide()

    BreakTimer.frame = frame
end

function BreakTimer:ApplySettings()
    local font = media:Fetch("font", "Expressway.ttf") or "fonts/frizqt__.ttf"
    local size = SLUI.db.global.breakTimer.size or 200
    self.frame.titleText:SetFont(font, size * 0.15, "OUTLINE")
    self.frame.timerText:SetFont(font, size * 0.2, "OUTLINE")
    self.frame.titleText:SetText("On Break!")
    self.frame:SetSize(size, size)
    self:UpdatePosition()
end

function BreakTimer:UpdateVisibility()
    self.frame:SetShown(self.frame.texture:GetTexture() ~= nil and not PlayerIsInCombat())
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
                self:SendCommMessage("SLUI_BreakImage", tostring(self:GetRandomImageIndex()), UnitInRaid("player") and "RAID" or "PARTY")
            end
        end
    end

    self:SetTimer(seconds)
end

function BreakTimer:UpdatePosition()
    BreakTimer.frame:ClearAllPoints()
    BreakTimer.frame:SetPoint(SLUI.db.global.breakTimer.point, UIParent, SLUI.db.global.breakTimer.point, SLUI.db.global.breakTimer.offsetX, SLUI.db.global.breakTimer.offsetY)
end

function BreakTimer:PlayLowWarningMessage()
    if string.trim(SLUI.db.global.breakTimer.lowWarning) ~= "" then
        C_VoiceChat.SpeakText(0, SLUI.db.global.breakTimer.lowWarning, 1, SLUI.db.global.breakTimer.ttsVolume, false)
    end
end