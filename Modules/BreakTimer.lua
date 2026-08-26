---@class SLUI
local SLUI = select(2, ...)
---@class BreakTimer: AceModule, AceEvent-3.0, AceComm-3.0
local BreakTimer = SLUI:NewModule("BreakTimer", "AceEvent-3.0", "AceComm-3.0")
local media = LibStub("LibSharedMedia-3.0")

SLUI.defaults.global.breakTimer = {
    enable = true,
    font = "Friz Quadrata TT",
    fontSize = 40,
    fontOutline = "OUTLINE",
    position = { "CENTER", "UIParent", "CENTER", -400, 100 },
    size = 200,
    lowWarning = "",
    ttsVolume = 100,
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
        header = {
            type = "header",
            order = 2,
            name = "Break Timer",
        },
        font = {
            order = 10,
            name = "Font",
            dialogControl = "LSM30_Font",
            type = "select",
            disabled = function() return not SLUI.db.global.breakTimer.enable end,
            values = media:HashTable(media.MediaType.FONT),
            get = function() return SLUI.db.global.breakTimer.font end,
            set = function(_, value)
                SLUI.db.global.breakTimer.font = value
                BreakTimer:ApplySettings()
            end,
        },
        fontSize = {
            order = 11,
            name = "Size",
            type = "range",
            disabled = function() return not SLUI.db.global.breakTimer.enable end,
            min = 10,
            max = 100,
            bigStep = 1,
            get = function() return SLUI.db.global.breakTimer.fontSize end,
            set = function(_, value)
                SLUI.db.global.breakTimer.fontSize = value
                BreakTimer:ApplySettings()
            end,
        },
        fontOutline = {
            order = 12,
            name = "Outline",
            type = "select",
            disabled = function() return not SLUI.db.global.breakTimer.enable end,
            values = SLUI.OUTLINES,
            get = function() return SLUI.db.global.breakTimer.fontOutline end,
            set = function(_, value)
                SLUI.db.global.breakTimer.fontOutline = value
                BreakTimer:ApplySettings()
            end,
        },
        position = {
            order = 20,
            name = "Position",
            type = "group",
            inline = true,
            disabled = function() return not SLUI.db.global.breakTimer.enable end,
            args = {
                point = {
                    order = 2,
                    name = "Anchor from",
                    type = "select",
                    values = SLUI.ANCHOR_POINTS,
                    get = function() return SLUI.db.global.breakTimer.position[1] end,
                    set = function(_, value)
                        SLUI.db.global.breakTimer.position[1] = value
                        BreakTimer:ApplySettings()
                    end,
                },
                relativeTo = {
                    order = 1,
                    name = "Anchored to",
                    type = "input",
                    get = function() return SLUI.db.global.breakTimer.position[2] end,
                    set = function(_, value)
                        SLUI.db.global.breakTimer.position[2] = value
                        BreakTimer:ApplySettings()
                    end,
                },
                relativePoint = {
                    order = 3,
                    name = "to frame's",
                    type = "select",
                    values = SLUI.ANCHOR_POINTS,
                    get = function() return SLUI.db.global.breakTimer.position[3] end,
                    set = function(_, value)
                        SLUI.db.global.breakTimer.position[3] = value
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
                    get = function() return SLUI.db.global.breakTimer.position[4] end,
                    set = function(_, value)
                        SLUI.db.global.breakTimer.position[4] = value
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
                    get = function() return SLUI.db.global.breakTimer.position[5] end,
                    set = function(_, value)
                        SLUI.db.global.breakTimer.position[5] = value
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
        },
        lowTimeWarning = {
            order = 30,
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
            order = 31,
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
            order = 32,
            name = "Test",
            type = "execute",
            func = function() BreakTimer:PlayLowWarningMessage() end,
            width = "half",
        },
    },
}

function BreakTimer:ApplySettings()
    local font = media:Fetch(media.MediaType.FONT, self.db.font)
    local outline = self.db.fontOutline
    local fontSize = self.db.fontSize or 40
    local size = self.db.size or 200
    self.frame.titleText:SetFont(font, fontSize * 0.75, outline)
    self.frame.timerText:SetFont(font, fontSize, outline)
    self.frame.titleText:SetText("On Break!")
    self.frame:SetSize(size, size)
    self:UpdatePosition()
end

function BreakTimer:CreateBreakTimer()
    -- Ensure we only create this once
    if not self.frame then
        local frame = CreateFrame("Frame", "Break Timer", UIParent)
        frame:SetFrameLevel(80)

        frame.texture = frame:CreateTexture(nil, "ARTWORK")
        frame.texture:SetAllPoints()

        frame.titleText = frame:CreateFontString(nil, "OVERLAY")
        frame.titleText:SetPoint("BOTTOM", frame, "TOP", 0, 2)

        frame.timerText = frame:CreateFontString(nil, "OVERLAY")
        frame.timerText:SetPoint("TOP", frame, "BOTTOM", 0, -4)
        frame:Hide()

        self.frame = frame
    end
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

--- Show a placeholder break timer so position/size/font settings can be
--- previewed while the options page is open. Skipped if a real break is
--- already in progress so we don't clobber it.
function BreakTimer:ShowPlaceholder()
    self:CreateBreakTimer()
    if self.frame.texture:GetTexture() or self.duration then return end

    self.previewing = true
    self:ApplySettings()
    self:SetImage(nil)
    self.frame.timerText:SetText("0:00")
end

function BreakTimer:HidePlaceholder()
    if not self.previewing then return end
    self.previewing = false
    if not self.duration then
        self:ClearImage()
    end
end

function BreakTimer:SetTimer(seconds)
    if seconds <= 0 then
        self:ClearTimer()
    else
        local duration = C_DurationUtil.CreateDuration()
        duration:SetTimeFromStart(GetTime(), seconds)
        self.lowWarningTriggered = false
        self.duration = duration
        self.timer = C_Timer.NewTicker(0.2, function() self:UpdateTimer() end)
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
                self:PlayLowWarningMessage()
            end
            local minute, seconds = math.floor(remaining / 60), math.fmod(remaining, 60)
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
        elseif not UnitInRaid("PLAYER") and not UnitInParty("PLAYER") then
            self:SetImage(nil)
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
    self.frame:ClearAllPoints()
    self.frame:SetPoint(unpack(self.db.position))
end

function BreakTimer:PlayLowWarningMessage()
    if string.trim(self.db.lowWarning) ~= "" then
        C_VoiceChat.SpeakText(0, self.db.lowWarning, 1, self.db.ttsVolume, false)
    end
end

function BreakTimer:PLAYER_REGEN_DISABLED()
    self:UpdateVisibility()
end

function BreakTimer:PLAYER_REGEN_ENABLED()
    self:UpdateVisibility()
end

function BreakTimer:OnCommReceived(_, index)
    if self:IsEnabled() then
        self:SetImage(SLUI.breakImages[tonumber(index)])
    end
end

function BreakTimer:OnInitialize()
    self.db = SLUI.db.global.breakTimer
    self:SetEnabledState(self.db.enable)

    self:RegisterComm("SLUI_BreakImage")

    if SLUI.optionsFrame then
        SLUI.optionsFrame:HookScript("OnShow", function() self:ShowPlaceholder() end)
        SLUI.optionsFrame:HookScript("OnHide", function() self:HidePlaceholder() end)
    end
end

function BreakTimer:OnEnable()
    self:CreateBreakTimer()
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    if BigWigsLoader then
        BigWigsLoader.RegisterMessage(SLUI, "BigWigs_StartBreak", function(_, _, seconds, _, _, reboot) self:StartBreak(seconds, reboot, false) end)
        BigWigsLoader.RegisterMessage(SLUI, "BigWigs_StopBreak", function(_, _, seconds, _, _, reboot) self:StopBreak() end)
    end

    self:ApplySettings()

    if SLUI.optionsFrame and SLUI.optionsFrame:IsShown() then
        self:ShowPlaceholder()
    end
end

function BreakTimer:OnDisable()
    self:UnregisterAllEvents()
    self:UnregisterAllMessages()
    if BigWigsLoader then
        BigWigsLoader.UnregisterMessage(SLUI, "BigWigs_StartBreak")
        BigWigsLoader.UnregisterMessage(SLUI, "BigWigs_StopBreak")
    end

    self:HidePlaceholder()
end
