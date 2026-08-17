local mapitem = {}

local ids = {}

local map = require("smb3map")

local function dropItem(id)
    player.reservePowerup = id
end


--[[
Registers an NPC's `id` as only something that can be used on the map and is kept in the player's reserve.

can include cheats that give the item.
]]
function mapitem.register(id,cheats)
    ids[id] = true
    if type(cheats) == "nil" then return end
    if type(cheats) ~= "table" then
        cheats = {tostring(cheats)}
    end
    local aliases = table.iclone(cheats)

    local cheater = table.remove(aliases, 1)
    Cheats.register(cheater,{
        onActivate = function ()
            dropItem(id)
            return true
        end,
        aliases = aliases,
        activateSFX = 12,
    })
end

function mapitem.onInitAPI()
    registerEvent(mapitem, "onNPCCollect")
end

-- Executes *immediately* when any NPC is collected. Passes the NPC `v`, the player that collected it `p`, and a token `e` that can be used to cancel the death.
---@param e EventToken
---@param v NPC
---@param p Player
function mapitem.onNPCCollect(e,v,p)
    if not ids[v.id] then return end
    if Level.filename() == map.levelFilename and not map.enteringlevel then return end
    e.cancelled = true
    if not map.enteringlevel then
       SFX.play(12) 
    end
    p.reservePowerup = v.id
    v:kill(HARM_TYPE_VANISH)
end

return mapitem