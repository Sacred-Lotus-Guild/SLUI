--- @class SLUI
local SLUI = select(2, ...)

local SharedMedia = LibStub("LibSharedMedia-3.0")

SLUI.logo = [[Interface\AddOns\SLUI\Media\Textures\logo.blp]]
SLUI.breakImages = {
    common = {
        [[Interface\AddOns\SLUI\Media\Textures\HorseBio.tga]],
    },
    group1 = {
        [[Interface\AddOns\SLUI\Media\Textures\CalemKnee.tga]],
        [[Interface\AddOns\SLUI\Media\Textures\Priory.tga]],
        [[Interface\AddOns\SLUI\Media\Textures\StripperBio.tga]],
        [[Interface\AddOns\SLUI\Media\Textures\WerthersOriginal.tga]],
        [[Interface\AddOns\SLUI\Media\Textures\Wolf.tga]],
    },
    group2 = {}
}

SharedMedia:Register("sound", "|cff00ff98Awoo|r", [[Interface\AddOns\SLUI\Media\Sounds\Awoo.ogg]])
