---@class SLUI
local SLUI = select(2, ...)

local SharedMedia = LibStub("LibSharedMedia-3.0")

SLUI.logo = [[Interface\AddOns\SLUI\Media\Textures\logo.blp]]
SLUI.breakBackupImage = [[Interface\AddOns\SLUI\Media\Textures\Placeholder.tga]]
SLUI.breakImages = {
    [[Interface\AddOns\SLUI\Media\Textures\CalemKnee.tga]],
    [[Interface\AddOns\SLUI\Media\Textures\ForThomas.tga]],
    [[Interface\AddOns\SLUI\Media\Textures\HorseBio.tga]],
    [[Interface\AddOns\SLUI\Media\Textures\Priory.tga]],
    [[Interface\AddOns\SLUI\Media\Textures\StripperBio.tga]],
    [[Interface\AddOns\SLUI\Media\Textures\WerthersOriginal.tga]],
    [[Interface\AddOns\SLUI\Media\Textures\Wolf.tga]],
    [[Interface\AddOns\SLUI\Media\Textures\Glizzies.tga]],
    [[Interface\AddOns\SLUI\Media\Textures\Voodoo.tga]],
    [[Interface\AddOns\SLUI\Media\Textures\Spongebob.tga]],
    [[Interface\AddOns\SLUI\Media\Textures\HideAndSeek.tga]],
    [[Interface\AddOns\SLUI\Media\Textures\BioWorm.tga]],
    [[Interface\AddOns\SLUI\Media\Textures\BioCarpet.tga]],
    [[Interface\AddOns\SLUI\Media\Textures\xalatath.tga]],
    [[Interface\AddOns\SLUI\Media\Textures\ShcorpAfk.tga]],
    [[Interface\AddOns\SLUI\Media\Textures\PoopdollarBanana.tga]],
    [[Interface\AddOns\SLUI\Media\Textures\Sentinels.tga]],
}

SharedMedia:Register("sound", "|cff00ff98Awoo|r", [[Interface\AddOns\SLUI\Media\Sounds\Awoo.ogg]])
SharedMedia:Register("sound", "|cff00ff98Woah|r", [[Interface\AddOns\SLUI\Media\Sounds\TreeWoah.ogg]])
