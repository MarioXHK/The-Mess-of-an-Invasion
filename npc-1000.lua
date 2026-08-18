local npcManager = require("npcManager")

local puppet = require("puppet")

local npcutils = require("npcs/npcutils")

local drugs = {}

local npcID = NPC_ID

local drugsSettings = {
	id = npcID,

	-- ANIMATION
	--Sprite size
	gfxwidth = 32,
	gfxheight = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 1,
	framestyle = 0,
	framespeed = 128, -- number of ticks (in-game frames) between animation frame changes

	foreground = true, -- Set to true to cause built-in rendering to render the NPC to Priority -15 rather than -45

	-- LOGIC
	--Movement speed. Only affects speedX by default.
	speed = 8,
	luahandlesspeed = true, -- If set to true, the speed config can be manually re-implemented
	nowaterphysics = true,
	cliffturn = false, -- Makes the NPC turn on ledges
	staticdirection = true, -- If set to true, built-in logic no longer changes the NPC's direction, and the direction has to be changed manually

	--Collision-related
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = true,
	noblockcollision = false,
	notcointransformable = true, -- Prevents turning into coins when beating the level
	nofireball = true,
	noiceball = true,
	nohammer=true,
	noyoshi= true,

	score = 0, -- Score granted when killed
	--  1 = 10,    2 = 100,    3 = 200,  4 = 400,  5 = 800,
	--  6 = 1000,  7 = 2000,   8 = 4000, 9 = 8000, 10 = 1up,
	-- 11 = 2up,  12 = 3up,  13+ = 5-up, 0 = 0

	--Various interactions
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false
	nowalldeath = false, -- If true, the NPC will not die when released in a wall

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = false,
	--isbot = false,
	--isvegetable = false,
	--isshoe = false,
	--isyoshi = false,
	isinteractable = true,
	--iscoin = false,
	--isvine = false,
	--iscollectablegoal = false,
	--isflying = false,
	--iswaternpc = false,
	--isshell = false,
	
	--Various interactions
	--ishot = true,
	--iscold = true,
	--iselectric = true,
	--durability = -1, -- Durability for elemental interactions like ishot and iscold. -1 = infinite durability
	--weight = 2,
	--isstationary = true, -- gradually slows down the NPC
	--nogliding = true, -- The NPC ignores gliding blocks (1f0)

	--Emits light if the Darkness feature is active:
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	-- Custom properties below
}


local red = Color.fromHexRGB(0xF81810)
local orange = Color.fromHexRGB(0xF88010)

puppet.registerPuppet{
	id = "whimsyshroom",
	root = "wshroom",

	priority = -10,

	parts = {
		{
			parent = "arrows1",
			texture = "arrow",
			offsetX = 20,
			rotationOffset = 180,
			color = red,
		},
		{
			parent = "arrows2",
			texture = "arrow",
			offsetY = 20,
			rotationOffset = 90,
			color = orange,
		},
		{
			parent = "arrows1",
			texture = "arrow",
			offsetX = -20,
			rotationOffset = 0,
			color = red,
		},
		{
			parent = "arrows2",
			texture = "arrow",
			offsetY = -20,
			rotationOffset = 270,
			color = orange,
		},
		arrowbase = {
			scale = 2,
		},
		arrows1 = {
			parent = "arrowbase",
			priorityOffset = -0.025,
		},
		arrows2 = {
			parent = "arrowbase",
			priorityOffset = -0.02,
		},
		head = {
			scale = 2,
		},
		eyes = {
			parent = "head",
			texture = "",
		},
		spots = {
			parent = "head",
			priorityOffset = 0.01,
		},
		eye1 = {
			parent = "eyes",
			texture = "eyes",
			sourceX = 0,
			sourceY = 0,
			sourceWidth = 8,
			sourceHeight = 8,
			offsetX = -8,
			offsetY = -8,
			priorityOffset = 0.015,
		},
		eye2 = {
			parent = "eyes",
			texture = "eyes",
			sourceX = 8,
			sourceY = 0,
			sourceWidth = 8,
			sourceHeight = 8,
			offsetX = 8,
			offsetY = -8,
			priorityOffset = 0.015,
		},
		eye3 = {
			parent = "eyes",
			texture = "eyes",
			sourceX = 0,
			sourceY = 8,
			sourceWidth = 8,
			sourceHeight = 8,
			offsetX = -8,
			offsetY = 8,
			priorityOffset = 0.015,
		},
		eye4 = {
			parent = "eyes",
			texture = "eyes",
			sourceX = 8,
			sourceY = 8,
			sourceWidth = 8,
			sourceHeight = 8,
			offsetX = 8,
			offsetY = 8,
			priorityOffset = 0.015,
		},
		stem = {
			scale = 2,
			offsetY = -14,
			y = 28,
			priorityOffset = -0.01
		}
	},
	animations = {
		idle = {
			parts = {
				head = {
					[0] = {
						rotation = 0,
					},
					[7.5] = {
						rotation = 360,
					}
				},
				stem = {
					[3.5] = {
						rotation = -25,
						easing = "inOutCubic"
					},
					[7] = {
						rotation = 25,
						easing = "inOutCubic"
					},
				},
				arrows1 = {
					[0] = {
						rotation = 0,
					},
					[5] = {
						rotation = 360,
					}
				},
				arrows2 = {
					[0] = {
						rotation = 0,
					},
					[3.75] = {
						rotation = 360,
					}
				},
			},
		}
	},
	startAnimation = "idle",
}







npcManager.setNpcSettings(drugsSettings)

npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

function drugs.onInitAPI()
	npcManager.registerEvent(npcID, drugs, "onTickNPC")
	npcManager.registerEvent(npcID, drugs, "onTickEndNPC")
	npcManager.registerEvent(npcID, drugs, "onDrawNPC")
	--registerEvent(drugs, "onNPCHarm")
	--registerEvent(drugs, "onNPCKill")
	--registerEvent(drugs, "onPostNPCHarm")
	--registerEvent(drugs, "onPostNPCKill")
	--registerEvent(drugs, "onNPCCollect")
	--registerEvent(drugs, "onPostNPCCollect")
end

-- The function that every game tick for the NPC `v`
---@param v NPC
function drugs.onTickNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data -- NPC's data
	local config = NPC.config[v.id] -- NPC config
	local settings = data._settings -- Custom extra settings

	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.puppet = puppet.spawn{
			id = "whimsyshroom",
			parent = v
		}
		data.timer = 0
	end

	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		data.timer = 0
	end
	data.timer = data.timer + 1
end

-- Function that runs after onTick and internal smbx code for the NPC `v`
---@param v NPC
function drugs.onTickEndNPC(v)
	if not v.data.initialized then return end
	local data = v.data
	local config = NPC.config[v.id]
	local settings = data._settings

	data.puppet.y = v.y+math.cos(data.timer/config.framespeed)*config.speed
end

-- Function that runs every time the screen is drawn for the NPC `v`
---@param v NPC
function drugs.onDrawNPC(v)
	if not v.data.initialized then return end
	local data = v.data
	local config = NPC.config[v.id]
	local settings = data._settings
	npcutils.hideNPC(v)
end

-- Executes when the NPC `v` gets harmed by `r` reason. It also gives the eventToken `e` and the culprit `n`
---@param e EventToken
---@param v NPC
---@param r number
---@param n Player|NPC|nil
function drugs.onNPCHarm(e,v,r,n)
	if v.id ~= npcID then return end
end

-- Executes when the NPC `v` gets killed by `r` reason. It also gives the eventToken `e`
---@param e EventToken
---@param v NPC
---@param r number
function drugs.onNPCKill(e,v,r)
	if v.id ~= npcID then return end
end

--Executes *immediately* when any NPC takes damage. Passes the NPC `v`, the harm type causing the damage `r`, and any culprit `n` if it exists.
---@param v NPC
---@param r number
---@param n Player|NPC|nil
function drugs.onPostNPCHarm(v,r,n)
	if v.id ~= npcID then return end
end

-- Executes when the NPC `v` gets killed by `r` reason without being cancelled.
---@param v NPC
---@param r number
function drugs.onPostNPCKill(v,r)
	if v.id ~= npcID then return end
end

--Executes *immediately* when any NPC is collected. Passes the NPC `v`, the player that collected it `p`, and a token `e` that can be used to cancel the death.
---@param e EventToken
---@param v NPC
---@param p Player
function drugs.onNPCCollect(e,v,p)
    if v.id ~= npcID then return end
end

--Executes *immediately* when any NPC is collected. Passes the NPC `v` and the player `p` that collected it. Since this event runs only when onNPCCollect was not cancelled, it is useful for running code that should happen only when NPCs were actually collected.
---@param v NPC
---@param p Player
function drugs.onPostNPCCollect(v,p)
    if v.id ~= npcID then return end
end

return drugs