local inventory = {}

-- SMB3 HUD
local smb3hud
pcall(function() smb3hud = require("smb3HUD") end)

-- NERDS ONLY!
---@type boolean
inventory.debug = false

-- For the nerds who wanna open the inventory anywhere!
---@type boolean
inventory.openanywhere = false

-- If the inventory is visible on the screen even when it's closed
---@type boolean
inventory.show = false

-- If the inventory can be used
---@type boolean
inventory.canuse = true

-- If the inventory is currently in use and can be used
---@type boolean
inventory.isusing = false

-- If the inventory is in use. Updates on tick end unlike isusing
---@type boolean
inventory.isopen = true

-- If the inventory is on the world map (hub level)
---@type boolean
inventory.onmap = false

-- The max amount of items the inventory can store
---@type integer
inventory.maxlength = 16

-- The rendering priority of the inventory HUD
---@type number
inventory.priority = 5.1

-- If the inventory system should take reserve items and put them into the inventory instantly.
---@type boolean
inventory.takereserve = false

--Spawns an `item` NPC at a `p`layer and makes the player instantly collect it
---@param item integer
---@param p Player
function inventory.spawnCollect(item,p)
    p = p or player
    local v = NPC.spawn(item,p.x,p.y)
    v.direction = p.direction
    v:collect(p)
end

-- Takes effect when `dropFunction` is `spawnReserve`. If true, the powerup spawns in the middle of the camera
---@type boolean
inventory.dropMiddle = false

--Spawns an `item` right above a `p`layer in a reserve fashion
---@param item integer
---@param p Player
function inventory.spawnReserve(item,p)
    p = p or player
    local x = p.x
    if inventory.dropMiddle then
        x = camera.x/2
    end
    local v = NPC.spawn(item,x,camera.y)
    v.y = v.y+v.height
    v.forcedState = NPCFORCEDSTATE_DROPPED_ITEM
    SFX.play(11)
end

---- Takes effect when `dropFunction` is `spawnHidden`. If true then dontMove is true
-----@type boolean
--inventory.hiddenDoesntMove = false

--Spawns a Hidden Item NPC right on top of the player
---@param item integer
---@param p Player
function inventory.spawnHidden(item,p)
    p = p or player
    local v = NPC.spawn(412,p.x,p.y)
    --v.dontMove = inventory.hiddenDoesntMove
    v.direction = p.direction
    v.ai1 = item
end

-- A function to run when something in the inventory is used. Gets passed the item used and the player (item,p)
---@type function
inventory.dropFunction = inventory.spawnCollect

-- A list of all the items that if the reserve box has, the inventory won't accept it
---@type table
inventory.reserveblacklist = {
    [9] = true, -- SMB3 Mushroom
    [184] = true, -- SMB1 Mushroom
    [185] = true, -- SMW Mushroom
    [249] = true, -- SMB2 Mushroom
    [250] = true, -- Heart Container
    [462] = true, -- SMB2 Heart
}


-- If the inventory system should make sure the reserve box is never occupied. (doesn't work if `takereserve` is true too)
---@type boolean
inventory.clearreserve = false

-- If the inventory should show up at the top of the screen instead of the bottom
---@type boolean
inventory.bottom = false

-- If the black bar should show up even if the inventory is closed
---@type boolean
inventory.showblackbarevenwithoutinventory = false

-- If the inventory's rendering is controlled elsewhere and shouldn't be the job of the inventory.
---@type boolean
inventory.customrender = false

-- The player who has control over the inventory
---@type Player|nil
inventory.controllingplayer = nil

-- If all players can control the inventory at the same time
---@type boolean
inventory.ourinventory = true

-- If the inventory closes automatically after an item's used
---@type boolean
inventory.autoclose = true

-- How many items can be shown at a time
---@type integer
inventory.showlength = 9

-- Spacing between the items in the inventory
---@type Vector2
inventory.spacing = vector(48,0)

-- Offset of items in the inventory
---@type Vector2
inventory.offset = vector(-8,28)

-- Where the entire inventory renders
---@type Vector2
inventory.pos = vector(0,4)

-- How much the items scale in the inventory
---@type Vector2
inventory.itemscale = vector(1,1)

-- The button to press to open the inventory
---@type string
inventory.button = "altRun"

-- The button to press to close the inventory
---@type string
inventory.unbutton = "altRun"

-- If the inventory is allowed to be opened when empty
---@type boolean
inventory.openempty = false

-- The key that progresses the inventory left
---@type string
inventory.keyleft = "left"

-- The key that progresses the inventory left
---@type string
inventory.keyright = "right"

-- The key that uses an item
---@type string
inventory.keyuse = "jump"

-- The sound that plays when the player moves from one item to another
---@type number|string?
inventory.movesfx = 26

-- The sound that plays when the player can't move further up or down
---@type number|string?
inventory.cantmovesfx = 3

-- The sound that plays when the player can't use an item
---@type number|string?
inventory.cantusesfx = 3

-- The sound that plays when the player can't open the inventory
---@type number|string?
inventory.cantopensfx = 3

-- The sound that plays when the inventory opens
---@type number|string?
inventory.opensfx = 13

-- The sound that plays when the inventory closes
---@type number|string?
inventory.closesfx = 23

-- The sound that plays when an item in the inventory is used
---@type number|string?
inventory.usesfx = nil

-- If the inventory should pause the game
---@type boolean
inventory.pause = false

-- If the inventory can only be used by players on the ground (for hub style episodes)
---@type boolean
inventory.onlyonground = false

-- If `onlyonground` is enabled and underwater counts as on the ground
---@type boolean
inventory.canuseunderwater = true

-- If `onlyonground` is enabled and climbing counts as on the ground
---@type boolean
inventory.canuseclimbing = true

-- If `onlyonground` is enabled and the player's allowed to use the inventory on NPCs
---@type boolean
inventory.canstandonNPC = false

-- If the black bar should be shown
---@type boolean
inventory.showblackbar = true

-- The width of the inventory
---@type number
inventory.width = 472

-- The height of the inventory
---@type number
inventory.height = 48

-- Color tint of the inventory
---@type Color
inventory.tint = Color(1,1,1,1)

-- A function to run alongside the inventory drawing. Passes the same arguments `drawInventory` has
---@type function|nil
inventory.onInventoryDraw = nil

-- The texture to have when things have gone arry
---@type Texture|nil
inventory.missingtexture = Graphics.loadImage(Misc.resolveGraphicsFile("missing.png"))

function inventory.onInitAPI()
    registerEvent(inventory,"onStart")
    registerEvent(inventory,"onCameraDraw")

    registerEvent(inventory,"onTick")
    registerEvent(inventory,"onTickEnd")
    registerEvent(inventory,"onDraw")
end

SaveData.inventory = SaveData.inventory or {}

-- The table storage the inventory has
---@type table<integer,integer>
inventory.backpack = SaveData.inventory

local selected = 1

local pressed = {
    false,
    false,
    false,
    false,
    false,
}

-- Returns true if the inventory is full
---@return boolean
function inventory.full()
    return #inventory.backpack >= inventory.maxlength
end

-- Adds an NPC `id` to the inventory
---@param id integer
function inventory.add(id)
    if not inventory.full() then
        inventory.backpack[#inventory.backpack+1] = id
    end
end

-- Clears the inventory
function inventory.clear()
    if #inventory.backpack <= 0 then return end
    for i = #inventory.backpack, 1, -1 do
        inventory.backpack[i] = nil
    end
end

-- Checks if the inventory.backpack has the key `id`, returns the index
---@param id string|number
---@return integer|nil
function inventory.index(id)
    for index,key in ipairs(inventory.backpack) do
        if id == key then
            return index
        end
    end
end

-- Checks if the inventory.backpack has the key `id`
---@param id string|number
---@return boolean
function inventory.has(id)
    for index,key in ipairs(inventory.backpack) do
        if id == key then
            return true
        end
    end
    return false
end

-- Removes the key `id` from the backpack if it exists
function inventory.remove(id)
    local key = inventory.index(id)
    if id then
        table.remove(inventory.backpack,key)
    end
end

-- Closes the inventory
---@param sound boolean|nil if the inventory closing sound should be played
function inventory.close(sound)
    if sound and inventory.closesfx then
        SFX.play(inventory.closesfx)
    end
    if inventory.pause then
        Misc.unpause()
    end
    inventory.isusing = false
    inventory.controllingplayer = nil
end

-- A mapped table of items that cant be used
---@type table<integer,boolean>
inventory.restricted = {}

local haynow = nil

-- A function that runs for each player. Depending on if `pause` is turned on, it'll run on either onTick or onDraw
---@param p Player
function inventory.onInventoryTickPlayer(p)
    if p:isDead() then return end
    if not p.keys[inventory.button] then
        pressed[4] = false
    end
    if not p.keys[inventory.unbutton] then
        pressed[5] = false
    end
    if inventory.isusing then
        local closing = false
        if inventory.ourinventory or inventory.controllingplayer == p then
            if not p.keys[inventory.keyright] then
                pressed[1] = false
            end
            if not p.keys[inventory.keyleft] then
                pressed[2] = false
            end
            if not p.keys[inventory.keyuse] then
                pressed[3] = false
            end
            if p.keys[inventory.keyright] and not pressed[1] then
                selected = selected+1
                pressed[1] = true
                if selected > #inventory.backpack or selected <= 0 then
                    if inventory.cantmovesfx then
                        SFX.play(inventory.cantmovesfx)
                    end
                elseif inventory.movesfx then
                    SFX.play(inventory.movesfx)
                end
                selected = math.clamp(selected,1,#inventory.backpack)
            elseif p.keys[inventory.keyleft] and not pressed[2] then
                selected = selected-1
                pressed[2] = true
                if selected > #inventory.backpack or selected <= 0 then
                    if inventory.cantmovesfx then
                        SFX.play(inventory.cantmovesfx)
                    end
                elseif inventory.movesfx then
                    SFX.play(inventory.movesfx)
                end
                selected = math.clamp(selected,1,#inventory.backpack)
            elseif p.keys[inventory.keyuse] and not pressed[3] then
                pressed[3] = true
                if #inventory.backpack > 0 then
                    local thang = math.clamp(selected,1,#inventory.backpack)
                    local thing = inventory.backpack[thang]
                    if type(inventory.dropFunction) == "function" and not inventory.restricted[thing] then
                        if inventory.usesfx then
                            SFX.play(inventory.usesfx)
                        end
                        thing = table.remove(inventory.backpack,thang)
                        inventory.dropFunction(thing,p)
                    else
                        if inventory.cantusesfx then
                            SFX.play(inventory.cantusesfx)
                        end
                        if not inventory.restricted[thing] then
                            return
                        end
                    end
                    if inventory.autoclose then
                        inventory.isusing = false
                        inventory.controllingplayer = nil
                        closing = true
                        inventory.close(false)
                    end
                elseif inventory.cantusesfx then
                    SFX.play(inventory.cantusesfx)
                end
            elseif p.keys[inventory.unbutton] and (not pressed[5]) then
                pressed[5] = true
                closing = true
                inventory.close(true)
            end
        end
        if not closing then
            p.keys.right = false
            p.keys.left = false
            p.keys.jump = false
            p.keys.up = false
            p.keys.down = false
            p.keys.altRun = false
        elseif pressed[3] then
            haynow = inventory.keyuse
        elseif pressed[4] then
            haynow = inventory.button
        elseif pressed[5] then
            haynow = inventory.unbutton
        end
    elseif p.forcedState == FORCEDSTATE_NONE and (inventory.onlyonground or ((p:isOnGround() and (inventory.canstandonNPC or not p.standingNPC))) or (inventory.canuseunderwater and p:isUnderwater()) or (inventory.canuseclimbing and p:isClimbing())) and (inventory.onmap or inventory.openanywhere) and not pressed[4] then
        if p.keys[inventory.button] then
            local keyitems
            pcall(function() keyitems = require("keyitems") end)
            if not (keyitems and keyitems.isopen) then
                pressed[4] = true
                p.keys[inventory.button] = false
                if (inventory.openempty or #inventory.backpack > 0) then
                    inventory.isusing = true
                    selected = 1
                    inventory.controllingplayer = p
                    if inventory.opensfx then
                        SFX.play(inventory.opensfx)
                    end
                    if inventory.pause then
                        Misc.pause(true)
                    end
                elseif inventory.cantopensfx then
                    SFX.play(inventory.cantopensfx)
                end
            end
            
        end
    end
end

function inventory.onTick()
    if not (inventory.backpack and inventory.canuse) then return end
    if not (inventory.openempty or #inventory.backpack > 0) then
        inventory.isusing = false
    end
    for _,p in ipairs(Player.get()) do
        -- Take reserve powerups into the inventory
        if (inventory.takereserve or inventory.clearreserve) and p.reservePowerup ~= 0 then
            if inventory.takereserve and not inventory.reserveblacklist[p.reservePowerup] then
                inventory.add(p.reservePowerup)
            end
            p.reservePowerup = 0
        end
        if not inventory.pause then
            inventory.onInventoryTickPlayer(p)
        end
        -- Prevents weird stuff hopefully
        if haynow then
            if p.keys[haynow] then
                p.keys[haynow] = false
            else
                haynow = nil
            end
        end
    end
    
end

function inventory.onTickEnd()
    if inventory.isopen ~= inventory.isusing then
        inventory.isopen = inventory.isusing
    end
end

function inventory.drawInventory(idx,priority)
    if type(inventory.onInventoryDraw) == "function" then
        inventory.onInventoryDraw(idx,priority)
    end
    local cam = Camera(idx)
    local y = inventory.pos.y
    if inventory.bottom then
        y = cam.height-64
    end
    local youcandraw = (inventory.backpack and (inventory.show or inventory.isusing) and inventory.canuse)
    if inventory.showblackbar and ((youcandraw and not smb3hud) or inventory.showblackbarevenwithoutinventory) then
       Graphics.drawBox{
            x=0,
            y=y,
            width = cam.width,
            height = 64,
            color = Color(0,0,0,inventory.tint.a),
            priority = priority - 0.02,
        }
    end
    if not youcandraw then return end
    local centerX = cam.width/2
	--local centerY = cam.height/2
    local x = (centerX-inventory.width/2)+inventory.pos.x
    y = inventory.pos.y
    if inventory.bottom then
        y = cam.height-(64-inventory.pos.y)
    end
    if smb3hud then
        smb3hud.drawStatusBox(x+4,y,27,priority)
    else
        Graphics.drawBox{
            x=x,
            y=y,
            width = inventory.width,
            height = inventory.height,
            color = inventory.tint,
            priority = priority,
        }
    end
    local offset = 0
    if #inventory.backpack > inventory.showlength then
        if inventory.isusing then
            offset = math.clamp(selected-math.ceil(inventory.showlength/2),0,#inventory.backpack-inventory.showlength)
        else
            offset = math.max(#inventory.backpack,inventory.showlength)-inventory.showlength
        end
    end
    for _,id in ipairs(inventory.backpack) do
        if _ > offset and _ <= inventory.showlength+offset then
            local sprite = Graphics.sprites.npc[id].img
            local color = inventory.tint
            if inventory.isusing and _ ~= selected then
                color = Color(inventory.tint.r/2,inventory.tint.b/2,inventory.tint.g/2,inventory.tint.a)
            end
            if inventory.restricted[id] then
                color = Color(color.r/2,color.g/2,color.b/2,color.a)
            end
            if sprite then
                local config = NPC.config[id]
                local width = config.gfxwidth
                if width == 0 or not width then
                    width = sprite.width
                end
                local h = sprite.height
                local frames = config.frames
                if frames == 0 or not frames then
                    frames = h/width
                end
                local height = config.gfxheight
                if height == 0 or not height then
                    height = sprite.height/frames
                end
                Graphics.drawBox{
                    texture = sprite,
                    x = x+(_-offset)*inventory.spacing.x+inventory.offset.x,
                    y = y+(_-offset)*inventory.spacing.y+inventory.offset.y,
                    priority = priority+0.1,
                    sourceX = 0,
                    sourceY = 0,
                    sourceWidth = width,
                    sourceHeight = height,
                    width = width*inventory.itemscale.x,
                    height = height*inventory.itemscale.y,
                    centered = true,
                    color = color,
                }
            elseif inventory.missingtexture then
                Graphics.drawBox{
                    texture = sprite,
                    x = x+(_-offset)*inventory.spacing.x+inventory.offset.x,
                    y = y+(_-offset)*inventory.spacing.y+inventory.offset.y,
                    priority = priority+0.1,
                    sourceX = 0,
                    sourceY = 0,
                    sourceWidth = inventory.missingtexture.width,
                    sourceHeight = inventory.missingtexture.height,
                    width = inventory.missingtexture.width*inventory.itemscale.x,
                    height = inventory.missingtexture.height*inventory.itemscale.y,
                    centered = true,
                    color = color,
                }
            end
        end
    end
end

function inventory.onDraw()
    for _,p in ipairs(Player.get()) do
        if inventory.pause then
            inventory.onInventoryTickPlayer(p)
        end
    end
end

function inventory.onCameraDraw(idx)
    if inventory.customrender then return end
    inventory.drawInventory(idx,inventory.priority)
end

-- Restricts an item from being used
---@param id integer
function inventory.restrict(id)
    inventory.restricted[id] = true
end

-- Unestricts an item from being used
---@param id integer
function inventory.unrestrict(id)
    inventory.restricted[id] = false
end

Cheats.register("declutter",{
    aliases = {"dontneedanyofthisgarbage","onecloudstorage","eatallitems"},
    onActivate = function ()
        inventory.clear()
        return true
    end,
    activateSFX = 36,
    isCheat = false,
})

return inventory