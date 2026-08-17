local npcManager = require("npcManager")

local superHammerBro = {}

local npcID = NPC_ID

local superHammerBroSettings = {
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
	framespeed = 12, -- number of ticks (in-game frames) between animation frame changes

	foreground = false, -- Set to true to cause built-in rendering to render the NPC to Priority -15 rather than -45

	-- LOGIC
	--Movement speed. Only affects speedX by default.
	speed = 1,
	luahandlesspeed = false, -- If set to true, the speed config can be manually re-implemented
	nowaterphysics = true,
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
	noyoshi= false,

	score = 6,

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

npcManager.setNpcSettings(superHammerBroSettings)

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

function superHammerBro.onInitAPI()
	registerEvent(superHammerBro, "onPostNPCCollect")
	registerEvent(superHammerBro, "onNPCCollect")
end

local map = require("smb3map")

local weirdAl = require("AI/mapitem",{"needamaphammer","imgonnawreckit","icanfixit","thestrongesthammer"})

weirdAl.register(npcID)

-- Executes *immediately* when any NPC is collected. Passes the NPC `v`, the player that collected it `p`, and a token `e` that can be used to cancel the death.
---@param e EventToken
---@param v NPC
---@param p Player
function superHammerBro.onNPCCollect(e,v,p)
    if v.id ~= npcID then return end
    if Level.filename() ~= map.levelFilename then return end
	local plr = p.data.mapObj
	if plr then
		local xoff = 0
		local yoff = 0
		if plr.direction == map.direction.UP then
			yoff = -plr.height
		elseif plr.direction == map.direction.DOWN then
			yoff = plr.height
		elseif plr.direction == map.direction.LEFT then
			xoff = -plr.width
		elseif plr.direction == map.direction.RIGHT then
			xoff = plr.width
		end
		local cant = true
		for __,w in NPC.iterateIntersecting(plr.x+xoff+map.playerspace,plr.y+yoff+map.playerspace,plr.x+plr.width+xoff-map.playerspace,plr.y+plr.height+yoff-map.playerspace) do
			if w.isValid and not (w.isHidden or w.isGenerator or w.friendly) then
				if NPC.config[w.id].isrock then
					cant = false
					break
				end
			end
		end
		if cant then
			e.cancelled = true
		end
	else
		e.cancelled = true
	end
	if e.cancelled then
		SFX.play(3)
		p.reservePowerup = v.id
		v:kill(HARM_TYPE_VANISH)
	end
end

--Executes *immediately* when any NPC is collected. Passes the NPC `v` and the player `p` that collected it. This event runs only when onNPCCollect was not cancelled.
---@param v NPC
---@param p Player
function superHammerBro.onPostNPCCollect(v,p)
	if v.id ~= npcID then return end
	local plr = map.players[p.idx]
	if plr then
		local xoff = 0
		local yoff = 0
		if plr.direction == map.direction.UP then
			yoff = -plr.height
		elseif plr.direction == map.direction.DOWN then
			yoff = plr.height
		elseif plr.direction == map.direction.LEFT then
			xoff = -plr.width
		elseif plr.direction == map.direction.RIGHT then
			xoff = plr.width
		end
		for __,w in NPC.iterateIntersecting(plr.x+xoff+map.playerspace,plr.y+yoff+map.playerspace,plr.x+plr.width+xoff-map.playerspace,plr.y+plr.height+yoff-map.playerspace) do
			if w.isValid and not (w.isHidden or w.isGenerator or w.friendly) then
				if NPC.config[w.id].isrock then
					SaveData.smb3map.destroyedlist[w.idx] = true
					Effect.spawn(131,w)
					w:kill(HARM_TYPE_SPINJUMP)
				end
			end
		end
	end
end

return superHammerBro