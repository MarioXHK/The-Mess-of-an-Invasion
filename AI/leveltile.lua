local level = {}

local IDs = {}

local npcManager = require("npcManager")

local npcutils = require("npcs/npcutils")

local map = require("smb3map")

--[[
Registers an NPC's `id` as a level tile

as a level tile, it can do level things
]]
function level.register(id)
    IDs[id] = true
    npcManager.registerEvent(id, level, "onTickNPC")
	npcManager.registerEvent(id, level, "onTickEndNPC")
	npcManager.registerEvent(id, level, "onDrawNPC")
	npcManager.registerEvent(id, level, "onDrawEndNPC")
	--npcManager.registerEvent(id, level, "onCameraDrawNPC")
    --npcManager.registerEvent(id, level, "onStartNPC")
end

function level.onInitAPI()
    --registerEvent(level, "onStart")
    --registerEvent(level, "onNPCHarm")
    --registerEvent(level, "onPostNPCKill")
end

local directions = {
    "up",
    "down",
    "left",
    "right",
}

local extendeddirections = {
    "up",
    "down",
    "left",
    "right",
    "upleft",
    "upright",
    "downleft",
    "downright",
}

-- Returns true if only one of them is true, and not both
---@param a any
---@param b any
---@return boolean
local function xor(a,b)
    return ((a or b) and not (a and b))
end

--function level.onStartNPC(v)
--    local data = v.data
--    local settings = data._settings
--    local levelsave = SaveData.smb3map[settings.levelFilename]
--end

level.winframe = Graphics.loadImage(Misc.resolveGraphicsFile("smb3map/cleartile.png"))

local winframe = level.winframe

-- How many win frames are there in the level.winframe graphic. The first one's for all the characters, and the rest is for all the rest of the characters in their own respective numbers
---@type integer
level.winframes = 18

-- How many ticks for the help sign to blink
---@type integer
level.helpblinktimer = 40

local redirections = {
    [191] = "up",
    [192] = "down",
    [193] = "left",
    [194] = "right",
    [195] = "upleft",
    [196] = "upright",
    [197] = "downright",
    [198] = "downleft",
    [199] = "stop",
    [221] = "invert",
    [222] = "random",
}

-- Turns a `dir`ection around
---@param dir string
---@return string?
local function turnaround(dir)
    if dir == "up" then
        return "down"
    elseif dir == "down" then
        return "up"
    elseif dir == "left" then
        return "right"
    elseif dir == "right" then
        return "left"
    elseif dir == "upleft" then
        return "downright"
    elseif dir == "upright" then
        return "downleft"
    elseif dir == "downleft" then
        return "upright"
    elseif dir == "downright" then
        return "upleft"
    end
    return dir
end

-- Stops a tile from moving
local function donemoving(v)
    local data = v.data
    local settings = data._settings
    local config = NPC.config[v.id]
    data.direction = 0
    data.doneanimating = true
    if SaveData.smb3map.enemypos and not config.ismover then
        SaveData.smb3map.enemypos[map.spawnidx(v)] = vector(v.x,v.y)
    end
end


-- Checks the grid for several things (redirectors, levels, paths, corners)
---@param v NPC
local function gridcheck(v)
    local data = v.data
    local settings = data._settings
    local config = NPC.config[v.id]
    local leveled = nil
    local redirector = nil
    if (not v.friendly) and map.animatedenemies() and settings.levelFilename and settings.levelFilename ~= "" then
        for _,p in ipairs(Player.getIntersecting(v.x+map.playerspace,v.y+map.playerspace,v.x+v.width-map.playerspace,v.y+v.height-map.playerspace)) do
            if p.isValid and map.canenterlevel(p) then
                if settings.levelFilename and settings.levelFilename ~= "" then
                    map.enterlevel(v,p,settings.warp)
                else
                    v:kill(HARM_TYPE_SPINJUMP)
                end
            end
        end
    end

    if config.followredirectors then
        for __,r in BGO.iterateIntersecting(v.x+map.playerspace,v.y+map.playerspace,v.x+v.width-map.playerspace,v.y+v.height-map.playerspace) do -- check for redirectors
            if r.isValid and not r.isHidden then
                if redirections[r.id] then
                    redirector = r
                    break
                end
            end
        end
    end
    if not (redirector or config.ignorelevels) then
        for __,l in NPC.iterateIntersecting(v.x+map.playerspace,v.y+map.playerspace,v.x+v.width-map.playerspace,v.y+v.height-map.playerspace) do -- check for levels and nodes
            if l.isValid and not (l.isHidden or l.isGenerator) then
                if NPC.config[l.id].isnode or NPC.config[l.id].islevel then
                    leveled = l
                    break
                end
            end
        end
    end
    if v.speedX ~= 0 then
        if v.speedX > 0 then
            v.x = v.x+data.distance
        else
            v.x = v.x-data.distance
        end
    end
    if v.speedY ~= 0 then
        if v.speedY > 0 then
            v.y = v.y+data.distance
        else
            v.y = v.y-data.distance
        end
    end
    if leveled then -- ur on a level/node/redirector+dothosethings? cool
        data.currentcorner = nil
        local lonfig = NPC.config[leveled.id]
        v.x = leveled.x + (lonfig.playeroffsetx or 0)
        v.y = leveled.y + (lonfig.playeroffsety or 0)
        if (data.steps > 0 or config.ismover) then -- Still have steps and not stopped? Keep on moving!
            --if data.steps % 2 == 1 then
            --    SFX.play(72)
            --else
            --    SFX.play(71)
            --end
            if not (config.ignorepaths) then
                local availableDirections = {}
                for ___,dir in ipairs(directions) do -- go through all the directions to see if you can do them
                    local can = false
                    local xoff = 0
                    local yoff = 0
                    if dir == "up" then
                        yoff = -v.height
                    elseif dir == "down" then
                        yoff = v.height
                    elseif dir == "left" then
                        xoff = -v.width
                    elseif dir == "right" then
                        xoff = v.width
                    end
                    for __,p in Block.iterateIntersecting(v.x+xoff+map.playerspace,v.y+yoff+map.playerspace,v.x+v.width+xoff-map.playerspace,v.y+v.height+yoff-map.playerspace) do -- check for paths
                        if p.isValid and not p.isHidden then
                            local pathfig = Block.config[p.id]
                            if (pathfig.ispath and not config.enemypathonly) or pathfig.isenemypath then
                                can = true
                                break
                            end
                        end
                    end
                    if can then
                        for __,b in Block.iterateIntersecting(v.x+xoff+map.playerspace,v.y+yoff+map.playerspace,v.x+v.width+xoff-map.playerspace,v.y+v.height+yoff-map.playerspace) do -- check for blockers
                            if b.isValid and not b.isHidden then
                                local blockig = Block.config[b.id]
                                if blockig.isenemyblocker then
                                    can = false
                                    break
                                end
                            end
                        end
                        if not can then
                            for __,b in Block.iterateIntersecting(v.x+xoff+map.playerspace,v.y+yoff+map.playerspace,v.x+v.width+xoff-map.playerspace,v.y+v.height+yoff-map.playerspace) do
                                if b.isValid and not b.isHidden then
                                    local blockig = Block.config[b.id]
                                    if blockig.isblockerblocker then -- My newest invention
                                        can = true
                                        break
                                    end
                                end
                            end
                        end
                    end
                    if can then
                        for __,w in NPC.iterateIntersecting(v.x+xoff+map.playerspace,v.y+yoff+map.playerspace,v.x+v.width+xoff-map.playerspace,v.y+v.height+yoff-map.playerspace) do -- check for blockers
                            if w.isValid and not (w.isHidden or w.isGenerator) then
                                local boobler = Block.config[w.id]
                                if boobler.isblocker then
                                    can = false
                                    break
                                end
                            end
                        end
                    end
                    if can then
                        availableDirections[#availableDirections+1] = dir
                    end
                end
                if #availableDirections == 0 and SaveData.smb3map.enemypos then -- oh, the enemy's blocked off from all directions... oh well
                    data.steps = 0
                    data.direction = 0
                    data.doneanimating = true
                    SaveData.smb3map.enemypos[map.spawnidx(v)] = vector(v.x,v.y)
                else -- Oh cool I can move :D
                    data.steps = data.steps - 1
                    data.direction = RNG.randomEntry(availableDirections)
                    if v.attachedLayerName and v.attachedLayerName ~= "" and not settings.dontsavepos then -- no need for an offset of this layer if it's moving!
                        map.layeroffset[v.attachedLayerName] = nil
                    end
                end
            end
        else
            donemoving(v)
        end
    else
        if redirector then -- Redirect into those stuffs!
            data.currentcorner = nil
            local lonfig = BGO.config[redirector.id]
            v.x = redirector.x + (lonfig.playeroffsetx or 0)
            v.y = redirector.y + (lonfig.playeroffsety or 0)
            if (data.steps > 0 or config.ismover) and redirections[redirector.id] ~= "stop" then
                if redirections[redirector.id] == "invert" then
                    data.direction = turnaround(data.direction)
                elseif redirections[redirector.id] == "random" then
                    data.direction = RNG.randomEntry(directions)
                else
                    data.direction = redirections[redirector.id]
                end
            else
                donemoving(v)
            end
        elseif not (config.ignorepaths) then  -- Check for corners if you're not on a level
            for __,b in Block.iterateIntersecting(v.x+map.playerspace,v.y+map.playerspace,v.x+v.width-map.playerspace,v.y+v.height-map.playerspace) do
                if b.isValid and not b.isHidden then
                    local bonfig = Block.config[b.id]
                    if (bonfig.ispath and not config.enemypathonly) or bonfig.isenemypath then
                        if data.currentcorner ~= b and (bonfig.pathcorner and bonfig.pathcorner ~= 0) then
                            data.currentcorner = b
                            if v.speedX ~= 0 then
                                local speed = v.speedX
                                v.speedX = 0
                                if speed > 0 and (bonfig.pathcorner == 2 or bonfig.pathcorner == 4) then
                                    speed = math.abs(speed)
                                    if bonfig.pathcorner == 2 then
                                        v.speedY = speed
                                        data.direction = "down"
                                    else
                                        v.speedY = -speed
                                        data.direction = "up"
                                    end
                                elseif speed < 0 and (bonfig.pathcorner == 1 or bonfig.pathcorner == 3) then
                                    speed = math.abs(speed)
                                    if bonfig.pathcorner == 1 then
                                        v.speedY = speed
                                        data.direction = "down"
                                    else
                                        v.speedY = -speed
                                        data.direction = "up"
                                    end
                                else
                                    v.speedX = speed
                                end
                            elseif v.speedY ~= 0 then
                                local speed = v.speedY
                                v.speedY = 0
                                if speed < 0 and (bonfig.pathcorner == 1 or bonfig.pathcorner == 2) then
                                    speed = math.abs(speed)
                                    if bonfig.pathcorner == 1 then
                                        v.speedX = speed
                                        data.direction = "right"
                                    else
                                        v.speedX = -speed
                                        data.direction = "left"
                                    end
                                elseif speed > 0 and (bonfig.pathcorner == 3 or bonfig.pathcorner == 4) then
                                    speed = math.abs(speed)
                                    if bonfig.pathcorner == 3 then
                                        v.speedX = speed
                                        data.direction = "right"
                                    else
                                        v.speedX = -speed
                                        data.direction = "left"
                                    end
                                else
                                    v.speedY = speed
                                end
                            end
                            --if v.speedX ~= 0 then
                            --    plr.x = plr.x-plr.distance
                            --    local speed = math.abs(v.speedX)
                            --    v.speedX = 0
                            --    if config.pathcorner == 1 or config.pathcorner == 2 then
                            --        v.speedY = speed
                            --    else
                            --        v.speedY = -speed
                            --    end
                            --elseif v.speedY ~= 0 then
                            --    plr.y = plr.y-plr.distance
                            --    local speed = math.abs(v.speedY)
                            --    v.speedY = 0
                            --    if config.pathcorner == 1 or config.pathcorner == 3 then
                            --        v.speedX = speed
                            --    else
                            --        v.speedX = -speed
                            --    end
                            --end
                        end
                    end
                end
            end
        end
    end
    data.distance = data.distance + map.traveldist
end

-- The function that every game tick for the NPC `v`
---@param v NPC
function level.onTickNPC(v)
    local data = v.data
	local config = NPC.config[v.id]
	local settings = v.data._settings

    v.despawnTimer = 2

    if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

    v.collisionGroup = "Level Tile"

    local levelsave = SaveData.smb3map[settings.levelFilename]
    if settings.idxsave or config.isenemy then
        levelsave = SaveData.smb3map[map.spawnidx(v)]
    end

    if not data.initialized then
        data.initialized = true
        if config.isnumbered then
            data.frame = 0
            data.frametimer = 0
            data.number = settings.number or 0
        end
        data.helpvisible = false
        data.slideoffset = 0
        data.slidestep = false
        data.unlockedDirections = {
            up = false,
            down = false,
            left = false,
            right = false,
        }
        if config.isairship or config.isenemy then
            for _,dir in ipairs(directions) do
                data.unlockedDirections[dir] = true
            end
        elseif settings.unlock then
            for _,dir in ipairs(directions) do
                if settings.unlock[dir] == 1 then
                    data.unlockedDirections[dir] = true
                end
            end

            if levelsave then
                for _,dir in ipairs(directions) do
                    if settings.unlock[dir] and ((levelsave.won and settings.unlock[dir] == 2) or (settings.unlock[dir] ~= 0 and levelsave.winTypes[settings.unlock[dir]-2])) then
                        data.unlockedDirections[dir] = true
                    end
                end
            end
        end
        if config.isenemy or config.ismover or config.followredirectors then
            data.currentcorner = nil
            data.distance = 0
            if (config.ismover or config.followredirectors) and settings.direction and settings.direction ~= 0 then
                if settings.direction == 9 then
                    data.direction = RNG.randomEntry(directions)
                else
                    data.direction = extendeddirections[settings.direction]
                end
            else
                data.direction = 0
            end
            if config.ismover or config.followredirectors then
                data.steps = 0
            else -- Enemy setup
                if SaveData.smb3map.enemypos and SaveData.smb3map.enemypos[map.spawnidx(v)] and not (settings.dontsavepos or data.zoomies) then
                    if v.attachedLayerName and v.attachedLayerName ~= "" then -- Zoomies? ZOOMIES! IT'S ZOOMIES TIME I'M OGNANFFSDJGUISHFGIUJDFHIUKGDFGHUYGDFSJHKGSUYJFSGDFJY
                        data.zoomies = vector(SaveData.smb3map.enemypos[map.spawnidx(v)].x-v.spawnX,SaveData.smb3map.enemypos[map.spawnidx(v)].y-v.spawnY)
                        if data.zoomies.x ~= 0 or data.zoomies.y ~= 0 then -- Better make sure that it's actually moved so I don't put in the effort to do all the things
                            -- have to do this manually :<
                            for _,n in NPC.iterate() do
                                if n.isValid and n.layerName == v.attachedLayerName then
                                    n.x = n.x+data.zoomies.x
                                    n.y = n.y+data.zoomies.y
                                    n.spawnX = n.spawnX+data.zoomies.x
                                    n.spawnY = n.spawnY+data.zoomies.y
                                end
                            end
                            -- Blocks are difficult so we're going to hang them and create new ones that have the same properties
                            for _,b in Block.iterate() do
                                if b.isValid and b.layerName == v.attachedLayerName then
                                    local uhoh = vector(b.x+data.zoomies.x,b.y+data.zoomies.y)
                                    local aaah = vector(b.width,b.height)
                                    local id = b.id
                                    local ay = b:mem(0x0C,FIELD_STRING) -- hit event
                                    local bee = b:mem(0x10,FIELD_STRING) -- destroy event
                                    local sea = b:mem(0x14,FIELD_STRING) -- layerempty event
                                    local troll = b:mem(0x5A,FIELD_BOOL) -- invisible (in editor)
                                    local slip = b.slippery
                                    local contid = b.contentID
                                    b:delete()
                                    local nb = Block.spawn(id,uhoh.x,uhoh.y)
                                    nb.width = aaah.x
                                    nb.height = aaah.y
                                    nb.layerName = v.attachedLayerName
                                    nb:mem(0x0C,FIELD_STRING,ay)
                                    nb:mem(0x10,FIELD_STRING,bee)
                                    nb:mem(0x14,FIELD_STRING,sea)
                                    nb:mem(0x5A,FIELD_BOOL,troll)
                                    nb.slippery = slip
                                    nb.contentID = contid
                                end
                            end
                            for _,o in BGO.iterate() do
                                if o.isValid and o.layerName == v.attachedLayerName then
                                    o.x = o.x+data.zoomies.x
                                    o.y = o.y+data.zoomies.y
                                end
                            end
                        end
                    end
                    v.x = SaveData.smb3map.enemypos[map.spawnidx(v)].x
                    v.y = SaveData.smb3map.enemypos[map.spawnidx(v)].y
                end
                local dothepos = not ((SaveData.smb3map.enemypos and SaveData.smb3map.enemypos[map.spawnidx(v)]) or settings.dontsavepos)
                if v.dontMove or config.speed == 0 or (config.issleeper and SaveData.smb3map.musicboxturns and SaveData.smb3map.musicboxturns > 0) or dothepos then
                    data.steps = 0
                    if dothepos and SaveData.smb3map.enemypos then
                        SaveData.smb3map.enemypos[map.spawnidx(v)] = vector(v.x,v.y)
                    elseif settings.dontsavepos then
                        data.steps = (settings.steps or 4)
                    end
                else
                    data.steps = (settings.steps or 4)
                end
            end
        end
        if config.isairship then -- airship setup
            if not map.airships[settings.levelFilename] then
                map.airships[settings.levelFilename] = v
            end
            data.airshipLayer = data.airshipLayer or settings.airshipLayer
            if SaveData.smb3map.airshippos and not (levelsave and levelsave.won) then
                if SaveData.smb3map.airshippos[settings.levelFilename] then
                    v.x = SaveData.smb3map.airshippos[settings.levelFilename].x
                    v.y = SaveData.smb3map.airshippos[settings.levelFilename].y
                else
                    SaveData.smb3map.airshippos[settings.levelFilename] = vector(v.x,v.y)
                end
            end
        end
        -- Checking for our lil n marks
        if config.islevel and SaveData.smb3map.nmarkspades and not data.spademarked then
            for markname,spadedata in pairs(SaveData.smb3map.nmarkspades) do
                for num,spade in ipairs(spadedata) do
                    if spade.target == settings.levelFilename and not spade.used then
                        data.spademarked = markname
                        break
                    end
                end
                if data.spademarked then
                    break
                end
            end
        end
    end
    -- Thumbnails are handled outside of the leveltile AI
    if not data.thumbnailinitialize then
        data.thumbnailinitialize = true
        data.drewthumbnail = false
        if type(settings.thumbnail) ~= "nil" and not data.thumbnail then
            local checkme = settings.thumbnail
            if type(checkme) == "table" then
                checkme = settings.thumbnail.texture or settings.thumbnail.image or settings.thumbnail.thumbnail
            end
            if type(checkme) == "string" and checkme ~= "" then
                local root = tostring(map.root)
                local itype = tostring(map.imagetype)
                local dome = false
                if Misc.resolveGraphicsFile(root..checkme..itype) and not settings.thumbnail.noroot then
                    dome = true
                    checkme = root..checkme..itype
                elseif Misc.resolveGraphicsFile(root..checkme) and not settings.thumbnail.noroot then
                    dome = true
                    checkme = root..checkme
                elseif Misc.resolveGraphicsFile(checkme..itype) then
                    dome = true
                    checkme = checkme..itype
                elseif Misc.resolveGraphicsFile(checkme) then
                    dome = true
                end

                if dome then
                    data.thumbnail = Graphics.loadImage(Misc.resolveGraphicsFile(checkme))
                else
                    SFX.play(54)
                end
            end
        end
    end
    if not (levelsave and levelsave.won) then -- This level hasn't been beaten yet!
        if settings.airship then -- If you died at a level that was meant to be an airship, then one *will* spawn
            local id = map.airshipTile
            if v.ai1 ~= 0 then
                id = v.ai1
            end
            data.airshiped = true
            if ((GameData.smb3map.level == settings.levelFilename and GameData.smb3map.loser) or (SaveData.smb3map.airshippos and SaveData.smb3map.airshippos[settings.levelFilename])) and not map.airships[settings.levelFilename] then
                map.airships[settings.levelFilename] = NPC.spawn(id,v.x,v.y,v.section,true)
                local air = map.airships[settings.levelFilename]
                -- Attached to the airship!
                air.attachedLayerName = v.attachedLayerName
                v.attachedLayerName = ""
                air.data._settings.levelFilename = settings.levelFilename
                air.data.airshipLayer = settings.airshipLayer
                air.data.airshipFilename = settings.airshipFilename
                air.data._settings.levelTitle = settings.levelTitle
                if SaveData.smb3map.airshippos[settings.levelFilename] then
                    air.x = SaveData.smb3map.airshippos[settings.levelFilename].x
                    air.y = SaveData.smb3map.airshippos[settings.levelFilename].y
                else
                    SaveData.smb3map.airshippos[settings.levelFilename] = vector(air.x,air.y)
                end
            end
        end
    end

    if not data.layed then -- You need to do your layers, big boy
        if levelsave and levelsave.won and settings.layer then
            if settings.layer.show and settings.layer.show ~= "" then
                Layer.get(settings.layer.show):show(true)
                data.layed = true
            end
            if settings.layer.hide and settings.layer.hide ~= "" then
                Layer.get(settings.layer.hide):hide(true)
                data.layed = true
            end
            --if settings.layer.toggle and settings.layer.toggle ~= "" then
            --    map.toggleLayer(settings.layer.toggle,true)
            --    data.layed = true
            --end
            for _,dir in ipairs(directions) do
                if settings.layer[dir] then
                    local lsd = settings.layer[dir]
                    if lsd.show and lsd.show ~= "" then
                        Layer.get(lsd.show):show(true)
                        data.layed = true
                    end
                    if lsd.hide and lsd.hide ~= "" then
                        Layer.get(lsd.hide):hide(true)
                        data.layed = true
                    end
                    --if lsd.toggle and lsd.toggle ~= "" then
                    --    map.toggleLayer(lsd.toggle,true)
                    --    data.layed = true
                    --end
                end
            end
        end
    end

    if settings.once and levelsave and settings.respawntime and settings.respawntime ~= 0 then
        if levelsave.respawnticks then
            if not data.rticked then
                data.rticked = true
                levelsave.respawnticks = levelsave.respawnticks - 1
            end
        else
            levelsave.respawnticks = settings.respawntime
        end
    end

    if not data.triggered then -- trigger an event
        if levelsave and levelsave.won and ((not levelsave.respawnticks) or levelsave.respawnticks > 0) and v.talkEventName ~= "" then
            triggerEvent(v.talkEventName)
            data.triggered = true
        end
    end

    if config.isenemy or config.ismover or config.followredirectors then -- Enemy AI
        if config.isenemy and levelsave and levelsave.won and settings.once then
            if levelsave.respawnticks and levelsave.respawnticks <= 0 then
                map.uncomplete(v)
            else
                v:kill(HARM_TYPE_VANISH)
                return
            end
        end

        if map.anchorActive() and not config.anchorimmune then
            data.steps = 0
            data.doneanimating = true
            v.speedX = 0
            v.speedY = 0
        elseif map.enemyanimationphase == 2 or config.ismover or data.forcemove then
            if v.speedX == 0 or math.abs(v.speedY) > math.abs(v.speedX) then
                data.distance = data.distance - math.abs(v.speedY)
            elseif v.speedY == 0 or math.abs(v.speedY) < math.abs(v.speedX) then
                data.distance = data.distance - math.abs(v.speedX)
            else
                data.distance = data.distance - (math.abs(v.speedX)+math.abs(v.speedY))/2
            end
            if (math.abs(v.speedX)+math.abs(v.speedY)) > 0 and not config.ismute then
                SFX.play(74)
            end
            --Text.print(data.dishelpsigntance,100,100)
            --Text.print(v.idx,100,120)

            if data.distance <= 0 and not data.doneanimating then
                gridcheck(v)
            end
            if data.doneanimating and config.followredirectors then -- Reactivate?
                local redirector = nil
                if config.followredirectors then
                    for __,r in BGO.iterateIntersecting(v.x+map.playerspace,v.y+map.playerspace,v.x+v.width-map.playerspace,v.y+v.height-map.playerspace) do -- check for redirectors
                        if r.isValid and not r.isHidden then
                            if redirections[r.id] then
                                redirector = r
                                break
                            end
                        end
                    end
                end
                if redirector and redirections[redirector.id] ~= "stop" and redirections[redirector.id] ~= "invert" then -- Yes rico, reactivate
                    data.doneanimating = false
                    data.currentcorner = nil
                    local lonfig = BGO.config[redirector.id]
                    v.x = redirector.x + (lonfig.playeroffsetx or 0)
                    v.y = redirector.y + (lonfig.playeroffsety or 0)
                    if redirections[redirector.id] == "random" then
                        data.direction = RNG.randomEntry(directions)
                    else
                        data.direction = redirections[redirector.id]
                    end
                end
            end
            if data.doneanimating then
                v.speedX = 0
                v.speedY = 0
                data.currentcorner = nil
                data.forcemove = false
            else
                if data.direction == "up" or data.direction == "upleft" or data.direction == "upright" then
                    v.speedY = -config.speed
                    if data.direction == "up" then
                        v.speedX = 0
                    else
                        v.speedY = v.speedY*math.sqrt(0.5)
                    end
                end
                if data.direction == "down" or data.direction == "downleft" or data.direction == "downright" then
                    v.speedY = config.speed
                    if data.direction == "down" then
                        v.speedX = 0
                    else
                        v.speedY = v.speedY*math.sqrt(0.5)
                    end
                end
                if data.direction == "left" or data.direction == "upleft" or data.direction == "downleft" then
                    v.speedX = -config.speed
                    v.direction = -1
                    if data.direction == "left" then
                        v.speedY = 0
                    else
                        v.speedX = v.speedX*math.sqrt(0.5)
                    end
                end
                if data.direction == "right" or data.direction == "upright" or data.direction == "downright" then
                    v.speedX = config.speed
                    v.direction = 1
                    if data.direction == "right" then
                        v.speedY = 0
                    else
                        v.speedX = v.speedX*math.sqrt(0.5)
                    end
                end
            end
        else
            v.speedX = 0
            v.speedY = 0
        end
    end

    v.x = v.x+v.layerObj.speedX
    v.y = v.y+v.layerObj.speedY
end

-- Function that runs after onTick and internal smbx code for the NPC `v`
---@param v NPC
function level.onTickEndNPC(v)
    if v.isHidden or not v.data.initialized then return end
    local data = v.data
    local config = NPC.config[v.id]
	local settings = data._settings
    local levelsave = SaveData.smb3map[settings.levelFilename]
    if config.slideamount or data.spademarked or data.treasureship then
        if data.slidestep then
            data.slideoffset = data.slideoffset-(config.slidespeed or map.slidespeed)
            if data.slideoffset < -(config.slideamount or v.width/2) then
                data.slideoffset = -(config.slideamount or v.width/2)
                data.slidestep = false
            end
        else
            data.slideoffset = data.slideoffset+(config.slidespeed or map.slidespeed)
            if data.slideoffset > (config.slideamount or v.width/2) then
                data.slideoffset = (config.slideamount or v.width/2)
                data.slidestep = true
            end
        end
    end
    if settings.helpcall and not (levelsave and levelsave.won) then
        if lunatime.tick() % level.helpblinktimer == 0 then
            if data.helpvisible then
                data.helpvisible = false
            else
                data.helpvisible = true
            end
        end
    end
    if config.isnumbered then
        data.frametimer = (data.frametimer or 0) + 1
        if data.frametimer % config.framespeed == 0 then
            data.frame = (data.frame or 0) + 1
            if data.frame >= config.frames then
                data.frametimer = 0
                data.frame = 0
            end
        end
    end
end

-- Function that runs every time the screen is drawn for the NPC `v`
---@param v NPC
function level.onDrawNPC(v)
	if v.isHidden or not v.data.initialized then return end
    local data = v.data
    local config = NPC.config[v.id]
	local settings = data._settings

    local levelsave = SaveData.smb3map[settings.levelFilename]

    if config.isnumbered and data.frame and data.number then
        v.animationFrame = data.frame+data.number*config.frames
    end

    if settings.idxsave or config.isenemy then
        levelsave = SaveData.smb3map[map.spawnidx(v)]
    end

    if (data.airshiped and settings.hideselfairship) or (levelsave and levelsave.won and settings.vanishonwin) then
        npcutils.hideNPC(v)
        return
    end

    local puhprior = -45
    if config.foreground then
        puhprior = -15
    end
    --if config.isenemy then
    --    Text.print(data.distance,200,200)
    --end
    if data.helpvisible and map.helpsign then
        Graphics.drawBox{
            texture = map.helpsign,
            x = v.x+(config.iconoffsetx or 0)+v.width,
            y = v.y+(config.iconoffsety or 0)-v.height,
            sceneCoords = true,
            sourceX = 0,
            sourceY = 0,
            sourceWidth = map.helpsign.width,
            sourceHeight = map.helpsign.height,
            priority = -20
        }
    end

    if data.spademarked or data.treasureship then
        --Text.print("Spade",v.x-camera.x,v.y-camera.y)
        --Text.print("(Temp)",v.x-camera.x,v.y-camera.y+20)
        local nsprite = map.nspritespade
        if data.spademarked and SaveData.smb3map and SaveData.smb3map.nmarkspades and SaveData.smb3map.nmarkspades[data.spademarked].sprite then
            nsprite = SaveData.smb3map.nmarkspades[data.spademarked].sprite
        end
        if data.treasureship then
            nsprite = map.treasuresprite
            npcutils.hideNPC(v)
        end
        if nsprite then
            Graphics.drawBox{
                texture = nsprite,
                x = v.x+(config.iconoffsetx or 0)+data.slideoffset,
                y = v.y+(config.iconoffsety or 0),
                sceneCoords = true,
                sourceX = 0,
                sourceY = 0,
                sourceWidth = nsprite.width,
                sourceHeight = nsprite.height,
                priority = math.max(-27.5,puhprior+0.1,(config.iconpriority or -100)+0.1)
            }
        end
    elseif map.starlock and settings.stars and settings.stars > mem(0x00B251E0,FIELD_WORD) then
        Graphics.drawBox{
            texture = map.starlock,
            x = v.x+v.width/2+(config.iconoffsetx or 0),
            y = v.y+v.height/2+(config.iconoffsety or 0),
            centered = true,
            sceneCoords = true,
            sourceX = 0,
            sourceY = 0,
            sourceWidth = map.starlock.width,
            sourceHeight = map.starlock.height,
            priority = puhprior+0.02
        }
    end

    if (config.isenemy or config.isairship or config.ismover or config.followredirectors) and map.anchoricon and map.anchorActive() and not config.anchorimmune then
        Graphics.drawBox{
            texture = map.anchoricon,
            x = v.x+v.width+(config.iconoffsetx or 0)-map.anchoricon.width,
            y = v.y+v.height+(config.iconoffsety or 0)-map.anchoricon.height,
            sceneCoords = true,
            sourceX = 0,
            sourceY = 0,
            sourceWidth = map.anchoricon.width,
            sourceHeight = map.anchoricon.height,
            priority = puhprior+0.01
        }
    end

    if config.isenemy and map.musicBoxActive() and config.issleeper then
        v.animationFrame = config.frames*2^config.framestyle
        if config.framestyle ~= 0 and v.direction ~= -1 then
            v.animationFrame = v.animationFrame + 1
        end
        return
    end
    if not settings.mark then return end
    if levelsave and levelsave.won then
        local n = 0
        if settings.once then
            if config.canbedestroyed then
                v.animationFrame = config.frames
                return
            end
        else
            n = winframe.width/2
        end
        local prior = -45
        if config.iconpriority and config.iconpriority > -100 then
            prior = config.iconpriority
        elseif config.foreground then
            prior = -15
        end
        local frame = math.clamp(levelsave.character,0,level.winframes-1)
        Graphics.drawBox{
            texture = winframe,
            x = v.x+v.width/2+(config.iconoffsetx or 0),
            y = v.y+v.height/2+(config.iconoffsety or 0),
            centered = true,
            sceneCoords = true,
            sourceX = n,
            sourceY = (winframe.height/level.winframes)*frame,
            sourceWidth = winframe.width/2,
            sourceHeight = winframe.height/level.winframes,
            priority = prior+0.02
        }
    end
end

-- Function that runs after every time the screen is drawn for the NPC `v`
---@param v NPC
function level.onDrawEndNPC(v)
    local data = v.data
    if not data.thumbnailinitialize then return end
    if data.drewthumbnail then
        data.drewthumbnail = false
    end
end

return level