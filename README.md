# SLUI

&lt;Sacred Lotus&gt; UI Utilities.

## Includes:

- Break Timer: shows a countdown timer with an optional image during raid breaks, synced to the
  raid via addon comms, with an optional TTS warning at 60 seconds remaining
- Combat Cross: shows a movable "+" marker while in combat
- Combat Timer: shows a movable combat duration timer, with a separate saved position per
  specialization role
- Invite Tools: invites (or suggests inviting) characters who whisper a configurable keyword,
  auto-accepts invites from Battle.net friends, character friends, or guild members, and
  auto-promotes configured characters or guild ranks to assistant when they join a raid
- Ready Check: shows each raid member's buffs on a ready check so missing buffs/consumables are
  easy to spot
- Tier Token Tweaks: adds the armor type and slot to tier token names in tooltips and the
  encounter journal

## Converting images:

Using [ImageMagick](https://imagemagick.org/)

```
magick input.xyz -resize 256x256^ -gravity Center -crop 256x256+0+0 output.tga
```
