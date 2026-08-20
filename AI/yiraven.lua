local npcManager = require("npcManager")

--[[
# YI Ravens
*Guys that could only be found skidding all over circles in YI.*

by MarioXHK

requested by KurtTheKing
]]
local yoshiGalaxy = {}

function yoshiGalaxy.register(id)
    npcManager.registerEvent(id, yoshiGalaxy, "onTickNPC")
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
		data.speed = config.speed
		data.timer = RNG.randomInt(config.timermin,config.timermax)
	end

	data.timer = data.timer - 1
	if data.timer <= 0 then
		if data.speed > 0 then
			data.timer = RNG.randomInt(config.timermin,config.timermax)
			data.speed = 0
			if RNG.randomInt(1,2) == 1 then
				v.direction = -v.direction
			end
		else
			data.timer = RNG.randomInt(config.turntimermin,config.turntimermax)
			if RNG.randomInt(1,3) == 1 then
				data.speed = config.speed
				if RNG.randomInt(1,2) == 1 then
					v.direction = -v.direction
				end
			else
				v.direction = -v.direction
			end
		end
	end
	if data.speed <= 0 then
		data.frametimer = 0
	end
end


return yoshiGalaxy