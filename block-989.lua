local blockManager = require("blockManager")

local fake = {}

local blockID = BLOCK_ID

local rotate = require("AI/circleslope")

local fakeSettings = {
	id = blockID,
	--Frameloop-related
	frames = 1,
	framespeed = 8,
	semisolid = true,
	circleblock = true,
}

blockManager.setBlockSettings(fakeSettings)

rotate.register(blockID)

return fake