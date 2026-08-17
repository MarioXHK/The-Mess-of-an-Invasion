local blockManager = require("blockManager")

local sampleBlock = {}
local blockID = BLOCK_ID

local inferred = require("AI/blockinfereal")

inferred.register(blockID)

local sampleBlockSettings = {
	id = blockID,
	--Frameloop-related
	frames = 1,
	framespeed = 8, --# frames between frame change

	passthrough=true,semisolid=false,lava=false,floorslope=0,ceilingslope=0,walkpaststair=false,bumpable=false,noshadows = true,lightradius=0,
	-- If the block is a path that can be walked on
	isenemypath = true,
	-- Corner type. 0: no corner, 1: top left, 2: top right, 3: bottom left, 4: bottom right
	pathcorner = 1,
	-- If the block changes the music
	changemusic = false,
}

blockManager.setBlockSettings(sampleBlockSettings)

function sampleBlock.onInitAPI()
	blockManager.registerEvent(blockID, sampleBlock, "onTickBlock")
	--blockManager.registerEvent(blockID, sampleBlock, "onTickEndBlock")
	--blockManager.registerEvent(blockID, sampleBlock, "onDrawBlock")
	--registerEvent(sampleBlock, "onBlockHit")
	--registerEvent(sampleBlock, "onPostBlockHit")
end

function sampleBlock.onBlockHit(event, v, upper, p) -- "event" eventToken, "v" hitBlock, "upper" fromUpper, "p" playerOrNil
	if v.id ~= BLOCK_ID then return end
end

function sampleBlock.onPostBlockHit(v, upper, p)
	if v.id ~= BLOCK_ID then return end
end

function sampleBlock.onTickBlock(v)
    -- Don't run code for invisible entities
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	local data = v.data -- Block's data
	local config = Block.config[v.id] -- Block config
	local settings = data._settings -- Custom extra settings

	if not data.initialized then
		data.initialized = true
		-- data here
	end
end

return sampleBlock