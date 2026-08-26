---@class SLUI
local SLUI = select(2, ...)
---@class InviteTools: AceModule, AceEvent-3.0, AceHook-3.0
local InviteTools = SLUI:NewModule("InviteTools", "AceEvent-3.0", "AceHook-3.0")

SLUI.defaults.global.invite = {
    enable = true,
    keywords = { "inv", "invite", "raidinv", },
    characters = {},
    guildRank = 1,
    autoAccept = false,
}

SLUI.options.args.invite = {
    name = "Invite Tools",
    type = "group",
    args = {
        enable = {
            order = 0,
            name = "Enable",
            desc = "Enable or disable the Invite Tools module.",
            type = "toggle",
            get = function() return SLUI.db.global.invite.enable end,
            set = function(_, val)
                SLUI.db.global.invite.enable = val
                if val then InviteTools:Enable() else InviteTools:Disable() end
            end,
        },
        header = {
            type = "header",
            order = 1,
            name = "Invite Tools",
        },
        keywords = {
            order = 2,
            name = "Keywords",
            desc = "List of keywords to trigger an invite.",
            type = "input",
            get = function() return table.concat(SLUI.db.global.invite.keywords, " ") end,
            set = function(_, val)
                SLUI.db.global.invite.keywords = {}
                for _, keyword in ipairs({ strsplit(" ", val:trim():lower()) }) do
                    if keyword ~= "" then
                        tinsert(SLUI.db.global.invite.keywords, keyword)
                    end
                end
            end,
            disabled = function() return not SLUI.db.global.invite.enable end,
            width = "full",
        },
        characters = {
            order = 3,
            name = "Auto-promote characters",
            desc = "List of characters to auto-promote to assist when they join the group.",
            type = "input",
            get = function() return table.concat(SLUI.db.global.invite.characters, " ") end,
            set = function(_, val)
                SLUI.db.global.invite.characters = {}
                for _, name in ipairs({ strsplit(" ", val:trim()) }) do
                    if name ~= "" then
                        tinsert(SLUI.db.global.invite.characters, Ambiguate(name, "none"))
                    end
                end
            end,
            disabled = function() return not SLUI.db.global.invite.enable end,
            width = "full",
        },
        guildRank = {
            order = 4,
            name = "Auto-promote rank",
            desc = "Auto-promote characters of this guild rank or \"higher\" (actually a lower index value).",
            type = "select",
            get = function() return SLUI.db.global.invite.guildRank end,
            set = function(_, val)
                SLUI.db.global.invite.guildRank = val
                InviteTools:GUILD_ROSTER_UPDATE()
            end,
            values = function()
                local ranks = {}
                for i = 1, GuildControlGetNumRanks() do
                    local rankName = GuildControlGetRankName(i)
                    if rankName then
                        ranks[i] = i .. " - " .. rankName
                    end
                end
                return ranks
            end,
            disabled = function() return not SLUI.db.global.invite.enable or not IsInGuild() end,
        },
        autoAccept = {
            order = 5,
            name = "Auto Accept Invites",
            desc = "Automatically accept group invites from Battle.net friends, character friends, or guild members.",
            type = "toggle",
            get = function() return SLUI.db.global.invite.autoAccept end,
            set = function(_, val) SLUI.db.global.invite.autoAccept = val end,
            disabled = function() return not SLUI.db.global.invite.enable end,
        },
    }
}

--- Returns true if the player will suggest invite instead of invite themselves.
local function WillSuggestInvite()
    return IsInGroup() and not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player"))
end

--- Returns true if the inviter is a Battle.net friend, character friend, or guild member.
local function ShouldAcceptInvite(inviterGUID)
    return C_BattleNet.GetGameAccountInfoByGUID(inviterGUID) or C_FriendList.IsFriend(inviterGUID) or IsGuildMember(inviterGUID)
end

--- Cache a list of guild members that should be promoted based on the configured
--- minimum guild rank.
function InviteTools:GUILD_ROSTER_UPDATE()
    if InCombatLockdown() or not IsInGuild() then return end
    wipe(self.promoteGuildMembers)

    -- Request updated guild roster information from the server.
    C_GuildInfo.GuildRoster()

    local numGuildMembers = GetNumGuildMembers() or 0
    for i = 1, numGuildMembers do
        local name, _, rankIndex = GetGuildRosterInfo(i)

        -- The `rankIndex` returned is 0-indexed while guildRank from
        -- `GuildControlGetRankName` is 1-indexed, so we use < rather than
        -- <= here to compare them.
        -- see: https://warcraft.wiki.gg/wiki/API_GetGuildRosterInfo
        if name and rankIndex < self.db.guildRank then
            tinsert(self.promoteGuildMembers, Ambiguate(name, "none"))
        end
    end
end

--- Convert to a raid if we're at 5 group members.
function InviteTools:CheckAndConvertToRaid()
    if not IsInRaid() and GetNumGroupMembers() == 5 then
        C_PartyInfo.ConvertToRaid()
    end
end

--- Handle whispers for invite keywords.
function InviteTools:CHAT_MSG_WHISPER(_, text, playerName)
    if WillSuggestInvite() or issecretvalue(text) or issecretvalue(playerName) then return end

    -- BNet friends fire both CHAT_MSG_WHISPER and CHAT_MSG_BN_WHISPER;
    -- the whisper sender for BNet is an encoded name ("|Kxxxx|k"), skip it
    if playerName:find("|K") then return end

    if tContains(self.db.keywords, text:trim():lower()) then
        self:CheckAndConvertToRaid();
        C_PartyInfo.InviteUnit(Ambiguate(playerName, "none"))
    end
end

--- Auto-accept a group invite from a Battle.net friend, character friend, or
--- guild member (ported from AtrocityEssentials/ElvUI's Misc:AutoInvite).
function InviteTools:PARTY_INVITE_REQUEST(_, _, _, _, _, _, _, inviterGUID)
    if not self.db.autoAccept or not inviterGUID or issecretvalue(inviterGUID) or IsInGroup() then return end

    -- Don't accept an invite while queued for LFG/PvP.
    if QueueStatusButton and QueueStatusButton:IsShown() then return end

    if ShouldAcceptInvite(inviterGUID) then
        self.inviteAccepted = true
        AcceptGroup()
    end
end

--- Handle Battle.net whispers for invite keywords.
function InviteTools:CHAT_MSG_BN_WHISPER(_, text, _, _, _, _, _, _, _, _, _, _, _, bnSenderID)
    if WillSuggestInvite() or issecretvalue(text) or issecretvalue(bnSenderID) then return end

    if tContains(self.db.keywords, text:trim():lower()) then
        local accountInfo = C_BattleNet.GetAccountInfoByID(bnSenderID)
        if accountInfo and accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.gameAccountID then
            self:CheckAndConvertToRaid()

            local gameAccountID = accountInfo.gameAccountInfo.gameAccountID
            BNInviteFriend(gameAccountID)
        end
    end
end

--- Returns true if the player should be promoted to assistant based on their
--- guild rank or character name.
---@param unit string
---@return boolean
function InviteTools:ShouldPromote(unit)
    if issecretvalue(unit) or self.demotedPlayers[UnitName(unit)] then return false end

    local name = Ambiguate(unit, "none")
    return tContains(self.promoteGuildMembers, name) or tContains(self.db.characters, name)
end

--- Auto-promote players to assistant when they join the raid if they are in the
--- configured list of characters or have the required guild rank. Also hides
--- the invite popup once an auto-accepted invite has actually gone through --
--- it otherwise lingers until the roster updates.
function InviteTools:GROUP_ROSTER_UPDATE()
    if self.inviteAccepted then
        if LFGInvitePopup then
            StaticPopupSpecial_Hide(LFGInvitePopup)
        end
        StaticPopup_Hide("PARTY_INVITE")
        self.inviteAccepted = nil
    end

    if not IsInRaid() or not UnitIsGroupLeader("player") then return end

    -- It's discouraged to use GetNumGroupMembers() since there can be "holes"
    -- between raid1 to raid40.
    -- see: https://warcraft.wiki.gg/wiki/API_GetRaidRosterInfo
    for i = 1, MAX_RAID_MEMBERS do
        local name, rank = GetRaidRosterInfo(i)
        if name and rank < 1 then
            if self:ShouldPromote(name) then
                PromoteToAssistant(name)
            end
        end
    end
end

function InviteTools:GROUP_JOINED()
    wipe(self.demotedPlayers)
end

function InviteTools:GROUP_FORMED()
    wipe(self.demotedPlayers)
end

function InviteTools:GROUP_LEFT()
    wipe(self.demotedPlayers)
end

function InviteTools:DemoteAssistant(unit)
    if unit and not issecretvalue(unit) then
        local name = UnitName(unit)
        if name then
            self.demotedPlayers[name] = true
        end
    end
end

function InviteTools:OnInitialize()
    self.db = SLUI.db.global.invite
    self:SetEnabledState(self.db.enable)
    self.demotedPlayers = {}
    self.promoteGuildMembers = {}
end

function InviteTools:OnEnable()
    self:GUILD_ROSTER_UPDATE()
    wipe(self.demotedPlayers)

    self:RegisterEvent("GUILD_ROSTER_UPDATE")
    self:RegisterEvent("CHAT_MSG_WHISPER")
    self:RegisterEvent("CHAT_MSG_BN_WHISPER")
    self:RegisterEvent("PARTY_INVITE_REQUEST")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("GROUP_JOINED")
    self:RegisterEvent("GROUP_FORMED")
    self:RegisterEvent("GROUP_LEFT")

    self:SecureHook("DemoteAssistant")
end

function InviteTools:OnDisable()
    self:UnregisterAllEvents()
    self:UnhookAll()
end
