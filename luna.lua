local map = require("smb3map")
local transition = require("warpTransition")
local dialogue = require("littleDialogue")

map.levelFilename = "world.lvlx"
map.introFilename = "level0.lvlx"

-- Paper Mario style
dialogue.registerStyle("pm",{
    textColor = Color.white,
    speakerNameColor = Color.white,
    typewriterEnabled = true,
    borderSize = 12,
    showTextWhileOpening = true,

    openStartScaleX = 0,
    openStartScaleY = 0,
    openStartOpacity = 0,

    speakerNameOnTop = false,
    speakerNameOffsetX = 24,
    speakerNameOffsetY = 4,
    speakerNamePivot = 0,
    speakerNameXScale = 2,
    speakerNameYScale = 2,

    openSpeed = 0.06,
    pageScrollSpeed = 0.075,

    textMaxWidth = 600,

    forcedPosEnabled = true,
    forcedPosX = 400,
    forcedPosY = 32,
    forcedPosHorizontalPivot = 0.5,
    forcedPosVerticalPivot = 0,

    minBoxMainHeight = 104,

    chatPoint = true,
    chatPointReach = 0.4,
    forceTween = true,
    layers = {
        Color.fromHexRGB(0x78B8F8),
        Color.fromHexRGB(0x202020),
    },
})

dialogue.defaultStyleName = "pm"