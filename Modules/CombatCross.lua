--- @class SLUI
local SLUI = select(2, ...)
--- @class CombatCross: AceModule, AceEvent-3.0
local CombatCross = SLUI:NewModule("CombatCross", "AceEvent-3.0")
local Media = LibStub("LibSharedMedia-3.0")

local FONT_SCALAR = 2

SLUI.defaults.global.combatCross = {
    enable = false,
    font = "Friz Quadrata TT",
    fontSize = 24,
    fontOutline = "OUTLINE",
    color = { 0, 1, 0, 1 },
    position = { "CENTER", "UIParent", "CENTER", 0, -10 },
}

SLUI.options.args.combatCross = {
    name = "Combat Cross",
    type = "group",
    args = {
        enable = {
            order = 0,
            name = "Enable",
            type = "toggle",
            get = function() return SLUI.db.global.combatCross.enable end,
            set = function(_, value)
                SLUI.db.global.combatCross.enable = value
                if value then CombatCross:Enable() else CombatCross:Disable() end
            end,
        },
        test = {
            order = 1,
            name = "Test",
            type = "toggle",
            disabled = function() return not SLUI.db.global.combatCross.enable end,
            get = function() return CombatCross.frame and CombatCross.frame:IsShown() end,
            set = function(_, value)
                if not CombatCross.frame then return end
                if value then
                    CombatCross.frame:Show()
                    CombatCross.frame:SetAlpha(1)
                else
                    CombatCross.frame:Hide()
                end
            end,
        },
        header = {
            type = "header",
            order = 2,
            name = "Combat Cross",
        },
        font = {
            order = 3,
            name = "Font",
            dialogControl = "LSM30_Font",
            type = "select",
            disabled = function() return not SLUI.db.global.combatCross.enable end,
            values = Media:HashTable(Media.MediaType.FONT),
            get = function() return SLUI.db.global.combatCross.font end,
            set = function(_, value)
                SLUI.db.global.combatCross.font = value
                CombatCross:ApplySettings()
            end,
        },
        fontSize = {
            order = 4,
            name = "Size",
            type = "range",
            disabled = function() return not SLUI.db.global.combatCross.enable end,
            min = 10,
            max = 72,
            step = 1,
            get = function() return SLUI.db.global.combatCross.fontSize end,
            set = function(_, value)
                SLUI.db.global.combatCross.fontSize = value
                CombatCross:ApplySettings()
            end,
        },
        fontOutline = {
            order = 5,
            name = "Outline",
            type = "select",
            disabled = function() return not SLUI.db.global.combatCross.enable end,
            values = {
                [""] = "None",
                ["OUTLINE"] = "Thin",
                ["THICKOUTLINE"] = "Thick",
                ["MONOCHROME"] = "Monochrome",
                ["MONOCHROMEOUTLINE"] = "Monochrome Thin",
                ["MONOCHROMETHICKOUTLINE"] = "Monochrome Thick",
            },
            get = function() return SLUI.db.global.combatCross.fontOutline end,
            set = function(_, value)
                SLUI.db.global.combatCross.fontOutline = value
                CombatCross:ApplySettings()
            end,
        },
        color = {
            order = 6,
            name = "Color",
            type = "color",
            disabled = function() return not SLUI.db.global.combatCross.enable end,
            hasAlpha = true,
            get = function() return unpack(SLUI.db.global.combatCross.color) end,
            set = function(_, r, g, b, a)
                SLUI.db.global.combatCross.color = { r, g, b, a }
                CombatCross:ApplySettings()
            end,
        },
        position = {
            order = 7,
            name = "Position",
            type = "group",
            inline = true,
            disabled = function() return not SLUI.db.global.combatCross.enable end,
            args = {
                point = {
                    order = 2,
                    name = "Anchor from",
                    type = "select",
                    values = SLUI.ANCHOR_POINTS,
                    get = function() return SLUI.db.global.combatCross.position[1] end,
                    set = function(_, value)
                        SLUI.db.global.combatCross.position[1] = value
                        CombatCross:ApplySettings()
                    end,
                },
                relativeTo = {
                    order = 1,
                    name = "Anchored to",
                    type = "input",
                    get = function() return SLUI.db.global.combatCross.position[2] end,
                    set = function(_, value)
                        SLUI.db.global.combatCross.position[2] = value
                        CombatCross:ApplySettings()
                    end,
                },
                relativePoint = {
                    order = 3,
                    name = "to frame's",
                    type = "select",
                    values = SLUI.ANCHOR_POINTS,
                    get = function() return SLUI.db.global.combatCross.position[3] end,
                    set = function(_, value)
                        SLUI.db.global.combatCross.position[3] = value
                        CombatCross:ApplySettings()
                    end,
                },
                offsetX = {
                    order = 4,
                    name = "X Offset",
                    type = "range",
                    min = -1000,
                    max = 1000,
                    bigStep = 1,
                    get = function() return SLUI.db.global.combatCross.position[4] end,
                    set = function(_, value)
                        SLUI.db.global.combatCross.position[4] = value
                        CombatCross:ApplySettings()
                    end,
                },
                offsetY = {
                    order = 5,
                    name = "Y Offset",
                    type = "range",
                    min = -1000,
                    max = 1000,
                    bigStep = 1,
                    get = function() return SLUI.db.global.combatCross.position[5] end,
                    set = function(_, value)
                        SLUI.db.global.combatCross.position[5] = value
                        CombatCross:ApplySettings()
                    end,
                },
            },
        },
    },
}

function CombatCross:ApplySettings()
    if not self.frame or not self.text then return end

    self.frame:ClearAllPoints()
    self.frame:SetPoint(unpack(self.db.position))

    self.text:SetFont(Media:Fetch(Media.MediaType.FONT, self.db.font), self.db.fontSize * FONT_SCALAR, self.db.fontOutline)
    self.text:SetTextColor(unpack(self.db.color))
end

function CombatCross:CreateFrame()
    if self.frame then return end

    local frame = CreateFrame("Frame", "SLCCFrame", UIParent)
    frame:SetSize(30, 30)
    frame:SetPoint(unpack(self.db.position))
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(100)
    frame:Hide()

    local text = frame:CreateFontString("SLCCText", "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    text:SetFont(Media:Fetch(Media.MediaType.FONT, self.db.font), self.db.fontSize * FONT_SCALAR, self.db.fontOutline)
    text:SetText("+")
    text:SetTextColor(unpack(self.db.color))
    frame.text = text

    self.frame = frame
    self.text = text
end

function CombatCross:PLAYER_REGEN_DISABLED()
    if self.frame then
        self.frame:SetAlpha(0)
        self.frame:Show()
        UIFrameFadeIn(self.frame, 0.3, 0, 1)
    end
end

function CombatCross:PLAYER_REGEN_ENABLED()
    if self.frame then
        UIFrameFadeOut(self.frame, 0.3, 1, 0)
        C_Timer.After(1, function()
            if self.frame then self.frame:Hide() end
        end)
    end
end

function CombatCross:OnInitialize()
    self.db = SLUI.db.global.combatCross
    self:SetEnabledState(self.db.enable)
end

function CombatCross:OnEnable()
    self:CreateFrame()
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function CombatCross:OnDisable()
    if self.frame then self.frame:Hide() end
    self:UnregisterAllEvents()
end
