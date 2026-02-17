local SLUI = select(2,...)

--- @class SLINV: AceModule, AceEvent-3.0
local SLINV = SLUI:NewModule("SLINV", "AceEvent-3.0")
local sldb

-- Saved variables (will persist between sessions)
SLUI.defaults.global.invites = {
    debug = false,
    keywords = {
        ["raidinv"] = true,
        ["inv"] = true,
        ["invite"] = true,
    },
    promote = {
        ["Biopriest-Area52"] = true,
        ["Lavernius-Area52"] = true,
        ["Shukadin-Area52"]  = true,
        ["Notdravus-Area52"] = true,
        ["Dwavus-Area52"]    = true,
        ["Faulks-Area52"]    = true,
    },
}

-- Helper function for debug printing
local function DebugPrint(...)
    if sldb.debug then
        print("|cff00ff00[SLINV Debug]|r", ...)
    end
end

-- Helper function for addon messages
local function AddonPrint(...)
    print("|cff1e90ff[SLINV]|r", ...)
end

local function NormalizeName(name)
    if not name then return nil end
    if name:find("-") then
        return name
    end
    return name .. "-" .. GetNormalizedRealmName()
end

local function IsRaidCombatRestricted()
 return C_RestrictedActions.IsAddOnRestrictionActive(
            Enum.AddOnRestrictionType.Encounter
        )
end

-- State tracking
local pendingConvertToRaid = false
local demotedPlayers = {} -- Track manually demoted players to avoid re-promoting

-- Helper function to invite a player
local function InvitePlayer(name)
    if name then
        C_PartyInfo.InviteUnit(name)
    end
end

-- Check if we should convert to raid
local function CheckAndConvertToRaid()
    if not IsInRaid() and GetNumGroupMembers() >= 5 then
        pendingConvertToRaid = true
    end
    
    if pendingConvertToRaid and not IsInRaid() then
        C_PartyInfo.ConvertToRaid()
    end
end

-- Get raid member info and check if they should be promoted
local function ShouldPromoteMember(name)
    if IsRaidCombatRestricted() then
        return false
    end

    local normalizedName = NormalizeName(name)
    if not normalizedName then
        return false
    end

    -- Explicit whitelist check
    if sldb.promote[normalizedName] then
        -- Respect manual demotions
        if not demotedPlayers[normalizedName] then
            return true
        end
    end

    return false
end

-- Promote eligible raid members
local function PromoteEligibleMembers()
    if IsRaidCombatRestricted() then
        return
    end

    if not IsInRaid() or not UnitIsGroupLeader("player") then
        return
    end

    local numMembers = GetNumGroupMembers()
    for i = 1, numMembers do
        local name, rank = GetRaidRosterInfo(i)
        if name and rank == 0 then
            if ShouldPromoteMember(name) then
                PromoteToAssistant(name)
            end
        end
    end
end

-- Track demoted players to avoid auto-promoting them again
hooksecurefunc("DemoteAssistant", function(unit)
    if not unit then return end

    local name = UnitName(unit)
    if name then
        local normalizedName = NormalizeName(name)
        demotedPlayers[normalizedName] = true
    end
end)

function SLINV:CHAT_MSG_WHISPER(event, msg, sender)
    if IsRaidCombatRestricted() then
        return
    end

    -- Check if message is an invite keyword
    msg = string.lower(msg:trim())
    if sldb.keywords[msg] then
        -- Check if we need to convert to raid first
        CheckAndConvertToRaid()
        
        -- Invite the player
        C_Timer.After(1, function()
            InvitePlayer(sender)
        end)
    end
end

function SLINV:CHAT_MSG_BN_WHISPER(event, msg, sender, _, _, _, _, _, _, _, _, _, _, senderBnetID)
    if IsRaidCombatRestricted() then
        DebugPrint("Battle.net whisper ignored - restricted combat active")
        return
    end
    
    DebugPrint("===== Battle.net Whisper Received =====")
    DebugPrint("Message:", msg)
    DebugPrint("Sender:", sender)
    DebugPrint("Sender BNet ID:", senderBnetID)
    
    -- Validate inputs
    if not msg or type(msg) ~= "string" then
        DebugPrint("ERROR: Invalid message type")
        return
    end
    
    if not senderBnetID then
        DebugPrint("ERROR: No sender BNet ID")
        return
    end
    
    -- Check if message is an invite keyword
    local lowerMsg = string.lower(msg:trim())
    DebugPrint("Lowercase message:", lowerMsg)
    DebugPrint("Is invite keyword:", sldb.keywords[lowerMsg] and "YES" or "NO")
    
    if sldb.keywords[lowerMsg] then
        DebugPrint("Keyword matched! Processing invite...")
        
        -- Check if we need to convert to raid first
        CheckAndConvertToRaid()
        
        -- For Battle.net friends, we need to find their game account
        local numFriends = BNGetNumFriends()
        DebugPrint("Number of Battle.net friends:", numFriends)
        
        if not numFriends or numFriends == 0 then
            DebugPrint("ERROR: No Battle.net friends found")
            return
        end
        
        local foundFriend = false
        for i = 1, numFriends do
            local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
            
            if accountInfo then
                DebugPrint(string.format("Friend %d: BNet ID = %s", i, tostring(accountInfo.bnetAccountID)))
                
                if accountInfo.bnetAccountID == senderBnetID then
                    foundFriend = true
                    DebugPrint("FOUND matching friend!")
                    
                    -- Check if they have game account info
                    if not accountInfo.gameAccountInfo then
                        DebugPrint("ERROR: No gameAccountInfo")
                        break
                    end
                    
                    DebugPrint("Game Account Info:")
                    DebugPrint("  - Character Name:", accountInfo.gameAccountInfo.characterName or "nil")
                    DebugPrint("  - Client Program:", accountInfo.gameAccountInfo.clientProgram or "nil")
                    DebugPrint("  - Is Online:", tostring(accountInfo.gameAccountInfo.isOnline))
                    DebugPrint("  - Game Account ID:", tostring(accountInfo.gameAccountInfo.gameAccountID))
                    
                    -- Check if they're on WoW
                    if accountInfo.gameAccountInfo.isOnline and
                        accountInfo.gameAccountInfo.clientProgram == BNET_CLIENT_WOW then
                        DebugPrint("Friend is online on WoW! Sending invite...")
                        
                        local gameAccountID = accountInfo.gameAccountInfo.gameAccountID
                        if gameAccountID then
                            C_Timer.After(1, function()
                                DebugPrint("Executing BNInviteFriend with ID:", gameAccountID)
                                BNInviteFriend(gameAccountID)
                                DebugPrint("Invite sent!")
                            end)
                        else
                            DebugPrint("ERROR: gameAccountID is nil")
                        end
                    else
                        if not accountInfo.gameAccountInfo.isOnline then
                            DebugPrint("Friend is OFFLINE")
                        elseif accountInfo.gameAccountInfo.clientProgram ~= BNET_CLIENT_WOW then
                            DebugPrint("Friend is not on WoW. Client:", accountInfo.gameAccountInfo.clientProgram)
                        end
                    end
                    break
                end
            else
                DebugPrint(string.format("Friend %d: accountInfo is nil", i))
            end
        end
        
        if not foundFriend then
            DebugPrint("ERROR: Could not find matching Battle.net friend with ID:", senderBnetID)
        end
        
        DebugPrint("===== End Battle.net Processing =====")
    end
end

function SLINV:GROUP_ROSTER_UPDATE(event)
    if IsRaidCombatRestricted() then
        return
    end
    -- Check if we're in a raid now
    if IsInRaid() then
        pendingConvertToRaid = false
    elseif pendingConvertToRaid then
        -- Try to convert again
        C_PartyInfo.ConvertToRaid()
    end
    
    -- Promote eligible members
    PromoteEligibleMembers()
end

function SLINV:OnInitialize()
    sldb = SLUI.db.global.invites
    -- Build keyword list for display
    local keywords = {}
    for keyword, _ in pairs(sldb.keywords) do
        table.insert(keywords, keyword)
    end
    table.sort(keywords)

    self:RegisterEvent("CHAT_MSG_WHISPER")
    self:RegisterEvent("CHAT_MSG_BN_WHISPER")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")

    AddonPrint("loaded. Type |cffffcc00/slinv help|r for commands")
    print("  Invite keywords: |cff00ff00" .. table.concat(keywords, ", ") .. "|r")
    if sldb.debug then
        print("  |cffff9900Debug mode is ENABLED|r")
    end
end

-- Slash commands
local function ShowHelp()
    AddonPrint("Available commands:")
    print("  |cffffcc00/slinv debug|r - Toggle debug mode on/off")
    print("  |cffffcc00/slinv add <keyword>|r - Add an invite keyword")
    print("  |cffffcc00/slinv remove <keyword>|r - Remove an invite keyword")
    print("  |cffffcc00/slinv list|r - List all invite keywords")
    print("  |cffffcc00/slinv promote <name>|r - Add a name to promote whitelist")
    print("  |cffffcc00/slinv nopromote <name>|r - Remove a name from promote whitelist")
    print("  |cffffcc00/slinv listpromote|r - List all promote whitelist names")
    print("  |cffffcc00/slinv help|r - Show this help message")
end

local function ToggleDebug()
    sldb.debug = not sldb.debug
    if sldb.debug then
        AddonPrint("|cff00ff00Debug mode ENABLED|r")
    else
        AddonPrint("|cffff0000Debug mode DISABLED|r")
    end
end

local function AddKeyword(keyword)
    if not keyword or keyword == "" then
        AddonPrint("|cffff0000Error:|r Please specify a keyword to add")
        return
    end
    
    keyword = string.lower(keyword)
    
    if sldb.keywords[keyword] then
        AddonPrint("|cffffcc00Warning:|r Keyword '|cff00ff00" .. keyword .. "|r' already exists")
    else
        sldb.keywords[keyword] = true
        AddonPrint("Added keyword: |cff00ff00" .. keyword .. "|r")
    end
end

local function RemoveKeyword(keyword)
    if not keyword or keyword == "" then
        AddonPrint("|cffff0000Error:|r Please specify a keyword to remove")
        return
    end
    
    keyword = string.lower(keyword)
    
    if sldb.keywords[keyword] then
        sldb.keywords[keyword] = nil
        AddonPrint("Removed keyword: |cffff0000" .. keyword .. "|r")
    else
        AddonPrint("|cffffcc00Warning:|r Keyword '|cffff0000" .. keyword .. "|r' not found")
    end
end

local function ListKeywords()
    AddonPrint("Current invite keywords:")
    local count = 0
    for keyword, _ in pairs(sldb.keywords) do
        print("  |cff00ff00" .. keyword .. "|r")
        count = count + 1
    end
    if count == 0 then
        print("  |cffff0000(none)|r")
    end
end

local function AddPromote(name)
    if not name or name == "" then
        AddonPrint("|cffff0000Error:|r Please specify a name to add")
        return
    end
    
    local normalizedName = NormalizeName(name)
    if not normalizedName then
        AddonPrint("|cffff0000Error:|r Invalid name format")
        return
    end
    
    if sldb.promote[normalizedName] then
        AddonPrint("|cffffcc00Warning:|r '|cff00ff00" .. normalizedName .. "|r' is already in the promote whitelist")
    else
        sldb.promote[normalizedName] = true
        AddonPrint("Added to promote whitelist: |cff00ff00" .. normalizedName .. "|r")
    end
end

local function RemovePromote(name)
    if not name or name == "" then
        AddonPrint("|cffff0000Error:|r Please specify a name to remove")
        return
    end
    
    local normalizedName = NormalizeName(name)
    if not normalizedName then
        AddonPrint("|cffff0000Error:|r Invalid name format")
        return
    end
    
    if sldb.promote[normalizedName] then
        sldb.promote[normalizedName] = nil
        AddonPrint("Removed from promote whitelist: |cffff0000" .. normalizedName .. "|r")
    else
        AddonPrint("|cffffcc00Warning:|r '|cffff0000" .. normalizedName .. "|r' not found in promote whitelist")
    end
end

local function ListPromote()
    AddonPrint("Current promote whitelist:")
    local count = 0
    for name, _ in pairs(sldb.promote) do
        print("  |cff00ff00" .. name .. "|r")
        count = count + 1
    end
    if count == 0 then
        print("  |cffff0000(none)|r")
    end
end

-- Slash command handler
local function SlashCommandHandler(msg)
    local command, arg = msg:match("^(%S*)%s*(.-)$")
    command = command:lower()
    
    if command == "debug" then
        ToggleDebug()
    elseif command == "add" then
        AddKeyword(arg)
    elseif command == "remove" then
        RemoveKeyword(arg)
    elseif command == "list" then
        ListKeywords()
    elseif command == "promote" then
        AddPromote(arg)
    elseif command == "nopromote" then
        RemovePromote(arg)
    elseif command == "listpromote" then
        ListPromote()
    elseif command == "help" or command == "" then
        ShowHelp()
    else
        AddonPrint("|cffff0000Unknown command:|r " .. command)
        ShowHelp()
    end
end

-- Register slash commands
SLASH_SLINV1 = "/slinv"
SLASH_SLINV2 = "/SLinvite"
SlashCmdList["SLINV"] = SlashCommandHandler