local npcManager = require("npcManager")

--[[
# Guys that can stand on circular platforms

*They stand on platforms that are circular and circulate them*

by MarioXHK
]]
local marioGalaxy = {}

local npcutils = require("npcs/npcutils")

local IDs = {}

function marioGalaxy.register(id)
	IDs[id] = true
    npcManager.registerEvent(id, marioGalaxy, "onTickNPC")
	npcManager.registerEvent(id, marioGalaxy, "onTickEndNPC")
	npcManager.registerEvent(id, marioGalaxy, "onDrawNPC")
end

function marioGalaxy.onInitAPI()
	registerEvent(marioGalaxy, "onNPCKill")
end

-- The function that every game tick for the NPC `v`
---@param v NPC
function marioGalaxy.onTickNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data -- NPC's data
	local config = NPC.config[v.id] -- NPC config
	local settings = data._settings -- Custom extra settings

	if v.despawnTimer <= 0 then
		data.frameinit = false
		return
	end

	--Initialize
	if not data.frameinit then
		--Initialize necessary data.
		data.frameinit = true
		data.frame = 0
		data.frametimer = 0
		data.roff = 0
	end

	if data.speedY and not (config.isfloater or config.overridegravity) then
		data.speedY = math.clamp(data.speedY+Defines.npc_grav,-Defines.gravity,Defines.gravity)
		data.height = data.height-data.speedY
		if data.height then
			if data.height <= data.baseheight then
				data.height = 0
				data.speedY = 0
			end
		end
	end
end

-- Function that runs after onTick and internal smbx code for the NPC `v`
---@param v NPC
function marioGalaxy.onTickEndNPC(v)
	local config = NPC.config[v.id]
	local data = v.data

	if not (data.parent and data.parent.isValid) then
		if not config.basenpc or config.basenpc == 0 then
			v:kill(HARM_TYPE_SPINJUMP)
		else
			if data.angle <= 180 then
			v.direction = -v.direction
			end
			v:transform(config.basenpc)
		end
	end

	if config.ihandleframes or not data.frameinit then return end
	data.frametimer = data.frametimer+1
	if data.frametimer % config.framespeed == 0 then
		data.frame = data.frame + 1
		if data.frame >= config.frames then
			data.frame = 0
			data.frametimer = 0
		end
	end
end

-- Function that runs every time the screen is drawn for the NPC `v`
---@param v NPC
function marioGalaxy.onDrawNPC(v)
	local config = NPC.config[v.id]
	if not config.showme then
		npcutils.hideNPC(v)
	else
		return
	end
	if not config.npctexture then return end
	local priority = config.priority
	if not priority then
		priority = -45
	end
	if v.data.debug then
		Graphics.drawBox{
			x = v.centerX,
			y = v.centerY,
			centered = true,
			sceneCoords = true,
			priority = 0,
			width = v.width,
			height = v.height,
			color = Color(1,0,0,0.25)
		}
		Graphics.drawBox{
			x = v.centerX,
			y = v.centerY,
			centered = true,
			sceneCoords = true,
			priority = priority-1,
			width = v.width,
			height = v.height,
			color = Color(1,0,0,0.5)
		}
	end
	if v.data.hidden or not (v.data.angle and v.data.frameinit) then return end
	local data = v.data
	local frame = data.frame
	if config.framestyle ~= 0 and v.direction > 0 then
		frame = frame+config.frames
	end
	local off = config.gfxoffsetr
	if not off then
		off = 0
	end
	if data.roff < 0 then
		data.roff = data.roff+360
	end
	if data.roff > 360 then
		data.roff = data.roff-360
	end
	off = off + data.roff
	if data.invert then
		off = off + 180
		if config.framestyle ~= 0 then
			if frame == data.frame+config.frames then
				frame = data.frame
			else
				frame = data.frame+config.frames
			end
		end
	end
	local offs = {
		x = 0,
		y = 0,
	}
	if math.abs(config.gfxoffsetx)+math.abs(config.gfxoffsety) > 0 then
		offs = vector(config.gfxoffsetx,config.gfxoffsety):rotate(v.data.angle+off)
	end
	Graphics.drawBox{
		texture = config.npctexture,
		x = v.centerX+offs.x,
		y = v.centerY+offs.y,
		centered = true,
		sceneCoords = true,
		priority = priority,
		sourceX = 0,
		sourceY = frame*config.gfxheight,
		sourceWidth = config.gfxwidth,
		sourceHeight = config.gfxheight,
		rotation = v.data.angle+off,
	}
end

-- Executes when the NPC `v` gets killed by `r` reason. It also gives the eventToken `e`
---@param e EventToken
---@param v NPC
---@param r number
function marioGalaxy.onNPCKill(e,v,r)
	if not IDs[v.id] then return end
	if r == HARM_TYPE_LAVA then return end
	local t = NPC.config[v.id].transformid
	if t and (NPC.config[v.id].neededreason == -1 or r == NPC.config[v.id].neededreason or r == NPC.config[v.id].neededreason2 or r == NPC.config[v.id].neededreason3) then
		e.cancelled = true
		v.data.circling = NPC.config[t].iscircler
		if v.data.circling and v.data.height then
			v.data.height = v.data.height + (NPC.config[t].height-v.height)/2
		end
		if r == HARM_TYPE_JUMP then
			SFX.play(2)
		end
		v.id = t
		v.data.initialized = false
		if NPC.config[t].iscircler then
			v.data.frameinit = false
		end
	end
end

return marioGalaxy