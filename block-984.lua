local blockManager = require("blockManager")

--[[
# An imperfect Circle

by MarioXHK
]]
local imperfectCircle = {}

local blockID = BLOCK_ID

local function center(v,isY)
	if isY then
		return v.y+v.height/2
	else
		return v.x+v.width/2
	end
end

--Defines Block config for our Block. You can remove superfluous definitions.
local imperfectCircleSettings = {
	id = blockID,
	--Frameloop-related
	frames = 1,
	framespeed = 8, --# frames between frame change

	--Identity-related flags:
	--semisolid = false, --top-only collision
	--sizable = false, --sizable block
	passthrough = true, --no collision
	--bumpable = false, --can be hit from below
	--lava = false, --instakill
	--pswitchable = false, --turn into coins when pswitch is hit
	--smashable = 0, --interaction with smashing NPCs. 1 = destroyed but stops smasher, 2 = hit, not destroyed, 3 = destroyed like butter

	--floorslope = 0, -1 = left, 1 = right
	--ceilingslope = 0,

	--Emits light if the Darkness feature is active:
	--lightsettings.radius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	--Define custom properties below
	circleblock = true,
	speedreduction = 10,
	basebandwidth = 100,
}

blockManager.setBlockSettings(imperfectCircleSettings)

function imperfectCircle.onInitAPI()
	blockManager.registerEvent(blockID, imperfectCircle, "onTickBlock")
	blockManager.registerEvent(blockID, imperfectCircle, "onTickEndBlock")
	blockManager.registerEvent(blockID, imperfectCircle, "onDrawBlock")
	registerEvent(imperfectCircle, "onStart")
	registerEvent(imperfectCircle, "onTickEnd")
	registerEvent(imperfectCircle, "onPostEventDirect")
end

local fieldList = {"ai1", "ai2", "ai3", "ai4", "ai5", "ai6", "attachedLayerName", "deathEventName", "talkEventName", "noMoreObjInLayer", "friendly", "msg"}

local function countusers(cable)
	local count = 0
	for _,i in Block.iterate(blockID) do
		if i.isValid and i.data._settings.internet == cable then
			count = count + 1
		end
	end
	return count
end


function imperfectCircle.onStart()
	GameData.circlewifi = {}
	GameData.circledata = {}
end

function imperfectCircle.onTickEnd()
	for _,v in Block.iterate(blockID) do
		if v.data.initialized then
			local data = v.data
			local settings = data._settings
			if settings.sid ~= 0 and data.speed ~= 0 then
				local inputspeed = data.speed
				if settings.internet ~= 0 then
					inputspeed = GameData.circledata[settings.internet]
				end
				inputspeed = inputspeed*settings.sspeed
				if GameData.circlewifi[settings.sid] then
					GameData.circlewifi[settings.sid] = GameData.circlewifi[settings.sid] + inputspeed
				else
					GameData.circlewifi[settings.sid] = inputspeed
				end
			end
		end
	end
	for _,v in Block.iterate(blockID) do
		if v.data.initialized then
			local data = v.data
			local settings = data._settings
			if settings.rid ~= 0 and GameData.circlewifi[settings.rid] then
				if settings.internet == 0 then
					data.speed = GameData.circlewifi[settings.rid]*settings.rspeed
				else
					GameData.circledata[settings.internet] = GameData.circlewifi[settings.rid]*settings.rspeed
				end
			end
		end
	end
	GameData.shareingcirclewifi = GameData.circlewifi
	GameData.circlewifi = {}
end

local function blockcheck(v)
    local cfg = Block.config[v.id]
    return v.isValid and not (cfg.circleblock or v.isHidden or v:mem(0x5A, FIELD_BOOL) or cfg.semisolid or cfg.passthrough or cfg.sizable)
end

function imperfectCircle.onTickBlock(v)
    -- Don't run code for invisible entities
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	local data = v.data

	local settings = data._settings
	local step = 90/settings.step

	local centx = center(v)
	local centy = center(v,true)
	if not data.initialized then
		if Misc.resolveGraphicsFile("test.png") then
			data.dbtexture = Graphics.loadImage(Misc.resolveGraphicsFile("test.png"))
		end
		if Misc.resolveGraphicsFile("text.png") then
			data.dbfuck = Graphics.loadImage(Misc.resolveGraphicsFile("text.png"))
		end
		data.initialized = true
		local reducedspeed = settings.speed/Block.config[v.id].speedreduction
		if settings.internet == 0 then
			data.speed = reducedspeed
		else
			reducedspeed = reducedspeed*(settings.bandwidth/Block.config[v.id].basebandwidth)
			local count = countusers(settings.internet)
			if not GameData.circledata[settings.internet] then
				GameData.circledata[settings.internet] = reducedspeed/count
			else
				GameData.circledata[settings.internet] = GameData.circledata[settings.internet] + reducedspeed/count
			end
			data.speed = 0
		end
		data.id = settings.id
		for i = 0,359.9,step do
			
			local istep = i+step
			local x = centx+math.cos(i*(math.pi/180))*settings.radius*(settings.cx/10)
			local y = centy+math.sin(i*(math.pi/180))*settings.radius*(settings.cy/10)
			local width = centx+math.cos(istep*(math.pi/180))*settings.radius*(settings.cx/10)
			local height = centy+math.sin(istep*(math.pi/180))*settings.radius*(settings.cy/10)
			local yay = false
			local xfik = x > width
			local yfik = y > height
			if xfik then
				local tempx = x
				x = width
				width = tempx
			end
			if yfik then
				local tempy = y
				y = height
				height = tempy
			end
			local id = v.id
			if not (xfik or yfik) then
				yay = settings.wy
				if settings.invert then
					id = id+3
				else
					id = id+2
				end
				
			elseif xfik and yfik then
				yay = settings.xh
				if settings.invert then
					id = id+2
				else
					id = id+3
				end
			elseif xfik then
				yay = settings.wh
				if settings.invert then
					id = id+1
				else
					id = id+4
				end
			elseif yfik then
				yay = settings.xy
				if settings.invert then
					id = id+4
				else
					id = id+1
				end
			end
			local semitruck = false
			if settings.semisolid then
				if id == v.id+1 then
					id = v.id-1
					semitruck = true
				end
				if id == v.id+2 then
					id = v.id-2
					semitruck = true
				end
			end
			local janked = ((width-x)/settings.jank < (height-y) or (settings.invert and (i % 90 == 0 or istep % 90 == 0)))
			if semitruck and yay and not settings.invert then
				yay = not janked
			end
			if yay then
				if janked or settings.unslope then
					id = v.id+6
					if (settings.invert and semitruck and (i % 180 == 90 or istep % 180 == 90)) or (settings.unslope and settings.semisolid) then
						id = id - 1
					end
				end
				local w = Block.spawn(id,x,y)
				w.width = width-x
				w.height = height-y
				w.data.parent = v
				w.layerObj = v.layerObj
				w.layerName = v.layerName
				w.data.upper = not xfik
				w.data.right = not yfik
				w.data.lower = xfik
				w.data.left = yfik
				--if data.speed ~= 0 then
				--	if xfik then
				--		w.speedX = -data.speed*(settings.radius/56)
				--	else
				--		w.speedX = data.speed*(settings.radius/56)
				--	end
				--end
				if not (i % 180 == 90 or istep % 180 == 90 or semitruck or settings.invert or settings.hollow) then
					local xx = centx
					local yy = y
					local ww = x-centx
					if yfik then
						ww = width-centx
					end
					local hh = height-y
					
					local xinger = ww < 0
					if xinger then
						ww = -ww
						xx = xx-ww
					end
					
					local z = Block.spawn(v.id+6,xx,yy)
					z.height = hh
					z.width = ww
					z.data.parent = v
					z.layerObj = v.layerObj
					z.layerName = v.layerName
					z.data.upper = not xfik
					z.data.right = not yfik
					z.data.lower = xfik
					z.data.left = yfik
					z.data.filler = true
				end
			end
		end
		data.center = true
		if settings.image and Misc.resolveGraphicsFile(settings.image) then
            data.image = Graphics.loadImage(Misc.resolveGraphicsFile(settings.image))
        end
		data.rotation = settings.rotation
		data.contents = {}
		settings.contents = settings.contents or {}
		for idx,npc in ipairs(settings.contentList) do
			if npc.id ~= 0 then
				data.contents[idx] = NPC.spawn(npc.id,centx+settings.radius+NPC.config[npc.id].width/2,centy,v.section,true,true)
				local you = data.contents[idx]
				you.data.angle = npc.angle
				you.data.debug = settings.debug
				you.direction = npc.direction-1
				you.data.donotmove = npc.dontmove
				you.data.ignore = npc.ignorecircle
				you.data.npccollision = npc.bumpnpcs
				you.data.blockcollision = npc.bumpwalls
				you.data.height = npc.height
				you.data.baseheight = npc.height
				you.data.invert = settings.invert
				you.layerObj = v.layerObj
				you.layerName = v.layerName
				you.data.effecttilt = npc.tilt
				you.data.parent = v
				you.data.ignoremove = npc.ignoremove
				you.data.speedmultiplier = npc.speedmultiplier
				you.x = centx+math.cos(npc.angle*(math.pi/180))*(settings.radius*(settings.cx/10)+you.height/2+npc.height)-you.width/2
				you.y = centy+math.sin(npc.angle*(math.pi/180))*(settings.radius*(settings.cy/10)+you.height/2+npc.height)-you.height/2
				you.data.circling = true
				you.data.followXspeed = not npc.speedx
				you.data.followYspeed = not npc.speedy
				if settings.invert then
					you.direction = -you.direction
				end
				if you.direction == 0 and NPC.config[npc.id].iscircler then
					you.direction = RNG.randomSign()
				end
				for s, field in ipairs(fieldList) do
                    if npc.extra[field] ~= nil then
                        you[field] = npc.extra[field]
                    end
                end
			end
		end
	end

	if (not data.contentinit) and v.contentID > 1000 and v.contentID <= 2000 then
		local content = v.contentID-1000
		local npccfg = NPC.config[content]
		local dominant = npccfg.height
		local resessive = npccfg.width
		local yawn = resessive/2
		local radius = settings.radius
		if settings.invert then
			yawn = -yawn
			radius = radius+dominant
		end
		for i = 0+data.rotation,360+data.rotation,((360-settings.block.thickness)*npccfg.width)/(2*math.pi*radius) do
			
			local x = centx+math.cos(i*(math.pi/180))*(((settings.radius*(settings.cx/10))-yawn)+npccfg.height/2)-npccfg.width/2
			local y = centy+math.sin(i*(math.pi/180))*(((settings.radius*(settings.cy/10))-yawn)+npccfg.height/2)-npccfg.height/2

			local yay = settings.flp

			if not yay then
				local rx = centx+math.cos((i-90)*(math.pi/180))*((settings.radius*(settings.cx/10))-yawn)
				local ry = centy+math.sin((i-90)*(math.pi/180))*((settings.radius*(settings.cy/10))-yawn)
				local xfik = rx > centx
				local yfik = ry > centy
				if not (xfik or yfik) then
					yay = settings.wy
				elseif xfik and yfik then
					yay = settings.xh
				elseif xfik then
					yay = settings.wh
				elseif yfik then
					yay = settings.xy
				end
			end

			if yay then
				data.contents[#data.contents+1] = NPC.spawn(content,x,y,v.section,true,true)
				local you = data.contents[#data.contents] --here we go again!
				you.data.angle = i
				you.data.debug = settings.debug
				you.direction = 0
				you.data.donotmove = true
				you.data.ignore = true
				you.data.npccollision = false
				you.data.blockcollision = false
				you.data.height = 0
				you.data.baseheight = 0
				you.data.invert = settings.invert
				you.layerObj = v.layerObj
				you.layerName = v.layerName
				you.data.effecttilt = false
				you.data.parent = v
				you.data.ignoremove = false
				you.data.speedmultiplier = 1
				you.data.circling = true
			end
		end
	end
	data.contentinit = true



	for _,npc in ipairs(data.contents) do -- NPCS WHAT THE sigma?!
		if npc and npc.isValid and npc.data.circling then
			npc.despawnTimer = 1.1
			npc.speedX = 0
			npc.speedY = 0
			local nata = npc.data
			if nata.angle < 0 then
				nata.angle = nata.angle+360
			end
			if nata.angle > 360 then
				nata.angle = nata.angle-360
			end
			if settings.debug then
				Text.print(npc.id,100,100)
				Text.print(nata.angle,100,120)
			end
			local xheight = nata.height
			if settings.invert then
				xheight = -xheight-npc.height
			end
			
			local wid = -npc.width/2
			local hei = -npc.height/2

			local oldx = centx+math.cos(nata.angle*(math.pi/180))*(settings.radius*(settings.cx/10)-hei+xheight)+wid
			local oldy = centy+math.sin(nata.angle*(math.pi/180))*(settings.radius*(settings.cy/10)-hei+xheight)+hei
			local cfg = NPC.config[npc.id]
			local speed = cfg.speed*npc.direction
			if cfg.ihandlespeed and nata.speed then
				speed = nata.speed*npc.direction
			end
			if nata.donotmove then
				speed = 0
			end

			speed = speed*nata.speedmultiplier

			local add = speed*64.1/settings.radius

			if not nata.ignoremove then
				if settings.internet == 0 then
					add = add + data.speed
				else
					add = add + GameData.circledata[settings.internet]/(settings.bandwidth/Block.config[v.id].basebandwidth)
				end
			end
			local turn = false
			local fall = false
			if not (cfg.isfloater or nata.ignore) then
				if not (settings.wy or turn) then
					turn = nata.angle+add > 270 and nata.angle+add < 360
				end
				if not (settings.xy or turn) then
					turn = nata.angle+add > 180 and nata.angle+add < 270
				end
				if not (settings.xh or turn) then
					turn = nata.angle+add > 90 and nata.angle+add < 180
				end
				if not (settings.wh or turn) then
					turn = nata.angle+add > 0 and nata.angle+add < 90
				end
				if turn then
					if cfg.cliffturn then
						npc.direction = -npc.direction
						add = -add
					else
						fall = true
					end
				end
			end
			if not fall then
				nata.angle = nata.angle+add
			end
			
			if not (cfg.isfloater or nata.ignore) then
				if turn and not fall then
					if not (settings.wy or fall) then
						fall = nata.angle+add > 270 and nata.angle+add < 360
					end
					if not (settings.xy or fall) then
						fall = nata.angle+add > 180 and nata.angle+add < 270
					end
					if not (settings.xh or fall) then
						fall = nata.angle+add > 90 and nata.angle+add < 180
					end
					if not (settings.wh or fall) then
						fall = nata.angle+add > 0 and nata.angle+add < 90
					end
				end
			else
				fall = false
			end

			if fall or npc.id == 263 or npc.heldIndex ~= 0 or npc.isProjectile or npc.forcedState > 0 then
				npc.data.circling = false
				if cfg.iscircler then
					if (not cfg.basenpc) or cfg.basenpc == 0 then
						npc:kill(HARM_TYPE_SPINJUMP)
					else
						if nata.angle <= 180 then
						npc.direction = -npc.direction
						end
						npc:transform(cfg.basenpc)
					end
				end
			else
				npc.x = centx+math.cos(nata.angle*(math.pi/180))*(settings.radius*(settings.cx/10)-hei+xheight)+wid
				npc.y = centy+math.sin(nata.angle*(math.pi/180))*(settings.radius*(settings.cy/10)-hei+xheight)+hei
			end

			local bump = false
			if npc.data.npccollision and not (cfg.imshell and nata.speed > 0 and not nata.friendly) then
				for __, pp in NPC.iterateIntersecting(npc.x,npc.y,npc.x+npc.width,npc.y+npc.height) do
					if npc ~= pp and pp.isValid and not (pp.isHidden or NPC.config[pp.id].notouchies or (pp.noblockcollision and not NPC.config[pp.id].iscircler)) then
						bump = true
						pp.direction = -pp.direction
					end
				end
			end
			if npc.data.blockcollision then
				for __, cc in Block.iterateIntersecting(npc.x,npc.y,npc.x+npc.width,npc.y+npc.height) do
					if blockcheck(cc) then
						bump = true
						if cfg.imshell and nata.speed > 0 then
							cc:hit()
							SFX.play(3)
						end
						break
					end
				end
			end
			if bump then
				npc.direction = -npc.direction
				nata.angle = nata.angle-add
				npc.x = centx+math.cos(nata.angle*(math.pi/180))*(settings.radius*(settings.cx/10)-hei+xheight)+wid
				npc.y = centy+math.sin(nata.angle*(math.pi/180))*(settings.radius*(settings.cy/10)-hei+xheight)+hei
			end
			-- Giving the illusion of speed~
			if nata.followXspeed then
				npc.speedX = npc.layerObj.speedX+(npc.x-oldx)
			end
			if nata.followYspeed then
				npc.speedY = npc.layerObj.speedY+(npc.y-oldy)
			end

			if nata.effecttilt and not npc.isHidden then
				data.tilted = true
				local weight = npc:getWeight()
				if weight == 0 then
					weight = 1
				end
				if (center(npc) > center(v) and not settings.invert) or (center(npc) < center(v) and settings.invert) then
					speed = (weight/settings.radius)*settings.sensitivity
				else
					speed = -(weight/settings.radius)*settings.sensitivity
				end
				if settings.internet == 0 then
					data.speed = data.speed+speed
				elseif data.parent and data.parent.id then
					GameData.circledata[settings.internet] = GameData.circledata[settings.internet]+speed*(settings.bandwidth/Block.config[data.parent.id].basebandwidth)
				end
			end
		end
	end
end

function imperfectCircle.onTickEndBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	local data = v.data

	if not data.initialized then return end
	local settings = data._settings

	if settings.tilt and not data.tilted then
		if settings.internet == 0 then
			if math.abs(data.speed) > 0 then
				if data.speed < 0 then
					data.speed = data.speed+settings.friction/settings.radius
					if data.speed > 0 then
						data.speed = 0
					end
				else
					data.speed = data.speed-settings.friction/settings.radius
					if data.speed < 0 then
						data.speed = 0
					end
				end
			end
		else
			local count = countusers(settings.internet)

			if math.abs(GameData.circledata[settings.internet]) > 0 then
				if GameData.circledata[settings.internet] < 0 then
					GameData.circledata[settings.internet] = GameData.circledata[settings.internet]+(settings.friction/settings.radius)/count
					if GameData.circledata[settings.internet] > 0 then
						GameData.circledata[settings.internet] = 0
					end
				else
					GameData.circledata[settings.internet] = GameData.circledata[settings.internet]-(settings.friction/settings.radius)/count
					if GameData.circledata[settings.internet] < 0 then
						GameData.circledata[settings.internet] = 0
					end
				end
			end
		end
	end

	if settings.internet ~= 0 then
		data.speed = GameData.circledata[settings.internet]/(settings.bandwidth/Block.config[v.id].basebandwidth)
	end

	if data.speed ~= 0 then
		data.rotation = data.rotation + data.speed
		if data.rotation > 360 then
			data.rotation = data.rotation - 360
		end
	end

	data.tilted = false
end

function imperfectCircle.onDrawBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	local data = v.data
	if not data.initialized then return end
	
	local settings = data._settings

	local centx = (v.x+v.width/2)
	local centy = (v.y+v.height/2)

	local cam = camera
    local cam2 = camera2

    local boxx = centx-settings.radius*(settings.cx/7.5)
    local boxy = centy-settings.radius*(settings.cy/7.5)
	local boxw = centx+settings.radius*(settings.cx/7.5)
	local boxh = centy+settings.radius*(settings.cy/7.5)

    local can = boxw >= cam.x and boxx <= cam.x+cam.width and boxh >= cam.y and boxy <= cam.y+cam.height
    if cam2 and not can then
        can = boxw >= cam2.x and boxx <= cam2.x+cam2.width and boxh >= cam2.y and boxy <= cam2.y+cam2.height
    end

    if not can then return end

	
	if settings.debug and data.center then
		Graphics.drawBox{
			sceneCoords = true,
			priority = -10,
			x = v.x,
			y = v.y,
			width = v.width,
			height = v.height,
			color = Color(0.5,0,1,0.5)
		}
	end
	if data.image then
		Graphics.drawBox{
			texture = data.image,
			x = centx,
			y = centy,
			centered = true,
			sceneCoords = true,
			priority = settings.priority,
			sourceX = settings.gfxoffsetx,
			sourceY = settings.gfxoffsety,
			sourceWidth = data.image.width*(settings.gx/32),
			sourceHeight = data.image.height*(settings.gy/32),
			width = data.image.width*(settings.gx/32)*settings.scalex,
			height = data.image.height*(settings.gy/32)*settings.scaley,
			rotation = data.rotation,
		}
	end
	if settings.block.allow then
		if settings.block.id and settings.block.id > 0 and settings.block.id <= 2000 then
			if not data.blockimage then
				data.blockimage = Graphics.sprites.block[settings.block.id].img
			end
			local sprite = data.blockimage
			local dominant = sprite.height/Block.config[settings.block.id].frames
			local resessive = sprite.width
			if settings.block.usewidth then
				dominant = sprite.width
				resessive = sprite.height/Block.config[settings.block.id].frames
			end
			local yawn = resessive/2
			local radius = settings.radius
			if settings.invert then
				yawn = -yawn
				radius = radius+dominant
			end
			for i = 0+data.rotation,360+data.rotation,((360-settings.block.thickness)*dominant)/(2*math.pi*radius) do
				
				local x = centx+math.cos(i*(math.pi/180))*(((settings.radius*(settings.cx/10))-yawn)+settings.block.inflate)
				local y = centy+math.sin(i*(math.pi/180))*(((settings.radius*(settings.cy/10))-yawn)+settings.block.inflate)

				local yay = settings.block.exrender
				if not yay then
					local rx = centx+math.cos((i-90)*(math.pi/180))*((settings.radius*(settings.cx/10))-yawn)
					local ry = centy+math.sin((i-90)*(math.pi/180))*((settings.radius*(settings.cy/10))-yawn)
					local xfik = rx > centx
					local yfik = ry > centy
					if not (xfik or yfik) then
						yay = settings.wy
					elseif xfik and yfik then
						yay = settings.xh
					elseif xfik then
						yay = settings.wh
					elseif yfik then
						yay = settings.xy
					end
				end
				
				if yay then
					local rboxlimit = sprite.width+(sprite.height/Block.config[settings.block.id].frames)

					yay = x+rboxlimit >= cam.x and x-rboxlimit <= cam.x+cam.width and y+rboxlimit >= cam.y and y-rboxlimit <= cam.y+cam.height
					if cam2 and not yay then
						yay = x+rboxlimit >= cam2.x and x-rboxlimit <= cam2.x+cam2.width and y+rboxlimit >= cam2.y and y-rboxlimit <= cam2.y+cam2.height
					end
				end

				if yay then
					Graphics.drawBox{
						texture = sprite,
						sceneCoords = true,
						priority = settings.block.priority,
						centered = true,
						x = x,
						y = y,
						sourceX = settings.block.gfxoffsetx,
						sourceY = settings.block.gfxoffsety,
						sourceWidth = sprite.width*(settings.block.gx/32),
						sourceHeight = sprite.height*(settings.block.gy/32),
						width = sprite.width,
						height = sprite.height/Block.config[settings.block.id].frames,
						rotation = i+settings.block.rotation,
					}
				end
			end
		end
		if (not settings.invert) and settings.block.nid and settings.block.nid > 0 and settings.block.nid <= 2000 then
			if not data.blockimage2 then
				data.blockimage2 = Graphics.sprites.block[settings.block.nid].img
			end
			local sprite = data.blockimage2
			local dominant = sprite.height/Block.config[settings.block.nid].frames
			local resessive = sprite.width
			if settings.block.usewidth2 then
				dominant = sprite.width
				resessive = sprite.height/Block.config[settings.block.nid].frames
			end
			local yawn = resessive/2
			local radius = settings.radius
			if settings.invert then
				yawn = -yawn
				radius = radius+dominant
			end
			for h = radius-yawn, 0+(resessive*settings.block.depth),-(resessive*(settings.block.space/10)) do
				for i = 0+data.rotation,360+data.rotation,((360-settings.block.thickness)*dominant)/(2*math.pi*h) do
				
					local x = centx+math.cos(i*(math.pi/180))*((h*(settings.cx/10)-yawn)+settings.block.inflate)
					local y = centy+math.sin(i*(math.pi/180))*((h*(settings.cy/10)-yawn)+settings.block.inflate)

					local yay = settings.block.exrender

					if not yay then
						local rx = centx+math.cos((i-90)*(math.pi/180))*(h*(settings.cx/10)-yawn)
						local ry = centy+math.sin((i-90)*(math.pi/180))*(h*(settings.cy/10)-yawn)
						local xfik = rx > centx
						local yfik = ry > centy
						if not (xfik or yfik) then
							yay = settings.wy
						elseif xfik and yfik then
							yay = settings.xh
						elseif xfik then
							yay = settings.wh
						elseif yfik then
							yay = settings.xy
						end
					end
					
					if yay then
						local rboxlimit = sprite.width+sprite.height/Block.config[settings.block.nid].frames

						yay = x+rboxlimit >= cam.x and x-rboxlimit <= cam.x+cam.width and y+rboxlimit >= cam.y and y-rboxlimit <= cam.y+cam.height
						if cam2 and not yay then
							yay = x+rboxlimit >= cam2.x and x-rboxlimit <= cam2.x+cam2.width and y+rboxlimit >= cam2.y and y-rboxlimit <= cam2.y+cam2.height
						end
					end
					
					
					if yay then
						Graphics.drawBox{
							texture = sprite,
							sceneCoords = true,
							priority = settings.block.priority-0.1,
							centered = true,
							x = x,
							y = y,
							sourceX = settings.block.gfxoffsetx,
							sourceY = settings.block.gfxoffsety,
							sourceWidth = sprite.width*(settings.block.gx/32),
							sourceHeight = sprite.height*(settings.block.gy/32),
							width = sprite.width,
							height = sprite.height/Block.config[settings.block.nid].frames,
							rotation = i+settings.block.rotation2,
						}
					end
				end
			end
		end
	end

end

function imperfectCircle.onPostEventDirect(eventName)
	for _,v in Block.iterate(blockID) do
		if v.data.initialized then
			local data = v.data
			local settings = data._settings
			for __,e in ipairs(settings.events) do
				if e.name == eventName then
					local reducedspeed = e.speed/Block.config[v.id].speedreduction
					if e.add then
						if settings.internet == 0 then
							reducedspeed = reducedspeed+data.speed
						else
							if GameData.circledata[settings.internet] then
								reducedspeed = GameData.circledata[settings.internet]+data.speed
							end
						end
					end
					if settings.internet == 0 then
						data.speed = reducedspeed
					else
						reducedspeed = reducedspeed*(settings.bandwidth/Block.config[v.id].basebandwidth)
						local count = countusers(settings.internet)
						if not GameData.circledata[settings.internet] then
							GameData.circledata[settings.internet] = reducedspeed/count
						else
							GameData.circledata[settings.internet] = GameData.circledata[settings.internet] + reducedspeed/count
						end
						data.speed = 0
					end
					break
				end
			end
		end
	end
end

return imperfectCircle