local npcManager = require("npcManager")

local lineguide = require("base/lineguide");

local spinMeRightRound = {}

local npcID = NPC_ID

local npcutils = require("npcs/npcutils")

local spinMeRightRoundSettings = {
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
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes

	foreground = true, -- Set to true to cause built-in rendering to render the NPC to Priority -15 rather than -45

	-- LOGIC
	--Movement speed. Only affects speedX by default.
	speed = 1,
	luahandlesspeed = true, -- If set to true, the speed config can be manually re-implemented
	nowaterphysics = false,
	cliffturn = false, -- Makes the NPC turn on ledges
	staticdirection = false, -- If set to true, built-in logic no longer changes the NPC's direction, and the direction has to be changed manually

	--Collision-related
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = true,
	noblockcollision = true,
	notcointransformable = true, -- Prevents turning into coins when beating the level
	nofireball = true,
	noiceball = true,
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
	--isinteractable = false,
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
	wheel = npcID,
}

npcManager.setNpcSettings(spinMeRightRoundSettings)

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

local AXIS = {
    HORIZ = 0,
    VERT = 1
};

function spinMeRightRound.onInitAPI()
	npcManager.registerEvent(npcID, spinMeRightRound, "onTickNPC")
	npcManager.registerEvent(npcID, spinMeRightRound, "onDrawNPC")
	lineguide.registerNpcs(npcID);

    lineguide.properties[npcID] = {
        lineSpeed = 0,
    }
end

function spinMeRightRound.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data -- NPC's data
	local cfg = NPC.config[v.id] -- NPC config
	local settings = data._settings -- Custom extra settings
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
	end

	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		-- return
	end

	if not data.connect then
		for _,w in Block.iterate(cfg.wheel) do
			if not (w.isHidden or w:mem(0x5A, FIELD_BOOL)) then
				if w.data.id == settings.id then
					data.connect = w
					break
				end
			end
		end
	end

	if not data.connect then return end

	local wheel = data.connect

	if v.data._basegame.lineguide then
		if v.data._basegame.lineguide.state == lineguide.states.ONLINE then
			if not v.data._basegame.lineguide.bgoTimer then
				local speed = -wheel.data.speed*settings.speed
				v.data._basegame.lineguide.lineSpeed = speed
			end
		else
			if v:mem(0x132, FIELD_WORD) == 0 then
				if settings.axis == AXIS.HORIZ then
					v.speedX = settings.speed * wheel.data.speed
				else
					v.speedY = settings.speed * wheel.data.speed
				end
			else
				v.speedX = 0;
				
				if cfg.nogravity then
					v.speedY = 0;
				else
					v.speedY = -Defines.npc_grav;
				end
			end
		end
	end
end

function spinMeRightRound.onDrawNPC(v)
	if not v.data._settings.show then
		npcutils.hideNPC(v)
	end
end


return spinMeRightRound