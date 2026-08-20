--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local multiCoin = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

local registeredBlocks = {}

--Defines NPC config for our NPC. You can remove superfluous definitions.
local multiCoinSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	frames = 1,

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false
	notcointransformable = true,
	grabside=false,
	grabtop=false,
	ignorethrownnpcs = true,
	
	--Put an npc id in here. If the block contains one of these npc ids initially, it will instead transform the block instead of dispensing like normal
	transformIntoNPCs = {211, 58, 45},
}

--Applies NPC settings
npcManager.setNpcSettings(multiCoinSettings)

--Register events
function multiCoin.onInitAPI()
	npcManager.registerEvent(npcID, multiCoin, "onTickNPC")
	registerEvent(multiCoin, "onBlockHit")
	registerEvent(multiCoin, "onTick")
end

-- registers all blocks as a the npc on start whenever the npc's placed on top on them
function multiCoin.onTickNPC(v)
	if v.isHidden then return end
	local data = v.data
	for i,b in Block.iterateIntersecting(v.x + 16,v.y + 16,v.x + v.width - 16, v.y + v.height - 16) do
		b.data.originalContents = b.contentID
		for _,n in ipairs(multiCoinSettings.transformIntoNPCs) do if b.data.originalContents == n + 1000 then b.data.transformBlockAfterHit = true end end
		b.data.multiCoinBlockHitCount = 0
		b.data.multiCoinBlockTimer = v.data._settings.blockTime
		b.data.maxCoinsToReach = v.data._settings.maxCoins
		b.contentID = v.data._settings.maxCoins
	end
	v:kill(9)
end

function multiCoin.onBlockHit(token, v, above, p)
	--if v.contentID <= 0 then return end
	if not v.data.originalContents then return end

	--Start the block hitting timer if it hasnt already
	v.data.multiCoinBlockTimerFlag = true

	--Check that its hit all the coins, if it has then dispense the bonus
	if p then if not p.data.luigiHitsBlocksNormally then v.data.multiCoinBlockHitCount = v.data.multiCoinBlockHitCount + 1 end else v.data.multiCoinBlockHitCount = v.data.multiCoinBlockHitCount + 1 end
	if v.data.multiCoinBlockHitCount == v.data.maxCoinsToReach and v.contentID ~= 0 then
		if v.data.originalContents ~= 0 then
			if v.data.originalContents > 1000 then
				if v.data.transformBlockAfterHit then
					v:remove()
					v.contentID = 0
					local n = NPC.spawn(v.data.originalContents - 1000, v.x, v.y, player.section, false)
				else
					v.contentID = v.data.originalContents
				end
			else
				SFX.play(27)
				for i=1,v.data.originalContents do
					local coin = NPC.spawn(10,v.x + 0.5 * v.width - 0.5 * NPC.config[10].width, v.y + (0.5 * v.height - 0.5 * NPC.config[10].height) - v.height * 1.5--[[, section]])
					coin.speedX = RNG.randomInt(-2,2)
					coin.speedY = RNG.randomInt(-8,-3)
					coin.ai1 = 1
				end
			end
		else
			v.contentID = 1
		end
		v.data.originalContents = nil
		v.data.multiCoinBlockTimerFlag = nil
	end
end

--Count down the timer that gets set, when it hits 0 then end the block hitting combo
function multiCoin.onTick(v)
	for _,v in ipairs(Block.get()) do
		if v.data.multiCoinBlockTimerFlag then
			v.data.multiCoinBlockTimer = v.data.multiCoinBlockTimer - 1
			if v.data.multiCoinBlockTimer <= 0 then
				v.contentID = 1
				v.data.originalContents = nil
				v.data.multiCoinBlockTimerFlag = nil
			end
		end
	end
end

--Gotta return the library table!
return multiCoin