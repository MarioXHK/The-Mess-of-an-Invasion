local npcManager = require("npcManager")

local sampleNPC = {}

local npcID = NPC_ID

local tileAI = require("AI/leveltile")

tileAI.register(npcID)

local mapconfig = require("AI/mapconfig")

mapconfig.registermapnpc{
	id = npcID,
	frames = 4,
	framespeed = 16,
	speed = 0,

	islevel = true,
	isgrabber = false,
	markimmune = false,
	mirrorblock = 115,
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
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
end

local blockutils = require("blocks/blockutils")

function sampleNPC.onTickNPC(v)
	v.dontMove = true
end

function sampleNPC.onDrawNPC(v)
	v.animationFrame = blockutils.getBlockFrame(NPC.config[v.id].mirrorblock or npcID)
end

return sampleNPC