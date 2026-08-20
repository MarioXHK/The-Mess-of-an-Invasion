local blockManager = require("blockManager")
local sampleBlock = {}
local blockID = BLOCK_ID
local sampleBlockSettings = {
	id = blockID,
	frames = 1,
	framespeed = 8,
	passthrough = true,
	nopassthrough = true, -- I'm 100% not a passthrough block trust me I'm a dolphin
}

blockManager.setBlockSettings(sampleBlockSettings)

return sampleBlock