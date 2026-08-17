local npcManager = require("npcManager")

local sampleNPC = {}

local npcID = NPC_ID

local tileAI = require("AI/leveltile")

tileAI.register(npcID)

local mapconfig = require("AI/mapconfig")

mapconfig.registermapnpc{
	width = 32,
	height = 48,
	gfxwidth = 32,
	gfxheight = 48,
	id = npcID,
	frames = 2,
	speed = 0,

	isenemy = true,
	isoffgrid = true,
	foreground = true,
}

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

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	--registerEvent(sampleNPC, "onNPCKill")
end

local map = require("smb3map")

local h
local i
local npcutils = require("npcs/npcutils")

function sampleNPC.onTickNPC(v)
	local data = v.data._basegame
	local config = NPC.config[v.id]
	if map.musicBoxActive() then
		--data.home = data.home or v.y
		--data.directon = data.directon or v.direction
		--data.state = 0
		--data.timer = 0
		--data.jumpSpeed = nil
		--data.animationTimer = 0
		if not h then
			h = config.hidetime
			config.hidetime = 99999999
		end
		if not i then
			i = config.resttime
			config.resttime = 0
		end
	else
		if h then
			config.hidetime = h
			h = nil
		end
		if h then
			config.resttime = i
			i = nil
		end
	end
end

function sampleNPC.onDrawNPC(v)
	npcutils.hideNPC(v)
end

return sampleNPC