---@class SLUI
local SLUI = select(2, ...)
---@class InviteTools: AceModule, AceEvent-3.0, AceHook-3.0
local BreakTimer = SLUI:NewModule("BreakTimer", "AceEvent-3.0", "AceHook-3.0")
local MEDIA = LibStub("LibSharedMedia-3.0")
local COMMS = LibStub("AceComm-3.0")
local BASE_SIZE = 200

local defaultPosition = {
    point = "CENTER",
    x = -200,
    y = 100
}

SLUI.defaults.global.breakTimer = {
    enable = true,
    position = {-defaultPosition.x, defaultPosition.y},
    scale = 1,
}

function BreakTimer:OnInitialize()
    self:SetEnabledState(SLUI.db.global.breakTimer.enable)
end

function BreakTimer:OnEnable()
    self:RegisterEvent("PLAYER_REGEN_ENABLED", function() BreakTimer:UpdateVisibility() end)
    self:RegisterEvent("PLAYER_REGEN_DISABLED", function() BreakTimer:UpdateVisibility() end)
    self:RegisterMessage("SLUI_BREAK_DEBUG", function(_, timer) BreakTimer:StartBreak(timer, false) end)
    BigWigsLoader.RegisterMessage(SLUI, "BigWigs_StartBreak", function(_, _, seconds, _, _, reboot) end)
    BigWigsLoader.RegisterMessage(SLUI, "BigWigs_StopBreak", function(_, _, seconds, _, _, reboot) end)
    COMMS:RegisterComm("SLUI_BreakImage", function(_, index) BreakTimer:SetImage(SLUI.breakImages[index]) end)

    self:UpdateUIFromSettings()
end

function BreakTimer:OnDisable()
    self:UnregisterAllEvents()
    self:UnregisterAllMessages()
    BigWigsLoader.UnregisterMessage(SLUI, "BigWigs_StartBreak")
    BigWigsLoader.UnregisterMessage(SLUI, "BigWigs_StopBreak")
    COMMS:UnregisterComm("SLUI_Break")
end

local frame = CreateFrame("Frame", "SLUI_BreakTimer", UIParent, "BackdropTemplate")
frame:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
frame:SetBackdropBorderColor(0, 0, 0, 1)
frame:SetSize(BASE_SIZE, BASE_SIZE)

frame.texture = frame:CreateTexture(nil, "ARTWORK")
frame.texture:SetAllPoints()

frame.titleText = frame:CreateFontString(nil, "OVERLAY")
frame.titleText:SetPoint("BOTTOM", frame, "TOP", 0, 2)

frame.timerText = frame:CreateFontString(nil, "OVERLAY")
frame.timerText:SetPoint("TOP", frame, "BOTTOM", 0, -4)

BreakTimer.frame = frame

function BreakTimer:UpdateUIFromSettings()
    local font = MEDIA:Fetch("font", "Expressway.ttf") or "fonts/frizqt__.ttf"
    self.frame.titleText:SetFont(font, BASE_SIZE * 0.15, "OUTLINE")
    self.frame.timerText:SetFont(font, BASE_SIZE * 0.2, "OUTLINE")
    self.frame.titleText:SetText("On Break!")
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
    else
        local duration = C_DurationUtil.CreateDuration()
        duration:SetTimeFromStart(GetTime(), seconds)
        self.duration = duration
        self.timer = C_Timer.NewTicker(0.2, function() BreakTimer:UpdateTimer() end)
    end
end

function BreakTimer:UpdateTimer()
    if self.duration then
        local remaining = self.duration:GetRemainingDuration()
        if remaining <= 0 then
            self:StopBreak()
        else
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

function BreakTimer:StartBreak(seconds, reboot)
    -- Backup if the lead doesn't have SLUI or a reload is done
    if not self.frame.texture:GetTexture() then
        C_Timer.After(1, function()
            if not self:IsShown() then
                self:SetImage(frame:GetRandomImageIndex())
            end
        end)

        if not reboot and UnitIsGroupLeader("player") then
            COMMS:SendCommMessage("SLUI_Break", tostring(frame:GetRandomImageIndex()), UnitInRaid("player") and "RAID" or "PARTY")
        end
    end

    self:SetTimer(seconds)
end