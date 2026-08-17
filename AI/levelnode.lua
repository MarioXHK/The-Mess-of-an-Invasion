local node = {}

local ids = {}

local npcManager = require("npcManager")

local npcutils = require("npcs/npcutils")

local map = require("smb3map")

--[[
Registers an NPC's `id` as a Node tile

as a Node tile, it can do...not that many things honestly. This is just here so they can follow with layer movements
]]
function node.register(id)
    ids[id] = true
    npcManager.registerEvent(id, node, "onTickNPC")
	--npcManager.registerEvent(id, node, "onTickEndNPC")
	--npcManager.registerEvent(id, node, "onDrawNPC")
	--npcManager.registerEvent(id, node, "onCameraDrawNPC")
    --npcManager.registerEvent(id, node, "onStartNPC")
end

function node.onInitAPI()
    --registerEvent(node, "onPostBlockHit")
    --registerEvent(node, "onNPCHarm")
    --registerEvent(node, "onPostNPCKill")
end

local directions = {
    "up",
    "down",
    "left",
    "right"
}

function node.onStartNPC(v)
    local data = v.data
    local settings = data._settings
    local nodesave = SaveData.smb3map[settings.nodeFilename]
end

node.winframes = 18

-- The function that every game tick for the NPC `v`
---@param v NPC
function node.onTickNPC(v)
    local data = v.data
	local config = NPC.config[v.id]
	local settings = v.data._settings

    v.despawnTimer = 2

    if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

    v.collisionGroup = "Node Tile"

    if not data.initialized then
        data.initialized = true
    end

    v.x = v.x+v.layerObj.speedX
    v.y = v.y+v.layerObj.speedY
end

return node