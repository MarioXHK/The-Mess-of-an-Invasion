--[[
# Super Mario Bros. 3 Style Map
###### At least it's better than the basegame

info on how to use can be found in _infoguidecredits.txt

any of the smb3map textures can be set to nil to disable them (ex: `smb3map.starlock = nil` makes star locks invisible)
]]
local smb3map = {}

-- For only the nerdiest of nerds. Comes free if you're in the editor and hit drop item
---@type boolean
smb3map.debug = false

--[[#### DeBug Options
Options for debugging, enabling and disabling certain things
]]
---@type table<string,boolean>
smb3map.dbo = {
    -- Show GameData related level things that are used when a level's being entered
    gamedatalevel = false,
    -- Show the player object's collision
    collision = false,
    -- Show the dots of detection when freeroam is 2
    freeroamcollision = false,
    -- Complete levels instantly by pressing altJump, and go through hands and enemies by holding it
    levelcheat = true,
    -- Save your position by pressing altRun, go to the position by pressing run while on a path
    position = true,
    -- Reset the map's save and game data by pressing altrun and altjump at the same time
    reset = true,
    -- Reset the map's save data on start (reguardless if in debug mode)
    resetOnStart = false,
    -- Shows the player's currentlevel and currentcorner
    currentmatters = true,
    -- track your distance on the grid
    distance = false,
    -- Show all the warps along with if the player's going through one and where they're headed
    warp = false,
    -- Show information about checkpoints
    checkpoint = false,
    -- Remove the overlay and default HUD things
    removeoverlay = true,
    -- Tells you where each level goes
    levelfiles = false,
    -- NPCs tell you what layer they belong to
    layerbelong = false,
    -- shows a circle at the player, but it won't leave the screen even if the player's not in it
    oobcheck = false,
    -- Shows the roaming status of the player
    roamingstatus = false,
    -- Shows the saved music
    music = false,
    -- Shows the saved section to spawn in
    section = false,
    -- Shows player position information as circles. Blue is the current one, green is the failsafe one that's been previously saved.
    playerpos = true,
    -- Shows the directions of a level and how to access them, along with the level filename and the warp it'll start in
    levelinfo = true,
    -- Information about warp whistle wind, specifically it's x position
    wind = true,
    -- Shows all the hitboxes of all the paths and levels. Red is path, orange is freeroam area, blue is level, node, or enemy, green is trigger stuff, and cyan is waterzone
    hitbox = false,
    -- Shows the player's current direction
    playerdir = false,
    -- Show enemy steps and distance
    enemystep = false,
    -- Shows the amount of enemies that need to be animated and how many have already animated
    enemyanim = false,
    -- True if the player has the ability to go in any direction reguardless of anything
    cangoanywhere = true,
    -- Shows the spawn and current idx of an npc
    idx = false,
    -- Shows the a player's jump values
    jump = false,
    -- Shows all NPC's IDs
    npcid = false,
}

--<[ Character things! ]>--

-- Names of all the characters
local characternames = {
    [CHARACTER_MARIO] = "mario",
    [CHARACTER_LUIGI] = "luigi",
    [CHARACTER_PEACH] = "peach",
    [CHARACTER_TOAD] = "toad",
    [CHARACTER_LINK] = "link",
    [CHARACTER_MEGAMAN] = "megaman",
    [CHARACTER_WARIO] = "wario",
    [CHARACTER_BOWSER] = "bowser",
    [CHARACTER_KLONOA] = "klonoa",
    [CHARACTER_NINJABOMBERMAN] = "ninjabomberman",
    [CHARACTER_ROSALINA] = "rosalina",
    [CHARACTER_SNAKE] = "snake",
    [CHARACTER_ZELDA] = "zelda",
    [CHARACTER_ULTIMATERINKA] = "ultimaterinka",
    [CHARACTER_UNCLEBROADSWORD] = "unclebroadsword",
    [CHARACTER_SAMUS] = "samus",
}

-- Names of all the characters grammatically correct
local characterNamesProper = {
    [CHARACTER_MARIO] = "Mario",
    [CHARACTER_LUIGI] = "Luigi",
    [CHARACTER_PEACH] = "Peach",
    [CHARACTER_TOAD] = "Toad",
    [CHARACTER_LINK] = "Link",
    [CHARACTER_MEGAMAN] = "Megaman",
    [CHARACTER_WARIO] = "Wario",
    [CHARACTER_BOWSER] = "Bowser",
    [CHARACTER_KLONOA] = "Klonoa",
    [CHARACTER_NINJABOMBERMAN] = "Ninja Bomberman",
    [CHARACTER_ROSALINA] = "Rosalina",
    [CHARACTER_SNAKE] = "Snake",
    [CHARACTER_ZELDA] = "Zelda",
    [CHARACTER_ULTIMATERINKA] = "Ultimate Rinka",
    [CHARACTER_UNCLEBROADSWORD] = "Uncle Broadsword",
    [CHARACTER_SAMUS] = "Samus",
}

-- A table of all the loaded character images
local playerimages = {}

local defaultchar = CHARACTER_MARIO
smb3map.defaultchar = CHARACTER_MARIO

-- The root of the primary assets used in smb3map
---@type string
smb3map.root = "smb3map/"

-- The primary image type used for loading images
---@type string
smb3map.imagetype = ".png"

-- Attempts to load a sprite from the smb3map.root directory (assuming it's a png). If failed, small mario will render instead
---@param image string
---@param p Player?
---@return Texture
local function attemptload(image,p)
    local resolveimage = smb3map.root..tostring(image)..smb3map.imagetype
    if Misc.resolveGraphicsFile(resolveimage) then
        return Graphics.loadImage(Misc.resolveGraphicsFile(resolveimage))
    elseif type(p) == "number" then
        return Graphics.loadImage(Misc.resolveGraphicsFile("player-"..tostring(p.character)..smb3map.imagetype))
    elseif p then
        return attemptload(characternames[p.character],p.character)
        -- I love recurssion
    else
        return Graphics.loadImage(Misc.resolveGraphicsFile(smb3map.root..characternames[(smb3map.defaultchar or defaultchar)]..smb3map.imagetype))
    end
end

--=<[ LIBRARIES ]>=--


local starman = require("npcs/ai/starman")

local textplus = require("textplus")

local handycam = require("handycam")

-- Custom Powerups
local cp
pcall(function() cp = require("customPowerups") end)

-- SMB3 HUD
local smb3hud
pcall(function() smb3hud = require("smb3HUD") end)

-- SMB3 Inventory
local inventory
pcall(function() inventory = require("smb3inv") end)

-- Warp Transitions
local transition
--pcall(function() transition = require("warpTransition") end)

local pm = require("playerManager")

--=<[ LIBRARY VARIABLES ]>=--


-- Why would you want to make the texture missing on purpose?
---@type boolean?
smb3map.intentionallymisstexture = false

-- Speed of the player on the map
---@type number
smb3map.playerspeed = 4

-- How much the player's hitbox is squished down
---@type number
smb3map.playerspace = 4

-- How long does a pulling animation last
---@type number
smb3map.pulltimer = 100

-- The precision of the grid when traveling
---@type number
smb3map.traveldist = 32

-- True if the player should always snap to a node/tile when possible
---@type boolean
smb3map.snaptogrid = true

-- True if the lives counter should show an infinity symbol next to it (doesn't actually set the lives to endless, do that yourself)
---@type boolean
smb3map.infinitelives = false

-- A currency that can override the regular coin count on the map.
smb3map.overridecurrency = nil

-- True if smb3map should show it's overlay and hide the default HUD. automatically true if smb3hud is installed
---@type boolean
smb3map.drawoverlay = true

-- Music to play when the music box is active
---@type string
smb3map.musicbox = "Music Box.spc|0;g=2.7"

-- How many frames the music box has
---@type number
smb3map.musicboxframes = 8

-- Framespeed of the music box
---@type number
smb3map.musicboxframespeed = 12

-- If true, items used in the reserve will effect all players
---@type boolean
smb3map.sharingcaring = false

-- Because pipe world stuff can only be set to a max of 32767 and a level's much greater than that in size, this will multiply any value of that so it can work in the actual thing
---@type number
smb3map.warpgrid = smb3map.traveldist

-- Table of what each section corrisponds to what number when displayed (1-21 style)
---@type table<integer,integer?>
smb3map.worlds = {
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
}

-- Table of names for each section (by default empty)
---@type table<integer,string>
smb3map.worldnames = {

}

-- Table of all the player objects on the map
---@type table<integer,PlayerMapObject>
smb3map.players = {}

-- The index of the warp to go to when entering a level
---@type integer|nil
smb3map.warpIndex = nil

-- Curent frame of the players on the overlay
---@type table<integer,integer>
smb3map.playerframe = {}

-- Framespeed of the players on the overlay
---@type integer
smb3map.playerframespeed = 10

-- Filename of the hub level
---@type string
smb3map.levelFilename = "map.lvlx"

-- Filename of the intro level. The player must complete the level before the level map's allowed to load. Will continue as normal if none is set
---@type string|nil
smb3map.introFilename = ""

-- Warp index of the intro level
---@type integer|nil
smb3map.introwarp = nil

-- If the intro level can ignore clear condition of just being alive and thus be skipped if the level exits by any means.
---@type boolean
smb3map.introskip = false

-- Table of active airships
---@type table<integer?,NPC>
smb3map.airships = {}

-- Table of active enemies that are in the same section as active players
---@type table
smb3map.enemies = {}

-- Table of directions
---@type table<string,integer>
smb3map.direction = {
    DOWN = 1,
    LEFT = 2,
    RIGHT = 3,
    UP = 4,
}

-- Positions of each of the default overlay features
---@type table<string,Vector2>
smb3map.overlayposes = {
    -- The player and his companions
    player = vector(100,120),
    lives = vector(100,100),
    coins = vector(100,100-24),
    stars = vector(100,100-48),
    reserve = vector(400,80),
    musicbox = vector(64,80),
    name = vector(100,40),
    thumbnail = vector(-192,64),
}

-- Priority of the default overlay
---@type number
smb3map.overlaypriority = 5

-- If thumbnails should render relative to a level instead of the screen
---@type boolean
smb3map.thumbnailOnMap = false

-- Priority of the player object on the map
---@type number
smb3map.playerpriority = -25

-- If true, only the first player can choose levels to go to and change the music. Doesn't apply to enemy tiles
---@type boolean
smb3map.leadersChoice = false

-- 0: no direction animations, 1: 4-way direction animations, defaults to 0
smb3map.framestyle = {
    [CHARACTER_MARIO] = {
        [1] = 1,
    },
    [CHARACTER_LUIGI] = {
        [1] = 1,
    },
    [CHARACTER_PEACH] = {
        [1] = 1
    },
    [CHARACTER_TOAD] = {
        [1] = 1
    },
    [CHARACTER_LINK] = {
        [1] = 1
    },
    [CHARACTER_MEGAMAN] = {
        [1] = 1,
    },
    [CHARACTER_WARIO] = {
        [1] = 1,
    },
    [CHARACTER_BOWSER] = {
        [1] = 1
    },
    [CHARACTER_KLONOA] = {
        [1] = 1
    },
    [CHARACTER_NINJABOMBERMAN] = {
        [1] = 1
    },
    [CHARACTER_ROSALINA] = {
        [1] = 1,
    },
    [CHARACTER_SNAKE] = {
        [1] = 1,
    },
    [CHARACTER_ZELDA] = {
        [1] = 1
    },
    [CHARACTER_ULTIMATERINKA] = {
    },
    [CHARACTER_UNCLEBROADSWORD] = {
    },
    [CHARACTER_SAMUS] = {
    },
}

-- How many frames are there in each animation. Defaults to 2
smb3map.frames = {
    [CHARACTER_MARIO] = {
    },
    [CHARACTER_LUIGI] = {
    },
    [CHARACTER_PEACH] = {
    },
    [CHARACTER_TOAD] = {
    },
    [CHARACTER_LINK] = {
    },
    [CHARACTER_MEGAMAN] = {
    },
    [CHARACTER_WARIO] = {
    },
    [CHARACTER_BOWSER] = {
    },
    [CHARACTER_KLONOA] = {
    },
    [CHARACTER_NINJABOMBERMAN] = {
    },
    [CHARACTER_ROSALINA] = {
    },
    [CHARACTER_SNAKE] = {
    },
    [CHARACTER_ZELDA] = {
    },
    [CHARACTER_ULTIMATERINKA] = {
        [1] = 4
    },
    [CHARACTER_UNCLEBROADSWORD] = {
        [1] = 1
    },
    [CHARACTER_SAMUS] = {
    },
}

-- defaults to 8
smb3map.framespeed = {
    [CHARACTER_MARIO] = {
    },
    [CHARACTER_LUIGI] = {
    },
    [CHARACTER_PEACH] = {
    },
    [CHARACTER_TOAD] = {
    },
    [CHARACTER_LINK] = {
    },
    [CHARACTER_MEGAMAN] = {
    },
    [CHARACTER_WARIO] = {
    },
    [CHARACTER_BOWSER] = {
    },
    [CHARACTER_KLONOA] = {
    },
    [CHARACTER_NINJABOMBERMAN] = {
    },
    [CHARACTER_ROSALINA] = {
    },
    [CHARACTER_SNAKE] = {
    },
    [CHARACTER_ZELDA] = {
    },
    [CHARACTER_ULTIMATERINKA] = {
    },
    [CHARACTER_UNCLEBROADSWORD] = {
    },
    [CHARACTER_SAMUS] = {
    },
}

-- Icon of the star to use when a level/warp's locked
---@type Texture|nil
smb3map.starlock = attemptload("star")

-- Overlay gfx (when smb3hud isn't present)
---@type Texture|nil
smb3map.overlay = attemptload("overlay")

-- Sprite of the hand that drags you down
---@type Texture|nil
smb3map.handsprite = attemptload("hand")

-- Sprite of the lakitu cloud
---@type Texture|nil
smb3map.cloudsprite = attemptload("cloud")

-- Sprite of the boat to use
---@type Texture|nil
smb3map.boatsprite = attemptload("boat")

-- Sprite of the overlay lives to use
---@type Texture|nil
smb3map.lifeicon = Graphics.sprites.hardcoded["33-3"].img

-- Sprite of the overlay coins to use
---@type Texture|nil
smb3map.coinicon = Graphics.sprites.hardcoded["33-2"].img

-- Sprite of the overlay stars to use
---@type Texture|nil
smb3map.staricon = Graphics.sprites.hardcoded["33-5"].img

-- Sprite of the small anchor to use
---@type Texture|nil
smb3map.anchoricon = attemptload("anchorsmall")

-- Sprite of the animated music box
---@type Texture|nil
smb3map.musicboxsprite = attemptload("musicbox")

-- Sprite of warp whistle wind
---@type Texture|nil
smb3map.tornadosprite = attemptload("whirlwind")

-- Sprite of the help sign
---@type Texture|nil
smb3map.helpsign = attemptload("helpsign")

-- Sprite of the N-Mark Spade
---@type Texture|nil
smb3map.nspritespade = attemptload("n-spade")

-- Sprite of the Treasure Ship
---@type Texture|nil
smb3map.treasuresprite = attemptload("treasure-ship")

-- Sprite of the opening stars
---@type Texture|nil
smb3map.sparklesprite = attemptload("twinkle")

-- Sprite of the opening ui
---@type Texture|nil
smb3map.startscreen = attemptload("startscreen")

-- When do the sparkles appear on the start screen
---@type number
smb3map.sparkleon = 64

-- How many sparkles are there
---@type integer
smb3map.startsparkles = 8

-- What will be the maximum radius of the sparkles spreading
---@type number
smb3map.sparklespread = 256

-- How much should sparkles rotate relative to how much time has passed
---@type number
smb3map.startrotationovertime = 4

-- Framespeed of the sparkles
---@type number
smb3map.sparkleframespeed = 4

-- Frames of the sparkles
---@type number
smb3map.sparkleframes = 2

-- SFX for making an n-mark spade appear
---@type integer|string?
smb3map.nmarksfx = 34

-- How many frames the tornado GFX has
---@type integer
smb3map.tornadoframes = 2

-- Framespeed of the tornado GFX
---@type integer
smb3map.tornadoframespeed = 10

-- Altframespeed
---@type number
smb3map.altframespeed = 8

-- N-spade and enemy slider speed
---@type number
smb3map.slidespeed = 1

-- The level that's being entered at rn
---@type string|nil
smb3map.enteringlevel = nil

-- Ticks up when a level is being entered
---@type number
smb3map.entertimer = 0

-- when `smb3map.entertimer` reaches this, it'll load the level frfr
---@type number
smb3map.enteron = 100

-- How long the basic transition shall last
---@type number
smb3map.backtomaptimer = 16

--The level tile to use as an airship
---@type integer
smb3map.airshipTile = 217

-- The duration of the player's going back animation
---@type number
smb3map.backtimer = 40

-- Phase of baddie animations. 0: unanimated. 1: airships. 2: ground enemies, -1 means it's finished
---@type number
smb3map.enemyanimationphase = 0

-- How long it takes for the start animation to happen (must at least be as much as smb3map.sparkleon, which by default is 64)
---@type number
smb3map.worldstartticks = lunatime.toTicks(3)

-- Font smb3map uses
smb3map.font = textplus.loadFont(smb3map.root.."font.ini")

-- The default amount of turns that the music box has
---@type integer
smb3map.defaultMusicBoxTurns = 2

-- The default amount of moves that the anchor has
---@type integer
smb3map.defaultAnchorCounter = 5

-- If the anchor effect is visible to everything that effects it
---@type boolean
smb3map.visibleanchor = true

-- The SFX of the warp whistle
---@type string?
smb3map.whistlesound = Misc.resolveSoundFile(smb3map.root.."whistle")

-- X position of the wind
---@type number
smb3map.windx = 0

-- How fast the wind goes
---@type number
smb3map.windspeed = 4

-- How many times should a corner be checked for between corners after encountering another corner?
---@type number
smb3map.cornerchecks = 2

-- If corners should be checked on a smaller grid that's a division of the bigger grid by `smb3map.cornerchecks`
---@type boolean
smb3map.subcorners = true

-- The gravity of a player when jumping
---@type number
smb3map.playergravity = defines.player_grav

-- First part of starmessage message
---@type string
smb3map.starmessagea = "You need "

-- Second part of starmessage message if tellhowmanyleft is false
---@type string
smb3map.starmessageb = " stars to enter."

-- Second part of starmessage message if tellhowmanyleft is true
---@type string
smb3map.starmessagec = " more stars to enter."

-- Default tellhowmanyleft state of starmessage
---@type boolean
smb3map.tellmedefault = true

-- Default timer for a warp
---@type integer
smb3map.warptimer = 16

-- The duration of the airships flying animation
---@type number
smb3map.shiptimer = 50

-- If true, the player can use their reserve on the map
---@type boolean
smb3map.usereserve = true

-- True if a world start animation is playing
---@type boolean
smb3map.worldstarting = true

-- Timer for world start animation
---@type number
smb3map.worldstarttimer = 0

-- The SFX to play when skidding back
---@type integer|string?
smb3map.skidsfx = 10

-- The SFX to play when a world starts
---@type integer|string?
smb3map.startsfx = 41

-- The SFX to play when manually warping
---@type integer|string?
smb3map.warpsfx = 17

-- The SFX to play when you stop floating
---@type integer|string?
smb3map.stopfloatingsfx = 41

-- The SFX to play when the player's on a level
---@type integer|string?
smb3map.levelsfx = 26

-- The SFX to play when the player's entering a level
---@type integer|string?
smb3map.enterlevelsfx = 28

-- The SFX to play when a level's beaten
---@type integer|string?
smb3map.levelbeatsfx = 27

-- The SFX to play when an enemy's been knocked aside
---@type integer|string?
smb3map.enemybeatsfx = 9

-- The SFX to play when a level with the `canbedestroyed` config is beaten
---@type integer|string?
smb3map.leveldestroysfx = 4

-- The SFX to play when an airship's flying
---@type integer|string?
smb3map.airshipsfx = 63

-- The SFX to play when an airship's been beaten
---@type integer|string?
smb3map.airshipbeatsfx = 41

-- The SFX to play when the player's entering an enemy's level
---@type integer|string?
smb3map.bumpbaddysfx = 28

-- The SFX to play when the player's on a node
---@type integer|string?
smb3map.nodesfx = 26

-- The SFX to play when the player's being knocked back
---@type integer|string?
smb3map.knockbacksfx = 9

-- The SFX to play when something appears on the map
---@type integer|string?
smb3map.appearsfx = 34

-- If freeroam players shouldn't be knocked back after loosing a level
---@type boolean
smb3map.forgivefreeroamers = false

-- Default character to use when marking levels complete when the player's unavailable
---@type CharacterType
smb3map.defaultchar = CHARACTER_MARIO


--=<[ LOCAL VARIABLES ]>=--


local savemefromthishell = false

-- New positions for the airships to be at
local newairshippos = {}


-- Table of layer offsets
smb3map.layeroffset = {}

-- Table of layer offsets
local layeroffset = smb3map.layeroffset

-- The basegame map music
local defaultmusic = {
    "music/smw-yoshisisland.spc|0;g=2.7;",
    "music/smw-worldmap.spc|0;g=2.7;",
    "music/smw-vanilladome.spc|0;g=2.7;",
    "music/smw-forestofillusion.spc|0;g=2.7;",
    "music/smw-bowserscastle.spc|0;g=2.7;",
    "music/smw-starroad.spc|0;g=2.7;",
    "music/smw-special.spc|0;g=2.7;",
    "music/smb3-world1.spc|0;g=2.7;",
    "music/smb3-world2.spc|0;g=2.7;",
    "music/smb3-world3.spc|0;g=2.7;",
    "music/smb3-world4.spc|0;g=2.7;",
    "music/smb3-world5.spc|0;g=2.7;",
    "music/smb3-world6.spc|0;g=2.7;",
    "music/smb3-world7.spc|0;g=2.7;",
    "music/smb3-world8.spc|0;g=2.7;",
}

-- Ticks down when the hub's been loaded
local btmt = smb3map.backtomaptimer+1

-- A table of players warping to places
local activewarps = {}

-- The blackness timer of the warps
local transtimer = smb3map.warptimer

-- The timer that ticks up when `smb3map.enemyanimationphase` is 1
---@type number
local shiptimer = 0

local starmanshader = Misc.multiResolveFile("starman.frag", "shaders\\npc\\starman.frag")

local sshader

-- The delay between loading in and being able to detect a level (because data and settings don't wanna exist for a split second for some reason)
---@type number
local detectdelay = 2

-- If the animatedplayer variable should wait for warps to be finished
local waitforwarp = false

-- If stuff after ontick has been initialized
local postinitialized = false

-- if to go in reverse when animating the overlay player
local playerreverse = {}

-- Current frame of the music box
---@type number
local musicboxframe = 0

local dirs = {
    "up",
    "down",
    "left",
    "right"
}

-- mirror of smb3map.airships
---@type table<integer?,NPC>
local airships = smb3map.airships

-- mirror of smb3map.enemies
local enemies = smb3map.enemies

-- Timer to reset the level for debug purposes
---@type number
local resetTimer = 0

local tornadoframe = 0

-- Have the players done their animations
---@type boolean
local animatedplayer = false

-- Are level tiles done animating (flip animations, n-spade, ect.)
---@type boolean
local animatedtiles = false

-- Are one-time tile stuffs done for animatedtiles?
---@type boolean
local didsometiles = false

-- The timer that ticks down when animatedplayer is true and animatedtiles isn't
---@type number
local tileanimtimer = 16

-- Have the things that move on screen done their animations
---@type boolean
local animatedbaddies = false

-- Has the start animation played?
---@type boolean
local animatedstart = false

-- Has the music been set and played yet
---@type boolean
local musicset = false

-- A table of all the default music of the sections
local basemusic = {}

-- Timer for world start animation
---@type number
local startanimtimer = 0

-- The block for warpwhistling to
---@type Block|nil
local whistleBlock = nil

-- Status of warping your whistle
---@type boolean
local whistlingwarp = false

-- if the whistle warp is now in the different section
---@type boolean
local warpedwhistle = false

-- If someone hasn't already gone into a warp that transports you to a different spot in the map
---@type boolean
local warperoo = true

-- If the players aren't allowed to move
---@type boolean
local freezeplayers = false

-- The world name
---@type string?
local worldName = ""

-- The memory address for Lives
---@type integer
local plives = 0x00B2C5AC


--=<[ SAVEDATA VARIABLES ]>=--


SaveData.smb3map = SaveData.smb3map or {}

-- smb3map Save Data
local save = SaveData.smb3map

-- Table of all the starmen mapped
---@type table<integer,boolean>
save.starmen = save.starmen or {}

-- table of start animated sections mapped
---@type table<integer,boolean>
save.animatedsections = save.animatedsections or {}

-- The current N-mark spades on the map
save.nmarkspades = save.nmarkspades or {}

-- If [section] is true in this table, then it means a treasure ship has already spawned here and has been collected
---@type table<integer,boolean>
save.shippedtreasures = save.shippedtreasures or {}

-- If [section] is true in this table, then it means a treasure ship has spawned in [section] section
---@type table<integer,boolean>
save.treasureshipping = save.treasureshipping or {}

-- Table of airship positions
---@type table<integer,Vector2>
save.airshippos = save.airshippos or {}

-- Table of enemy positions
save.enemypos = save.enemypos or {}

-- How many turns of the music box are left before it stops winding and the enemies are awake?
---@type integer
save.musicboxturns = save.musicboxturns or 0

-- How long the is anchor active for
---@type integer
save.anchorTimer = save.anchorTimer or 0

-- the idx to destroy on the start as they've been destroyed
---@type table<integer,boolean>
save.destroyedlist = save.destroyedlist or {}

-- The most amount of score ever gotten
---@type integer
save.score = save.score or 0

-- If the player has triggered the intro level. If no intro level is present, then it'll be true when the player wins their first level
---@type boolean
save.introdone = save.introdone
if type(save.introdone) == "nil" then
    save.introdone = false
end

--=<[ GAMEDATA VARIABLES ]>=--


GameData.smb3map = GameData.smb3map or {}

-- smb3map Game Data
local saveTemp = GameData.smb3map

-- Here to make sure you can't drop items
saveTemp.reserve = {}

-- The type of win that got executed after exiting a level
---@type number
saveTemp.winType = saveTemp.winType or 0

-- The filename of the level that has been entered
---@type string
saveTemp.level = saveTemp.level or ""

-- If a ship should be triggered via the usual means
---@type boolean
saveTemp.triggership = saveTemp.triggership or false

-- All triggered events in a level
---@type table<integer,string>
saveTemp.triggeredEvents = saveTemp.triggeredEvents or {}

-- Used to make sure the first level isn't marked when an intro level's selected. Setting this to true will make any level left unmarked (not the same as loosing a level)
---@type boolean
saveTemp.dontmark = saveTemp.dontmark
if type(saveTemp.dontmark) == "nil" then
    saveTemp.dontmark = true
end

--=<[ LOCAL FUNCTIONS ]>=--


-- Attempts to clone a table without referencing any of its values, even nested table values. Returns the table and an additional table of all the index values. if it's NOT a table then it'll return as itself
---@param tab table?
---@return table
---@return table<integer,any>?
local function clonetable(tab)
    if type(tab) ~= "table" then
---@diagnostic disable-next-line: return-type-mismatch
        return tab
    end
    local le = {}
    local indi = {}
    for index,thing in pairs(tab) do
        indi[#indi+1] = index
        if type(thing) == "table" then
            le[index] = clonetable(thing)
        else
            le[index] = thing
        end
    end
    return le,indi
end

-- Returns true if a cheat exists and is active
---@param cheddar string
---@return boolean
local function cheatisactive(cheddar)
    if Cheats.get(cheddar) and Cheats.get(cheddar).active then
        return true
    end
    return false
end

-- forces the player into a jumping animation
---@param p Player
---@param soundeffect (string|number|unknown)?
---@param grav number|nil
---@param speed number|nil
---@param height number|nil
---@param terminalv number|nil
local function mapJump(p,soundeffect,grav,speed,height,terminalv)
    local plr = p.data.mapObj
    SFX.play(soundeffect)
    if not plr then return end
    plr.gravity = grav or plr.gravity or smb3map.playergravity or defines.player_grav
    plr.jumpspeed = speed or defines.jumpspeed
    plr.jumpheight = height or 0
    plr.gravitydir = math.sign(plr.gravity)
    plr.terminalv = terminalv or 0
end

-- Resets the gamedata and savedata,
---@param dobasegametoo boolean|nil if true, the score, coin, and lives counter will also be reset
local function resetMap(dobasegametoo)
    SaveData.smb3map = {
        starmen = {},
        animatedsections = {},
        nmarkspades = {},
        shippedtreasures = {},
        treasureshipping = {},
        airshippos = {},
        enemypos = {},
        musicboxturns = 0,
        anchorTimer = 0,
        destroyedlist = {},
        score = 0,
    }
    GameData.smb3map = {
        reserve = {},
        winType = 0,
        level = "",
        triggership = false,
        triggeredEvents = {},

    }
    for _,c in ipairs(smb3map.cheats) do
        c.active = false
    end
    if dobasegametoo then
        Misc.score(-Misc.score())
        Misc.coins(-Misc.coins(),false)
        mem(plives,FIELD_FLOAT,4)
    end
end

-- Returns the given section based on a pos, however it spawns a collectable trigger NPC at said pos
---@param pos Vector2|Block
---@return number
local function getsecfrompos(pos)
    return NPC.spawn(465,pos.x,pos.y).section
end

--[[
A crazy idea

at the start of smb3map, an npc's absolute idx is stored on it's 0x14 (FIELD_WORD) memory. This returns that memory slot unless it's 0, then it returns it's regular idx

Unlike everything else, this memory hasn't been touched, and it won't be touched becaused it's an unused slot. It won't go away when the npc despawns, and it won't change without other codes ruining it
]]
---@param v NPC
---@return integer
local function spawnidx(v)
    if v:mem(0x14,FIELD_WORD) ~= 0 then
        return v:mem(0x14,FIELD_WORD)
    else
        return v.idx
    end
end

-- returns if an NPC `v` is valid
---@param v NPC
---@return boolean
local function npcisvalid(v)
    return (v.isValid and not (v.isHidden or v.isGenerator))
end

-- Returns true if only one of them is true, and not both
---@param a any
---@param b any
---@return boolean
local function xor(a,b)
    return ((a or b) and not (a and b))
end

-- returns if an Block `b` is valid
---@param b Block
---@return boolean
local function blockisvalid(b)
    return (b.isValid and b.id > 0 and not (b.isHidden --[[or b.invisible or b:mem(0x5A,FIELD_BOOL)]]))
end

-- Returns either the default powerup value for the player, or if customPowerups is installed, the custom powerup
---@param p Player
---@return number|string
local function getpowerup(p)
    if cp then
        return cp.getCurrentName(p)
    else
        return p.powerup
    end
end

-- Returns true if all the starting animations (enemies, players, tiles, world start) have finished
---@return boolean
local function doneanimating()
    return (animatedtiles and animatedplayer and animatedbaddies and animatedstart)
end

-- Returns if the music box is active or not
---@return boolean
local function mboxactive()
    return (save.musicboxturns and save.musicboxturns > 0)
end

-- Returns if an anchor is active or not
---@return boolean
local function anchactive()
    return (save.anchorTimer and save.anchorTimer > 0)
end

-- Converts smb3map's direction system into a warp direction
---@param dir number
---@return number
local function smb3dirtowarpdir(dir)
    if dir == smb3map.direction.UP then
        return 1
    elseif dir == smb3map.direction.LEFT then
        return 2
    elseif dir == smb3map.direction.DOWN then
        return 3
    elseif dir == smb3map.direction.RIGHT then
        return 4
    end
    return dir
end

-- Converts a warp direction into a smb3map direction
---@param dir number
---@return number
local function warpdirtosmb3dir(dir)
    if dir == 1 then
        return smb3map.direction.UP
    elseif dir == 2 then
        return smb3map.direction.LEFT
    elseif dir == 3 then
        return smb3map.direction.DOWN
    elseif dir == 4 then
        return smb3map.direction.RIGHT
    end
    return dir
end

-- Turns a smb3map direction clockwise
---@param dir number
---@return number
local function turnclockwise(dir)
    if dir == smb3map.direction.UP then
        return smb3map.direction.RIGHT
    elseif dir == smb3map.direction.DOWN then
        return smb3map.direction.LEFT
    elseif dir == smb3map.direction.LEFT then
        return smb3map.direction.DOWN
    elseif dir == smb3map.direction.RIGHT then
        return smb3map.direction.UP
    end
    return dir
end

-- Turns a smb3map direction counter-clockwise
---@param dir number
---@return number
local function turncounterclockwise(dir)
    if dir == smb3map.direction.UP then
        return smb3map.direction.LEFT
    elseif dir == smb3map.direction.DOWN then
        return smb3map.direction.RIGHT
    elseif dir == smb3map.direction.LEFT then
        return smb3map.direction.DOWN
    elseif dir == smb3map.direction.RIGHT then
        return smb3map.direction.UP
    end
    return dir
end

-- Turns a smb3map direction around
---@param dir number
---@return number
local function turnaround(dir)
    if dir == smb3map.direction.UP then
        return smb3map.direction.DOWN
    elseif dir == smb3map.direction.DOWN then
        return smb3map.direction.UP
    elseif dir == smb3map.direction.LEFT then
        return smb3map.direction.RIGHT
    elseif dir == smb3map.direction.RIGHT then
        return smb3map.direction.LEFT
    end
    return dir
end

-- Turns a warp direction around
---@param dir number
---@return number
local function turnwarparound(dir)
    return smb3dirtowarpdir(turnaround(warpdirtosmb3dir(dir)))
end

-- Slow the animation down of all the blocks and BGOs
local function slowAnimations()
    for i = 1, 2000 do
        local blockconfig = Block.config[i]
        if blockconfig then
            blockconfig.framespeed = blockconfig.framespeed*2
        end
        if i <= 1000 then
            local bgoconfig = BGO.config[i]
            if bgoconfig then
                bgoconfig.framespeed = bgoconfig.framespeed*2
            end
        end
    end
end

-- Set the speed of a player object
---comment
---@param plr table
---@param speed number|nil
local function setplrspeeds(plr,speed)
    speed = speed or plr.speed
    if plr.direction == smb3map.direction.UP then
        plr.speedX = 0
        plr.speedY = -plr.speed
    elseif plr.direction == smb3map.direction.DOWN then
        plr.speedX = 0
        plr.speedY = plr.speed
    elseif plr.direction == smb3map.direction.LEFT then
        plr.speedX = -plr.speed
        plr.speedY = 0
    elseif plr.direction == smb3map.direction.RIGHT then
        plr.speedX = plr.speed
        plr.speedY = 0
    end
end

-- Saves the current position of the player
---@param p Player|Vector2|table|NPC|nil
local function savepos(p)
    if save.playerpos then
        save.lastplayerpos = vector(save.playerpos.x,save.playerpos.y)
    end
    if save.section then
        save.lastsection = save.section
    elseif p.section then
        save.lastsection = p.section
    else
        save.lastsection = player.section
    end
    if p and p.isValid then
        if p.section then
            save.section = p.section
        end
        if p.ai1 --[[A variable that an NPC has, but a player hasn't]] then
            local off = vector(0,0)
            local l = Layer.get(p.layerName)
            if l and layeroffset[p.layerName] then
                off = layeroffset[p.layerName]
            end
            save.playerpos = vector(p.x+off.x,p.y+off.y)
        else
            if p.idx and p.data.mapObj then
                local plr = p.data.mapObj
                save.playerpos = vector(plr.x,plr.y)
                save.lastfreeroam = save.freeroam or plr.freeroam
                save.freeroam = plr.freeroam
            else
                save.playerpos = vector(p.x,p.y)
            end
        end
    else
        save.playerpos = vector(player.x,player.y)
        save.section = player.section
        if player.data.mapObj then
            save.lastfreeroam = save.freeroam or player.data.mapObj.freeroam
            save.freeroam = player.data.mapObj.freeroam
        end
    end
end

-- resets a player object's speed values
---@param plr PlayerMapObject
local function resetpspeed(plr)
    plr.speedX = 0
    plr.speedY = 0
    plr.speed = smb3map.playerspeed
end

-- Stops the player object from moving
---@param plr PlayerMapObject
local function stopplr(plr)
    plr.moving = false
    resetpspeed(plr)
    plr.distance = 0
    plr.mcdist = 0
end

-- Checks for several block things
---@param p Player
---@param blackconfig string|nil if the block has this config, then it won't be checked
---@param whiteconfig string|nil if this is anything, then the block must have this config
local function checkforblockstuff(p,blackconfig,whiteconfig)
    ---@type PlayerMapObject
    local plr = p.data.mapObj
    if not plr then return end
    if (p == player or not smb3map.leadersChoice) and smb3map.canenterlevel(p) --[[and not plr.moving]] then
        for __,b in Block.iterate() do
            if blockisvalid(b) then
                local config = Block.config[b.id]
                local data = b.data
                local settings = data._settings
                if ((config.changemusic and not config.warppoint) or config.savepoint or config.speedchange or config.jumpblock) -- config checks
                and (not (blackconfig and config[blackconfig])) and ((not whiteconfig) or config[whiteconfig]) -- blacklist and whitelist checks
                and Colliders.collide(b,plr.collider) -- collision
                and ((not settings.reqdirection) or settings.reqdirection == 0 or settings.reqdirection == plr.direction) -- direction check
                then
                    if config.changemusic then
                        if settings.customMusicPath and settings.customMusicPath ~= "" then
                            save.music = settings.customMusicPath
                        elseif settings.music then
                            if settings.music > 1 then
                                local index = settings.music-2
                                save.music = index
                            elseif settings.music == 1 then
                                save.music = nil
                            end
                        end
                    elseif config.speedchange then
                        if settings.add and settings.speed  then
                            if plr.speedblock ~= b then
                                plr.speed = (plr.speed or smb3map.playerspeed)+settings.speed
                                plr.speedblock = b
                            end
                        else
                            plr.speed = math.abs(settings.speed) or plr.speed or smb3map.playerspeed
                        end
                        plr.speed = math.clamp(plr.speed,0.1,smb3map.traveldist) -- don't go too slow or too fast now, k?
                        setplrspeeds(plr)
                    elseif config.jumpblock then
                        if plr.gravitydir == 0 or (settings.stack and plr.gravblock ~= b) then
                            local soundeffect
                            if settings.jumpsound then
                                if type(settings.jumpsound) == "number" or tonumber(settings.jumpsound) then
                                    local soundsfx = math.clamp(math.floor(tonumber(settings.jumpsound)),0,91)
                                    soundeffect = soundsfx
                                elseif type(settings.jumpsound) == "string" then
                                    soundeffect = Misc.resolveSoundFile(settings.jumpsound)
                                else
                                    soundeffect = 1
                                end
                            end
                            mapJump(p,soundeffect,settings.gravity,settings.jumpspeed,settings.jumpheight,settings.terminalv)
                            if settings.stack then
                                plr.gravblock = b
                            end
                        end
                    else
                        savepos(p)
                    end
                end
            end
        end
    end
end

-- Uses an NPC or Block's config to determine if it should preform it's effect
---@param config NPCConfig|BlockConfig
---@param p Player
---@return boolean
local function cantouch(config,p)
    ---@type PlayerMapObject|nil
    local plr = p.data.mapObj
    return (((not config.neededpowerup) or (tonumber(config.neededpowerup) and tonumber(config.neededpowerup) <= 0) or getpowerup(p) == config.neededpowerup) and
            ((not config.neededmount) or config.neededmount < 0 or p.mount == config.neededmount or (config.neededmount > 3 and p.mount ~= MOUNT_NONE)) and ((not config.isfloater) or plr.incloud))
end

-- Checks for corners in your local area and acts accordingly
---@param plr PlayerMapObject
---@param onlycheck boolean? if true, then it won't change any of the values of plr
---@return boolean|nil
local function checkforcorners(plr,onlycheck)
    if not plr then return end
    for __,b in Block.iterate() do
        if blockisvalid(b) then
            local config = Block.config[b.id]
            if plr.currentcorner ~= b and config.pathcorner and config.pathcorner ~= 0 and (not config.isenemypath) and Colliders.collide(b,plr.collider) then
                if not onlycheck then
                    plr.currentcorner = b
                    if plr.checkingcorners then
                        if plr.speedX ~= 0 then
                            if plr.speedX > 0 then
                                plr.x = plr.x-plr.mcdist
                            else
                                plr.x = plr.x+plr.mcdist
                            end
                        end
                        if plr.speedY ~= 0 then
                            if plr.speedY > 0 then
                                plr.y = plr.y-plr.mcdist
                            else
                                plr.y = plr.y+plr.mcdist
                            end
                        end
                    else
                        if plr.speedX ~= 0 then
                            if plr.speedX > 0 then
                                plr.x = plr.x-plr.distance
                            else
                                plr.x = plr.x+plr.distance
                            end
                        end
                        if plr.speedY ~= 0 then
                            if plr.speedY > 0 then
                                plr.y = plr.y-plr.distance
                            else
                                plr.y = plr.y+plr.distance
                            end
                        end
                    end
                    plr.distance = 0
                    if plr.speedX ~= 0 then
                        local speed = plr.speedX
                        plr.speedX = 0
                        if speed > 0 and (config.pathcorner == 2 or config.pathcorner == 4) then
                            speed = math.abs(speed)
                            if config.pathcorner == 2 then
                                plr.speedY = speed
                                plr.direction = smb3map.direction.DOWN
                            else
                                plr.speedY = -speed
                                plr.direction = smb3map.direction.UP
                            end
                        elseif speed < 0 and (config.pathcorner == 1 or config.pathcorner == 3) then
                            speed = math.abs(speed)
                            if config.pathcorner == 1 then
                                plr.speedY = speed
                                plr.direction = smb3map.direction.DOWN
                            else
                                plr.speedY = -speed
                                plr.direction = smb3map.direction.UP
                            end
                        else
                            plr.speedX = speed
                        end
                    elseif plr.speedY ~= 0 then
                        local speed = plr.speedY
                        plr.speedY = 0
                        if speed < 0 and (config.pathcorner == 1 or config.pathcorner == 2) then
                            speed = math.abs(speed)
                            if config.pathcorner == 1 then
                                plr.speedX = speed
                                plr.direction = smb3map.direction.RIGHT
                            else
                                plr.speedX = -speed
                                plr.direction = smb3map.direction.LEFT
                            end
                        elseif speed > 0 and (config.pathcorner == 3 or config.pathcorner == 4) then
                            speed = math.abs(speed)
                            if config.pathcorner == 3 then
                                plr.speedX = speed
                                plr.direction = smb3map.direction.RIGHT
                            else
                                plr.speedX = -speed
                                plr.direction = smb3map.direction.LEFT
                            end
                        else
                            plr.speedY = speed
                        end
                    end
                    --if plr.speedX ~= 0 then
                    --    plr.x = plr.x-plr.distance
                    --    local speed = math.abs(plr.speedX)
                    --    plr.speedX = 0
                    --    if config.pathcorner == 1 or config.pathcorner == 2 then
                    --        plr.speedY = speed
                    --    else
                    --        plr.speedY = -speed
                    --    end
                    --elseif plr.speedY ~= 0 then
                    --    plr.y = plr.y-plr.distance
                    --    local speed = math.abs(plr.speedY)
                    --    plr.speedY = 0
                    --    if config.pathcorner == 1 or config.pathcorner == 3 then
                    --        plr.speedX = speed
                    --    else
                    --        plr.speedX = -speed
                    --    end
                    --end
                end
                return true
            end
        end
    end
    return false
end

-- Corrects the player object `plr`'s collision hitbox
---@param plr table
local function correctCollider(plr)
    plr.collider.x = plr.x+smb3map.playerspace
    plr.collider.y = plr.y+smb3map.playerspace
    plr.colliderouter.x = plr.x-smb3map.playerspace
    plr.colliderouter.y = plr.y-smb3map.playerspace
end

-- Checks if a player object is inside water, and if so, gives them a boat (sets `plr.inwater` to true)
---@param plr table
local function trywater(plr)
    local needboat = false
    correctCollider(plr)
    for __,b in Block.iterate() do -- are you in need of a boat, sir?
        if blockisvalid(b) then
            if Block.config[b.id].waterzone and Colliders.collide(b,plr.collider) then
                needboat = true
                break
            end
        end
    end
    if needboat then
        plr.inwater = true
    else
        plr.inwater = false
    end
end

local function unpull(plr)
    plr.pullinglevel = nil
    plr.pulltimer = 0
    if freezeplayers then
        freezeplayers = false
    end
    if not plr.visible then
        plr.visible = true
    end
end

-- Marks a `level` as complete with a win type `w` and an optional character `char`
---@param level string|NPC|integer can either be the string of a level's filename, an NPC that's the level tile, or the idx of the npc
---@param w number? if this is a negative, then all win types will be marked as true
---@param char number?
local function markAsComplete(level,w,char)
    -- Fail due to lack of level
    if not level then
        SFX.play(54)
        return
    end
    for _,p in ipairs(Player.get()) do
        unpull(p)
    end
    local playsound = (type(level) == "string" or type(level) == "number" or level.data._settings.mark)
    w = w or 1
    local playdestroysound
    if type(level) ~= "string" and type(level) ~= "number" then
        local config = NPC.config[level.id]
        local data = level.data
        local settings = data._settings
        if config.canbedestroyed and settings.once then
            playdestroysound = true
        elseif not config.isenemy then
            Effect.spawn(78,level)
        end
        if settings.idxsave or config.isenemy then
            level = spawnidx(level)
        else
            level = settings.levelFilename
        end
    end
    if level == "" or not level then return end -- double checking it's not nil
    save[level] = save[level] or {}
    local levelsave = save[level]
    if not levelsave.won then
        if playdestroysound then
            SFX.play(smb3map.leveldestroysfx)
            playsound = false
        end
    end
    levelsave.won = true
    levelsave.character = char or player.character or smb3map.defaultchar or CHARACTER_MARIO
    levelsave.winTypes = levelsave.winTypes or {}
    local t = w
    if w < 0 then
        for i = 1,11 do
            levelsave.winTypes[i] = true
        end
    end

    if not levelsave.winTypes[t] then
        if playsound then
            SFX.play(smb3map.levelbeatsfx)
        end
    end

    levelsave.winTypes[t] = true

    for __,v in NPC.iterate() do
        if npcisvalid(v) then
            local config = NPC.config[v.id]
            if config.islevel or config.isenemy then
                local data = v.data
                local settings = data._settings
                if (settings.levelFilename == level or ((settings.idxsave or config.isenemy) and spawnidx(v) == level)) and settings.layer then
                    if settings.layer.show and settings.layer.show ~= "" then
                        local l = Layer.get(settings.layer.show)
                        if l then
                            l:show(settings.layer.noSmoke)
                        else
                            SFX.play(54)
                        end
                    end
                    if settings.layer.hide and settings.layer.hide ~= "" then
                        local l = Layer.get(settings.layer.hide)
                        if l then
                            l:hide(settings.layer.noSmoke)
                        else
                            SFX.play(54)
                        end
                    end
                    if settings.layer.toggle and settings.layer.toggle ~= "" then
                        smb3map.toggleLayer(settings.layer.toggle,settings.layer.noSmoke)
                    end
                    for _,dir in ipairs(dirs) do
                        if settings.layer[dir] then
                            local lsd = settings.layer[dir]
                            if lsd.show and lsd.show ~= "" then
                                Layer.get(lsd.show):show(settings.layer.noSmoke)
                            end
                            if lsd.hide and lsd.hide ~= "" then
                                Layer.get(lsd.hide):hide(settings.layer.noSmoke)
                            end
                            if lsd.toggle and lsd.toggle ~= "" then
                                smb3map.toggleLayer(lsd.toggle)
                            end
                        end
                    end
                    data.layed = true
                    if v.talkEventName ~= "" then
                        triggerEvent(v.talkEventName)
                    end
                    data.triggered = true
                    data.initialized = false
                    if config.isairship or config.isenemy then
                        playsound = false
                        if config.isairship or (settings.airship and not airships[settings.levelFilename]) then
                            Effect.spawn(69,v)
                            SFX.play(smb3map.airshipbeatsfx)
                        else
                            Effect.spawn(10,v)
                            SFX.play(smb3map.enemybeatsfx)
                        end
                        v:kill()
                    end
                end
            end
        end
    end
end

-- Unmarks a `level` as complete, erasing its save file
---@param level string|NPC|integer can either be the string of a level's filename, an NPC that's the level tile, or the idx of the npc
local function markAsIncomplete(level)
    -- Fail due to lack of level
    if not level then
        SFX.play(54)
        return
    end
    if type(level) ~= "string" and type(level) ~= "number" then
        local config = NPC.config[level.id]
        local data = level.data
        local settings = data._settings
        if settings.idxsave or config.isenemy then
            level = spawnidx(level)
        else
            level = settings.levelFilename
        end
    end
    if level == "" or not level then return end -- double checking it's not nil
    save[level] = {}
end

-- Cause a message box to appear about how many stars you need to meet the `requirement`
---@param requirement number required stars
---@param tellhowmanyleft boolean|nil if true, it will tell you how many stars are left to collect, while if false, it will tell you the total amount of stars reqired. if neither, then it will defaul to the value of smb3map.tellmedefault
local function starmessage(requirement,tellhowmanyleft)
    local needed = requirement
    local words = smb3map.starmessageb
    if type(tellhowmanyleft) ~= "boolean" then
        tellhowmanyleft = smb3map.tellmedefault
    end
    if tellhowmanyleft and mem(0x00B251E0,FIELD_WORD) > 0 then
        needed = needed - mem(0x00B251E0,FIELD_WORD)
        words = smb3map.starmessagec
    end
    Text.showMessageBox(smb3map.starmessagea..tostring(needed)..words)
end

-- Warps the player `p` to a different location `target`
---@param p Player
---@param target Warp|Vector2|NPC|Block|BGO The location. If it's a warp, it'll go to the exit location. If not, target *is* the exit location
---@param dir number? optional direction (warp style direction)
---@param playsound boolean|number|SFX|string|nil optional sound
---@param ignorerequirement boolean|nil if true, the warp will activate even if it doesn't have the required stars or is locked
---@param standstill boolean|nil if true, the player won't move after coming out of the warp
---@param savep boolean|nil if true, the warp will save the position of the player after it's done
---@return table|nil warp won't return if the player's already in an active warp transition
local function warpPlayer(p,target,dir,playsound,ignorerequirement,standstill,savep)
    if activewarps[p.idx] then return end -- You're already in a warp!
    if smb3map.enteringlevel then return end -- As if you'll warp while entering a level!
    if cheatisactive("grandstar") then
        ignorerequirement = true
    end
    if target.starsRequired and target.starsRequired > mem(0x00B251E0,FIELD_WORD) and not ignorerequirement then
        starmessage(target.starsRequired)
        if target.warpType ~= 2 then
            ---@type PlayerMapObject
            local plr = p.data.mapObj
            if plr then
                plr.speedX = -plr.speedX
                plr.speedY = -plr.speedY
                plr.direction = turnaround(plr.direction)
            end
        end
        return
    end
    if playsound then
        if type(playsound) == "boolean" then
            SFX.play(smb3map.warpsfx)
        else
            SFX.play(playsound)
        end
    end

    activewarps[p.idx] = {
        timer = smb3map.warptimer,
        standstill = standstill,
        savepos = savep,
    }
    ---@class ActiveMapWarp
    local warp = activewarps[p.idx]
    if transition then
        warp.timer = 0
    end
    --warp.playsound = playsound
    if target.x and target.y then
        warp.target = vector(target.x,target.y)
        if target.section then
            warp.section = target.section
        end
    else
        warp.section = target.exitSection
        warp.target = vector(target.exitX, target.exitY)

        if target.warpType == 3 then -- Portal taught me something: something something momentum
            local direction = p.data.mapObj.direction
            if target.entranceDirection ~= turnwarparound(target.exitDirection) then
                if target.entranceDirection == 1 then
                    if target.exitDirection == 2 then
                        direction = turncounterclockwise(direction)
                    elseif target.exitDirection == 4 then
                        direction = turnclockwise(direction)
                    else
                        direction = turnaround(direction)
                    end
                elseif target.entranceDirection == 2 then
                    if target.exitDirection == 3 then
                        direction = turncounterclockwise(direction)
                    elseif target.exitDirection == 1 then
                        direction = turnclockwise(direction)
                    else
                        direction = turnaround(direction)
                    end
                elseif target.entranceDirection == 3 then
                    if target.exitDirection == 1 then
                        direction = turncounterclockwise(direction)
                    elseif target.exitDirection == 3 then
                        direction = turnclockwise(direction)
                    else
                        direction = turnaround(direction)
                    end
                elseif target.entranceDirection == 4 then
                    if target.exitDirection == 1 then
                        direction = turncounterclockwise(direction)
                    elseif target.exitDirection == 3 then
                        direction = turnclockwise(direction)
                    else
                        direction = turnaround(direction)
                    end
                end
            end
            warp.direction = smb3dirtowarpdir(turnaround(direction))
        elseif target.warpType == 1 then -- Absolute exit direction
            warp.direction = turnwarparound(target.exitDirection) -- I've learned that it turns out that warp direction entrances and exits are inverted
        end
        --if p.data.mapObj then
        --    p.data.mapObj.direction = warpdirtosmb3dir(warp.direction)
        --end
        if transition then
            transition.currentWarp = warp
        end
    end
    if dir then
        warp.direction = dir
    elseif not warp.direction then
        warp.direction = smb3dirtowarpdir(p.data.mapObj.direction)
    end
    warp.warpType = target.warpType
    return warp
end

-- Saves the current position of the player entering the level `p` and begins the transition into the level `level`, along with the warp `index` it should be
---@param level string|NPC
---@param p Player|nil
---@param index integer|nil
---@param ignorerequirement boolean|nil
local function enterlevel(level,p,index,ignorerequirement)
    if smb3map.enteringlevel then return end
    if cheatisactive("grandstar") then
        ignorerequirement = true
    end
    p = p or player
    ---@type PlayerMapObject
    local plr = p.data.mapObj
    if cheatisactive("instantclear") then
        if plr and plr.pullinglevel then
            unpull(plr)
        end
        markAsComplete(level,-1,p.character)
        return
    end
    -- Fail due to lack of level
    if (not level) or level == "" then
        SFX.play(54)
        if plr and plr.pullinglevel then
            unpull(plr)
        end
        return
    end
    local enemy
    local savemii
    local idx
    if type(level) == "string" then
        savemii = p
    else -- An NPC is afoot, it has to be!
        local config = NPC.config[level.id]
        local data = level.data
        local settings = data._settings
        enemy = config.isenemy
        if settings.stars and settings.stars > mem(0x00B251E0,FIELD_WORD) and not ignorerequirement then
            starmessage(settings.stars)
            if plr and plr.pullinglevel then
                unpull(plr)
            end
            return
        end
        if config.isenemy or settings.idxsave then
            idx = spawnidx(level)
        end
        if config.isenemy and plr.starman then -- there's a starman and AAAAA
            if plr and plr.pullinglevel then
                unpull(plr)
            end
            markAsComplete(level,LEVEL_WIN_TYPE_STAR,p.character)
            SFX.play(smb3map.knockbacksfx)
            return
        end
        if config.isoffgrid or level.speedX ~= 0 or level.speedY ~= 0 then
            if plr then -- you're a player object, time to find the nearest level or node and save that!
                if plr.currentlevel then
                    savemii = plr.currentlevel
                else
                    for __,v in NPC.iterate() do
                        if npcisvalid(v) then
                            local bonfig = NPC.config[v.id]
                            if (bonfig.islevel or bonfig.isnode) and (not bonfig.isoffgrid) and (Colliders.collide(v,plr.collider) or Colliders.collide(v,level)) then
                                savemii = v
                                break
                            end
                        end
                    end
                end
            else
                savemii = p
            end
        else
            savemii = p
        end
        saveTemp.intendedLevel = settings.levelFilename -- To count these other things as the same level
        if data.stack and data.stack ~= "" and Misc.resolveFile(data.stack.."-"..settings.levelFilename) then -- Airship stacked onto a level
            level = data.stack.."-"..settings.levelFilename
        elseif config.isairship and data.airshipFilename and data.airshipFilename ~= "" then -- Airship solo
            level = data.airshipFilename
        elseif data.treasureship then -- Treasure ship
            save.shippedtreasures[level.section] = true
            level = data.treasureship
        else
            level = settings.levelFilename
        end
        if saveTemp.intendedLevel ~= level and saveTemp.intendedLevel then -- Transfering those checkpoints
            GameData.__checkpoints[level] = GameData.__checkpoints[saveTemp.intendedLevel]
        end
    end
    -- Fail due to lack of valid level file
    if not Misc.resolveFile(level) then
        if Misc.inEditor() then
            markAsComplete(level,-1,p.character)
        else
            SFX.play(54)
            if plr and plr.pullinglevel then
                unpull(plr)
            end
        end
        return
    end
    if savemii then
        savepos(savemii)
    end
    if idx then
        saveTemp.itsanidx = idx
    end
    for i = 0, 20 do
        Audio.MusicFadeOut(i,lunatime.toSeconds(smb3map.enteron))
        Section(i).music = 0
    end
    smb3map.enteringlevel = level
    smb3map.warpIndex = index
    if enemy then
        SFX.play(smb3map.bumpbaddysfx)
    else
        SFX.play(smb3map.enterlevelsfx)
    end
end

-- Resets smb3map.windx's position to the side of the screen
local function resetWind()
    smb3map.windx = 0
    if smb3map.tornadosprite then
        smb3map.windx = -smb3map.tornadosprite.width
    end
end

-- a function to make sure characters exist and makes sure some don't
local function charcheck(char,backward)
    if char < 1 then
        char = 16
    elseif char > 16 then
        char = 1
    end
    for _,c in ipairs(pm.overworldCharacters) do
        if char == c then -- oh cool! you're allowed :D
            return c
        end
    end
    -- you didn't return, meaning you're NOT allowed!
    if backward then
        char = char-1
    else
        char = char+1
    end
    return charcheck(char,backward)
end

-- Draws the `b` texture next to the `a` texture based on `distance` and the original texture's `pos`ition and an optional `prior`ity
---@param pos Vector2
---@param a Texture
---@param b Texture
---@param distance number|nil
---@param prior number|nil
local function drawNextTo(pos,a,b,distance,prior)
    prior = prior or 0
    distance = distance or 0
    Graphics.drawBox{
        texture = b,
        x = pos.x+a.width+b.width/2+distance,
        y = pos.y+a.height/2,
        centered = true,
        sourceX = 0,
        sourceY = 0,
        sourceWidth = b.width,
        sourceHeight = b.height,
        priority = prior
    }
end

-- Reads out info on the current checkpoint or the checkpoint of a `level`
---@param level string|nil
local function debugCheckpoints(level)
    local ocho = 0
    if Level.filename() ~= smb3map.levelFilename then
        ocho = 80
        if level then
            level = Level.filename()
        end
    end
    if level and level ~= "" and GameData.__checkpoints[level] then
        local dp = 0
        for data,point in pairs(GameData.__checkpoints[level]) do
            dp = dp + 1
            Text.print(tostring(data)..": "..tostring(point),300,dp*20+ocho)
        end
        if dp == 0 then
            Text.print("No checkpoints detected here!",300,20+ocho)
        end
    elseif level == "" then
        Text.print("Empty Level detected!",300,20+ocho)
    else
        Text.print("No level detected here!",300,20+ocho)
    end
end

-- copy a player object's speed values to another
---@param plr table object to paste into
---@param tplr table object to copy from
local function copypspeed(plr,tplr)
    plr.moving = tplr.moving
    plr.speedX = tplr.speedX
    plr.speedY = tplr.speedY
    plr.speed = tplr.speed
    plr.distance = tplr.distance
    plr.mcdist = tplr.mcdist
    plr.direction = tplr.direction
end

-- teleport one player to another and mimic their movement
---@param plr table object to paste into
---@param tplr table object to copy from
local function copyplrpos(plr,tplr)
    plr.x = tplr.x
    plr.y = tplr.y
    plr.freeroam = tplr.freeroam
    plr.currentlevel = tplr.currentlevel
    plr.currentcorner = tplr.currentcorner
    copypspeed(plr,tplr)
end

local function startanimate(id)
    save.animatedsections[id] = true
    if cheatisactive("skipthesequence") then return end
    animatedstart = false
    startanimtimer = math.max(smb3map.worldstartticks,smb3map.sparkleon)
    local tp = player
    for _,p in ipairs(Player.get()) do
        if p.section == id then
            tp = p
            break
        end
    end
    local tplr = tp.data.mapObj
    for _,p in ipairs(Player.get()) do
        ---@type PlayerMapObject
        local plr = p.data.mapObj
        if p ~= tp and plr and tplr then
            copyplrpos(plr,tplr)
        end
    end
end

-- Renders a player `p`'s object
---@param p Player The player with the object
---@param pos Vector2|nil optional position to render at
---@param prior number|nil Priority to render
---@param sceneCoords boolean|nil if it's nil, it's automatically true
---@param direction number|nil direction of the player object
---@param pulloffset number|nil Offset of any pulling
---@param shader Shader|nil Shader of the player
local function renderPlayer(p,pos,prior,sceneCoords,direction,pulloffset,shader,uniforms)
    if not p then return end
    ---@type PlayerMapObject
    local plr = p.data.mapObj
    if not plr then return end

    direction = direction or plr.direction

    if type(sceneCoords) == "nil" then
        sceneCoords = true
    end

    prior = prior or -25

    pulloffset = pulloffset or 0

    local animationframe = plr.frame
    local frames = 2
    if smb3map.frames[p.character] then
        frames = smb3map.frames[p.character][getpowerup(p)] or frames
    end
    local totalframes = frames
    if smb3map.framestyle[p.character] and smb3map.framestyle[p.character][getpowerup(p)] == 1 then
        totalframes = totalframes*4
        animationframe = animationframe+frames*(direction-1)
    end
    if not playerimages[p.character] then
        playerimages[p.character] = {}
    end
    if not playerimages[p.character][getpowerup(p)] then
        playerimages[p.character][getpowerup(p)] = attemptload(characternames[p.character].."-"..tostring(getpowerup(p)),p)
    end

    ---@type Texture
    local sprite = playerimages[p.character][getpowerup(p)]
    local height = sprite.height/totalframes

    pos = pos or vector(plr.x+plr.width/2-sprite.width/2,plr.y+(plr.height-height)+plr.jumpoffset)
    if smb3map.debug then
        if smb3map.dbo.playerpos then
            Graphics.drawBox{
                x = pos.x,
                y = pos.y,
                width = plr.width,
                height = plr.height,
                sceneCoords = true,
                priority = -10,
                color = Color(1,1,0,0.5)
            }
        end
        if smb3map.hitbox then
            Graphics.drawBox{
                x = plr.x,
                y = plr.y,
                width = plr.width,
                height = plr.height,
                sceneCoords = true,
                priority = -10.1,
                color = Color(1,0,1,0.5)
            }
        end
    end

    if sprite and not (smb3map.intentionallymisstexture or plr.intentionallymisstexture) then -- The player's sprite!
        Graphics.drawBox{
            texture = sprite,
            x = pos.x,
            y = pos.y+pulloffset,
            sourceHeight = height-math.clamp(pulloffset,0,height),
            sourceWidth = sprite.width,
            sourceX = 0,
            sourceY = animationframe*height,
            sceneCoords = sceneCoords,
            priority = prior,
            shader = shader,
            uniforms = uniforms,
        }
    else -- Missing texture moment, a Tissing mexture if you will.
        Graphics.drawBox{
            x = pos.x,
            y = pos.y+pulloffset,
            width = plr.width/2,
            height = plr.height/2,
            sceneCoords = sceneCoords,
            priority = prior,
            color = Color.magenta,
            shader = shader,
            uniforms = uniforms,
        }
        Graphics.drawBox{
            x = pos.x+plr.width/2,
            y = pos.y+pulloffset,
            width = plr.width/2,
            height = plr.height/2,
            sceneCoords = sceneCoords,
            priority = prior,
            color = Color.black,
            shader = shader,
            uniforms = uniforms,
        }
        Graphics.drawBox{
            x = pos.x,
            y = pos.y+pulloffset+plr.height/2,
            width = plr.width/2,
            height = plr.height/2,
            sceneCoords = sceneCoords,
            priority = prior,
            color = Color.black,
            shader = shader,
            uniforms = uniforms,
        }
        Graphics.drawBox{
            x = pos.x+plr.width/2,
            y = pos.y+pulloffset+plr.height/2,
            width = plr.width/2,
            height = plr.height/2,
            sceneCoords = sceneCoords,
            priority = prior,
            color = Color.magenta,
            shader = shader,
            uniforms = uniforms,
        }
    end
end

-- Does a lil thing. Returns if the function should break the loop
---@param v NPC
---@param p Player
---@return boolean
local function spidercheck(v,p)
    ---@type PlayerMapObject
    local plr = p.data.mapObj
    if cheatisactive("goaroundenemies") or Cheats.get("donthurtme").active then return true end
    if npcisvalid(v) and cantouch(NPC.config[v.id],p) then -- The giant enemy spiders
        local config = NPC.config[v.id]
        local settings = v.data._settings

        local levelsave = SaveData.smb3map[settings.levelFilename]
        if settings.idxsave or config.isenemy then
            levelsave = SaveData.smb3map[spawnidx(v)]
        end
        if (not v.friendly) and (config.isenemy or config.isgrabber) and (not (config.issleeper and mboxactive())) and Colliders.collide(v,plr.collider) then
            if smb3map.debug and p.keys.altJump and smb3map.dbo.levelcheat then
                SFX.play(43)
                markAsComplete(v,-1,p.character)
            elseif config.isenemy or (config.isgrabber and RNG.randomInt(1,2) == 1) and not (levelsave and levelsave.won) then
                if plr.freeroam ~= 2 then
                    if plr.speedX ~= 0 then
                        if plr.speedX > 0 then
                            plr.x = plr.x-plr.distance
                        else
                            plr.x = plr.x+plr.distance
                        end
                    end
                    if plr.speedY ~= 0 then
                        if plr.speedY > 0 then
                            plr.y = plr.y-plr.distance
                        else
                            plr.y = plr.y+plr.distance
                        end
                    end
                    stopplr(plr)
                end
                if config.isenemy then
                    if settings.levelFilename and settings.levelFilename ~= "" then
                        enterlevel(v,p,v.data._settings.warp)
                    else
                        v:kill(HARM_TYPE_FROMBELOW)
                    end
                else
                    freezeplayers = true
                    plr.pullinglevel = v
                end
                return true
            end
        end
    end
    return false
end



--=<[ LIBRARY FUNCTIONS ]>=--



-- Renders a player `p`'s object
---@param p Player The player with the object
---@param pos Vector2|nil optional position to render at
---@param prior number|nil Priority to render
---@param sceneCoords boolean|nil
---@param direction number|nil direction of the player object
---@param pulloffset number|nil Offset of any pulling
---@param shader Shader|nil Shader of the player
function smb3map.renderPlayer(p,pos,prior,sceneCoords,direction,pulloffset,shader)
    renderPlayer(p,pos,prior,sceneCoords,pulloffset,shader)
end


-- Returns if the initial enemy animation has finished
---@return boolean
function smb3map.animatedenemies()
    return animatedbaddies
end

-- Deactivates the music box
function smb3map.musicBoxDeactivate()
    save.musicboxturns = 0
    musicset = false
end

-- Returns if an anchor box is active or not
---@return boolean
function smb3map.anchorActive()
    return anchactive()
end

-- Activates an anchor for `turns` amount of times the map will be loaded
---@param turns integer|nil
function smb3map.anchorActivate(turns)
    save.anchorTimer = turns or smb3map.defaultAnchorCounter
end

-- Deactivates the music box
function smb3map.anchorDeactivate()
    save.anchorTimer = 0
end

-- Returns if the music box is active or not
---@return boolean
function smb3map.musicBoxActive()
    return mboxactive()
end

-- Returns true if all the starting animations (enemies, players, tiles, world start) have finished
---@return boolean
function smb3map.doneanimating()
    return doneanimating()
end

-- Returns if players aren't animated from going back
---@return boolean
function smb3map.animatedplayers()
    return animatedplayer
end

function smb3map.spawnidx(v)
    return spawnidx(v)
end

-- Toggles a current layer's state and then saves it so it stays toggled afterwards.
---@param layer string
---@param hidesmoke boolean|nil
function smb3map.toggleLayer(layer,hidesmoke)
    save.toggledlayers = save.toggledlayers or {}
    local tog = Layer.get(layer)
    if not tog then
        SFX.play(54)
        return
    end
    if type(save.toggledlayers[layer]) ~= "boolean" then
        save.toggledlayers[layer] = tog.isHidden
    end
    if save.toggledlayers[layer] then
        Layer.get(layer):show(hidesmoke)
        save.toggledlayers[layer] = false
    else
        Layer.get(layer):hide(hidesmoke)
        save.toggledlayers[layer] = true
    end
end

-- Marks a `level` as complete with a win type `w` and an optional character `char`
---@param level string|NPC|integer can either be the string of a level's filename, an NPC that's the level tile, or the idx of the npc
---@param w number? if this is a negative, then all win types will be marked as true
---@param char number?
function smb3map.complete(level,w,char)
    markAsComplete(level,w,char)
end

-- Unmarks a `level` as complete, erasing its save file
---@param level string|NPC|integer can either be the string of a level's filename, an NPC that's the level tile, or the idx of the npc
function smb3map.uncomplete(level)
    markAsIncomplete(level)
end

-- forces a player `p` into a jumping animation
---@param p Player
---@param soundeffect (string|number|unknown)?
---@param grav number|nil
---@param speed number|nil
---@param height number|nil
---@param terminalv number|nil
function smb3map.jump(p,soundeffect,grav,speed,height,terminalv)
    mapJump(p,soundeffect,grav,speed,height,terminalv)
end

-- Uses an NPC or Block's config to determine if it should preform it's effect
---@param config NPCConfig|BlockConfig
---@param p Player
---@return boolean
function smb3map.checktouch(config,p)
    return cantouch(config,p)
end

-- Activates the music box for `turns` amount of times the map will be loaded
---@param turns integer|nil if no turns are provided, it will use `smb3map.defaultMusicBoxTurns` instead (which by default is 2)
---@param changeframespeed boolean|nil if true, every BGO and Block will have it's framespeed halved (technically doubled)
function smb3map.musicBoxActivate(turns,changeframespeed)
    save.musicboxturns = turns or smb3map.defaultMusicBoxTurns
    if changeframespeed then
        save.framespeedchange = true
        slowAnimations()
    else
        save.framespeedchange = false
    end
end

-- Gives every enemy in `s` section an extra step.
---@param s integer
---@param fromzone boolean|nil
function smb3map.moveEnemies(s,fromzone)
    for _,v in NPC.iterate() do
        if npcisvalid(v) and v.section == s then
            local config = NPC.config[v.id]
            local data = v.data
            if config.isenemy and not ((fromzone and config.ignoreenemyzone) or v.dontMove or config.speed == 0 or (config.issleeper and SaveData.smb3map.musicboxturns and SaveData.smb3map.musicboxturns > 0)) then
                if data.doneanimating then
                   if type(data.distance) ~= "number" or data.distance > 0 then
                        data.distance = 0
                    end
                    data.doneanimating = false
                    data.forcemove = true
                end
                data.steps = (data.steps or 0) + 1
            end
        end
    end
end

-- Warps the player `p` to a different location `t`
---@param p Player
---@param t Warp|Vector2|NPC|Block|BGO The location. If it's a warp, it'll go to the exit location. If not, target *is* the exit location
---@param d number? optional direction (warp style direction)
---@param ps boolean|number|SFX|string|nil optional sound
---@param ir boolean|nil if true, the warp will activate even if it doesn't have the required stars or is locked
---@param st boolean|nil if true, the player won't move after coming out of the warp
---@param sp boolean|nil if true, the warp will save the position of the player after it's done
---@return table|nil warp won't return if the player's already in an active warp transition
function smb3map.warp(p,t,d,ps,ir,st,sp)
    return warpPlayer(p,t,d,ps,ir,st,sp)
end

-- Whistle a warp Whistle and cause things to happen
---@param p Player|nil
function smb3map.warpWhistle(p)
    p = p or player
    SFX.play(smb3map.whistlesound)
    for _,b in Block.iterate() do
        if blockisvalid(b) then
            local config = Block.config[b.id]
            local data = b.data
            local settings = data._settings
            if config.warppoint and settings.warpfrom then
                if settings.warpfrom == p.section then
                    whistleBlock = b
                    smb3map.windx = p.sectionObj.boundary.left
                    break
                end
            end
        end
    end
    if whistleBlock then
        freezeplayers = true
        whistlingwarp = true
        Audio.MusicStop()
        for _,s in ipairs(Section.get()) do
            s.music = ""
        end
    end
end

-- Returns the vector that the player's going back to. Returns nil if not going back
---@param p Player
---@return Vector2|nil
function smb3map.playergoingback(p)
    return p.data.goingback
end

-- Returns if the player `p` can enter the level
---@param p Player
---@return boolean
function smb3map.canenterlevel(p)
    ---@type PlayerMapObject
    local plr = p.data.mapObj
    return (
        plr -- If a player object exists
        and not smb3map.enteringlevel -- A level's already being entered
        and not smb3map.playergoingback(p) -- If the player's being yeeted back
        and not activewarps[p.idx] -- Not warping
        and not plr.frozen -- If the player can move
        and not plr.beingpulled -- If the player's being pulled by a level
        and not freezeplayers -- If the players in general can move
    )
end

-- Saves the current position of the player entering the level `p` and begins the transition into the level `level`, along with the warp `warpIndex` it should be
---@param level string|NPC
---@param p Player|nil
---@param warpIndex integer|nil
function smb3map.enterlevel(level,p,warpIndex)
    enterlevel(level,p,warpIndex)
end
-- Returns true if any player object is touching the specified object `v`
---@param v NPC|Block
function smb3map.playertouching(v)
    for _,p in pairs(Player.get()) do
        if p.data.mapObj and Colliders.collide(p.data.mapObj.collider,v) then
            return true
        end
    end
    return false
end

-- Saves the current position of the player
---@param p Player|Vector2|table|NPC|nil
function smb3map.savePos(p)
    savepos(p)
end

-- Loads the previous position as the new position
---@param p Player|nil
---@param pos Vector2? an optional position to chose as the next player pos
---@param sec integer|nil an optional section
---@param gtscfrmps boolean|nil if true, the section will be gotten from the position
---@param dontsave boolean|nil if true the reverted pos will not be saved
---@param dontsection boolean|nil if true, the section won't be updated
function smb3map.revertPos(p,pos,sec,gtscfrmps,dontsave,dontsection)
    pos = pos or save.lastplayerpos
    if gtscfrmps then
        local sgetter = NPC.spawn(465,pos.x,pos.y)
        sec = sgetter.section
        sgetter:kill(HARM_TYPE_VANISH)
    end
    if pos then
        if p then
            p.x = pos.x
            p.y = pos.y
            p.data.safepos = vector(pos.x,pos.y)
        end
        if not dontsave then
            save.playerpos = vector(pos.x,pos.y)
            save.lastplayerpos = vector(pos.x,pos.y)
        end
    end
    
    sec = sec or save.lastsection

    if p then
        if p.data.mapObj then
            ---@type PlayerMapObject
            local plr = p.data.mapObj
            plr.freeroam = save.lastfreeroam
            save.freeroam = save.lastfreeroam
            stopplr(plr)
        end
        
        if not dontsection then
            p.section = sec
        end
    end
    if not (dontsave or dontsection) then
        save.section = sec
        save.lastsection = sec
    end
end


--==<[ BASEGAME FUNCTIONS ]>==--


function smb3map.onInitAPI()
    registerEvent(smb3map,"onStart")
    registerEvent(smb3map,"onTick")
    registerEvent(smb3map,"onTickEnd")
    registerEvent(smb3map,"onDraw")
    registerEvent(smb3map,"onExitLevel")
    registerEvent(smb3map,"onCameraDraw")
    registerEvent(smb3map,"onInputUpdate")
    registerEvent(smb3map,"onPostWarpEnter")
    registerEvent(smb3map,"onPostEventDirect")

    registerEvent(smb3map,"onPlayerKill")
    registerEvent(smb3map,"onPlayerHarm")
end

-- Runs at the start of the game, after all libraries have been loaded. This is the first point in time when entities like players, NPCs and blocks are loaded in.
function smb3map.onStart()
    if cheatisactive("skipthesequence") then
        animatedbaddies = true
        animatedplayer = true
        animatedstart = true
        animatedtiles = true
        musicset = false
        save.introdone = true
    end
    if smb3map.dbo.resetOnStart then
        resetMap()
    end
    if inventory then
        inventory.bottom = true
        inventory.sharingcaring = smb3map.sharingcaring
    end
    for _,p in ipairs(Player.get()) do
        p.data.backtimer = 0
    end
    --player.reservePowerup = 293
    --inventory.add(184)
    --inventory.add(185)
    --inventory.add(182)
    --inventory.add(186)
    if Level.filename() == smb3map.levelFilename then -- on the map, the map
        if not save.introdone then
            if smb3map.introFilename and smb3map.introFilename ~= "" and Misc.resolveFile(smb3map.introFilename) then
                Level.load(smb3map.introFilename,nil,smb3map.introwarp)
                return
            else
                save.introdone = true
            end
        end
        handycam[1].yOffset = -64
        if inventory then
            inventory.onmap = true
            inventory.takereserve = true
            --inventory.show = true
        end
        if smb3hud then
            smb3hud.currentWorld = smb3map.worlds[player.section+1]
        end
        save.musicboxturns = math.max(save.musicboxturns - 1,0)
        save.anchorTimer = math.max(save.anchorTimer - 1,0)
        if mboxactive() and save.framespeedchange then
           slowAnimations()
        end
        if saveTemp.warppos then
            save.playerpos = saveTemp.warppos
        elseif saveTemp.winType ~= 0 and saveTemp.level ~= "" and not saveTemp.dontmark then
            if saveTemp.itsanidx == 0 or not saveTemp.itsanidx then
                markAsComplete(saveTemp.level,saveTemp.winType)
            else
                markAsComplete(saveTemp.itsanidx,saveTemp.winType)
            end
        end
        saveTemp.dontmark = (not save.introdone)
        if saveTemp.loser then
            animatedstart = true
            --SFX.play(1)
            if save.freeroam and save.freeroam ~= 0 and smb3map.forgivefreeroamers then
                SFX.play(smb3map.knockbacksfx)
            elseif not cheatisactive("immovableobject") then
                for _,p in ipairs(Player.get()) do
                    p.data.goingback = save.lastplayerpos
                end
            end
        else
            for _,p in ipairs(Player.get()) do
                p.data.backtimer = smb3map.backtimer
            end
        end
        for _,s in ipairs(Section.get()) do
            basemusic[_] = s.music
            s.music = ""
        end
        for _,v in NPC.iterate() do
            v:mem(0x14,FIELD_WORD,_)
        end
        for _,v in NPC.iterate() do
            if npcisvalid(v) then
                local config = NPC.config[v.id]
                if save.destroyedlist[spawnidx(v)] then
                    v:kill(HARM_TYPE_VANISH)
                end
            end
        end
        for _,l in ipairs(Layer.get()) do
            layeroffset[l.layerName] = vector(0,0)
        end
    else -- Inside of a level
        for _,p in ipairs(Player.get()) do
            if save.starmen[p.idx] then
                starman.start(p)
            end
        end
        save.starmen = {}
        saveTemp.triggership = false
        saveTemp.triggeredEvents = {}
        if inventory then
            inventory.onmap = false
            inventory.takereserve = false
        end
        if saveTemp.intendedLevel then
            saveTemp.level = saveTemp.intendedLevel
            saveTemp.intendedLevel = nil
        else
            saveTemp.level = Level.filename()
        end
    end
    saveTemp.warppos = nil
    if save.toggledlayers then
        for layer,toggled in pairs(save.toggledlayers) do
            local lay = Layer.get(layer)
            if lay then
                if toggled then
                    lay:show(true)
                else
                    lay:hide(true)
                end
            end
        end
    end
end

-- Runs every tick the game isn't paused. Executes directly before SMBX internal code, making it useful for handling (for example) player input during gameplay.
function smb3map.onTick()
    save.score = math.max(save.score,Misc.score())
    btmt = math.max(btmt-1,0)
    if smb3map.debug then
        if smb3map.dbo.gamedatalevel then
            Text.print(saveTemp.level,600,100)
            Text.print(saveTemp.intendedLevel,600,120)
        end
    end
    if Level.filename() ~= smb3map.levelFilename then return end
    if whistlingwarp then
        smb3map.windx = smb3map.windx + smb3map.windspeed
    else

    end

    if smb3map.enteringlevel then
        smb3map.entertimer = smb3map.entertimer + 1
    end

    local resting = true
    local prevm = save.music
    local cantuseinv = false
    for _,p in ipairs(Player.get()) do
        if p.data.goingback and btmt <= 0 then
            p.data.backtimer = p.data.backtimer + 1
            if p.data.nonfatal then
                p.data.backtimer = p.data.backtimer + 1
            end
        else
            p.data.nonfatal = false
        end
        if p.keys.dropItem == KEYS_PRESSED and ((not inventory) or (inventory.button ~= "dropItem")) then
            if p.reservePowerup ~= 0 and smb3map.usereserve and doneanimating() and
            not (freezeplayers or (p.data.mapObj and p.data.mapObj.frozen) or (inventory and inventory.takereserve) or smb3map.enteringlevel) then
                --SFX.play(11)
                if smb3map.sharingcaring then
                    for __,pp in ipairs(Player.get()) do
                        if pp.isValid then
                            local power = NPC.spawn(p.reservePowerup,pp.x,pp.y)
                            power:collect(pp)
                        end
                    end
                else
                    local power = NPC.spawn(p.reservePowerup,p.x,p.y)
                    power:collect(p)
                end
                p.reservePowerup = 0
            elseif Misc.inEditor() then
                if smb3map.debug then
                    smb3map.debug = false
                    SFX.play(5)
                else
                    smb3map.debug = true
                    SFX.play(6)
                end
            else
                if smb3map.usereserve then
                    --SFX.play(3)
                else
                    --p.keys.dropItem = false
                end
            end
        end
        saveTemp.reserve[_] = p.reservePowerup
        p.reservePowerup = 0

        p.speedX = 0
        p.speedY = 0

        if p.forcedState == FORCEDSTATE_NONE then
            p.forcedState = FORCEDSTATE_INVISIBLE
        else
            p.frame = 0
        end
        if p.data.mapObj then
            ---@type PlayerMapObject
            local plr = p.data.mapObj
            if not smb3map.enteringlevel then
                if plr.currentlevel and not npcisvalid(plr.currentlevel) then
                    plr.currentlevel = nil
                end
                if plr.currentcorner and not blockisvalid(plr.currentcorner) then
                    plr.currentcorner = nil
                end
                if plr.gravblock and not blockisvalid(plr.gravblock) then
                    plr.gravblock = nil
                end
                if plr.speedblock and not blockisvalid(plr.speedblock) then
                    plr.speedblock = nil
                end
                if activewarps[p.idx] then
                    plr.iswarping = true
                    --SFX.play(1)
                    -- Warping player code
                    local warp = activewarps[p.idx]
                    if cheatisactive("skipthesequence") then
                        warp.timer = 0
                    end
                    if warp.timer > 0 then
                        warp.timer = warp.timer - 1
                    else -- I'M GONNA WARP IT!!!
                        plr.x = warp.target.x
                        plr.y = warp.target.y

                        plr.direction = warpdirtosmb3dir(warp.direction)
                        if not (warp.warpType == 2 or warp.standstill) then
                            setplrspeeds(plr)
                        else
                            stopplr(plr)
                        end

                        if warp.section and warp.section ~= p.section then
                            p.section = warp.section
                        end
                        activewarps[p.idx] = nil
                        correctCollider(plr)
                        -- get a cool new level again
                        for __,v in NPC.iterate() do
                            if npcisvalid(v) then
                                local config = NPC.config[v.id]
                                if (config.islevel or config.isnode) and Colliders.collide(v,plr.collider) then
                                    plr.currentlevel = v
                                    if smb3map.snaptogrid then
                                        plr.x = v.x+(config.playeroffsetx or 0)
                                        plr.y = v.y+(config.playeroffsety or 0)
                                    end
                                    p.data.safepos = vector(plr.x,plr.y)
                                    break
                                end
                            end
                        end
                        if (p == player or not smb3map.leadersChoice) then
                            for __,b in Block.iterate() do
                                if blockisvalid(b) then
                                    local config = Block.config[b.id]
                                    if (config.changemusic) and Colliders.collide(b,plr.collider) then
                                        local data = b.data
                                        local settings = data._settings
                                        if settings.customMusicPath and settings.customMusicPath ~= "" then
                                            save.music = settings.customMusicPath
                                        elseif settings.music then
                                            if settings.music > 1 then
                                                local index = settings.music-2
                                                save.music = index
                                            elseif settings.music == 1 then
                                                save.music = nil
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        if whistlingwarp and not warpedwhistle then
                            warpedwhistle = true
                            prevm = ""
                            musicset = false
                            savepos(p)
                            smb3map.windx = Section(p.section).boundary.left
                        elseif warp.savepos then
                            savepos(p)
                        end
                        checkforblockstuff(p)
                    end
                else -- Regular player code
                    if p.data.goingback then -- If you're going back
                        if btmt <= 0 then -- wait for the transition back to the map to end
                            -- Playing sound
                            SFX.play(smb3map.skidsfx)
                        end
                        --if save.section ~= save.lastsection then
                        --    Effect.spawn(10,p)
                        --end
                        local from = p.data.goingbackfrom or save.playerpos

                        plr.currentlevel = nil
                        local backpos = p.data.backtimer/smb3map.backtimer
                        local vect = math.lerp(from,p.data.goingback,backpos)
                        plr.x = vect.x
                        plr.y = vect.y
                    elseif detectdelay <= 0 and not (plr.currentlevel or freezeplayers or plr.frozen or smb3map.enteringlevel) then
                        -- get a cool new level
                        for __,v in NPC.iterate() do
                            if npcisvalid(v) then
                                local config = NPC.config[v.id]
                                if (config.islevel or config.isnode) and Colliders.collide(v,plr.collider) then
                                    plr.currentlevel = v
                                    plr.x = v.x+(config.playeroffsetx or 0)
                                    plr.y = v.y+(config.playeroffsety or 0)
                                    save.playerpos = vector(plr.x,plr.y)
                                    p.data.safepos = vector(plr.x,plr.y)
                                    break
                                end
                            end
                        end
                    end

                    if (plr.freeroam == 2 or not plr.moving) then -- Input detection and causation
                        local mk
                        if p.character > 5 then
                            mk = p.rawKeys
                        else
                            mk = p.keys
                        end
                        if p.keys.jump == KEYS_PRESSED and (not (inventory and inventory.isopen)) then -- Entering places beyond imagination!
                            local sdfgdh = true
                            for __,w in ipairs(Warp.getIntersectingEntrance(plr.x,plr.y,plr.x+plr.width,plr.y+plr.height)) do
                                if w.isValid and not w.isHidden then
                                    if w.warpType == 2 then -- Let's go into this place! It seems fun!
                                        warpPlayer(p,w,nil,true)
                                        sdfgdh = false
                                    end
                                end
                            end
                            if sdfgdh and plr.currentlevel and (p == player or not smb3map.leadersChoice) and (plr.freeroam ~= 2 or (plr.currentlevel and Colliders.collide(plr.currentlevel,plr.collider))) then -- You're not currently entering a warp, right?
                                local lvl = plr.currentlevel
                                local lettings = lvl.data._settings
                                local lonfig = NPC.config[lvl.id]
                                if lonfig.islevel and ((lettings.levelFilename and lettings.levelFilename ~= "") or lvl.data.spademarked)
                                and (not (save[lettings.levelFilename] and lettings.once and save[lettings.levelFilename].won)) and
                                cantouch(lonfig,p) and (lvl == smb3map.airships[lettings.levelFilename] or not smb3map.airships[lettings.levelFilename]) then
                                    if lvl.data.spademarked then -- You're going to the bonus zone!
                                        enterlevel(lvl.data.spademarked,p)
                                        for ___,spade in ipairs(save.nmarkspades[lvl.data.spademarked]) do
                                            if spade.target == lettings.levelFilename then
                                                spade.used = true
                                            end
                                        end
                                    else
                                        enterlevel(lvl,p,lettings.warp)
                                    end
                                end
                            end
                        elseif ((mk.up or mk.down or mk.left or mk.right) or plr.freeroam == 2) and doneanimating() and not (freezeplayers or plr.frozen or plr.pullinglevel or smb3map.enteringlevel) then -- your WASD, please
                            if mk.up then
                                plr.direction = smb3map.direction.UP
                            elseif mk.down then
                                plr.direction = smb3map.direction.DOWN
                            elseif mk.left then
                                plr.direction = smb3map.direction.LEFT
                            elseif mk.right then
                                plr.direction = smb3map.direction.RIGHT
                            end
                            local can = true
                            local trycloud = false
                            ---@type Block|nil
                            local enemyspotted = nil
                            if plr.freeroam == 2 then

                            else
                                can = false
                                local xoff = 0
                                local yoff = 0
                                if plr.direction == smb3map.direction.UP then
                                    yoff = -plr.height
                                elseif plr.direction == smb3map.direction.DOWN then
                                    yoff = plr.height
                                elseif plr.direction == smb3map.direction.LEFT then
                                    xoff = -plr.width
                                elseif plr.direction == smb3map.direction.RIGHT then
                                    xoff = plr.width
                                end
                                local superfreeroam = (smb3map.debug and smb3map.dbo.cangoanywhere) or Cheats.get("illparkwhereiwant").active
                                if superfreeroam then
                                    can = true
                                else
                                    if plr.freeroam == 1 and cheatisactive("illroamwhereiwant") then
                                        can = true
                                    else
                                        -- Check for paths
                                        for __,b in Block.iterateIntersecting(plr.x+xoff+smb3map.playerspace,plr.y+yoff+smb3map.playerspace,plr.x+plr.width+xoff-smb3map.playerspace,plr.y+plr.height+yoff-smb3map.playerspace) do
                                            if blockisvalid(b) and cantouch(Block.config[b.id],p) then
                                                local config = Block.config[b.id]
                                                if plr.freeroam == 1 or (plr.currentlevel and NPC.config[plr.currentlevel.id].isdock) then
                                                    if config.freeroamzone then
                                                        can = true
                                                        if plr.freeroam ~= 1 then
                                                            plr.freeroam = 1
                                                        end
                                                    elseif config.ispath and plr.freeroam == 0 then
                                                        can = true
                                                    end
                                                elseif plr.freeroam == 0 then
                                                    if plr.currentlevel and NPC.config[plr.currentlevel.id].isopening and config.freeroamzone then
                                                        save.safeplayerpos = vector(plr.x,plr.y)
                                                        plr.x = plr.x+xoff
                                                        plr.y = plr.y+yoff
                                                        plr.freeroam = 2
                                                        SFX.play(1)
                                                        trywater(plr)
                                                        break
                                                    elseif config.ispath then
                                                        can = true
                                                    end
                                                end
                                                if can then break end
                                            end
                                        end
                                    end
                                end
                                if not (plr.freeroam == 0 and can) then
                                    -- Checks for docks
                                    for __,v in NPC.iterateIntersecting(plr.x+xoff+smb3map.playerspace,plr.y+yoff+smb3map.playerspace,plr.x+plr.width+xoff-smb3map.playerspace,plr.y+plr.height+yoff-smb3map.playerspace) do
                                        if npcisvalid(v) then
                                            if NPC.config[v.id].isdock then
                                                can = true
                                                break
                                            end
                                        end
                                    end
                                end
                                if not superfreeroam then
                                    if can then -- Check if the level's paths are unlocked (if applicable)
                                        if plr.freeroam == 0 and plr.currentlevel and plr.currentlevel.isValid and NPC.config[plr.currentlevel.id].islevel then
                                            local level = plr.currentlevel
                                            local ldata = level.data
                                            if plr.direction == smb3map.direction.UP then
                                                can = ldata.unlockedDirections.up
                                            elseif plr.direction == smb3map.direction.DOWN then
                                                can = ldata.unlockedDirections.down
                                            elseif plr.direction == smb3map.direction.LEFT then
                                                can = ldata.unlockedDirections.left
                                            elseif plr.direction == smb3map.direction.RIGHT then
                                                can = ldata.unlockedDirections.right
                                            end
                                            --if can then
                                            --    SFX.play(1)
                                            --end
                                            if plr.isfloating and not can then
                                                trycloud = true
                                                can = true
                                            end
                                        end
                                    elseif not plr.didsfx then
                                        SFX.play(3)
                                        plr.didsfx = true
                                    end
                                    can = can or Cheats.get("imtiredofallthiswalking").active
                                    if can then -- Check if the path is blocked by blockers specifically to the player
                                        for __,b in Block.iterateIntersecting(plr.x+xoff+smb3map.playerspace,plr.y+yoff+smb3map.playerspace,plr.x+plr.width+xoff-smb3map.playerspace,plr.y+plr.height+yoff-smb3map.playerspace) do
                                            if blockisvalid(b) then
                                                local config = Block.config[b.id]
                                                if config.isplayerblocker or config.isblocker then
                                                    can = false
                                                    break
                                                end
                                            end
                                        end
                                        if not can then
                                            for __,b in Block.iterateIntersecting(plr.x+xoff+smb3map.playerspace,plr.y+yoff+smb3map.playerspace,plr.x+plr.width+xoff-smb3map.playerspace,plr.y+plr.height+yoff-smb3map.playerspace) do
                                                if blockisvalid(b) then
                                                    local config = Block.config[b.id]
                                                    if config.isblockerblocker then -- My newest invention
                                                        can = true
                                                        break
                                                    end
                                                end
                                            end
                                            if not can then
                                                if not plr.didsfx then
                                                    SFX.play(3)
                                                    plr.didsfx = true
                                                end
                                            end
                                        end
                                    end
                                    if can then -- Check if the path is blocked by any other obstructions
                                        for __,v in NPC.iterateIntersecting(plr.x+xoff+smb3map.playerspace,plr.y+yoff+smb3map.playerspace,plr.x+plr.width+xoff-smb3map.playerspace,plr.y+plr.height+yoff-smb3map.playerspace) do
                                            if npcisvalid(v) then
                                                local config = NPC.config[v.id]
                                                if config.isblocker and not v.friendly then
                                                    can = false
                                                    if not plr.didsfx then
                                                        SFX.play(3)
                                                        plr.didsfx = true
                                                    end
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                                if can then
                                    -- You can do it? Well so can your enemies!
                                    for __,b in Block.iterate() do
                                        if blockisvalid(b) and cantouch(Block.config[b.id],p) and Colliders.collide(plr.collider,b) then
                                            local config = Block.config[b.id]
                                            if config.enemyzone then
                                                enemyspotted = b
                                                break
                                            end
                                        end
                                    end
                                    if not enemyspotted then
                                        for __,b in Block.iterateIntersecting(plr.x+xoff+smb3map.playerspace,plr.y+yoff+smb3map.playerspace,plr.x+plr.width+xoff-smb3map.playerspace,plr.y+plr.height+yoff-smb3map.playerspace) do
                                            if blockisvalid(b) and cantouch(Block.config[b.id],p) then
                                                local config = Block.config[b.id]
                                                if config.enemyzone then
                                                    enemyspotted = b
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                            end

                            if can then -- Everything's good to go? Alright, set the speeds!
                                if trycloud then
                                    plr.isfloating = false
                                    SFX.play(smb3map.stopfloatingsfx)
                                end
                                if enemyspotted then
                                    if enemyspotted:mem(0x0C,FIELD_STRING) ~= "" then
                                        triggerEvent(enemyspotted:mem(0x0C,FIELD_STRING))
                                    end
                                    smb3map.moveEnemies(p.section,true)
                                end
                                if plr.freeroam == 2 then -- Freeroaming in this buisness
                                    -- up and down
                                    if p.keys.up then
                                        plr.speedY = -plr.speed
                                    elseif p.keys.down then
                                        plr.speedY = plr.speed
                                    else
                                        plr.speedY = 0
                                    end
                                    -- left and right
                                    if p.keys.left then
                                        plr.speedX = -plr.speed
                                    elseif p.keys.right then
                                        plr.speedX = plr.speed
                                    else
                                        plr.speedX = 0
                                    end
                                    local space = smb3map.playerspace
                                    local cantx = true
                                    local canty = true
                                    local xoff = 0
                                    local yoff = 0
                                    local needed = {
                                        false,
                                        false,
                                        false,
                                        false,
                                    }
                                    -- Collision points that are 2 steps ahead
                                    local bigpoints = {
                                        Colliders.Point(plr.x+plr.speedX*2,plr.y+plr.speedY*2),
                                        Colliders.Point(plr.x+plr.speedX*2+plr.width,plr.y+plr.speedY*2),
                                        Colliders.Point(plr.x+plr.speedX*2,plr.y+plr.speedY*2+plr.height),
                                        Colliders.Point(plr.x+plr.speedX*2+plr.width,plr.y+plr.speedY*2+plr.height),
                                    }
                                    -- Collision points that are only 1 step ahead
                                    local points = {
                                        Colliders.Point(plr.x+plr.speedX,plr.y+plr.speedY),
                                        Colliders.Point(plr.x+plr.speedX+plr.width,plr.y+plr.speedY),
                                        Colliders.Point(plr.x+plr.speedX,plr.y+plr.speedY+plr.height),
                                        Colliders.Point(plr.x+plr.speedX+plr.width,plr.y+plr.speedY+plr.height),
                                    }
                                    if p.keys.up then
                                        needed[1] = true
                                        needed[2] = true
                                    elseif p.keys.down then
                                        needed[3] = true
                                        needed[4] = true
                                    end

                                    if p.keys.left then
                                        needed[1] = true
                                        needed[3] = true
                                    elseif p.keys.right then
                                        needed[2] = true
                                        needed[4] = true
                                    end
                                    can = false

                                    if smb3map.debug and smb3map.dbo.freeroamcollision then
                                        for i = 1,4 do
                                            if needed[i] then
                                                points[i]:Draw(Color.red)
                                            else
                                                points[i]:Draw(Color.black)
                                            end
                                        end
                                    end
                                    local did = {
                                        false,
                                        false,
                                        false,
                                        false,
                                    }
                                    local m = 0

                                    if Cheats.get("illparkwhereiwant").active or cheatisactive("illroamwhereiwant") then
                                        can = true
                                    else -- checking if these blocks are in the zone
                                        for __,b in Block.iterate() do
                                            if blockisvalid(b) then
                                                local config = Block.config[b.id]
                                                if config.freeroamzone then
                                                    local r = 0
                                                    for i = 1, 4 do
                                                        if needed[i] then
                                                            r = r + 1
                                                            if (Colliders.collide(b,points[i]) or Colliders.collide(b,bigpoints[i])) then
                                                                if not did[i] then
                                                                    m = m + 1
                                                                    did[i] = true
                                                                end
                                                                if smb3map.debug and smb3map.dbo.freeroamcollision then
                                                                    if Colliders.collide(b,points[i]) then
                                                                        points[i]:Draw(Color.green)
                                                                    end
                                                                    if Colliders.collide(b,bigpoints[i]) then
                                                                        bigpoints[i]:Draw(Color.blue)
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    end
                                                    if smb3map.debug and smb3map.dbo.freeroamcollision then
                                                        Text.print(m,200+(m-1)*10,80)
                                                        Text.print(r,200,100)
                                                        for numb,d in ipairs(did) do
                                                            Text.print(d,100,100+(numb-1)*20)
                                                        end
                                                    end
                                                    if m >= r then
                                                        can = true
                                                        break
                                                    else
                                                        if (needed[1] and needed[3] and xor(did[2],did[4])) or (needed[2] and needed[4] and xor(did[1],did[3])) then
                                                            canty = false
                                                        end
                                                        if (needed[1] and needed[2] and xor(did[3],did[4])) or (needed[3] and needed[4] and xor(did[1],did[2])) then
                                                            cantx = false
                                                        end
                                                        if (did[1] and did[4] and not (did[2] or did[3])) or (did[2] and did[3] and not (did[1] or did[4])) then
                                                            canty = true
                                                            cantx = true
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                    local newbox = Colliders.Box(plr.x+plr.speedX*2,plr.y+plr.speedY*2,plr.width,plr.height)
                                    if smb3map.debug and smb3map.dbo.collision then
                                        newbox:Draw(Color.green)
                                    end
                                    for __,v in NPC.iterate() do -- Checking for openings that lead back onto a path
                                        if npcisvalid(v) then
                                            local config = NPC.config[v.id]
                                            if config.isopening then
                                                if Colliders.collide(v,newbox) then
                                                    plr.currentlevel = v
                                                    plr.freeroam = 0
                                                    plr.x = v.x+(config.playeroffsetx or 0)
                                                    plr.y = v.y+(config.playeroffsety or 0)
                                                    resetpspeed(plr)
                                                    SFX.play(smb3map.nodesfx)
                                                    SFX.play(1)
                                                    break
                                                end
                                            end
                                        end
                                    end
                                    if can then
                                        cantx = false
                                        canty = false
                                    end
                                    if cantx then
                                        plr.speedX = 0
                                    end
                                    if canty then
                                        plr.speedY = 0
                                    end
                                else
                                    setplrspeeds(plr)
                                    plr.moving = true
                                end
                            elseif plr.freeroam == 2 then
                                resetpspeed(plr)
                            end
                        else
                            plr.didsfx = false
                        end
                    end

                    if smb3map.debug and smb3map.dbo.levelinfo and plr.currentlevel then
                        Text.print(plr.currentlevel.data._settings.levelFilename,100,80)
                        if plr.currentlevel.data.unlockedDirections then
                            local lol = 0
                            for ______,srdfihgt in pairs(plr.currentlevel.data.unlockedDirections) do
                                Text.print(tostring(______).." "..tostring(srdfihgt),100,100+lol*20)
                                lol = lol+1
                            end
                        end
                        Text.print(plr.currentlevel.data._settings.warp,100,200)
                    end

                    if freezeplayers or smb3map.enteringlevel then
                        resetpspeed(plr)
                    end

                    if smb3map.debug then -- so debugging it rn
                        if smb3map.dbo.position and p.keys.altRun == KEYS_PRESSED then
                            SFX.play(12)
                            savepos(p)
                        elseif smb3map.dbo.levelcheat and p.keys.altJump == KEYS_PRESSED and plr.currentlevel and type(plr.currentlevel.data._settings.levelFilename) == "string" and plr.currentlevel.data._settings.levelFilename ~= "" and animatedstart then
                            markAsComplete(plr.currentlevel,-1,p.character)
                        elseif smb3map.dbo.position and p.keys.run == KEYS_PRESSED then
                            SFX.play(24)
                            if p.keys.jump then
                                SFX.play(1)
                                smb3map.revertPos(p)
                            else
                                plr.x = save.playerpos.x
                                plr.y = save.playerpos.y
                                p.section = save.section
                            end

                            stopplr(plr)
                            plr.currentlevel = nil
                            plr.currentcorner = nil
                            plr.gravblock = nil
                            plr.speedblock = nil
                        end
                        if smb3map.dbo.reset and p.keys.altRun and p.keys.altJump then
                            resting = false
                            resetTimer = resetTimer + 1
                            SFX.play(10)
                            if resetTimer >= 192 then
                                resetMap(true)
                                Level.load(smb3map.levelFilename)
                                return
                            end
                        end
                        if smb3map.dbo.roamingstatus then
                            Text.print(plr.freeroam,300+_*100,100)
                            Text.print(plr.moving,300+_*100,120)
                        end
                    end
                    plr.x = plr.x+plr.speedX
                    plr.y = plr.y+plr.speedY

                    p.x = plr.x
                    p.y = plr.y

                    correctCollider(plr)

                    if plr.currentlevel then
                        plr.x = plr.x+plr.currentlevel.layerObj.speedX
                        plr.y = plr.y+plr.currentlevel.layerObj.speedY
                    end

                    checkforblockstuff(p,"savepoint")
                end
            end
        else -- Initialize a player map object if it doesn't exist!
            p.section = save.section or p.section
            ---@class PlayerMapObject
            p.data.mapObj = {
                -- The player map object's X position
                ---@type number
                x = 0,
                -- The player map object's Y position
                ---@type number
                y = 0,
                -- The player map object's Superficial Width
                ---@type number
                width = 32,
                -- The player map object's Superficial Height
                ---@type number
                height = 32,
                -- Horizontal Speed
                ---@type number
                speedX = 0,
                -- Vertical speed
                ---@type number
                speedY = 0,
                -- General speed (applied to horizontal and vertical when needed)
                ---@type number
                speed = smb3map.playerspeed,
                -- Direction of the object (follows smb3map directions)
                ---@type 1|2|3|4
                direction = smb3map.direction.DOWN,
                -- Free roam state. 0: Follow paths, 1: Follow Grid, 2: Fully roaming
                ---@type 0|1|2
                freeroam = save.freeroam or 0,
                -- If the player's moving with the grid
                ---@type boolean
                moving = false,
                -- animation frame of the player
                ---@type integer
                frame = 0,
                -- animation frametimer of the player
                ---@type number
                frametimer = 0,
                -- Powerup
                ---@type integer|string
                powerup = 1,
                -- The current level the player's standing on
                ---@type NPC|nil
                currentlevel = nil,
                -- The corner the player just passed
                ---@type Block|nil
                currentcorner = nil,
                -- A block to watch out for when stacking to make sure not to hit this block again
                ---@type Block|nil
                gravblock = nil,
                -- A block to watch out for when speeding to make sure not to hit this block again
                ---@type Block|nil
                speedblock = nil,
                -- How far has the player gone when `moving` is true
                ---@type number
                distance = 0,
                -- distance but limit is less
                ---@type number
                mcdist = 0,
                -- If the player's warping
                ---@type boolean
                iswarping = false,
                -- If the player object is visible
                ---@type boolean
                visible = true,
                -- If the player can't move
                ---@type boolean
                frozen = false,
                -- The level that's currently pulling onto the player
                ---@type NPC|nil
                pullinglevel = nil,
                -- Timer of being pulled
                ---@type number
                pulltimer = 0,
                -- alternate frames
                ---@type integer
                altframe = 0,
                -- alternate frametimer
                ---@type number
                altframetimer = 0,
                -- If the player has a cloud
                ---@type boolean
                isfloating = false,
                -- If the player is in water
                ---@type boolean
                inwater = false,
                -- If the player has a starman
                ---@type boolean
                starman = false,
                -- The SFX object of starman music
                ---@type AudioSource|nil
                starmusic = nil,
                -- Visual gravity
                ---@type number
                gravity = smb3map.playergravity,
                -- The speed that jumpoffset is changed
                ---@type number
                jumpspeed = 0,
                -- How many frames should the jumpspeed remain unchanged
                ---@type number
                jumpheight = 0,
                -- The direction of the visual gravity
                ---@type -1|0|1
                gravitydir = 0,
                -- The visual offset caused by jumping
                ---@type number
                jumpoffset = 0,
                -- The terminal velocity of jumping
                ---@type number
                terminalv = 0,
            }
            --SFX.play(1)
            local plr = p.data.mapObj
            plr.collider = Colliders.Box(p.x+smb3map.playerspace,p.y+smb3map.playerspace,plr.width-smb3map.playerspace*2,plr.height-smb3map.playerspace*2)
            plr.colliderouter = Colliders.Box(p.x-smb3map.playerspace,p.y-smb3map.playerspace,plr.width+smb3map.playerspace*2,plr.height+smb3map.playerspace*2)
            --for __,v in NPC.iterate() do
            --    if npcisvalid(v) then
            --        local config = NPC.config[v.id]
            --        if (config.islevel or config.isnode) and Colliders.collide(v,plr.collider) then
            --            plr.currentlevel = v
            --            break
            --        end
            --    end
            --end
            if save.playerpos then
                plr.x = save.playerpos.x
                plr.y = save.playerpos.y
            else -- This is your first time? Alright, lemme give you all the stuff
                if plr.currentlevel then
                    local config = NPC.config[plr.currentlevel.id]
                    plr.x = plr.currentlevel.x + (config.playeroffsetx or 0)
                    plr.y = plr.currentlevel.y + (config.playeroffsety or 0)
                else
                    plr.x = player.x
                    plr.y = player.y
                end
                save.playerpos = vector(plr.x,plr.y)
                p.data.safepos = vector(plr.x,plr.y)
            end
            trywater(plr)
        end
        smb3map.players[p.idx] = p.data.mapObj
        if not (smb3map.canenterlevel(p) and not (p.data.mapObj and p.data.mapObj.moving)) then
            cantuseinv = true
        end
    end
    if inventory then
        if cantuseinv then
            if inventory.isusing then
                inventory.close(true)

            end
            inventory.canuse = false
        else
            inventory.canuse = true
        end
    end

    if animatedplayer and not animatedtiles then
        if cheatisactive("skipthesequence") then
            tileanimtimer = 0
        else
            tileanimtimer = math.max(tileanimtimer-1,0)
        end
        if not didsometiles then
            for _,b in Block.iterate() do
                if blockisvalid(b) then
                    local config = Block.config[b.id]
                    local data = b.data
                    local settings = data._settings
                    if config.nspadespawner then -- Create n-spades and mark levels as complete
                        if settings.score and save.score then
                            local nspades = math.floor(save.score/settings.score)
                            if nspades > 0 and settings.levelFilename and settings.levelFilename ~= "" then
                                if nspades < 1 and settings.once then
                                    nspades = 1
                                end
                                save.nmarkspades[settings.levelFilename] = save.nmarkspades[settings.levelFilename] or {}
                                local spade = save.nmarkspades[settings.levelFilename]
                                local layer
                                if settings.nlayer and settings.nlayer ~= "" then
                                    layer = settings.nlayer
                                end
                                for i = 1, nspades do -- placing each spade
                                    if not spade[i] then
                                        local npool = {}
                                        for __,v in NPC.iterate() do
                                            if npcisvalid(v) then
                                                local lonfig = NPC.config[v.id]
                                                local lata = v.data
                                                local lettings = lata._settings
                                                if (not (lonfig.markimmune or lonfig.isairship)) and player.section == v.section and lonfig.islevel and lettings.levelFilename and lettings.levelFilename ~= "" and (not data.spademarked) and (not layer or (v.layerName == layer)) then
                                                    npool[#npool+1] = v
                                                end
                                            end
                                        end
                                        local luckycustomer = RNG.randomEntry(npool)
                                        if luckycustomer then
                                            SFX.play(smb3map.nmarksfx or smb3map.appearsfx)
                                            spade[i] = {}
                                            spade[i].target = luckycustomer.data._settings.levelFilename
                                            spade[i].used = false
                                            luckycustomer.data.spademarked = settings.levelFilename
                                        end
                                    end
                                end
                            end
                        end
                    elseif config.treasurespawner then -- Spawns treasure ships if nessesary
                        local event = settings.event
                        local eventhasbeentriggered = false
                        if event and event ~= "" then
                            for __,triggered in ipairs(saveTemp.triggeredEvents) do
                                if triggered == event then
                                    eventhasbeentriggered = true
                                    break
                                end
                            end
                        end
                        local sect = getsecfrompos(b)
                        if (saveTemp.triggership and ((not event) or event == "" or event == " ")) or eventhasbeentriggered or save.treasureshipping[sect] then
                            -- Attempt to spawn in a treasure ship
                            local layer
                            if settings.layer and settings.layer ~= "" then
                                layer = settings.layer
                            end
                            if sect == player.section and not save.shippedtreasures[sect] then
                                for ___,v in NPC.iterate() do
                                    if npcisvalid(v) and NPC.config[v.id].isenemy and not data.treasureship then
                                        v.data.treasureship = settings.levelFilename
                                        if (not save.treasureshipping[sect]) and ((not layer) or (v.layerName == layer)) then
                                            save.treasureshipping[sect] = true
                                            SFX.play(smb3map.appearsfx)
                                        end
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if tileanimtimer <= 0 then
            animatedtiles = true
        end
    elseif animatedplayer and animatedtiles and not animatedbaddies then -- ANIMATE THE BADDIES!
        if smb3map.enemyanimationphase == 1 then -- Airships are flying overhead!
            local airshipsdontexist = true
            for level,ship in pairs(airships) do
                if level and ship then
                    if airshipsdontexist then
                        for _,p in ipairs(Player.get()) do
                            if p.section == ship.section then
                                airshipsdontexist = false
                                break
                            end
                        end
                    end
                    local shipconfig = NPC.config[ship.id]
                    if not (newairshippos[level] or (anchactive() and not shipconfig.anchorimmune) or ship.dontMove) then -- give me a new position based off of the position of the other levels of the section
                        if not (smb3map.airshipoff or airshipsdontexist or shipconfig.ismute) then
                            smb3map.airshipoff = true
                            SFX.play(smb3map.airshipsfx)
                        end
                        local pool = {}
                        for _,v in NPC.iterate() do
                            if npcisvalid(v) then
                                local data = v.data
                                local config = NPC.config[v.id]
                                local settings = data._settings
                                local layer
                                if ship.data.airshipLayer and ship.data.airshipLayer ~= "" then
                                    layer = Layer.get(ship.data.airshipLayer)
                                end
                                if v ~= ship and v.section == ship.section and settings.levelFilename ~= ship.data._settings.levelFilename and ((config.islevel and not layer) or (layer and v.layerName == layer.layerName)) and not (config.isairship or v.friendly) then
                                    pool[#pool+1] = vector(v.x+(config.playeroffsetx or 0),v.y+(config.playeroffsety or 0))
                                end
                            end
                        end
                        local lucky = RNG.randomEntry(pool)
                        if lucky then
                            newairshippos[level] = vector(lucky.x,lucky.y)
                        end
                    end

                    if newairshippos[level] and not ship.dontMove then
                        if save.airshippos[level] then
                            local vect = math.lerp(save.airshippos[level],newairshippos[level],shiptimer/smb3map.shiptimer)
                            ship.x = vect.x
                            ship.y = vect.y
                        end
                    else
                        airshipsdontexist = true
                    end
                end
            end
            
            -- Note to self: Should make shiptimer a ship variable that adds it's speed config and check if they're all >= smb3map.shiptimer
            -- Of course, with math.min to make sure the shiptimer doesn't overshoot
            if airshipsdontexist or shiptimer >= smb3map.shiptimer then
                smb3map.enemyanimationphase = 2
                for level,ship in pairs(airships) do
                    if newairshippos[level] then
                        save.airshippos[level] = newairshippos[level]
                    end
                    for _,v in NPC.iterate() do
                        if npcisvalid(v) then
                            local config = NPC.config[v.id]
                            if config.islevel and Colliders.collide(v,ship) then
                                if v.data.unlockedDirections then
                                    ship.data.unlockedDirections = v.data.unlockedDirections
                                    ship.data.stack = v.data._settings.levelFilename
                                    ship.layerName = v.layerName
                                    break
                                end
                            end
                        end
                    end
                end
            else
                shiptimer = shiptimer + 1
            end
        elseif smb3map.enemyanimationphase == 2 then
            local baddies = 0
            local badcount = 0
            for _,v in NPC.iterate() do
                if npcisvalid(v) then
                    local config = NPC.config[v.id]
                    if (v.section == save.section or v.section == player.section) and config.isenemy and config.speed > 0 and not (v.dontMove or (config.issleeper and mboxactive()) or config.ismover) then
                        baddies = baddies + 1
                        if v.data.doneanimating then
                            badcount = badcount + 1
                        end
                    end
                end
            end
            if smb3map.debug and smb3map.dbo.enemyanim then
                Text.print(baddies,300,150)
                Text.print(badcount,300,170)
            end
            if baddies == badcount then
                animatedbaddies = true
                smb3map.enemyanimationphase = -1
            end
        end
    elseif animatedplayer and animatedbaddies and animatedtiles then -- Hold on, lemme just check if a start animation should play
        for _,s in ipairs(Section.getActive()) do
            if not save.animatedsections[s.idx] then
                for _,b in Block.iterateIntersecting(s.boundary.left,s.boundary.top,s.boundary.right,s.boundary.bottom) do
                    if blockisvalid(b) then
                        local config = Block.config[b.id]
                        if config.startworld then
                            local data = b.data
                            local settings = data._settings
                            worldName = settings.worldName
                            if settings.event == "" or not settings.event then
                                startanimate(s.idx)
                            end
                        end
                    end
                end
            end
        end
        if startanimtimer > 0 then
            if startanimtimer == smb3map.sparkleon then
                SFX.play(smb3map.startsfx)
            end
            startanimtimer = startanimtimer - 1
        else
            animatedstart = true
        end
    end

    if resting then
        resetTimer = 0
    end
    if ((prevm ~= save.music and not mboxactive()) or (mboxactive() and Section(1).music ~= smb3map.musicbox)) and (not smb3map.enteringlevel) and (warpedwhistle or not whistlingwarp) then
        musicset = false
    end

    if animatedtiles and animatedplayer and animatedbaddies and not musicset then -- Give me the music!
        musicset = true
        if save.music then
            local music = save.music
            if mboxactive() then
                music = smb3map.musicbox
            end
            if defaultmusic[music] then
                for _,s in ipairs(Section.get()) do
                    s.music = ""
                end
                Audio.MusicOpen(getSMBXPath().."/"..defaultmusic[music])
                Audio.MusicPlay()
            else
                Audio.MusicStop()
            end
            if not defaultmusic[music] then
                for _,s in ipairs(Section.get()) do
                    s.music = music
                end
            end
        else
            if defaultmusic[prevm] then
                Audio.MusicStop()
            end
            for _,s in ipairs(Section.get()) do
                s.music = basemusic[_]
            end
        end
    end
end

-- Runs every tick the game isn't paused. Executes directly after SMBX internal code, making it useful for reacting to what happened in the internal loop before the scene is drawn.
function smb3map.onTickEnd()
    if Level.filename() ~= smb3map.levelFilename then return end
    if not postinitialized then -- Runs once, then never again
        postinitialized = true
        saveTemp.level = ""
        saveTemp.itsanidx = 0
        saveTemp.loser = false
        for _,p in ipairs(Player.get()) do
            smb3map.playerframe[_] = 1
        end
    end

    -- get layer offsets via their speed
    for layerName,position in pairs(layeroffset) do
        local l = Layer.get(layerName)
        if l then
            position.x = position.x+l.speedX
            position.y = position.y+l.speedY
        end
    end

    if lunatime.tick() % smb3map.playerframespeed == 0 then -- animating players on the top right
        for _,p in ipairs(Player.get()) do
            smb3map.playerframe[_] = smb3map.playerframe[_] + 1
            if playerreverse[_] then
                smb3map.playerframe[_] = smb3map.playerframe[_] - 2
            end
            if (smb3map.playerframe[_] == 3 and p.powerup ~= 1) or (smb3map.playerframe[_] == 2 and p.powerup == 1) then -- last walk frame
                playerreverse[_] = true
            elseif smb3map.playerframe[_] == 1 then -- first walk frame
                playerreverse[_] = false
            end
        end
    end

    if lunatime.tick() % smb3map.tornadoframespeed == 0 then -- animating the whirlwind
        tornadoframe = tornadoframe + 1
        if tornadoframe >= smb3map.tornadoframes then
            tornadoframe = 0
        end
    end
    if detectdelay > 0 then
        detectdelay = detectdelay - 1
    end
    if whistlingwarp then
        if smb3map.debug and smb3map.dbo.wind then
            Text.print(smb3map.windx,100,200)
        end
        if smb3map.windx >= player.sectionObj.boundary.right and whistleBlock then
            local sgetter = NPC.spawn(465,whistleBlock.x,whistleBlock.y)
            for _,p in ipairs(Player.get()) do
                warpPlayer(p,sgetter)
            end
            sgetter:kill(HARM_TYPE_VANISH)
            whistleBlock = nil
        elseif warpedwhistle then
            if smb3map.windx == player.x then
                warpedwhistle = false
                whistlingwarp = false
                freezeplayers = false
                for _,p in ipairs(Player.get()) do
                    if p.data.mapObj then
                        p.data.mapObj.visible = true
                    end
                end
            end
        end
    end
    if smb3map.entertimer >= smb3map.enteron then
        Level.load(smb3map.enteringlevel,nil,smb3map.warpIndex)
    end
    local reallygoingback = false
    local warping = false
    for _,p in ipairs(Player.get()) do -- do player stuff
        if p.data.mapObj and not smb3map.enteringlevel then
            ---@type PlayerMapObject
            local plr = p.data.mapObj
            if Cheats.get("jumpman").active and plr.gravitydir == 0 then
                mapJump(p,1)
            end
            if (p.hasStarman or save.starmen[p.idx]) and not plr.starman then
                if not save.starmen[p.idx] then
                    save.starmen[p.idx] = true
                end
                plr.starman = true
                local stsfx = starman.sfxFile
                --if Cheats.get("thestarmen") then
                --    stsfx = Misc.resolveSoundFile("waitinginthesky.ogg")
                --end
                if starman.sfxFile and not plr.starmusic then
                    plr.starmusic = SFX.create{
                        x = p.x,
                        y = p.y,
                        falloffRadius=1000000,
                        falloffType=SFX.FALLOFF_NONE,
---@diagnostic disable-next-line: assign-type-mismatch
                        sound = stsfx,
                        volume = 0.5,
                        parent = p
                    }
                end
            end
            if p.hasStarman then
                starman.stop(p)
            end
            plr.altframetimer = plr.altframetimer + 1
            if plr.altframetimer >= smb3map.altframespeed then
                plr.altframetimer = plr.altframetimer - smb3map.altframespeed
                plr.altframe = plr.altframe + 1
                if plr.altframe >= 2 then
                    plr.altframe = 0
                end
            end

            if whistlingwarp and smb3map.windx >= plr.x then
                plr.visible = false
            end

            p.reservePowerup = saveTemp.reserve[_]

            for __,v in NPC.iterate() do -- Checking for airships takes top priority in being the level of the day
                if npcisvalid(v) and (v ~= plr.currentlevel) then
                    local config = NPC.config[v.id]
                    if (config.isairship) and Colliders.collide(v,plr.collider) then
                        plr.currentlevel = v
                        break
                    end
                end
            end
            if p.data.goingback then
                if plr.x == p.data.goingback.x and plr.y == p.data.goingback.y then
                    p.data.backtimer = smb3map.backtimer
                end
                if p.data.backtimer >= smb3map.backtimer then
                    local sgetter = NPC.spawn(465,p.data.goingback.x,p.data.goingback.y)
                    local sasavemeve = true
                    if p.data.goingbackfrom then
                        sasavemeve = false
                    end
                    if sgetter.section == p.section then
                        smb3map.revertPos(p,p.data.goingback,nil,nil,(not sasavemeve),true)
                    else
                        waitforwarp = true
                        smb3map.warp(p,sgetter,nil,nil,true,true,sasavemeve)
                    end
                    sgetter:kill(HARM_TYPE_VANISH)
                    if plr.frozen then
                        plr.frozen = false
                    end
                end
            end
            local framespeed = 8
            if smb3map.framespeed[p.character] then
                framespeed = smb3map.framespeed[p.character][getpowerup(p)] or framespeed
            end
            if not (freezeplayers or plr.frozen) then -- you're not stuck, right?
                if plr.freeroam == 2 then -- freeroaming?
                    plr.currentcorner = nil
                    local unsafe = true
                    for __,b in Block.iterate() do
                        if blockisvalid(b) then
                            if Block.config[b.id].freeroamzone and Colliders.collide(b,plr.collider) then
                                unsafe = false
                                break
                            end
                        end
                    end
                    if unsafe and save.safeplayerpos and not cheatisactive("illroamwhereiwant") then
                        plr.currentlevel = nil
                        plr.freeroam = 0
                        plr.x = save.safeplayerpos.x
                        plr.y = save.safeplayerpos.y
                        resetpspeed(plr)
                        p.data.safepos = vector(plr.x,plr.y)
                        SFX.play(smb3map.nodesfx)
                        SFX.play(3)
                    end
                    for __,v in NPC.iterate() do -- Collecting items off the grid
                        if npcisvalid(v) then
                            local config = NPC.config[v.id]
                            if (config.isinteractable) and Colliders.collide(v,plr.collider) then
                                v:collect(p)
                            end
                        end
                    end
                    if (plr.speedX ~= 0 or plr.speedY ~= 0) and not (plr.iswarping or plr.pullinglevel) then
                        trywater(plr)

                        for __,v in NPC.iterate() do
                            if spidercheck(v,p) then
                                break
                            end
                        end

                        for __,v in NPC.iterate() do -- Checking for nodes and levels in your local area to clamp onto
                            if npcisvalid(v) and (v ~= plr.currentlevel) then
                                local config = NPC.config[v.id]
                                if (config.islevel or config.isnode) and Colliders.collide(v,plr.collider) then
                                    plr.currentlevel = v

                                    if config.islevel then
                                        SFX.play(smb3map.levelsfx)
                                    else
                                        SFX.play(smb3map.nodesfx)
                                    end

                                    break
                                end
                            end
                        end
                    end
                elseif plr.moving and not (plr.iswarping or plr.pullinglevel) then -- movestuff
                    if plr.freeroam == 1 then
                        plr.currentcorner = nil
                    end
                    plr.distance = plr.distance+math.abs(plr.speedX)+math.abs(plr.speedY)
                    if plr.checkingcorners then
                        plr.mcdist = plr.mcdist+math.abs(plr.speedX)+math.abs(plr.speedY)
                        if plr.mcdist >= smb3map.traveldist/smb3map.cornerchecks then
                            plr.mcdist = plr.mcdist - smb3map.traveldist/smb3map.cornerchecks
                            if plr.freeroam == 0 and (not (plr.currentcorner and Colliders.collide(p,plr.currentcorner))) then
                                plr.checkingcorners = checkforcorners(plr)
                                --if plr.checkingcorners then
                                    plr.mcdist = 0
                                --end
                            end
                        end
                    end

                    if plr.distance >= smb3map.traveldist then -- check for everythings once the distance is distanced
                        plr.distance = plr.distance - smb3map.traveldist
                        local sdfgdh = true
                        for __,w in ipairs(Warp.getIntersectingEntrance(plr.collider.x,plr.collider.y,plr.collider.x+plr.collider.width,plr.collider.y+plr.collider.height)) do
                            if w.isValid and not w.isHidden then
                                if w.warpType ~= 2 then
                                    warpPlayer(p,w)
                                    sdfgdh = false
                                    break
                                end
                            end
                        end

                        checkforblockstuff(p,nil,"savepoint")
                        if sdfgdh then -- stuff will only happen if there's no warp happening
                            trywater(plr)
                            for __,v in NPC.iterate() do
                                if spidercheck(v,p) then
                                    break
                                end
                            end
                            for __,v in NPC.iterate() do -- Collecting items on the grid
                                if npcisvalid(v) then
                                    local config = NPC.config[v.id]
                                    if (config.isinteractable) and Colliders.collide(v,plr.collider) then
                                        v:collect(p)
                                    end
                                end
                            end
                            for __,v in NPC.iterate() do -- Checking for nodes and levels in your local area to clamp onto
                                if npcisvalid(v) and (v ~= plr.currentlevel or plr.currentcorner) then
                                    local config = NPC.config[v.id]
                                    if (config.islevel or config.isnode) and Colliders.collide(v,plr.collider) then
                                        plr.currentlevel = v
                                        if plr.speedX ~= 0 then
                                            if plr.speedX > 0 then
                                                plr.x = plr.x-plr.distance
                                            else
                                                plr.x = plr.x+plr.distance
                                            end
                                        end
                                        if plr.speedY ~= 0 then
                                            if plr.speedY > 0 then
                                                plr.y = plr.y-plr.distance
                                            else
                                                plr.y = plr.y+plr.distance
                                            end
                                        end
                                        if smb3map.snaptogrid then
                                            plr.x = v.x+(config.playeroffsetx or 0)
                                            plr.y = v.y+(config.playeroffsety or 0)
                                        end
                                        p.data.safepos = vector(plr.x,plr.y)
                                        if config.islevel then
                                            SFX.play(smb3map.levelsfx)
                                        else
                                            SFX.play(smb3map.nodesfx)
                                        end
                                        plr.currentcorner = nil
                                        plr.gravblock = nil
                                        plr.speedblock = nil
                                        stopplr(plr)
                                        break
                                    end
                                end
                            end
                            if not plr.moving then
                                for __,b in Block.iterate() do -- Trigger nessesary events when in the block
                                    if blockisvalid(b) and cantouch(Block.config[b.id],p) then
                                        local config = Block.config[b.id]
                                        if config.enemyzone and Colliders.collide(b,plr.collider) and b:mem(0x14,FIELD_STRING) ~= "" then
                                            triggerEvent(b:mem(0x14,FIELD_STRING))
                                        end
                                    end
                                end
                            end
                            if plr.freeroam == 0 then
                                plr.checkingcorners = checkforcorners(plr)
                            elseif plr.freeroam == 1 then
                                if plr.moving then
                                    SFX.play(smb3map.nodesfx)
                                end
                                p.data.safepos = vector(plr.x,plr.y)
                                plr.moving = false
                                resetpspeed(plr)
                            end
                        end
                    end
                end

                if plr.gravitydir ~= 0 then -- Gravity falls
                    plr.jumpoffset = plr.jumpoffset+plr.jumpspeed
                    if (plr.gravitydir > 0 and plr.jumpoffset >= 0) or (plr.gravitydir < 0 and plr.jumpoffset <= 0) then -- you can stop jumping now
                        plr.jumpoffset = 0
                        plr.gravitydir = 0
                        plr.jumpspeed = 0
                    elseif plr.jumpheight > 0 then -- Player's going up and doesn't care about gravity
                        plr.jumpheight = math.max(plr.jumpheight-1,0)
                    else -- Someone turned on the gravity
                        plr.jumpspeed = plr.jumpspeed + plr.gravity
                        if plr.terminalv ~= 0 then -- Air resistance or whatever makes terminal velocity
                            if plr.gravitydir < 0 then
                                plr.jumpspeed = math.max(plr.jumpspeed,-plr.terminalv)
                            else
                                plr.jumpspeed = math.min(plr.jumpspeed,plr.terminalv)
                            end
                        end
                    end
                end
            end
            if plr.pullinglevel then
                if npcisvalid(plr.pullinglevel) then
                    plr.pulltimer = plr.pulltimer + 1
                    if cheatisactive("skipthesequence") then
                        plr.pulltimer = smb3map.pulltimer
                    end
                    if plr.pulltimer >= smb3map.pulltimer then
                        plr.visible = false
                        if not smb3map.enteringlevel then
                            enterlevel(plr.pullinglevel,p,plr.pullinglevel.data._settings.warp)
                        end
                    end
                else
                    unpull(plr)
                end
            end

            if not smb3map.subcorners then
                plr.checkingcorners = false
            end

            if plr.freeroam == 1 and not plr.moving then
                for __,v in NPC.iterate() do -- trying to find docks to board on
                    if npcisvalid(v) then
                        local config = NPC.config[v.id]
                        if (config.isdock) and Colliders.collide(v,plr.collider) then
                            plr.currentlevel = v
                            plr.x = v.x
                            plr.y = v.y
                            save.safeplayerpos = vector(v.x,v.y)
                            plr.freeroam = 0
                            resetpspeed(plr)
                            break
                        end
                    end
                end
            end


            plr.frametimer = plr.frametimer + 1
            if plr.frametimer >= framespeed then
                plr.frametimer = plr.frametimer - framespeed
                plr.frame = plr.frame + 1
                local frames = 2
                if smb3map.frames[p.character] then
                    frames = smb3map.frames[p.character][getpowerup(p)] or frames
                end
                if plr.frame >= frames then
                    plr.frame = 0
                end
            end

            if plr.iswarping and not activewarps[p.idx] then
                plr.iswarping = false
            end

            --if savemefromthishell then
            --    savepos(p)
            --    savemefromthishell = false
            --end
            if not p.data.goingback then
                local alive = true
                for __,v in NPC.iterate() do -- Checks for harmful things and fatal things
                    if npcisvalid(v) then
                        local config = NPC.config[v.id]
                        if (config.isfatal) and Colliders.collide(v,plr.collider) then
                            p.data.nonfatal = false
                            p:kill()
                            alive = false
                            break
                        end
                    end
                end
                if alive then
                    for __,v in NPC.iterate() do -- Checks for harmful things and fatal things
                        if npcisvalid(v) then
                            local config = NPC.config[v.id]
                            if (config.isharmful) and Colliders.collide(v,plr.collider) then
                                p.data.nonfatal = true
                                p:kill()
                                break
                            end
                        end
                    end
                end
            end
        end
        if p.data.backtimer >= smb3map.backtimer then
            if p.data.goingback then
                p.data.goingback = nil
                p.data.goingbackfrom = nil
                --smb3map.revertPos()
            end
        end
        if p.data.goingback then
            reallygoingback = true
        end
        if activewarps[p.idx] then
            warping = true
            transtimer = math.min(transtimer,activewarps[p.idx].timer)
        end
    end

    if not warping then
        transtimer = math.min(transtimer+1,smb3map.warptimer)
    end


    if btmt <= 0 and not (animatedplayer or reallygoingback or (waitforwarp and warping)) then
        animatedplayer = true
        if not animatedbaddies then
            smb3map.enemyanimationphase = 1
        end
    end

    if cheatisactive("skipthesequence") and smb3map.enteringlevel then
        Level.load(smb3map.enteringlevel)
    end
end

-- Runs every tick, even when the game is paused. Executes at the start of the tick's draw cycle. Useful as it's the only draw function that only executes once per tick.
function smb3map.onDraw()
    if Level.filename() ~= smb3map.levelFilename then return end
    if(type(starmanshader) == "string") and not sshader then
		sshader = Shader()
		sshader:compileFromFile(nil, starmanshader)
	end
    local npx = smb3map.overlayposes.name.x
    if npx < 0 then
        npx = camera.width+npx
    end
    local npy = smb3map.overlayposes.name.y
    if npy < 0 then
        npy = camera.height+npx
    end
    local ntx = smb3map.overlayposes.thumbnail.x
    if ntx < 0 then
        ntx = camera.width+ntx
    end
    local nty = smb3map.overlayposes.thumbnail.y
    if nty < 0 then
        nty = camera.height+nty
    end
    for _,p in ipairs(Player.get()) do
        if p.data.mapObj then
            ---@type PlayerMapObject
            local plr = p.data.mapObj
            if Misc.isPaused() and doneanimating() and not freezeplayers then
                if (p.rawKeys.left == KEYS_PRESSED or p.rawKeys.right == KEYS_PRESSED) and not Misc.inEditor() then
                    if p.rawKeys.left == KEYS_PRESSED then
                        local char = charcheck(p.character-1,true)
                        SFX.play(71)
                        p:transform(math.clamp(char,1,16),false)
                    elseif p.rawKeys.right == KEYS_PRESSED then
                        local char = charcheck(p.character+1,false)
                        SFX.play(71)
                        p:transform(math.clamp(char,1,16),false)
                    end
                end
                smb3map.playerframe[_] = 1
                playerreverse[_] = false
                if plr then
                    plr.frame = 0
                    plr.frametimer = 0
                end
            end
            local pulldown = 0
            if plr.pullinglevel and plr.pulltimer > 0 then
                local handpos = 0
                local hframe = 0
                if plr.pulltimer < smb3map.pulltimer/2 then
                    handpos = plr.pulltimer/(smb3map.pulltimer/2)
                else
                    hframe = 1
                    handpos = 2-plr.pulltimer/(smb3map.pulltimer/2)
                    pulldown = math.max(plr.pulltimer-smb3map.pulltimer/2,0)
                end
                handpos = math.clamp(handpos)
                if smb3map.handsprite then
                    handpos = math.lerp(0,smb3map.handsprite.height/2,handpos)
                    Graphics.drawBox{
                        texture = smb3map.handsprite,
                        x = plr.x,
                        y = plr.y+plr.height-handpos,
                        sourceHeight = handpos,
                        sourceWidth = smb3map.handsprite.width,
                        sourceX = 0,
                        sourceY = hframe*(smb3map.handsprite.height/2),
                        sceneCoords = true,
                        priority = -10,
                    }
                end
            end
            
            if plr.visible and animatedstart and startanimtimer <= 0 then
                
                local shade
                local uniform
                if player.data.mapObj and player.data.mapObj.starman and sshader then
                    shade = sshader
                    uniform = {
                        time = lunatime.tick()*2;
                    }
                end
                local prior = (smb3map.playerpriority or -25)+0.1-(_*0.01)
                if plr.isfloating and smb3map.cloudsprite and not cheatisactive("nocloudmode") then -- Head in the cloud
                    Graphics.drawBox{
                        texture = smb3map.cloudsprite,
                        x = plr.x+plr.width/2,
                        y = plr.y+plr.height/2+plr.jumpoffset,
                        centered = true,
                        sourceHeight = smb3map.cloudsprite.width,
                        sourceWidth = smb3map.cloudsprite.height/2,
                        sourceX = 0,
                        sourceY = plr.altframe*(smb3map.cloudsprite.height/2),
                        sceneCoords = true,
                        priority = prior+9.9,
                        shader = shade,
                        uniforms = uniform,
                    }
                elseif plr.inwater and smb3map.boatsprite and not cheatisactive("noboatmode") then -- Boat
                    Graphics.drawBox{
                        texture = smb3map.boatsprite,
                        x = plr.x+plr.width/2,
                        y = plr.y+plr.height/2+plr.jumpoffset,
                        centered = true,
                        sourceHeight = smb3map.boatsprite.width,
                        sourceWidth = smb3map.boatsprite.height/2,
                        sourceX = 0,
                        sourceY = plr.altframe*(smb3map.boatsprite.height/2),
                        sceneCoords = true,
                        priority = prior,
                        shader = shade,
                        uniforms = uniform,
                    }
                else
                    renderPlayer(p,nil,prior,true,nil,pulldown,shade,uniform)
                end
            else

            end
            if smb3map.debug then
                if smb3map.dbo.collision then
                    plr.collider:Draw(Color(1,0,0,0.5))
                end
                if smb3map.dbo.currentmatters then
                    if plr.currentlevel then
                        local lvl = plr.currentlevel
                        Graphics.drawBox{
                            x = lvl.x,
                            y = lvl.y,
                            width = lvl.width,
                            height = lvl.height,
                            sceneCoords = true,
                            priority = -10,
                            color = Color(1,0.25,0.5,0.5)
                        }
                    end
                    if plr.pullinglevel then
                        local lvl = plr.pullinglevel
                        Text.print(plr.pulltimer,250,250)
                        Graphics.drawBox{
                            x = lvl.x,
                            y = lvl.y,
                            width = lvl.width,
                            height = lvl.height,
                            sceneCoords = true,
                            priority = -30,
                            color = Color.red
                        }
                    end
                    if plr.currentcorner then
                        local lvl = plr.currentcorner
                        Graphics.drawBox{
                            x = lvl.x,
                            y = lvl.y,
                            width = lvl.width,
                            height = lvl.height,
                            sceneCoords = true,
                            priority = -10,
                            color = Color(1,0.5,0,0.5)
                        }
                    end
                end
                if smb3map.dbo.distance then
                    Text.print(plr.distance,400,100+_*20)
                    Text.print(plr.mcdist,450,100+_*20)
                end
                if smb3map.dbo.warp and activewarps[p.idx] then
                    local warp = activewarps[p.idx]
                    Graphics.drawCircle{
                        x = warp.target.x,
                        y = warp.target.y,
                        sceneCoords = true,
                        radius = 8,
                        priority = -10,
                        color = Color(0,1,0,0.75)
                    }
                    Text.print(tostring(warpdirtosmb3dir(warp.direction)).." "..tostring(warp.direction).." "..tostring(warpdirtosmb3dir(warp.direction)),200,180+_*60)
                    Text.print(tostring(warpdirtosmb3dir(warp.target.exitDirection)).." "..tostring(warp.target.exitDirection),200,200+_*60)
                    Text.print(tostring(plr.direction).." "..tostring(smb3dirtowarpdir(plr.direction)).." "..tostring(warpdirtosmb3dir(smb3dirtowarpdir(plr.direction))),200,220+_*60)
                elseif smb3map.dbo.playerdir then
                    Text.print(tostring(plr.direction).." "..tostring(smb3dirtowarpdir(plr.direction)).." "..tostring(warpdirtosmb3dir(smb3dirtowarpdir(plr.direction))),200,220+_*60)
                end
            end
            -- THIS DISPLAYS THE LEVEL NAME HOW DIDN'T I FIGURE THAT OUT?!
            -- Also it now shows a thumbnail
            if (not (freezeplayers or whistlingwarp)) and doneanimating() and (p == player or not smb3map.leadersChoice)
            and smb3map.drawoverlay and (plr.freeroam == 2 or not plr.moving) and plr.currentlevel and npcisvalid(plr.currentlevel)
            and NPC.config[plr.currentlevel.id].islevel and Colliders.collide(plr.collider,plr.currentlevel) and not (plr.currentlevel.data.spademarked) then
                local xof = (_-1)*20
                if (p == player and smb3map.leadersChoice) then
                    xof = 0
                end
                local data = plr.currentlevel.data
                local settings = data._settings
                local title = settings.levelTitle
                if smb3map.debug then
                    title = "Level Name: \"".."".."\""
                end
                -- Printing the name of the thing
                Text.printWP(title,npx,npy-xof,smb3map.overlaypriority+0.1)
                -- Drawing the thumbnail
                if data.thumbnail and not data.drewthumbnail then
                    data.drewthumbnail = true
                    -- This won't get confusing at all :D
                    local tnx = ntx
                    local tny = nty
                    local scenec = false
                    if smb3map.thumbnailOnMap then
                        scenec = true
                        tnx = tnx+plr.currentlevel.centerX
                        tny = tny+plr.currentlevel.centerY
                    end
                    local ox = 0
                    local oy = 0
                    local sc = 1
                    local priro = smb3map.overlaypriority+0.1
                    if type(settings.thumbnail) == "table" then
                        ox = settings.thumbnail.offsetx or settings.thumbnail.offsetX or ox
                        oy = settings.thumbnail.offsety or settings.thumbnail.offsetY or oy
                        sc = settings.thumbnail.scale or sc
                        priro = settings.thumbnail.priority or settings.thumbnail.prior or priro
                    end
                    Graphics.drawBox{
                        x = tnx+ox,
                        y = tny+oy,
                        texture = data.thumbnail,
                        width = data.thumbnail.width*sc,
                        height = data.thumbnail.height*sc,
                        priority = priro,
                        centered = true,
                        sceneCoords = scenec,
                    }
                end
            end
        end
    end
    if smb3map.debug then
        for _,v in NPC.iterate() do
            if npcisvalid(v) then
                local config = NPC.config[v.id]
                local data = v.data
                if smb3map.dbo.hitbox then
                    if data.spademarked or data.treasureship then
                        Graphics.drawCircle{
                            x = v.x+v.width/2,
                            y = v.y+v.height/2,
                            radius = (v.width+v.height)/2,
                            sceneCoords = true,
                            priority = -10.1,
                            color = Color(1,1,0,0.5)
                        }
                    end
                    if config.islevel or config.isnode or config.isenemy then
                        Graphics.drawBox{
                            x = v.x,
                            y = v.y,
                            width = v.width,
                            height = v.height,
                            sceneCoords = true,
                            priority = -10.1,
                            color = Color(0,0,1,0.5)
                        }
                    elseif config.isfatal then
                        Graphics.drawBox{
                            x = v.x,
                            y = v.y,
                            width = v.width,
                            height = v.height,
                            sceneCoords = true,
                            priority = -10.1,
                            color = Color(1,1,1,0.5)
                        }
                    elseif config.isharmful then
                        Graphics.drawBox{
                            x = v.x,
                            y = v.y,
                            width = v.width,
                            height = v.height,
                            sceneCoords = true,
                            priority = -10.1,
                            color = Color(1,1,0,0.5)
                        }
                    else
                        Graphics.drawBox{
                            x = v.x,
                            y = v.y,
                            width = v.width,
                            height = v.height,
                            sceneCoords = true,
                            priority = -10.1,
                            color = Color(0,0,0,0.5)
                        }
                    end
                end
                if smb3map.dbo.npcid then
                    Text.printWP(v.id,v.x-camera.x,v.y-camera.y,10)
                end
            end
        end
        for _,b in Block.iterate() do
            if blockisvalid(b) then
                local config = Block.config[b.id]
                if smb3map.dbo.hitbox then
                    if config.ispath then
                        Graphics.drawBox{
                            x = b.x,
                            y = b.y,
                            width = b.width,
                            height = b.height,
                            sceneCoords = true,
                            priority = -10.1,
                            color = Color(1,0,0,0.5)
                        }
                    end
                    if config.freeroamzone then
                        Graphics.drawBox{
                            x = b.x,
                            y = b.y,
                            width = b.width,
                            height = b.height,
                            sceneCoords = true,
                            priority = -10.1,
                            color = Color(1,0.5,0,0.5)
                        }
                    end
                    if config.waterzone then
                        Graphics.drawBox{
                            x = b.x,
                            y = b.y,
                            width = b.width,
                            height = b.height,
                            sceneCoords = true,
                            priority = -16,
                            color = Color(0,1,1,0.5)
                        }
                    end
                    if config.changemusic or config.savepoint or config.warppoint then
                        Graphics.drawBox{
                            x = b.x,
                            y = b.y,
                            width = b.width,
                            height = b.height,
                            sceneCoords = true,
                            priority = -10.1,
                            color = Color(0,1,0,0.5)
                        }
                    end
                end
            end
        end
    end
    if smb3map.starlock then
        for _,w in ipairs(Warp.get()) do
            if w.starsRequired and w.starsRequired > mem(0x00B251E0,FIELD_WORD) then
                Graphics.drawBox{
                    texture = smb3map.starlock,
                    x = w.entranceX+w.entranceWidth/2,
                    y = w.entranceY+w.entranceHeight/2,
                    centered = true,
                    sceneCoords = true,
                    sourceX = 0,
                    sourceY = 0,
                    sourceWidth = smb3map.starlock.width,
                    sourceHeight = smb3map.starlock.height,
                    priority = -30
                }
            end
        end
    end
    if mboxactive() and smb3map.musicboxsprite then
        if lunatime.drawtick() % smb3map.musicboxframespeed == 0 then
            musicboxframe = musicboxframe + 1
            if musicboxframe >= smb3map.musicboxframes then
                musicboxframe = 0
            end
        end
        local mbx = smb3map.overlayposes.musicbox.x
        if mbx < 0 then
            mbx = camera.width+mbx
        end
        local mby = smb3map.overlayposes.musicbox.y
        if mby < 0 then
            mby = camera.height+mby
        end
        Graphics.drawBox{
            texture = smb3map.musicboxsprite,
            x = mbx,
            y = mby,
            centered = true,
            sourceX = 0,
            sourceY = (smb3map.musicboxsprite.height/smb3map.musicboxframes)*musicboxframe,
            sourceWidth = smb3map.musicboxsprite.width,
            sourceHeight = smb3map.musicboxsprite.height/smb3map.musicboxframes,
            priority = smb3map.overlaypriority+0.1,
        }
    end

    if startanimtimer > 0 then
        local center = vector(camera.width/2,camera.height/2)
        if startanimtimer > smb3map.sparkleon then -- draw a box and stuff
            -- I'm doing it, I'm texting the plus!!!
            local world = worldName
            if world == "" or not world then
                world = "World "..tostring(smb3map.worlds[player.section+1])
            end
            -- Setting up text

            local worldtext = textplus.parse(world,{
                font = smb3map.font,
            })

            worldtext = textplus.layout(worldtext)

            -- Drawing text
            textplus.render{
                x = center.x-#world*8,
                y = center.y-32,
                layout = worldtext,
                priority = smb3map.overlaypriority-0.256,
                color = Color.white,
            }

            local ihavecreativevariablenames = 8

            if Misc.inEditor() or smb3map.infinitelives or Cheats.get("liveforever") then
                ihavecreativevariablenames = 16
            end

            local yawn = -48
            local baseball = 0
            for _,p in ipairs(Player.get()) do
                if p.isValid then
                    local chara = string.upper(characterNamesProper[p.character] or "Nil")

                    local togore = chara

                    if p == player then
                        togore = togore.."   ` "..tostring(mem(plives,FIELD_FLOAT))
                    end

                    local charactertext = textplus.parse(togore,{
                        font = smb3map.font,
                    })

                    charactertext = textplus.layout(charactertext)

                    local yaw = (_-1)*48

                    -- Drawing text
                    textplus.render{
                        x = center.x-#chara*16,
                        y = center.y+16+yaw,
                        layout = charactertext,
                        priority = smb3map.overlaypriority-0.256,
                        color = Color.white,
                    }
                    
                    baseball = math.max(baseball,#chara*16)
                    
                    renderPlayer(p,vector(center.x+ihavecreativevariablenames,center.y+yaw),smb3map.overlaypriority-0.255,false,smb3map.direction.DOWN)
                    yawn = yawn + 48
                end
            end

            

            if smb3map.startscreen then
                local offshoot = math.max(smb3map.startscreen.width/2-16,#world*8,baseball)+16
                Graphics.drawBox{
                    texture = smb3map.startscreen,
                    x = center.x,
                    y = center.y+math.max(0,yawn/2),
                    centered = true,
                    sourceX = 0,
                    sourceY = 0,
                    sourceWidth = smb3map.startscreen.width,
                    sourceHeight = smb3map.startscreen.height,
                    width = offshoot*2,
                    height = math.max(smb3map.startscreen.height,smb3map.startscreen.height+yawn),
                    priority = smb3map.overlaypriority-0.26,
                }
            end
        elseif smb3map.sparklesprite then
            local stimer = math.clamp(1-startanimtimer/smb3map.sparkleon)
            local playp = vector(camera.x,camera.y)
            ---@type PlayerMapObject
            local plr = player.data.mapObj
            if plr then
                playp.x = plr.x+plr.width/2-playp.x
                playp.y = plr.y+plr.height/2-playp.y
            else
                playp.x = player.x+player.width/2-playp.x
                playp.y = player.y+player.height/2-playp.y
            end
            local plap = math.lerp(center,playp,stimer)
            
            local sparkles = math.max(smb3map.startsparkles,1)

            local spread = -smb3map.sparklespread*(math.clamp(stimer*2)-(math.clamp((stimer-0.5)*2)))

            for i = 1, sparkles do
                local relativepos = vector(0,spread):rotate((i-1)*(360/sparkles)+startanimtimer*smb3map.startrotationovertime)
                local sparklepos = plap+relativepos
                Graphics.drawBox{
                    texture = smb3map.sparklesprite,
                    x = sparklepos.x,
                    y = sparklepos.y,
                    centered = true,
                    sourceX = 0,
                    sourceY = smb3map.sparklesprite.height/2*math.floor((lunatime.tick()%(smb3map.sparkleframespeed*smb3map.sparkleframes)+1)/smb3map.sparkleframespeed),
                    sourceWidth = smb3map.sparklesprite.width,
                    sourceHeight = smb3map.sparklesprite.height/2,
                    priority = smb3map.overlaypriority-0.25,
                }
            end
        end
    end


    if smb3map.debug then
        if smb3map.dbo.music then
            Text.print(save.music,0,0)
        end
        if smb3map.dbo.section then
            Text.print(save.section,200,200)
        end
        if smb3map.dbo.playerpos then
            if save.playerpos then
                Graphics.drawCircle{
                    x = save.playerpos.x,
                    y = save.playerpos.y,
                    sceneCoords = true,
                    radius = 8,
                    priority = -14,
                    color = Color(0,0.5,1,0.75)
                }
            end
            if save.lastplayerpos then
                Graphics.drawCircle{
                    x = save.lastplayerpos.x,
                    y = save.lastplayerpos.y,
                    sceneCoords = true,
                    radius = 4,
                    priority = -10,
                    color = Color(0,0.85,0.15,0.5)
                }
            end
            if save.safeplayerpos then
                Graphics.drawCircle{
                    x = save.safeplayerpos.x,
                    y = save.safeplayerpos.y,
                    sceneCoords = true,
                    radius = 6,
                    priority = -12.5,
                    color = Color(0,1,0,0.75)
                }
            end
        end
    end
end

-- Runs every drawn tick. Executes once for each camera, just before the scene is rendered for it. Gets the respective camera's index `idx` passed.
---@param idx integer
function smb3map.onCameraDraw(idx)
    if Level.filename() ~= smb3map.levelFilename then
        if smb3map.debug and smb3map.dbo.checkpoint then
            debugCheckpoints()
        end
        return
    end
    local cam = Camera(idx)
    if smb3hud then -- HUD stuff
        Graphics.drawBox{
            x = cam.x,
            y = cam.y,
            sceneCoords = true,
            width = cam.width,
            height = 64,
            priority = 1,
            color = Color.black
        }
    elseif smb3map.drawoverlay and not cheatisactive("nomoremaphud") then
        Graphics.activateHud(false)
        -- don't draw the overlay if it's in debug mode!
        if not (smb3map.debug and smb3map.dbo.removeoverlay) then
            if smb3map.overlay then
                Graphics.drawBox{
                    texture = smb3map.overlay,
                    x = cam.x+cam.width/2,
                    y = cam.y+cam.height/2,
                    sceneCoords = true,
                    centered = true,
                    sourceX = 0,
                    sourceY = 0,
                    sourceWidth = smb3map.overlay.width,
                    sourceHeight = smb3map.overlay.height,
                    priority = smb3map.overlaypriority-0.2
                }
            end
            local xoffset = 0
            local features = clonetable(smb3map.overlayposes)
            for f,pos in pairs(features) do
                if pos.x < 0 then
                    pos.x = camera.width+pos.x
                end
                if pos.y < 0 then
                    pos.y = camera.height+pos.y
                end
            end
            for _,p in ipairs(Player.get()) do
                local psprite = Graphics.sprites[pm.getName(p.character)][p.powerup].img
                local ox = 0
                local oy = 0
                local cx = 0
                local cy = 5
                local height = p.height
                local width = p.width
                --if p.character <= 10 then
                --    local settings = p:getCurrentPlayerSetting()
                --    height = settings.hitboxHeight
                --    cx,cy = Player.convertFrame(smb3map.playerframe[_],-1)
                --    ox = settings:getSpriteOffsetX(cx,cy)
                --    oy = settings:getSpriteOffsetY(cx,cy)
                --    if p.character > 5 then
                --        ox = ox-64
                --        oy = oy-80
                --    end
                --    width = settings.hitboxWidth
                --end
                --Graphics.drawBox{
                --    texture = psprite,
                --    x = features.player.x+ox+xoffset,
                --    y = features.player.y+oy-height,
                --    --sceneCoords = true,
                --    --centered = true,
                --    sourceX = cx*100,
                --    sourceY = cy*100,
                --    sourceWidth = 100,
                --    sourceHeight = 100,
                --    priority = smb3map.overlaypriority+0.1-_*0.01
                --}
                local shade
                if player.data.mapObj and player.data.mapObj.starman and sshader then
                    shade = sshader
                end
                p:render{
                    shader = shade,
                    frame = smb3map.playerframe[_],
                    direction = -1,
                    ignorestate = true,
                    priority = smb3map.overlaypriority+0.1-_*0.01,
                    x = cam.x+features.player.x+ox+xoffset,
                    y = cam.y+features.player.y+oy-height,
                    uniforms =
                            {
                                time = lunatime.tick()*2;
                            },
                    drawmounts = (player:mem(0x108, FIELD_WORD) ~= 3)
                }
                --Graphics.drawBox{
                --    x = features.player.x+ox,
                --    y = features.player.y+oy-100,
                --    color = Color.red,
                --    width = 100,
                --    height = 100,
                --    priority = 5-_*0.01
                --}
                xoffset = xoffset + width+16
            end
            xoffset = features.player.x+xoffset
            local xicon = Graphics.sprites.hardcoded["33-1"].img
            if smb3map.lifeicon then
                local truex = math.max(xoffset,features.lives.x)
                Graphics.drawBox{
                    texture = smb3map.lifeicon,
                    x = truex,
                    y = features.lives.y,
                    sourceX = 0,
                    sourceY = 0,
                    sourceWidth = smb3map.lifeicon.width,
                    sourceHeight = smb3map.lifeicon.height,
                    priority = smb3map.overlaypriority
                }
                drawNextTo(vector(truex,features.lives.y),smb3map.lifeicon,xicon,8,smb3map.overlaypriority)
                if Misc.inEditor() or smb3map.infinitelives then
                    local infinity = Graphics.sprites.hardcoded["50-11"].img
                    Graphics.drawBox{
                        texture = infinity,
                        x = truex+xicon.width+smb3map.lifeicon.width+16,
                        y = features.lives.y,
                        sourceX = 0,
                        sourceY = 0,
                        sourceWidth = infinity.width,
                        sourceHeight = infinity.height,
                        priority = smb3map.overlaypriority
                    }
                else
                    Text.printWP(mem(plives,FIELD_FLOAT),1,truex+xicon.width+smb3map.lifeicon.width+16,features.lives.y,smb3map.overlaypriority)
                end
            end
            local coins = Misc.coins()
            if smb3map.overridecurrency then
                coins = smb3map.overridecurrency:getMoney()
            end
            if smb3map.coinicon then
                local truex = math.max(xoffset,features.coins.x)
                Graphics.drawBox{
                    texture = smb3map.coinicon,
                    x = truex,
                    y = features.coins.y,
                    sourceX = 0,
                    sourceY = 0,
                    sourceWidth = smb3map.coinicon.width,
                    sourceHeight = smb3map.coinicon.height,
                    priority = smb3map.overlaypriority
                }
                drawNextTo(vector(truex,features.coins.y),smb3map.coinicon,xicon,8,smb3map.overlaypriority)
                Text.printWP(coins,1,truex+xicon.width+smb3map.coinicon.width+16,features.coins.y,smb3map.overlaypriority)
            end
            if smb3map.staricon and mem(0x00B251E0,FIELD_FLOAT) > 0 then
                local truex = math.max(xoffset,features.stars.x)
                Graphics.drawBox{
                    texture = smb3map.staricon,
                    x = truex,
                    y = features.stars.y,
                    sourceX = 0,
                    sourceY = 0,
                    sourceWidth = smb3map.staricon.width,
                    sourceHeight = smb3map.staricon.height,
                    priority = smb3map.overlaypriority
                }
                drawNextTo(vector(truex,features.stars.y),smb3map.staricon,xicon,8,smb3map.overlaypriority)
                Text.printWP(mem(0x00B251E0,FIELD_FLOAT),1,truex+xicon.width+smb3map.staricon.width+16,features.stars.y,smb3map.overlaypriority)
            end
            xoffset = math.max(xoffset,features.stars.x+features.coins.x,features.lives.x)+xicon.width+32
            if smb3map.usereserve then
                local reserveicons = {
                    Graphics.sprites.hardcoded["48-0"].img,
                    Graphics.sprites.hardcoded["48-1"].img,
                    Graphics.sprites.hardcoded["48-2"].img,
                }
                local rstart = -1
                if player2 then
                    rstart = 0
                end
                local newoffset = 0
                for _,p in ipairs(Player.get()) do
                    local ress = (_+rstart) % #reserveicons + 1
                    if p.reservePowerup ~= 0 then
                        local icon = reserveicons[ress]
                        Graphics.drawBox{
                            texture = icon,
                            x = math.max(features.reserve.x,xoffset+icon.width/2+16)+newoffset,
                            y = features.reserve.y,
                            sourceX = 0,
                            sourceY = 0,
                            sourceWidth = icon.width,
                            sourceHeight = icon.height,
                            priority = smb3map.overlaypriority,
                            centered = true
                        }
                        local powerup = Graphics.sprites.npc[p.reservePowerup].img
                        local configp = NPC.config[p.reservePowerup]
                        if powerup then
                            local gwidth = configp.gfxwidth
                            if (gwidth == 0 or not gwidth) then
                                gwidth = configp.width
                            end
                            if (gwidth == 0 or not gwidth) then
                                gwidth = powerup.width
                            end
                            local gheight = configp.gfxheight
                            if (gheight == 0 or not gheight) then
                                gheight = configp.height
                            end
                            if (gheight == 0 or not gheight) then
                                gheight = powerup.height
                                if configp.frames and configp.frames ~= 0 then
                                    gheight = gheight/configp.frames
                                end
                            end
                            Graphics.drawBox{
                                texture = powerup,
                                x = math.max(features.reserve.x,xoffset+icon.width/2+16)+newoffset,
                                y = features.reserve.y,
                                sourceX = 0,
                                sourceY = 0,
                                sourceWidth = gwidth,
                                sourceHeight = gheight,
                                width = math.min(gwidth,icon.width),
                                height = math.min(gheight,icon.height),
                                priority = smb3map.overlaypriority-0.01,
                                centered = true
                            }
                        end
                        newoffset = newoffset + icon.width + 16
                    end
                end
            end
        end
    end
    if not cheatisactive("skipthesequence") then
        -- Transition blackness
        if transtimer < smb3map.warptimer then
            Graphics.drawScreen{
                priority = smb3map.overlaypriority-0.25,
                color = Color(0,0,0,1-math.clamp(transtimer/smb3map.warptimer)),
                cam = cam,
            }
        end
        -- Back to hub transitioon
        if btmt > 0 then
            Graphics.drawScreen{
                priority = smb3map.overlaypriority+5,
                color = Color(0,0,0,math.clamp(btmt/smb3map.backtomaptimer)),
                cam = cam,
            }
        end
        -- Entering transition
        if smb3map.enteringlevel then
            local entertimmy = (smb3map.entertimer/smb3map.enteron)*0.75
            Graphics.drawBox{
                x = 0,
                y = 0,
                width = cam.width,
                height = cam.height*entertimmy,
                priority = smb3map.overlaypriority+5,
                color = Color.black
            }
            Graphics.drawBox{
                x = 0,
                y = cam.height-cam.height*entertimmy,
                width = cam.width,
                height = cam.height,
                priority = smb3map.overlaypriority+5,
                color = Color.black
            }
            Graphics.drawBox{
                x = 0,
                y = 0,
                width = cam.width*entertimmy*0.5,
                height = cam.height,
                priority = smb3map.overlaypriority+5,
                color = Color.black
            }
            Graphics.drawBox{
                x = cam.width-cam.width*entertimmy*0.5,
                y = 0,
                width = cam.width,
                height = cam.height,
                priority = smb3map.overlaypriority+5,
                color = Color.black
            }
        end
    end


    if smb3map.debug and smb3map.dbo.warp then
        Text.printWP(transtimer,300,200,999)
    end

    if smb3map.debug then
        if resetTimer > 0 and smb3map.dbo.reset then
            Graphics.drawBox{
                x = cam.x,
                y = cam.y,
                width = cam.width,
                height = cam.height*(resetTimer/192),
                sceneCoords = true,
                priority = smb3map.overlaypriority+5,
                color = Color.black
            }
        end
        if smb3map.dbo.warp then
            for _,w in ipairs(Warp.get()) do
                Text.print(tostring(w.entranceDirection).." "..tostring(warpdirtosmb3dir(w.entranceDirection)),w.entranceX-cam.x,w.entranceY-cam.y)
                Text.print(tostring(w.exitDirection).." "..tostring(warpdirtosmb3dir(w.exitDirection)),w.exitX-cam.x,w.exitY-cam.y)
                Text.print(tostring(w.worldMapX).." "..tostring(w.worldMapY),w.entranceX-cam.x,w.entranceY-cam.y+20)
            end
        end

        for _,v in NPC.iterate() do
            if npcisvalid(v) then
                if smb3map.dbo.idx then
                    Text.print(v:mem(0x14,FIELD_WORD),v.x-cam.x,v.y-cam.y)
                    Text.print(v.idx,v.x-cam.x,v.y-cam.y+20)
                end
                local config = NPC.config[v.id]
                if config.islevel or config.isenemy or config.isairship then
                    if smb3map.dbo.levelfiles then
                        Text.print("Level filename: \""..v.data._settings.levelFilename.."\"",v.x-cam.x,v.y-cam.y)
                        Text.print(v.data._settings.airshipLayer,v.x-cam.x,v.y-cam.y+20)
                    end
                    if smb3map.dbo.layerbelong then
                        Text.print(v.layerName,v.x-cam.x,v.y-cam.y-20)
                    end
                    if smb3map.dbo.enemystep and config.isenemy then
                        Text.print(v.data.steps,v.x-cam.x,v.y-cam.y+40)
                        Text.print(v.data.distance,v.x-cam.x,v.y-cam.y+60)
                        Text.print(v.data.doneanimating,v.x-cam.x,v.y-cam.y+80)
                    end
                end
            end
        end
    end
    for _,p in ipairs(Player.get()) do
        if p.data.mapObj then
            ---@type PlayerMapObject
            local plr = p.data.mapObj
            if whistlingwarp and smb3map.tornadosprite then
                Graphics.drawBox{
                    texture = smb3map.tornadosprite,
                    x = smb3map.windx,
                    y = plr.y,
                    sceneCoords = true,
                    sourceHeight = smb3map.tornadosprite.height/smb3map.tornadoframes,
                    sourceWidth = smb3map.tornadosprite.width,
                    sourceX = 0,
                    sourceY = tornadoframe*(smb3map.tornadosprite.height/smb3map.tornadoframes),
                    priority = -5,
                }
            end

            local clampx = math.clamp(plr.x+plr.width/2,cam.x,cam.x+cam.width)
            local clampy = math.clamp(plr.y+plr.height/2,cam.y,cam.y+cam.height)
            if smb3map.debug then
                if smb3map.dbo.oobcheck then
                    Graphics.drawCircle{
                        x = clampx,
                        y = clampy,
                        radius = 32,
                        sceneCoords = true,
                        priority = -65.1,
                        color = Color(1,0,0,0.25)
                    }
                    Text.print(plr.x,clampx-(100+cam.x),clampy-(120+cam.y))
                    Text.print(plr.y,clampx-(100+cam.x),clampy-(100+cam.y))
                    if plr.currentlevel then
                        debugCheckpoints(plr.currentlevel.data._settings.levelFilename)
                    end
                elseif smb3map.dbo.jump then
                    Text.print(plr.gravity,clampx-(100+cam.x),clampy-(80+cam.y))
                    Text.print("gravity",clampx-(cam.x),clampy-(80+cam.y))
                    Text.print(plr.jumpspeed,clampx-(100+cam.x),clampy-(100+cam.y))
                    Text.print(plr.jumpheight,clampx-(100+cam.x),clampy-(120+cam.y))
                    Text.print(plr.gravitydir,clampx-(100+cam.x),clampy-(140+cam.y))
                    Text.print(plr.jumpoffset,clampx-(100+cam.x),clampy-(160+cam.y))
                    Text.print(plr.terminalv,clampx-(100+cam.x),clampy-(180+cam.y))
                    --gravity = smb3map.playergravity,
                    ---- The speed that jumpoffset is changed
                    --jumpspeed = 0,
                    ---- How many frames should the jumpspeed remain unchanged
                    --jumpheight = 0,
                    ---- The direction of the visual gravity
                    --gravitydir = 0,
                    ---- The visual offset caused by jumping
                    --jumpoffset = 0,
                    ---- The visual offset caused by jumping
                    --terminalv = 0
                end
            end
        end
    end
end

--[[
Executes immediately when a player takes damage.

Passes the Player `p` and a token `e` for cancelling the damage event.
]]
---@param e EventToken
---@param p Player
function smb3map.onPlayerKill(e,p)
    if Level.filename() ~= smb3map.levelFilename then return end
    if e.cancelled then return end
    e.cancelled = true
    if cheatisactive("immovableobject") then return end
    if not p.data.goingback then -- knocked back!
        SFX.play(smb3map.knockbacksfx)
        p.data.backtimer = 0
        if p.data.mapObj then
            p.data.mapObj.frozen = true
        end
        if p.data.nonfatal then
            if p.data.mapObj then
                p.data.goingbackfrom = vector(p.data.mapObj.x,p.data.mapObj.y)
            else
                p.data.goingbackfrom = vector(p.x,p.y)
            end
            p.data.goingback = p.data.safepos or save.lastplayerpos
        else
            savepos(p)
            p.data.goingback = save.lastplayerpos
        end
    end
end

--[[
Executes immediately when a player takes damage.

Passes the Player `p` and a token `e` for cancelling the damage event.
]]
---@param e EventToken
---@param p Player
function smb3map.onPlayerHarm(e,p)
    if Level.filename() ~= smb3map.levelFilename then return end
    if e.cancelled then return end
    e.cancelled = true
    SFX.play(smb3map.knockbacksfx)
end

function smb3map.onPostEventDirect(event)
    if (not event) or event == "" or event == " " then return end
    if Level.filename() ~= smb3map.levelFilename then
        saveTemp.triggeredEvents[#saveTemp.triggeredEvents+1] = event
        return
    end
    for __,b in Block.iterate() do
        if blockisvalid(b) then
            local config = Block.config[b.id]
            local data = b.data
            local settings = data._settings
            if (config.changemusic or config.startworld) and settings.event == event then
                if config.startworld then
                    local sec = getsecfrompos(b)
                    worldName = settings.worldName
                    if not save.animatedsections[sec] then
                        startanimate(sec)
                    end
                else
                    if settings.customMusicPath and settings.customMusicPath ~= "" then
                        save.music = settings.customMusicPath
                    elseif settings.music then
                        if settings.music > 1 then
                            local index = settings.music-2
                            save.music = index
                        elseif settings.music == 1 then
                            save.music = nil
                        end
                    end
                end
            end
        end
    end
end

function smb3map.onInputUpdate()
	for k,p in ipairs(Player.get()) do
        if p.data.goingback or smb3map.enteringlevel then
            for i, _ in pairs(p.keys) do
                p.keys[i] = false
            end
	    end
    end
end

-- Executes when a warp is initiated, if the onWarpEnter event was not cancelled.
---@param w Warp
---@param p Player
function smb3map.onPostWarpEnter(w,p)
    if warperoo and w.toOtherLevel and w.levelFilename == "" and w.worldMapX ~= -1 and w.worldMapY ~= -1 then
        saveTemp.warppos = vector(w.worldMapX*smb3map.warpgrid,w.worldMapY*smb3map.warpgrid)
        warperoo = false
    end
end

--Executes just before the level unloads. The `winType` is according to the `LEVEL_WIN_TYPE_*` constants.
function smb3map.onExitLevel(winType)
    saveTemp.winType = winType

    local winner = false
    for _,p in ipairs(Player.get()) do
        if p.isValid and not p:isDead() then
            winner = true
        end
    end
    if winner then
        saveTemp.loser = false
    else
        saveTemp.loser = true
    end
    if smb3map.introskip or (not (smb3map.introFilename and smb3map.introFilename ~= "")) or (winner and Level.filename() == smb3map.introFilename) then
        save.introdone = true
    end
    if Level.filename() ~= smb3map.levelFilename  then
        local coins = Misc.coins()
        if smb3map.overridecurrency then
            coins = smb3map.overridecurrency:getMoney()
        end
        if coins > 0 and coins % 11 == 0 and math.floor((Misc.score() % 100)/10) ~= 0 and math.floor((Misc.score() % 100)/10) == math.floor((coins % 100)/10) then
            saveTemp.triggership = true
        end
    end
end


--=<[ CHEATS ]>=--


-- A list of custom cheats that the map has
---@type table<integer,Cheat>
smb3map.cheats = {
    -- Activates the music box and anchor for a looooooooong time
    Cheats.register("youcanshutupnow",{
        aliases = {"enemysprayaway","npcspamisarealproblem","youreallbannedfrommoving"},
        activateSFX = 91,
        onActivate = function ()
            smb3map.musicBoxActivate(999,true)
            smb3map.anchorActivate(999)
            return true
        end
    }),
    -- Activates the music box for a looooooooong time
    Cheats.register("gothefucktosleep",{
        aliases = {"nyquil"},
        activateSFX = 91,
        onActivate = function ()
            smb3map.musicBoxActivate(999,true)
            return true
        end
    }),
    -- Activates the anchor for a looooooooong time
    Cheats.register("pleasestopmoving",{
        aliases = {"hammersahoy","sinktothebottomofthesea","battendownthehatches"},
        activateSFX = 91,
        onActivate = function ()
            smb3map.anchorActivate(999)
            return true
        end
    }),
    -- Disables the music box and anchor
    Cheats.register("releasethehounds",{
        aliases = {"goforitbaddies"},
        activateSFX = 91,
        onActivate = function ()
            smb3map.musicBoxDeactivate()
            smb3map.anchorDeactivate()
            return true
        end
    }),
    -- Disables the music box
    Cheats.register("wakethefuckup",{
        aliases = {"wakeuuuup","iaintgotnosleepcauseofyall","youaintnevagonnasleepcauseofme"},
        activateSFX = 91,
        onActivate = function ()
            smb3map.musicBoxDeactivate()
            return true
        end
    }),
    -- Disables the anchor
    Cheats.register("raisetheanchor",{
        aliases = {"setsail","youcanmoveagain"},
        activateSFX = 91,
        onActivate = function ()
            smb3map.anchorDeactivate()
            return true
        end
    }),
    -- Automatically clears the level the first player's on
    Cheats.register("skipthislevel",{
        aliases = {"thislevelsucksass","imcanoticallynabbit"},
        onActivate = function ()
            local plr = player.data.mapObj
            if plr and plr.currentlevel then
                markAsComplete(plr.currentlevel,-1,player.character)
            end
            return true
        end
    }),
    -- Unclears the level the first player's on
    Cheats.register("forgetiwashere",{
        aliases = {"iwannaplaythatlevelagain","letmeinletmein","openthedoorluthor"},
        onActivate = function ()
            local plr = player.data.mapObj
            if plr and plr.currentlevel then
                markAsIncomplete(plr.currentlevel)
            end
            return true
        end,
        activateSFX = 54,
        flashPlayer = true,
    }),
    -- Makes the player immune to being moved from being harmed or knocked from a level
    Cheats.register("immovableobject",{
        aliases = {"idontwannamovebackplease","whatifwedidntgethurt","openthedoorluthor"},
        activateSFX = 85,
        flashPlayer = true,
        deactivateSFX = 4,
    }),
    -- Makes the player ignore enemies and trap level tiles
    Cheats.register("goaroundenemies",{
        aliases = {"ignoremyenemies","thesansoption","andwhosaidyoucouldmakemeplayyourlevel"},
        activateSFX = 24,
        flashPlayer = true,
        deactivateSFX = 25,
    }),
    -- Skips all sequences, meaning nothing on the map moves and everything is snappy like good ol 1.3
    Cheats.register("skipthesequence",{
        aliases = {"whoneedstointroanyway","transitionsaremid","skiptheboringsequence","skiptotheend"},
        activateSFX = 67,
        deactivateSFX = 20,
        onActivate = function ()
            animatedbaddies = true
            animatedplayer = true
            animatedstart = true
            animatedtiles = true
            musicset = false
        end,
    }),
    -- Gets rid of the map HUD and replaces it with the default hud. Doesn't apply if smb3hud is active
    Cheats.register("nomoremaphud",{
        aliases = {"getthisoutofmyface","getthisshitoutofmyface","behindthescenes"},
        activateSFX = Misc.resolveSoundFile("chuck-whistle.ogg"),
        deactivateSFX = 12,
        isCheat = false,
        onActivate = function ()
            if not smb3map then
                Graphics.activateHud(true)
            end
        end,
        onDeactivate = function ()
            if not smb3map then
                Graphics.activateHud(false)
            end
        end,
    }),
    -- A less broken cheat of illparkwhereiwant that only applies to if the player is freeroaming
    Cheats.register("illroamwhereiwant",{
        aliases = {"whydidntidothisbefore","illroamwhereeveriwant"},
        activateSFX = 12,
        deactivateSFX = 11,
    }),
    -- Forces all players into a grid freeroamed state (Can't be undone). Also activates "illroamwhereiwant" cheat.
    Cheats.register("forcefreeroamone",{
        aliases = {"roamroamroamyourboat","wanderingaroundtherails","setsailcaptain"},
        activateSFX = 1,
        onActivate = function ()
            if not Cheats.get("illroamwhereiwant") then return end
            Cheats.get("illroamwhereiwant"):trigger(true)
            for _,p in ipairs(Player.get()) do
                local plr = p.data.mapObj
                if plr then
                    plr.freeroam = 1
                end
            end
            return true
        end,
    }),
    -- Forces all players into a fully freeroamed state (Can't be undone). Also activates "illroamwhereiwant" cheat.
    Cheats.register("forcefreeroamtwo",{
        aliases = {"walktowork","supermariobroswonderbelike","wanderingaroundtheroad"},
        activateSFX = 24,
        onActivate = function ()
            if not Cheats.get("illroamwhereiwant") then return end
            Cheats.get("illroamwhereiwant"):trigger(true)
            for _,p in ipairs(Player.get()) do
                local plr = p.data.mapObj
                if plr then
                    plr.freeroam = 2
                end
            end
            return true
        end,
    }),
    -- Doesn't render the player as a boat when inside of a water zone
    Cheats.register("noboatmode",{
        aliases = {"timeforswimminglessons","doggypaddle"},
        activateSFX = 72,
        deactivateSFX = 73,
        isCheat = false,
    }),
    -- Doesn't render the player as a cloud when floating
    Cheats.register("nocloudmode",{
        aliases = {"supermanflight","lookmanocloud"},
        activateSFX = 72,
        deactivateSFX = 73,
        isCheat = false,
    }),
    -- Stops all players starman
    Cheats.register("sunsetrise",{
        aliases = {"ifidonthaveoneneitherdoyou","starmanshouldrunoutnow","colonkillstarman"},
        activateSFX = 5,
        onActivate = function ()
            for _,p in ipairs(Player.get()) do
                if save.starmen[p.idx] then
                    save.starmen[p.idx] = false
                end
                local plr = p.data.mapObj
                if plr then
                    plr.starman = false
                    if plr.starmusic then
                        plr.starmusic:stop()
                        plr.starmusic = nil
                    end
                end
            end
            return true
        end,
    }),
    -- A cheat that when activated, automatically marks any level that's about to be entered as complete
    Cheats.register("instantclear",{
        aliases = {"ezmodeequaltrue","comicallylargeclearinghammer","mapshowcase"},
        activateSFX = 6,
        deactivateSFX = 5,
    }),
    -- Saves the position of the first player
    Cheats.register("saveposhere",{
        aliases = {"quicksave","thatballoonthatihate",},
        onActivate = function ()
            savepos(player)
            return true
        end
    }),
    -- Allows the player to enter levels even if they don't meet the star requirement
    Cheats.register("grandstar",{
        aliases = {"bellyfilledwithstars","filledwithstars","idontneedstars","moremagicalthanstars"},
        activateSFX = 52,
        deactivateSFX = 25,
    }),
    -- Resets the map entirely
    Cheats.register("enditall",{
        aliases = {"fortheloveofgodpleasekillme","freshnewstart","spmworldsix","fasterthanholdingdownaltjumpaltrun"},
        onActivate = function ()
            resetMap(false)
            Level.load(smb3map.levelFilename)
            return true
        end
    }),
}


-- See you later! Come back soon!
return smb3map
--5500 lines of code ;)