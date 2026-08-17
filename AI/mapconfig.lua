local config = {}

local npcManager = require("npcManager")

local blockManager = require("blockManager")

config.defaultnpc = {
	-- Default vanilla stuff
    gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 1,
	framestyle = 0,
	framespeed = 8,

	foreground = false,

	speed = 1,
	luahandlesspeed = true,
	nowaterphysics = true,
	cliffturn = false,
	staticdirection = true,

	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
	notcointransformable = true,
	nofireball = true,
	noiceball = true,
	nohammer=true,
	noyoshi= true,

	score = 0,

	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = true,
	harmlessthrown = true,
	nowalldeath = true,

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside = false,iswalker = false,isbot = false,isvegetable = false,isshoe = false,isyoshi = false,isvine = false,iscollectablegoal = false,isflying = false,iswaternpc = false,isshell = false,
	grabtop = false,ishot = false,iscold = false,durability = 0,weight = false,isstationary = false,nogliding = false,nopowblock = true,useclearpipe = false,

	--Global things

	-- The X offset of the player when they're on the tile
	playeroffsetx = 0,
	-- The Y offset of the player when they're on the tile
	playeroffsety = 0,
	-- The needed powerup to ignore a tiles effect or needed to enter a level
	neededpowerup = -1,
	-- The needed mount to ignore a tiles effect or needed to enter a level
	neededmount = -1,
	-- Should the NPC be killed by a player object's starman effect. Does not work if `starmanimmune` is set to true
	starmanweak = false,
	-- Will the NPC, if killed on the map not appear again.
	permakill = false,
	-- Does the NPC have extra frames based on numbers?
	isnumbered = false,

	-- Level things

	-- Is the tile a level that the player can choose to go to
	islevel = false,
	-- Is the tile something that can move around if the player hasn't cleared it
	isairship = false,
	-- Does the tile have a destroyed frame that it reverts to when it can't be entered again?
	canbedestroyed = false,
	-- X offset of the completion icon when the level has been beat, but can be re-entered
	iconoffsetx = 0,
	-- Y offset of the completion icon when the level has been beat, but can be re-entered
	iconoffsety = 0,
	-- The priority of the completion icon. If it's -100 or less, it'll follow the NPC's priority
	iconpriority = -100,
	-- If the tile can only be accessed when the cloud is on
	isfloater = false,
	-- If true, the level is immune to recieving an n-mark or white house
	markimmune = false,

	-- Node things

	-- Is the tile a node that the player stops on, but can't go to
	isnode = false,
	-- Is the tile something that the player can start free-roaming at?
	isdock = false,
	-- Is the tile something that the player can start *really* free-roaming at?
	isopening = false,

	-- Blocker/enemy things

	-- Is the tile something that blocks a path
	isblocker = false,
	-- Is the tile an enemy that the player is forced into and moves around paths
	isenemy = false,
	-- Is the tile something that grabs onto the player randomly and pulled into it's level
	isgrabber = false,
	-- Is the tile something that can be destroyed with a hammer
	isrock = false,
	-- Is the tile something that can be passed over by a cloud
	islowdown = false,
	-- Can the tile fall asleep from a music box
	issleeper = true,
	-- Can the player pass through the tile and does the tile block the entry of a level on top of it
	islevelblocker = false,
	-- Does the enemy in question ignore regular paths and thus shouldn't have is position saved
	isoffgrid = false,
	-- Is the tile immune to the anchor effect
	anchorimmune = false,
	-- Will the tile only take paths that have isenemypath to true
	enemypathonly = false,
	-- Will mute the enemies sounds
	ismute = false,
	-- Does the enemy ignore when the player goes into an enemy zone and not move at all?
	ignoreenemyzone = false,
	-- If true, the enemy can't get transformed into a treasure ship or any other bonus things
	nobonusship = false,
	-- Can the enemy tough the starman and do it's thing even if it's run over
	starmanimmune = false,

	-- Minigame/Bonus/Extra things

	-- Can the tile cause the player to get harmed and move back a tile
	isharmful = false,
	-- Can the tile cause the player to die and go back to a safe place
	isfatal = false,
	-- Is the tile temporary and will vanish next time the map is open
	istemporary = false,
	-- Can the player collect this thing
	isinteractable = false,
	-- Self explanatory
	iscoin = false,
	-- Will the tile make itself a new save point when collided
	issavepoint = false,
	-- Does the tile move around on it's own but still follows paths and corners accordingly
	ismover = false,
	-- Does the tile follow redirectors when ismover or isenemy is true
	followredirectors = false,
	-- Does the tile not follow paths when ismover or isenemy is true
	ignorepaths = false,
	-- Does the tile ignore levels and nodes when ismover or isenemy
	ignorelevels = false,
	-- If `isharmful` or `isfatal` is on, then if the player has a starman, the NPC won't deal such damages if this is true.
	noharmonstar = false,
}

-- Sets default settings of a map NPC, with overrides for their own thing. Overrides *must* have at least an NPC `id` field
---@param overrides table
function config.registermapnpc(overrides)
    local npcSettings = {}
    -- Getting the default npc stuff
    if type(overrides) ~= "table" or type(overrides.id) ~= "number" then return end
    for setting,conf in pairs(config.defaultnpc) do
        npcSettings[setting] = conf
    end
    -- Set overrides
    for setting,conf in pairs(overrides) do
        npcSettings[setting] = conf
    end
    npcManager.setNpcSettings(npcSettings)
    return npcSettings
end

return config