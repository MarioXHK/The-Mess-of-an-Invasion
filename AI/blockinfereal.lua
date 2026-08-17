--Stubborn vanilla blocks wanna keep their size? Too bad :D
local inferred = {}

local blockManager = require("blockManager")

function inferred.register(id)
    blockManager.registerEvent(id, inferred, "onTickBlock")
    blockManager.registerEvent(id, inferred, "onStartBlock")
end

-- The function that every game tick for the block `v`
---@param v Block
function inferred.onTickBlock(v)
    local sprite = Graphics.sprites.block[v.id].img
    local config = Block.config[v.id]
    if sprite then
        if v.width ~= sprite.width then
            v.width = sprite.width
        end
        local height = sprite.height
        if config.frames and config.frames > 1 then
            height = height/config.frames
        end
        if v.height ~= height then
            v.height = height
        end
    end
end

-- The function that at the start of the level for the block `v`
---@param v Block
function inferred.onStartBlock(v)
    local sprite = Graphics.sprites.block[v.id].img
    local config = Block.config[v.id]
    if sprite then
        if v.width ~= sprite.width then
            v.width = sprite.width
        end
        local height = sprite.height
        if config.frames and config.frames > 1 then
            height = height/config.frames
        end
        if v.height ~= height then
            v.height = height
        end
    end
end

return inferred