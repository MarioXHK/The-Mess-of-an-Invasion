local npcManager = require("npcManager")

local treasureChest = {}

local inventory
pcall(function() inventory = require("smb3inv") end)

local npcID = NPC_ID

local treasureChestSettings = {
	id = npcID,

	-- ANIMATION
	--Sprite size
	gfxwidth = 64,
	gfxheight = 64,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 64,
	height = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 1,
	framestyle = 1,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes

	foreground = false, -- Set to true to cause built-in rendering to render the NPC to Priority -15 rather than -45

	-- LOGIC
	--Movement speed. Only affects speedX by default.
	speed = 1,
	luahandlesspeed = false, -- If set to true, the speed config can be manually re-implemented
	nowaterphysics = false,
	cliffturn = false, -- Makes the NPC turn on ledges
	staticdirection = false, -- If set to true, built-in logic no longer changes the NPC's direction, and the direction has to be changed manually

	--Collision-related
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = false,
	noblockcollision = false,
	notcointransformable = true, -- Prevents turning into coins when beating the level
	nofireball = true,
	noiceball = true,
	nohammer=true,
	noyoshi= true,

	score = 0,

	--Various interactions
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false
	nowalldeath = true, -- If true, the NPC will not die when released in a wall

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

npcManager.setNpcSettings(treasureChestSettings)

npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
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
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

function treasureChest.onInitAPI()
	registerEvent(treasureChest, "onNPCCollect")
	registerEvent(treasureChest, "onPostNPCCollect")
	registerEvent(treasureChest, "onTickEnd")
	registerEvent(treasureChest, "onDraw")
end

local item = { -- Why would I have more than two of these in a level close to eachother?
	id = 0,
	x = 0,
	y = 0,
	speed = 0,
	life = 0,
}

function treasureChest.onNPCCollect(e,v,p)
	if v.id ~= npcID then return end
	if not p.keys.up then
		e.cancelled = true
	end
end

function treasureChest.onPostNPCCollect(v,p)
	if v.id ~= npcID then return end
	Effect.spawn(npcID,v.x,v.y)
	item.x = v.x+v.width/2
	item.y = v.y+v.height/2
	item.speed = 5
	item.life = 128
	item.id = v.ai1
	if inventory then
		inventory.add(v.ai1)
	else
		p.reservePowerup = v.ai1
	end
end

function treasureChest.onTickEnd()
	if item.life > 0 then
		item.life = item.life - 1
		item.speed = math.max(item.speed-0.25,0)
		item.y = item.y-item.speed
		if item.life <= 0 then
			Effect.spawn(10,item.x-16,item.y-16)
		end
	end
end

function treasureChest.onDraw()
	local id = item.id
	local sprite = Graphics.sprites.npc[id].img
	--Graphics.drawCircle{
	--	x = item.x,
	--	y = item.y,
	--	priority = -4,
	--	sceneCoords = true,
	--	radius = 16,
	--	color = Color.red,
	--}
	--Text.print(id,item.x-camera.x,item.y-camera.y)
	if item.life <= 0 or not sprite then return end
	local config = NPC.config[id]
	local width = config.gfxwidth
	if width == 0 or not width then
		width = sprite.width
	end
	local h = sprite.height
	local frames = config.frames
	if frames == 0 or not frames then
		frames = h/width
	end
	local height = config.gfxheight
	if height == 0 or not height then
		height = sprite.height/frames
	end
	Graphics.drawBox{
		texture = sprite,
		x = item.x,
		y = item.y,
		priority = -5,
		sourceX = 0,
		sourceY = 0,
		sourceWidth = width,
		sourceHeight = height,
		centered = true,
		sceneCoords = true,
	}
	
end

return treasureChest