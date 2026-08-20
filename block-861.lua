-- Bad mood. No comments for you other than this one. Unlikely anyone will even care enough to look at these or have the correct VScode addons installed to view correctly.
local blockManager = require("blockManager")
local whoAskedForThis = {}
local blockID = BLOCK_ID
local whoAskedForThisSettings = {
	id = blockID,
	frames = 1,
	framespeed = 8,
	passthrough = true,
}
blockManager.setBlockSettings(whoAskedForThisSettings)
local TYPE = {
    BLOCK = 0,
    BGO = 1,
	NPC = 2,
	FLUID = 3,
	WARP = 4,
	ENTRANCE = 5,
	EXIT = 6,
	ALL = 7,
}
local NuhUh = {
	"Default",
	"Destroyed Blocks",
	"Spawned NPCs",
}
function whoAskedForThis.onInitAPI()
	blockManager.registerEvent(blockID, whoAskedForThis, "onTickBlock")
	blockManager.registerEvent(blockID, whoAskedForThis, "onTickEndBlock")
end
local function checkLayer(v,settings,mylayer)
	if v.layerName == mylayer then return false end -- things of the same layer can't do fudge to eachother
	local yuhuh = true
	local l = nil
	if settings.layer == "" then
		for o,h in ipairs(NuhUh) do
			if v.layerName == h then
				yuhuh = false
				break
			end
		end
	else
		yuhuh = v.layerName == settings.layer
	end
	if yuhuh then
		local layer = Layer.get(v.layerName)
		if settings.left and layer.speedX < 0 then
			l = layer
		elseif settings.right and layer.speedX > 0 then
			l = layer
		elseif settings.up and layer.speedY < 0 then
			l = layer
		elseif settings.down and layer.speedY > 0 then
			l = layer
		elseif not (settings.left or settings.right or settings.up or settings.down) then
			if layer.speedX == 0 and layer.speedY == 0 then
				l = layer
			end
		end
	end
	return l
end
local function hidden(v,s)
	return (v.isHidden and s.blind)
end
function whoAskedForThis.onTickBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	local data = v.data
	local settings = data._settings
	if not data.initialized then
		data.initialized = true
		data.movingLayers = {}
	end
	if settings.typo == TYPE.ALL or settings.typo == TYPE.BLOCK then
		for _,b in Block.iterateIntersecting(v.x,v.y,v.right,v.bottom) do
			if b ~= v and (settings.id == 0 or settings.id == b.id) and not hidden(b,settings) then
				local l = checkLayer(b,settings,v.layerName)
				if l then
					data.movingLayers[#data.movingLayers+1] = l
				end
			end
		end
	end
	if settings.typo == TYPE.ALL or settings.typo == TYPE.NPC then
		for _,n in NPC.iterateIntersecting(v.x,v.y,v.right,v.bottom) do
			if (settings.id == 0 or settings.id == n.id) and not hidden(n,settings) then
				local l = checkLayer(n,settings,v.layerName)
				if l then
					data.movingLayers[#data.movingLayers+1] = l
				end
			end
		end
	end
	if settings.typo == TYPE.ALL or settings.typo == TYPE.BGO then
		for _,g in BGO.iterateIntersecting(v.x,v.y,v.right,v.bottom) do
			if (settings.id == 0 or settings.id == g.id) and not hidden(g,settings) then
				local l = checkLayer(g,settings,v.layerName)
				if l then
					data.movingLayers[#data.movingLayers+1] = l
				end
			end
		end
	end
	if settings.typo == TYPE.ALL or settings.typo == TYPE.FLUID then
		for _,f in ipairs(Liquid.getIntersecting(v.x,v.y,v.right,v.bottom)) do
			if (settings.id == 0 or (settings.id % 2 == 0) == (f.isQuicksand)) and not hidden(f,settings) then
				local l = checkLayer(f,settings,v.layerName)
				if l then
					data.movingLayers[#data.movingLayers+1] = l
				end
			end
		end
	end
	if settings.typo == TYPE.ALL or settings.typo == TYPE.WARP or settings.typo == TYPE.ENTRANCE then
		for _,f in ipairs(Warp.getIntersectingEntrance(v.x,v.y,v.right,v.bottom)) do
			if not hidden(f,settings) then
				local l = checkLayer(f,settings,v.layerName)
				if l then
					data.movingLayers[#data.movingLayers+1] = l
				end
			end
		end
	end

	if settings.typo == TYPE.ALL or settings.typo == TYPE.WARP or settings.typo == TYPE.EXIT then
		for _,f in ipairs(Warp.getIntersectingExit(v.x,v.y,v.right,v.bottom)) do
			if not hidden(f,settings) then
				local l = checkLayer(f,settings,v.layerName)
				if l then
					data.movingLayers[#data.movingLayers+1] = l
				end
			end
		end
	end

	if data.movingLayers and #data.movingLayers > 0 then
		if settings.correct then
			for _,l in ipairs(data.movingLayers) do
				if settings.doX then
					l.speedX = -l.speedX
				end
				if settings.doY then
					l.speedY = -l.speedY
				end
			end
		end
		local event = settings.event
		if event and event ~= "" then
			triggerEvent(event)
		end
	end
end
function whoAskedForThis.onTickEndBlock(v)
	if not v.data.initialized then return end
	local data = v.data
	local settings = data._settings
	if data.movingLayers and #data.movingLayers > 0 then
		for _,l in ipairs(data.movingLayers) do
			if settings.doX then
				l.speedX = settings.speedX
				if settings.addme then
					l.speedX = l.speedX + Layer.get(v.layerName).speedX
				end
			end
			if settings.doY then
				l.speedY = settings.speedY
				if settings.addme then
					l.speedY = l.speedY + Layer.get(v.layerName).speedY
				end
			end
		end
		if settings.destroy then
			v:remove()
		end
	end
	data.movingLayers = {}
end
return whoAskedForThis