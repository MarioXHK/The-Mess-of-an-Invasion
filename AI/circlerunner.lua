local npcManager = require("npcManager")

--[[
# Circle Runner

*NPCs that run on circular platforms,*

by MarioXHK
]]
local skipSqueak = {}

local IDs = {}

-- Register an NPC's id as an NPC that runs on circular hills
---@param id integer
function skipSqueak.register(id)
	IDs[id] = true
    npcManager.registerEvent(id, skipSqueak, "onTickNPC")
	npcManager.registerEvent(id, skipSqueak, "onTickEndNPC")
	--npcManager.registerEvent(id, skipSqueak, "onDrawNPC")
end

function skipSqueak.onInitAPI()
	--registerEvent(skipSqueak, "onNPCKill")
end

-- The function that every game tick for the NPC `v`
---@param v NPC
function skipSqueak.onTickNPC(v)
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

	if data.parent then
		data.speed = math.clamp((math.abs(data.parent.data.speed)*data.parent.data._settings.radius)/64.1,0,config.speed)
		if data.parent.data.speed < 0 then
			v.direction = 1
		elseif data.parent.data.speed > 0 then
			v.direction = -1
		end
	end
end

-- Function that runs after onTick and internal smbx code for the NPC `v`
---@param v NPC
function skipSqueak.onTickEndNPC(v)
	if v.isHidden or not v.data.initialized then return end
	local data = v.data
	local config = NPC.config[v.id]

	local overflow = false
	if config.stillframes > 0 and data.speed == 0 then
		data.frametimer = data.frametimer+1
		overflow = data.frame >= config.stillframes
	else
		data.frametimer = data.frametimer+data.speed
		overflow = data.frame < config.stillframes or data.frame >= config.stillframes+config.walkframes
	end

	if overflow then
		data.frame = 0
		if data.speed ~= 0 then
			data.frame = config.stillframes
		end
		data.frametimer = 0
	end

	local framespeed = config.framespeed
	if data.speed ~= 0 then
		framespeed = framespeed*config.framespeedmultiplier
	end

	if data.frametimer >= framespeed then
		data.frame = data.frame + 1
		if data.speed == 0 then
			data.frametimer = data.frametimer-framespeed
		else
			data.frametimer = data.frametimer-framespeed
		end
		if config.stillframes > 0 and data.speed == 0 then
			if data.frame >= config.stillframes then
				data.frame = 0
			end
		else
			if data.frame >= config.stillframes+config.walkframes then
				data.frame = config.stillframes
			end
		end
	end
end


return skipSqueak