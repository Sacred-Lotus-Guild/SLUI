local SLUI = select(2, ...)

local AceComm = LibStub("AceComm-3.0")
local EVENT = "SLUI_REMINDER"
local TIME_VISIBLE = 5

----------------------------------------------------------------------------------------------------------

local activeReminders = {}
local frame = CreateFrame("Frame", nil, UIParent)
frame:SetFrameStrata("HIGH")
frame:SetPoint("CENTER", nil, "CENTER")

frame.text = frame:CreateFontString(nil, "OVERLAY") 
frame.text:SetJustifyH("CENTER")
frame.text:SetJustifyV("MIDDLE")
frame.text:SetAllPoints()
frame.text:SetTextColor(1, 1, 1, 1)

local function UpdateReminders()
    local text = ""
    for i, reminder in ipairs(activeReminders) do
        local data = SLUI.reminders:GetReminderData(reminder)
        if data then
            text = text..data.message
            if i < #reminder then
                text = text.."\n"
            end
        end
    end

    local font = SLUI.media:Fetch(SLUI.media.MediaType.FONT, SLUI.defaults.global.reminders.common.font) or "Fonts\\FRIZQT__.TTF"
    frame:SetSize(200, #activeReminders * SLUI.defaults.global.reminders.common.fontSize)
    frame.text:SetFont(font, SLUI.defaults.global.reminders.common.fontSize, "OUTLINE")
    frame.text:SetText(text)
end


local function PopOldestReminder()
    table.remove(activeReminders, 1)
    UpdateReminders()
end

local function HasReminder(name)
    for _, reminder in ipairs(activeReminders) do
        if reminder == name then
            return true
        end
    end

    return false
end

local function ShowReminder(name)
    if not HasReminder(name) then        
        table.insert(activeReminders, name)
        C_Timer.After(TIME_VISIBLE, function() PopOldestReminder() end)

        local sound = SLUI.media:Fetch(SLUI.media.MediaType.SOUND, SLUI.db.global.reminders.common.sound)
        print(sound)
        if sound then
            PlaySoundFile(sound, SLUI.db.global.reminders.common.soundChannel)
        end
        UpdateReminders()
    end
end

local function OnEvent(self, event, _, _, spellId)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if InCombatLockdown() then
            return
        end

        local name = SLUI.reminders.idToName[spellId]
        if name then
            if UnitInParty("player") then
                AceComm:SendCommMessage(event, name, "PARTY")

            elseif UnitInRaid("player") then
                AceComm:SendCommMessage(event, name, "RAID")
            end
        end

    elseif event == "PLAYER_REGEN_DISABLED" then
        frame:Hide()
    elseif event == "PLAYER_REGEN_ENABLED" then
        frame:Show()
    end
end

local function OnReminderReceived(name)
    if not InCombatLockdown() then
        ShowReminder(name)
    end
end

function SLUI.reminders:TestReminder()
    ShowReminder("TEST")
end 

AceComm:RegisterComm(EVENT, OnReminderReceived)
frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:HookScript("OnEvent", OnEvent)
