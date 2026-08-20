local blockManager = require("blockManager")

-- The slopes that make up a circular platform (or as other people call it a "rolling hill")
local rotaryPhone = {}

rotaryPhone.base = 980

local blockutils = require("blocks/blockutils")

local IDs = {}

function rotaryPhone.register(id)
	IDs[id] = true
    blockManager.registerEvent(id, rotaryPhone, "onTickBlock")
    blockManager.registerEvent(id, rotaryPhone, "onTickEndBlock")
    blockManager.registerEvent(id, rotaryPhone, "onDrawBlock")
end

function rotaryPhone.onInitAPI()
	registerEvent(rotaryPhone, "onTickEnd")
    --registerEvent(rotaryPhone, "onBlockHit")
    --registerEvent(rotaryPhone, "onPostEventDirect")
end

-- checks if a block is real and isn't a semisolid or passthrough
---@param v Block
---@return boolean
local function blockcheck(v)
    local cfg = Block.config[v.id]
    local yeah = v.isValid and not (cfg.circleblock or v.isHidden or v:mem(0x5A, FIELD_BOOL) or cfg.semisolid or cfg.passthrough or cfg.sizable or cfg.circleignore)
    if yeah then
        --SFX.play(1)
        return true
    else
        return false
    end
end

-- returns if something is moving
---@param l Layer
---@return boolean
local function isMoving(l)
    return math.abs(l.speedX)+math.abs(l.speedY) > 0
end

-- returns if a block is actually a fake
---@param v Block
---@return boolean
local function isfake(v)
    return Block.config[v.id].nopassthrough and not v.isHidden
end

-- Recalculates the slope `v`'s dimensions based on any blocks that are in it
---@param v Block
local function recalculate(v)
    if not (v.data.initialized and v.data.parent) then return end
    local data = v.data
    local originalX = (v.x-data.addedX)
    local originalY = (v.y-data.addedY)
    local minusX = 0
    local minusY = 0
    local top = 0
    local bot = 0
    local left = 0
    local right = 0
    local width = data.spawnWidth
    local height = data.spawnHeight
    local centx = originalX+width/2
    local centy = originalY+height/2
    local settings = v.data.parent.data._settings
    --if not data.calcolliders then
    --    data.calcolliders = {
    --        Colliders.Point(centx,originalY),
    --        Colliders.Point(centx,originalY+data.spawnHeight),
    --        Colliders.Point(originalX,centy),
    --        Colliders.Point(originalX+data.spawnWidth,centy),
    --    }
    --end
    --local col = data.calcolliders
    --col[1].x = centx
    --col[2].x = centx
    --col[3].y = centy
    --col[4].y = centy

    --col[1].y = originalY
    --col[2].y = originalY+data.spawnHeight
    --col[3].x = originalX
    --col[4].x = originalX+data.spawnWidth

    --for _,b in Block.iterate() do
    --    if isfake(b) or blockcheck(b) then
    --        if Colliders.collide(b,col[1]) and top ~= 1 then
    --            minusY = (b.y+b.height)-originalY
    --            top = 1
    --        elseif Colliders.collide(b,col[2]) and bot ~= 1 then
    --            height = b.y-originalY
    --            bot = 1
    --        elseif Colliders.collide(b,col[3]) and left ~= 1 then
    --            minusX = b.right-originalX
    --            left = 1
    --        elseif Colliders.collide(b,col[3]) and right ~= 1 then
    --            width = b.x-originalX
    --            right = 1
    --        end
    --        if top == 1 and bot == 1 and left == 1 and right == 1 then
    --            break
    --        end
    --    end
    --end
    for _,b in Block.iterateIntersecting(centx,originalY,centx,originalY) do
        if isfake(b) or blockcheck(b) then
            minusY = (b.y+b.height)-originalY
            top = 1
            --break
        end
    end
    for _,b in Block.iterateIntersecting(centx,originalY+data.spawnHeight,centx,originalY+data.spawnHeight) do
        if isfake(b) or blockcheck(b) then
            height = b.y-originalY
            bot = 1
            break
        end
    end
    for _,b in Block.iterateIntersecting(originalX,centy,originalX,centy) do
        if isfake(b) or blockcheck(b) then
            minusX = b.right-originalX
            left = 1
            --break
        end
    end
    for _,b in Block.iterateIntersecting(originalX+data.spawnWidth,centy,originalX+data.spawnWidth,centy) do
        if isfake(b) or blockcheck(b) then
            width = b.x-originalX
            right = 1
            --break
        end
    end
    if minusY ~= 0 then
        v.y = originalY+minusY
        data.addedY = minusY
    end
    if minusX ~= 0 then
        v.x = originalX+minusX
        data.addedX = minusX
    end
    v.height = height-minusY
    v.width = width-minusX
    local sides = top + bot + left + right
    local cfg = Block.config[v.data.spawnID]
    local squeezetb = (top == 1 and cfg.floorslope ~= 0) or (bot == 1 and cfg.ceilingslope ~= 0)
    local squeezesides = (left == 1 and (cfg.floorslope < 0 or cfg.ceilingslope > 0)) or (right == 1 and (cfg.floorslope > 0 or cfg.ceilingslope < 0))
    if sides >= 3 then
        if sides >= 4 or data.filler then
            v.id = rotaryPhone.base+1
        else
            v.id = rotaryPhone.base+10
        end
        v.x = originalX
        v.y = originalY
        v.width = data.spawnWidth
        v.height = data.spawnHeight
        v.data.addedX = 0
        v.data.addedY = 0
    elseif squeezetb or squeezesides or math.abs(v.width-v.x)/settings.jank < math.abs(v.height-v.y) then
        data.squeezed = true
        if squeezetb or squeezesides then
            v.id = rotaryPhone.base+10
        end
    else
        v.id = data.spawnID
    end
    if sides == 0 then
        v.width = data.spawnWidth
        v.height = data.spawnHeight
        v.data.addedX = 0
        v.data.addedY = 0
    end
    data.calculationframes = data.calculationframes - 1
    if data.calculationframes <= 0 then
        data.calculated = true
        data.calculationframes = settings.cframes
    end
    if settings.debug then
        Text.print("Calculated movement!",100,200)
    end
end

-- The function that every game tick for the block `v`
---@param v Block
function rotaryPhone.onTickBlock(v)
    if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end

    local data = v.data
    local cnfg = Block.config[v.id]

    if not data.initialized then
        data.initialized = true
        data.speedX = 0
        data.spawnWidth = v.width
        data.spawnHeight = v.height
        data.addedX = 0
        data.addedY = 0
        data.spawnID = v.id
        data.calculated = false
        data.calculationframes = 1
        data.squeezed = false
    end
    local crush = false
    if data.parent then
        if data.parent.isValid then
            local pata = data.parent.data
            local speed = pata.speed
            local settings = pata._settings
            -- Squeezement
            data.squeezed = false
            if settings.squeeze and not data.calculated then
                recalculate(v)
            end

            -- Movement
            if settings.internet ~= 0 then
                speed = GameData.circledata[settings.internet]/(settings.bandwidth/Block.config[data.parent.id].basebandwidth)
            end
            crush = settings.crush
            if settings.tilt and not data.filler then -- Tilt controls!
                local tilted = false
                local extra = 1
                if settings.invert and cnfg.floorslope == 0 and cnfg.ceilingslope == 0 then
                    extra = 0
                end
                if cnfg.ceilingslope == 0 and not settings.ignoreplayer then
                    for _,p in ipairs(Player.getIntersecting(v.x-extra,v.y-extra,v.x+v.width+extra,v.y+v.height+extra)) do
                        if p.isValid and p:isOnGround() then
                            tilted = true
                            local weight = p:getWeight()
                            if weight == 0 then
                                weight = 1
                            end
                            if data.right then
                                if pata.conditioned then
                                    pata.conditioned = pata.conditioned + (weight/settings.radius)*settings.sensitivity
                                else
                                    speed = speed + (weight/settings.radius)*settings.sensitivity
                                end
                            else

                                if pata.conditioned then
                                    pata.conditioned = pata.conditioned - (weight/settings.radius)*settings.sensitivity
                                else
                                    speed = speed - (weight/settings.radius)*settings.sensitivity
                                end
                            end
                        end
                    end
                end
                if not settings.ignorenpc then
                    for _,w in NPC.iterateIntersecting(v.x-extra,v.y-extra,v.x+v.width+extra,v.y+v.height+extra) do
                        if (not w.isHidden) and w.isValid and (w.collidesBlockBottom or (w.data.circling and w.data.effecttilt)) and not (w.data.circling and not w.data.effecttilt) then
                            tilted = true
                            local weight = w:getWeight()
                            if weight == 0 then
                                weight = 1
                            end
                            if data.right then
                                speed = speed + (weight/settings.radius)*settings.sensitivity
                            else
                                speed = speed - (weight/settings.radius)*settings.sensitivity
                            end
                        end
                    end
                end
                
                if tilted then
                    pata.tilted = tilted
                end
                
                if math.abs(speed) > settings.tv then
                    if speed < 0 then
                        speed = -settings.tv
                    else
                        speed = settings.tv
                    end
                end
            end
            data.speedX = -speed*(settings.radius/56)
            if data.upper then
                data.speedX = -data.speedX
            end
            if settings.internet == 0 then
                pata.speed = speed
            else
                GameData.circledata[settings.internet] = speed*(settings.bandwidth/Block.config[data.parent.id].basebandwidth)
            end
        else
            v:remove()
        end
    end
    if v.layerName ~= "Default" and (cnfg.floorslope ~= 0 or cnfg.ceilingslope ~= 0) and isMoving(v.layerObj) then
        for _,p in ipairs(Player.getIntersecting(v.x-1,v.y-1,v.x+v.width+1,v.y+v.height+1)) do
            if p.isValid and p.isOnGround and not p.data.spud then
                p.data.spud = data.speedX
                p.data.ignorecrush = crush
            end
        end
        for _,x in NPC.iterateIntersecting(v.x-1,v.y-1,v.x+v.width+1,v.y+v.height+1) do
            if x.isValid and x.collidesBlockBottom and not (x.data.spud or x.isHidden) then
                x.data.spud = data.speedX
                x.data.ignorecrush = crush
            end
        end
    else
        v.speedX = data.speedX
    end
end

local layerHideStates = {}

-- The function that every game tick, right before internal smbx code runs
function rotaryPhone.onTick()
    for _,i in ipairs(Layer.get()) do
        layerHideStates[_] = i.isHidden
    end
end

-- Function that runs after onTick and internal smbx code
function rotaryPhone.onTickEnd()
    for _,i in ipairs(Layer.get()) do
        if i.isHidden ~= layerHideStates[_] then
            for __,t in ipairs(IDs) do
                if t then
                    for ___,v in NPC.iterate(__) do
                        v.data.calculated = false
                    end
                end
            end
            break
        end
    end
    for _,p in ipairs(Player.get()) do
        if p.data.spud then
            local can = true
            if not p.data.ignorecrush then
                if p.data.spud > 0 then
                    for _,v in Block.iterateIntersecting(p.right,p.y,p.right+math.abs(p.data.spud),p.bottom) do
                        if blockcheck(v) and not (Block.config[v.id].floorslope and Block.config[v.id].floorslope < 0) then
                            can = false
                            break
                        end
                    end
                else
                    for _,v in Block.iterateIntersecting(p.x-math.abs(p.data.spud),p.y,p.x,p.bottom) do
                        if blockcheck(v) and not (Block.config[v.id].floorslope and Block.config[v.id].floorslope > 0) then
                            can = false
                            break
                        end
                    end
                end
            end
            if can then
                p.x = p.x + p.data.spud
            end
            p.data.spud = false
        end
    end
    local uncalculate = true
    for _,p in NPC.iterate() do
        --if p.despawnTimer <= 0 then
        --    if uncalculate and p.attachedLayerObj and p.attachedLayerName and p.attachedLayerName ~= "" then
        --        uncalculate = false
        --        for __,t in ipairs(IDs) do
        --            if t then
        --                for ___,v in NPC.iterate(__) do
        --                    v.data.calculated = false
        --                end
        --            end
        --        end
        --    end
        --end
        if p.data.spud then
            local can = true
            if not p.data.ignorecrush then
                if p.data.spud > 0 then
                    for _,v in Block.iterateIntersecting(p.right,p.y,p.right+math.abs(p.data.spud),p.bottom) do
                        if blockcheck(v) and not (Block.config[v.id].floorslope and Block.config[v.id].floorslope < 0) then
                            can = false
                            break
                        end
                    end
                else
                    for _,v in Block.iterateIntersecting(p.x-math.abs(p.data.spud),p.y,p.x,p.bottom) do
                        if blockcheck(v) and not (Block.config[v.id].floorslope and Block.config[v.id].floorslope > 0) then
                            can = false
                            break
                        end
                    end
                end
            end
            if can then
                p.x = p.x + p.data.spud
            end
            p.data.spud = false
        end
    end
end

-- Function that runs after onTick and internal smbx code for the block `v`
---@param v Block
function rotaryPhone.onTickEndBlock(v)
    if isMoving(v.layerObj) then
        v.data.calculated = false
    end
end

-- Function that runs every time the screen is drawn for the block `v`
---@param v Block
function rotaryPhone.onDrawBlock(v)
    if v.isHidden or not (v.data.initialized and v.data.parent) then return end
    local data = v.data
    local settings = v.data.parent.data._settings

	local cam = camera
    local cam2 = camera2

    --Text.print(tostring(v.id)[3],v.x-camera.x,v.y-camera.y)

    if not (blockutils.visible(cam,v.x,v.y,v.width,v.height) or blockutils.visible(cam2,v.x,v.y,v.width,v.height)) then return end

    if not settings.debug then return end

    local r = 0
    local g = 0
    local b = 0
    local a = 1
    local vertx = {
            v.x,
            v.y,
            v.x+v.width,
            v.y,
            v.x+v.width,
            v.y+v.height,
            v.x,
            v.y+v.height,
        }
    local vtext = {
            0,
            0,
            1,
            0,
            1,
            1,
            0,
            1,
        }
    if v.id == rotaryPhone.base+10 then
        r = 1
        g = 0
        b = 1
        if v.width/settings.jank < v.height  then
            g = 1
            b = 0
        end
        if data.squeezed then
            r = 0
            g = 1
            b = 1
        end
    elseif v.id == rotaryPhone.base+1 then
        a = a/2
    else
        if not (data.lower or data.left) then
            r = 1
            g = 1
            b = 1
            if settings.invert then
                for j = 1,2 do
                    table.remove(vertx,7)
                    table.remove(vtext,7)
                end
            else
                for j = 1,2 do
                    table.remove(vertx,3)
                    table.remove(vtext,3)
                end
            end
        elseif data.lower and data.left then
            g = 1
            if settings.invert then
                for j = 1,2 do
                    table.remove(vertx,3)
                    table.remove(vtext,3)
                end
            else
                for j = 1,2 do
                    table.remove(vertx,7)
                    table.remove(vtext,7)
                end
            end
        elseif data.lower then
            b = 1
            if settings.invert then
                for j = 1,2 do
                    table.remove(vertx,1)
                    table.remove(vtext,1)
                end
            else
                for j = 1,2 do
                    table.remove(vertx,5)
                    table.remove(vtext,5)
                end
            end
        elseif data.left then
            r = 1
            if settings.invert then
                for j = 1,2 do
                    table.remove(vertx,5)
                    table.remove(vtext,5)
                end
            else
                for j = 1,2 do
                    table.remove(vertx,1)
                    table.remove(vtext,1)
                end
            end
        end
    end
    if Block.config[v.id].semisolid then
        r = r/2
        g = g/2
        b = b/2
    end
    if data.filler then
        a = a/2
    end
    local texture = data.parent.data.dbtexture
    if v.width < 0 or v.height < 0 then
        texture = data.parent.data.dbfuck
        if v.width < 0 then
            r = r/2
            Text.print("WIDTH WRONG",300,200)
        else
            b = b/2
            Text.print("HEIGHT WRONG",300,220)
        end
    end
    
    if texture then
        --SFX.play(1)
        Graphics.drawBox{
            sceneCoords = true,
            priority = 0,
            vertexCoords = vertx,
            texture = texture,
            textureCoords = vtext,
            color = Color(r,g,b,a),
        }
    end
end

return rotaryPhone