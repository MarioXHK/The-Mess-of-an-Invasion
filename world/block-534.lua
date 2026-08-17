local blockManager = require("blockManager")

local sampleBlock = {}
local blockID = BLOCK_ID

local sampleBlockSettings = {
	id = blockID,
	--Frameloop-related
	frames = 1,
	framespeed = 8, --# frames between frame change

	--Identity-related flags:
	--semisolid = false, --top-only collision
	sizable = true, --sizable block
	passthrough = true, --no collision
	--bumpable = false, --can be hit from below
	--lava = false, --instakill
	--pswitchable = false, --turn into coins when pswitch is hit
	--smashable = 0, --interaction with smashing NPCs. 1 = destroyed but stops smasher, 2 = hit, not destroyed, 3 = destroyed like butter

	--floorslope = 0, -1 = left, 1 = right
	--ceilingslope = 0,

	--Emits light if the Darkness feature is active:
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	-- Custom properties below
	freeroamzone = true,
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