local npcManager = require("npcManager")

--[[
# Rolling things on rolling hills
*Cool things that are visually rolling*

by MarioXHK
]]
local marioGalaxy = {}

function marioGalaxy.register(id)
	npcManager.registerEvent(id, marioGalaxy, "onTickEndNPC")
end

-- Function that runs after onTick and internal smbx code for the NPC `v`
---@param v NPC
function marioGalaxy.onTickEndNPC(v)
	local config = NPC.config[v.id]
	local data = v.data
	if not (data.frameinit and data.parent) then return end
	local speed = config.speed
	if config.ihandlespeed then
		speed = data.speed
	end

	data.roff = data.roff+speed*(data.parent.data._settings.radius/((v.width+v.height)/2))*v.direction

	Text.print(data.roff,500,100)
end

return marioGalaxy