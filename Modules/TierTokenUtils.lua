--- @class SLUI
local SLUI = select(2, ...)
--- @class TierTokens: AceModule, AceHook-3.0
local TierTokens = SLUI:NewModule("TierTokens", "AceHook-3.0")

SLUI.defaults.global.tierTokens = {
    encounterJournal = true,
    tooltips = true,
}

SLUI.options.args.tierTokens = {
    name = "Tier Token Utils",
    type = "group",
    args = {
        encounterJournal = {
            name = "Encounter Journal",
            desc = "Add token names to the encounter journal.",
            type = "toggle",
            get = function() return SLUI.db.global.tierTokens.encounterJournal end,
            set = function(_, val) SLUI.db.global.tierTokens.encounterJournal = val end,
        },
        tooltips = {
            name = "Tooltips",
            desc = "Append armor type and item slot to tier token tooltips.",
            type = "toggle",
            get = function() return SLUI.db.global.tierTokens.tooltips end,
            set = function(_, val) SLUI.db.global.tierTokens.tooltips = val end,
        },
    },
}

local TIER_TOKENS = {
    --- Midnight
    --- 12.0
    [249347] = "Cloth Chest Token",      -- Alnwoven Riftbloom,
    [249348] = "Leather Chest Token",    -- Alncured Riftbloom,
    [249349] = "Mail Chest Token",       -- Alncast Riftbloom,
    [249350] = "Plate Chest Token",      -- Alnforged Riftbloom,
    [249351] = "Cloth Hand Token",       -- Voidwoven Hungering Nullcore,
    [249352] = "Leather Hand Token",     -- Voidcured Hungering Nullcore,
    [249353] = "Mail Hand Token",        -- Voidcast Hungering Nullcore,
    [249354] = "Plate Hand Token",       -- Voidforged Hungering Nullcore,
    [249355] = "Cloth Head Token",       -- Voidwoven Fanatical Nullcore,
    [249356] = "Leather Head Token",     -- Voidcured Fanatical Nullcore,
    [249357] = "Mail Head Token",        -- Voidcast Fanatical Nullcore,
    [249358] = "Plate Head Token",       -- Voidforged Fanatical Nullcore,
    [249359] = "Cloth Leg Token",        -- Voidwoven Corrupted Nullcore,
    [249360] = "Leather Leg Token",      -- Voidcured Corrupted Nullcore,
    [249361] = "Mail Leg Token",         -- Voidcast Corrupted Nullcore,
    [249362] = "Plate Leg Token",        -- Voidforged Corrupted Nullcore,
    [249363] = "Cloth Shoulder Token",   -- Voidwoven Unraveled Nullcore,
    [249364] = "Leather Shoulder Token", -- Voidcured Unraveled Nullcore,
    [249365] = "Mail Shoulder Token",    -- Voidcast Unraveled Nullcore,
    [249366] = "Plate Shoulder Token",   -- Voidforged Unraveled Nullcore,
}

--- @param tooltip GameTooltip
--- @param data TooltipData | { id: number? }
local function RenameTierTokens(tooltip, data)
    if not data.id or issecretvalue(data.id) or not TIER_TOKENS[data.id] then return end
    tooltip:AppendText(format(" (%s)", TIER_TOKENS[data.id]))
end

--- @param button Button | { itemID: number?, slot: FontString }
--- @param elementData { index: number }
local function AddTierTokenText(button, elementData)
    if not button.itemID or issecretvalue(button.itemID) or not TIER_TOKENS[button.itemID] then return end
    button.slot:SetText(TIER_TOKENS[button.itemID])
end

function TierTokens:OnEnable()
    if SLUI.db.global.tierTokens.encounterJournal then
        EventUtil.ContinueOnAddOnLoaded("Blizzard_EncounterJournal", function()
            self:SecureHook(EncounterJournalItemMixin, "Init", AddTierTokenText)
        end)
    end

    if SLUI.db.global.tierTokens.tooltips then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, RenameTierTokens)
    end
end

function TierTokens:OnDisable()
    self:UnhookAll()
end
