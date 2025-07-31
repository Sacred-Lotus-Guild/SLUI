--- @class SLUI
local SLUI = select(2, ...)
local DF = _G["DetailsFramework"]

local optionsButtonTemplate = DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE")

local versionCheckerOptions = {}
local VersionChecker = DF:CreateSimplePanel(UIParent, 900, 515, "SLUI Version Checker", "VersionChecker",
    versionCheckerOptions)
VersionChecker:SetPoint("CENTER");
VersionChecker:SetFrameStrata("HIGH")

function VersionChecker:BuildQueryFrame(parent)
    local function checkVersions() end

    local checkVersionsButton = DF:CreateButton(parent, checkVersions, 120, 22, "Check Versions")
    checkVersionsButton:SetTemplate(optionsButtonTemplate)
    checkVersionsButton:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -30, -75)
    checkVersionsButton:SetHook("OnShow", function(button)
        if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
            button:Enable()
        else
            button:Disable()
        end
    end)

    local function refresh() end
    local function createLine() end

    local queryFrame = DF:CreateScrollBox(parent, "VersionCheckerScrollbox", refresh, {}, 860, 400, 20,
        createLine)
    DF:ReskinSlider(queryFrame)
    queryFrame.ReajustNumFrames = true
    queryFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -100)
end

function VersionChecker:Init()
    DF:CreateScaleBar(self, SLUI.db.global.ui)
    self:SetScale(SLUI.db.global.ui.scale)

    local tabContainer = DF:CreateTabContainer(self, "SLUI Version Checker", "SLUI_TabTemplate",
        { { name = "Query", text = "Query" }, { name = "Config", text = "Config" } },
        {
            width = 900,
            height = 510,
            backdrop_color = { 0, 0, 0, 0.2 },
            backdrop_border_color = { 0.1, 0.1, 0.1, 0.4 }
        })
    tabContainer:SetPoint("CENTER", self, "CENTER", 0, 0)

    local queryTab = tabContainer:GetTabFrameByName("Query")
    local configTab = tabContainer:GetTabFrameByName("Config")

    self:BuildQueryFrame(queryTab)
end

function VersionChecker:Toggle()
    if VersionChecker:IsShown() then
        VersionChecker:Hide()
    else
        VersionChecker:Show()
    end
end

SLUI.VersionChecker = VersionChecker
