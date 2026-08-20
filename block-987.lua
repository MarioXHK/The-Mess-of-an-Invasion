local blockManager = require("blockManager")

local fake = {}

local blockID = BLOCK_ID

local rotate = require("AI/circleslope")

local fakeSettings = {
	id = blockID,
	--Frameloop-related
	frames = 1,
	framespeed = 8, --# frames between frame change
	ceilingslope = 1,
	semisolid = false,
	circleblock = true,
}

blockManager.setBlockSettings(fakeSettings)

rotate.register(blockID)

return fake