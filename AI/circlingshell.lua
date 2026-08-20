local npcManager = require("npcManager")

--[[
# Rolling hill shells
*Koopa shells that decided to roll on a hill*

by MarioXHK
]]
local yoshiGalaxy = {}

local IDs = {}

function yoshiGalaxy.register(id)
	IDs[id] = true
    npcManager.registerEvent(id, yoshiGalaxy, "onTickNPC")
end

function yoshiGalaxy.onInitAPI()
	registerEvent(yoshiGalaxy, "onNPCHarm")
end

-- The function that every game tick for the NPC `v`
---@param v NPC
function yoshiGalaxy.onTickNPC(v)
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
		data.speed = 0
	end
	if data.speed <= 0 then
		data.frame = 0
		data.frametimer = 0
	end

	if data.speed > 0 and not v.friendly then
		for _,n in NPC.iterateIntersecting(v.x,v.y,v.right,v.bottom) do
			if n ~= v and n.isValid and not (n.isHidden or n.friendly) then
				n:harm(HARM_TYPE_NPC)
			end
		end
	end
end

-- Executes when the NPC `v` gets harmed by `r` reason. It also gives the eventToken `e` and the culprit `n`
---@param e EventToken
---@param v NPC
---@param r number
---@param n Player|NPC|nil
function yoshiGalaxy.onNPCHarm(e,v,r,n)
	if not IDs[v.id] then return end

	if r == HARM_TYPE_JUMP or r == HARM_TYPE_FROMBELOW then
		e.cancelled = true
		if v.data.speed <= 0 then
			v.data.speed = NPC.config[v.id].speed*RNG.randomSign()
			SFX.play(9)
		else
			v.data.speed = 0
			SFX.play(2)
		end
	end
end


return yoshiGalaxy