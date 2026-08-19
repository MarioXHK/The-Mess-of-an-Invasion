--[[# THE PUPPET MASTER!
A library for controlling animations via puppets, like in paper mario or cartoons.

puppet.lua made by MarioXHK. Give credit when using or else I'll find you and I'll throw tomatoes all over your thing!

For the best experience when using this, use VScode and [LunaLua Intellisense.](https://www.smbxgame.com/forums/viewtopic.php?t=29691)

v1.1
]]
local puppet = {}

-- For more information on how to use easing, see https://docs.codehaus.moe/#/modules/easing
local easing = require("ext/easing")

---@type table<integer,PuppetSettings>
puppet.settings = {}

---@type table<integer,Puppet>
puppet.puppets = {}

puppet.root = "puppet/"

-- Attempts to clone a table without referencing any of its values, even nested table values. Returns the table and an additional table of all the index values. if it's NOT a table then it'll return as itself
---@param tab table?
---@return table
---@return table<integer,any>?
local function clonetable(tab)
    if type(tab) ~= "table" then
---@diagnostic disable-next-line: return-type-mismatch
        return tab
    end
    local le = {}
    local indi = {}
    for index,thing in pairs(tab) do
        indi[#indi+1] = index
        if type(thing) == "table" then
            le[index] = clonetable(thing)
        else
            le[index] = thing
        end
    end
    return le,indi
end

-- Checks if the `list` table has a `set` table and if the `index` value in said table can count as a true statement
---@param list table
---@param index string|number
---@return boolean
local function checkSet(list,index)
    if list.set and list.set[index] then
        return true
    end
    return false
end

-- Returns the value nearest of the 2 values given. If neither value is given then it'll round the given number to the nearest whole.
---@param num number
---@param min number|nil
---@param max number|nil
---@return number
local function getNearest(num,min,max)
    local roundup = true
    min = min or math.floor(num)
    max = max or math.ceil(num)
    local mid = math.lerp(min,max,0.5)
    if num < mid then
        return min
    elseif num > mid then
        return max
    else
        if roundup then
            return max
        else
            return min
        end
    end
end

local function rootFinder(img,root,exte)
    for _,try in ipairs{root..img..exte,root..img} do
        if Misc.resolveGraphicsFile(try) then
            return try
        end
    end
end

-- Go through the animations inside of an animations list and check if any of their data shows that they need to be terminated. If they are to be terminated, then they are removed from the list
---@param animations table<string|number,PuppetAnimation>
---@return table deathrow a table that contains the layers (not the animations) that were whiped
function puppet.checkForTerminations(animations)
    -- iterate through them to check if any of them have terminated
    local deathrow = {}
    for layer,animate in pairs(animations) do
        if animate.data._base.terminate then
            deathrow[#deathrow+1] = layer
            if type(animate.data._base.terminatefunction) == "function" then
                animate.data._base.terminatefunction(animate)
            end
        end
    end
    if #deathrow ~= 0 then
        for i = #deathrow,1,-1 do
            if animations[deathrow[i]] then
                --SFX.play(1)
                animations[deathrow[i]] = nil
            end
        end
    end
    return deathrow
end

local textures = {}

-- Registers a part for the `settings` of a puppet
---@param settings PuppetSettings
---@param values table
---@param id string|number
---@return PuppetPartSettings
function puppet.registerPart(settings,id,values)
    settings.parts[id] = {}
    ---@class PuppetPartSettings
    local part = settings.parts[id]
    values = values or id
    if type(values) ~= "table" then
        values = {image = values}
    end
    local image = values.texture or values.image

    -- Texture of the part
    ---@type Texture|nil
    part.texture = image

    image = image or id

    if type(image) == "number" then
        image = tostring(image)
    end

    if type(image) == "string" then
        local img = rootFinder(image,puppet.root..settings.root,settings.extension)

        if not img then
            img = rootFinder(image,puppet.root..tostring(settings.id).."/",settings.extension)
        end
        if not img then
            img = rootFinder(image,settings.root,settings.extension)
        end
        if not img then
            img = rootFinder(image,tostring(settings.id),settings.extension)
        end

        if not img then
            for _,try in ipairs{image..settings.extension,image} do
                if Misc.resolveGraphicsFile(try) then
                    img = try
                    break
                end
            end
        end

        if img then
            if not textures[img] then
                textures[img] = Graphics.loadImageResolved(img)
            end

            part.texture = textures[img]
        else
            part.texture = nil
        end
    end
    -- ID of the part
    ---@type string|number?
    part.id = id
    -- Name of the part (not nessesarily its ID)
    ---@type string|number?
    part.name = values.name or id
    -- Default Scale of the part
    ---@type Vector2
    part.scale = values.scale or vector(values.scaleX or 1,values.scaleY or 1)
    if type(part.scale) == "number" then
        part.scale = vector(part.scale,part.scale)
    else
        part.scale = vector(part.scale.x,part.scale.y)
    end

    -- Default GFX Scale of the part
    ---@type Vector2
    part.gfxscale = values.gfxscale or vector(values.gfxscalex or 1,values.gfxscaley or 1)
    if type(part.gfxscale) == "number" then
        part.gfxscale = vector(part.gfxscale,part.gfxscale)
    end
    
    -- If the gfx scale should multiply instead of replace the regular scale
    ---@type boolean
    part.multiplygfxscale = true
    if type(values.multiplygfxscale) ~= "nil" then
        part.multiplygfxscale = values.multiplygfxscale
    end

    -- Default GFX Scale of the part
    ---@type Vector2
    part.offsetScale = values.offsetScale or values.offsetscale or vector(values.offsetScaleX or values.offsetscalex or 1,values.offsetScaleY or values.offsetscalex or 1)
    if type(part.gfxscale) == "number" then
        part.offsetScale = vector(part.offsetScale,part.offsetScale)
    end

    -- How many frames does the part have
    ---@type Vector2
    part.frames = values.frames or vector(values.framesX or values.framesx or 1,values.framesY or values.framesy or 1)
    if type(part.frames) == "number" then
        part.frames = vector(1,part.frames)
    else
        part.frame = vector(part.x,part.y)
    end

    -- If true, nerd stuff will appear I guess
    ---@type boolean
    part.debugMode = values.debugMode or values.debug or false

    --[[How frames are handled when rendering. Works almost like basegame framestyle. But a bit different.
    
    1 means it should be effected by only the puppet's direction, 2 means it'll only be effected by the part's direction and 3 means both.]]
    ---@type Vector2
    part.framestyle = values.framestyle or values.frameStyle or vector(values.framestylex or values.frameStyleX or 0,values.framestyley or values.frameStyleY or 0)

    -- If true, calculations will be swapped into legacy mode for framestyle, meaning that it'll act in line somewhat with what the basegame has. True if framestyle is set as a number by default
    ---@type boolean
    part.legacyframestyle = false

    if type(part.framestyle) == "number" then
        part.legacyframestyle = true
        part.framestyle = vector(0,part.framestyle)
    else
        part.framestyle = vector(part.framestyle.x,part.framestyle.y)
    end
    part.framestyle.x = math.clamp(math.floor(part.framestyle.x),0,3)
    part.framestyle.y = math.clamp(math.floor(part.framestyle.y),0,3)


    if type(values.legacyframestyle) ~= "nil" then
        part.legacyframestyle = values.legacyframestyle
    end

    -- If true, the X and Y frames will be swapped. I dunno how you could use this, but it's here
    ---@type boolean
    part.XYFrameSwap = false
    if type(values.XYFrameSwap) ~= "nil" then
        part.XYFrameSwap = values.XYFrameSwap
    end

    -- Width of the part
    ---@type number
    part.width = values.width or values.gfxwidth
    -- Height of the part
    ---@type number
    part.height = values.height or values.gfxheight
    -- GFX Width of the part
    ---@type number
    part.gfxwidth = values.gfxwidth or values.width
    -- GFX Height of the part
    ---@type number
    part.gfxheight = values.gfxheight or values.height

    if part.texture then
        part.width = part.width or (part.texture.width/(part.frames.x*(1+math.clamp(part.framestyle.x))))
        part.height = part.height or (part.texture.height/(part.frames.y*(1+math.clamp(part.framestyle.y))))
        part.gfxwidth = part.gfxwidth or (part.texture.width/(part.frames.x*(1+math.clamp(part.framestyle.x))))
        part.gfxheight = part.gfxheight or (part.texture.height/(part.frames.y*(1+math.clamp(part.framestyle.y))))
    else
        part.width = part.width or 8
        part.height = part.height or  8
        part.gfxwidth = part.gfxwidth or 0
        part.gfxheight = part.gfxheight or  0
    end

    -- Offset of the source
    ---@type Vector2
    part.sourceOffset = values.sourceOffset or vector(values.sourceOffsetX or values.sourceX or 0,values.sourceOffsetY or values.sourceY or 0)
    -- Spacing of the source frames
    ---@type Vector2
    part.sourceSpacing = values.sourceSpacing or vector(values.sourceSpacingX or 0,values.sourceSpacingY or 0)
    part.sourceSpacing = vector(part.sourceSpacing.x,part.sourceSpacing.y)
    -- Offset of the part
    ---@type Vector2
    part.offset = values.offset or values.gfxoffset or vector(values.offsetx or values.offsetX or values.gfxoffsetx or 0,values.offsety or values.offsetY or values.gfxoffsety or 0)
    part.offset = vector(part.offset.x,part.offset.y)
    -- If the part should be centered on its x and y axis
    ---@type boolean
    part.centered = true

    if type(values.centered) ~= "nil" then
        part.centered = values.centered
    end

    -- If the part should be a solid color if no texture is provided
    ---@type boolean
    part.solidColor = false

    if type(values.solidColor) ~= "nil" then
        part.solidColor = values.solidColor
    elseif type(values.solid) ~= "nil" then
        part.solidColor = values.solid
    elseif type(values.solidcolor) ~= "nil" then
        part.solidColor = values.solidcolor
    end

    -- If the part should render as a circle
    ---@type boolean
    part.isCircle = false

    if type(values.isCircle) ~= "nil" then
        part.isCircle = values.isCircle
    elseif type(values.iscircle) ~= "nil" then
        part.isCircle = values.iscircle
    end

    -- If the part should be visible at the start
    ---@type boolean
    part.visible = true

    if type(values.visible) ~= "nil" then
        part.visible = values.visible
    elseif type(values.invisible) ~= "nil" then
        part.visible = (not values.invisible)
    end

    -- If the part's gfxscale and angle should initially be effected by directions
    ---@type boolean
    part.paper = false

    if type(values.paper) ~= "nil" then
        part.paper = values.paper
    elseif type(settings.paper) ~= "nil" then
        part.paper = settings.paper
    end

    -- If only the part's gfxscale should initially be effected by directions
    ---@type boolean
    part.paperdims = false

    if type(values.paperdims) ~= "nil" then
        part.paperdims = values.paperdims
    elseif type(settings.paperdims) ~= "nil" then
        part.paperdims = settings.paperdims
    end

    -- If only the part's rotation should initially be effected by directions
    ---@type boolean
    part.paperangle = false
    if type(values.paperangle) ~= "nil" then
        part.paperangle = values.paperangle
    elseif type(values.paperrotation) ~= "nil" then
        part.paperrotation = values.paperrotation
    elseif type(settings.paperdims) ~= "nil" then
        part.paperangle = settings.paperangle
    end

    -- If, when graphics get flipped from paper, they should be mirrored and not just the same on boh sides
    ---@type boolean
    part.paperflip = true
    if type(values.paperflip) ~= "nil" then
        part.paperflip = values.paperflip
    elseif type(values.nopaperflip) ~= "nil" then
        part.paperflip = (not values.nopaperflip)
    elseif type(settings.paperflip) ~= "nil" then
        part.paperflip = settings.paperflip
    end


    -- Position of the part relative to the puppet's X and Y
    ---@type Vector2
    part.pos = values.pos or vector(values.x or 0,values.y or 0)
    part.pos = vector(part.pos.x,part.pos.y)
    -- If the part's pivot position (pos) should always be where its position is, reguardless of its current rotation
    ---@type boolean
    part.dontRotatePos = values.dontRotatePos or false
    -- How much the part is rotated by default
    ---@type number
    part.rotation = values.rotation or 0
    -- The part's visual rotational offset
    ---@type number
    part.rotationoffset = values.rotationoffset or values.rotationOffset or 0
    -- How far can a part be rotated before it snaps back to 0?
    ---@type number
    part.rotationlimit = values.rotationlimit or 360
    -- If the part should start off hidden
    ---@type boolean
    part.isHidden = false
    if type(values.isHidden) ~= "nil" then
        part.isHidden = values.isHidden
    end
    -- Priority of the part relative to the puppet
    ---@type number
    part.priority = values.priority or values.priorityOffset or 0
    -- If the priority of the part should be independent of the puppet
    ---@type boolean
    part.indiepriority = false
    if type(values.indiepriority) ~= "nil" then
        part.indiepriority = values.indiepriority
    end

    -- Parent of the part which in itself is one of the parts
    ---@type string|number|nil
    part.parent = values.parent
    -- What frame does the puppet start out on
    ---@type Vector2
    part.frame = values.frame or vector(values.frameX or values.framex or 1,values.frameY or values.framey or 1)
    if type(part.frame) == "number" then
        part.frame = vector(8,part.frame)
    else
        part.frame = vector(part.frame.x,part.frame.y)
    end
    -- How long does it take for the frame to update by default (using game ticks, not animation ticks)
    ---@type Vector2
    part.framespeed = values.framespeed or vector(values.framespeedX or values.framespeedx or 8,values.framespeedY or values.framespeedy or 8)
    if type(part.framespeed) == "number" then
        part.framespeed = vector(8,part.framespeed)
    else
        part.framespeed = vector(part.framespeed.x,part.framespeed.y)
    end

    -- The default tint color of the part
    ---@type Color
    part.color = values.color or Color.white

    -- vertexCoords of the part
    ---@type table<integer,number>|nil
    part.vertexCoords = values.vertexCoords

    -- primitive of the part
    ---@type PrimitiveType|nil
    part.primitive = values.primitive

    -- textureCoords of the part
    ---@type table<integer,number>|nil
    part.textureCoords = values.textureCoords

    -- Initial textureCoords of the part
    ---@type table<integer,number>|nil
    part.vertexColors = values.vertexColors

    -- Initial texture of the part
    ---@type Shader|nil
    part.shader = values.shader

    -- Initial Uniforms for the part
    ---@type table
    part.uniforms = values.uniforms or {}

    -- Initial Attributes for the part
    ---@type table
    part.attributes = values.attributes or {}

    -- Initial CaptureBuffer Target of the part
    ---@type CaptureBuffer|nil
    part.CBTarget = values.CBTarget or values.CaptureBufferTarget or values.CaptureBuffer or nil

    -- Function that runs before the regular part updating function. Passes the part.
    ---@type function|nil
    part.onUpdate = values.onUpdate

    -- Function that runs after the regular part updating function. Passes the part.
    ---@type function|nil
    part.onPostUpdate = values.onPostUpdate

    -- Function that runs when the part draws. Passes the part and additional arguments that part:draw() recieves.
    ---@type function|nil
    part.onDraw = values.onDraw

    -- If the part's rendering direction offset shouldn't be effected by the puppet's direction
    ---@type boolean
    part.ignorePupDirection = false
    if type(values.ignorePupDirection) ~= "nil" then
        part.ignorePupDirection = values.ignorePupDirection
    end

    -- If the part's rendering direction offset shouldn't be effected by its own direction
    ---@type boolean
    part.ignoreDirection = false
    if type(values.ignoreDirection) ~= "nil" then
        part.ignoreDirection = values.ignoreDirection
    end

    -- If offset and pivot variables should be effected by the direction of the part.
    ---@type boolean
    part.offsetDirection = true
    if type(values.offsetDirection) ~= "nil" then
        part.offsetDirection = values.offsetDirection
    elseif type(values.offsetIgnoreDirection) ~= "nil" then
        part.offsetDirection = (not values.offsetIgnoreDirection)
    end

    -- Initial direction of the part
    ---@type Vector2
    part.direction = values.direction or vector(1,1)
    if type(values.direction) == "number" then
        part.direction = vector(values.direction,1)
    else
        part.direction = vector(part.direction.x,part.direction.y)
    end

    return part
end

-- Registers a puppet
---@param args table
---@return PuppetSettings
function puppet.registerPuppet(args)
    ---@class PuppetSettings
    local settings = {}

    -- The settings of each part of the puppet
    ---@type table<string|number,PuppetPartSettings>
    settings.parts = {}

    -- Root of the resources used for this puppet
    ---@type string
    settings.root = args.root or args.rootDirectory or args.directory or ""

    -- Extension to use for all of the texture files. Just makes things easier
    ---@type string
    settings.extension = args.extension or args.textureextension or args.imageextension or ".png"

    settings.root = tostring(settings.root)
    settings.extension = tostring(settings.extension)

    if settings.root[#settings.root] ~= "/" and settings.root[#settings.root] ~= "\\" then
        settings.root = settings.root.."/"
    end

    if settings.extension[1] ~= "." then
        settings.extension = "."..settings.extension
    end

    -- if the puppet's animation is effected by the level freezing
    ---@type boolean
    settings.effectedByFreeze = settings.effectedByFreeze or false

    -- Initial rendering offset of the puppet
    ---@type Vector2
    settings.offset = args.offset or vector(args.offsetX or args.offsetx or 0, args.offsetY or args.offsety or 0)
    settings.offset = vector(settings.offset.x,settings.offset.y)

    -- Initial pivot offset of the puppet
    ---@type Vector2
    settings.pivot = args.pivot or vector(args.pivotX or args.pivotx or 0, args.pivotY or args.pivoty or 0)
    settings.pivot = vector(settings.pivot.x,settings.pivot.y)

    -- Initial rotation of the puppet
    ---@type number
    settings.rotation = args.rotation or args.rotationOffset or 0

    -- How far can the puppet be rotated before it snaps back to 0?
    ---@type number
    settings.rotationlimit = args.rotationlimit or 360

    -- If the puppet should point with their parent at first
    ---@type boolean
    settings.pointparent = true
    if type(args.pointparent) ~= "nil" then
        settings.pointparent = args.pointparent
    end

    -- Initial direction of the puppet
    ---@type Vector2
    settings.direction = args.direction or vector(1,1)
    if type(args.direction) == "number" then
        settings.direction = vector(args.direction,1)
    else
        settings.direction = vector(settings.direction.x,settings.direction.y)
    end

    -- The effect to spawn when hiding/showing/despawning the puppet
    ---@type integer
    settings.effect = args.effect or 10

    -- Offset of the effect when spawning it (effected by direction)
    ---@type Vector2
    settings.effectoffset = args.effectoffset or args.effectOffset or vector(args.effectoffsetx or args.effectOffsetX or -16, args.effectoffsety or args.effectOffsetY or -16)
    settings.effectoffset = vector(settings.effectoffset.x,settings.effectoffset.y)

    -- If the puppet should act like paper and have the directions effect rendering
    ---@type boolean
    settings.paper = false
    if type(args.paper) ~= "nil" then
        settings.paper = args.paper
    end

    -- If the puppet should somewhat act like paper and have the directions effect the dimensions of rendering
    ---@type boolean
    settings.paperdims = false
    if type(args.paperdims) ~= "nil" then
        settings.paperdims = args.paperdims
    end

    -- Master priority of the puppet
    ---@type number
    settings.priority = args.priority or 0

    -- If the puppet should somewhat act like paper and have the directions effect the rotation of rendering
    ---@type boolean
    settings.paperrotation = false
    if type(args.paperrotation) ~= "nil" then
        settings.paperrotation = args.paperrotation
    elseif type(args.paperrotation) ~= "nil" then
        settings.paperrotation = args.paperrotation
    end

    -- If, when graphics get flipped from paper, they should be mirrored and not just the same on boh sides
    ---@type boolean
    settings.paperflip = true
    if type(args.paperflip) ~= "nil" then
        settings.paperflip = args.paperflip
    elseif type(args.nopaperflip) ~= "nil" then
        settings.paperflip = (not args.nopaperflip)
    end

    -- Animations
    ---@type table<string|number,PuppetAnimationSettings>
    settings.animations = {}

    -- Registering parts
    for partname, values in pairs(args.parts) do
        puppet.registerPart(settings,partname,values)
    end

    -- If true, nerd stuff will appear I guess
    ---@type boolean
    settings.debugMode = args.debugMode or args.debug or false

    -- Registering animations
    if args.animations then
        for index,values in pairs(args.animations) do
            settings.animations[index] = {}
            ---@class PuppetAnimationSettings
            local animation = settings.animations[index]
            -- How long does one animation tick take in real game ticks. Defaults to 64.1
            ---@type number
            animation.time = values.time or 64.1
            if animation.time == 0 then
                animation.time = 64
            end
            -- Offset of the animation's time in game ticks
            ---@type number
            animation.offset = 0
            -- The animation's primary easing function
            ---@type string|function
            animation.easing = values.easing or "linear"
            -- If true, the animation easing (and snap values like booleans and parents) will prioritize easing of the frames its on
            ---@type boolean
            animation.easestart = values.easestart or false
            -- If true, the animation easing (and snap values like booleans and parents) will prioritize the easing of the frame its heading towards
            ---@type boolean
            animation.easeend = values.easeend or false
            -- If true, nerd stuff will appear I guess
            ---@type boolean
            animation.debugMode = values.debugMode or values.debug or false

            -- Parts and how to animate them. The index of the PuppetPartAnimation table assigned is the time of the animation in its ticks.
            ---@type table<string|number,PuppetPartAnimation>
            animation.part = {}

            ---@type table<string|number,PuppetPartAnimation>
            values.parts = values.parts or {}

            -- The times at which animation happen for each part
            ---@type table<string|number,table<integer,number>>
            animation.times = {}

            for name,partanim in pairs(values.parts) do
                local part = settings.parts[name]

                partanim = partanim

                local gimmeback = false
                if not partanim[0] then
                    gimmeback = true
                    partanim[0] = {}
                    ---@class PuppetPartFrame
                    local default = partanim[0]
                    default.x = 0
                    default.y = 0
                    default.rotation = 0
                    default.scale = vector(1,1)
                    default.centered = part.centered
                end

                ---@class PuppetPartAnimation
                animation.part[name],animation.times[name] = clonetable(partanim)
                table.sort(animation.times[name])
                if gimmeback then
                    animation.part[name][0] = clonetable(animation.part[name][animation.times[name][#animation.times[name]]])
                end
            end

            -- How to animate the global rotation
            ---@type PuppetPartAnimation
            animation.rotation = values.rotation

            local rfix = (animation.rotation and not animation.rotation[0])
            if rfix then
                animation.rotation[0] = {value = true}
            end

            -- How to animate the global offset
            ---@type PuppetPartAnimation
            animation.offset = values.offset

            local ofix = (animation.offset and not animation.offset[0])
            if ofix then
                animation.offset[0] = {something = true}
            end

            -- How to animate the pivot point of the puppet
            ---@type PuppetPartAnimation
            animation.pivot = values.pivot

            local pfix = (animation.pivot and not animation.pivot[0])
            if pfix then
                animation.pivot[0] = {knowing = false}
            end

            -- How to animate the global direction of the puppet
            ---@type PuppetPartAnimation
            animation.direction = values.direction

            local dfix = (animation.direction and not animation.direction[0])
            if dfix then
                animation.direction[0] = {rights = true}
            end

            -- How to animate the global rotation
            ---@type PuppetPartAnimation
            animation.priority = values.priority

            local yfix = (animation.priority and not animation.priority[0])
            if yfix then
                animation.priority[0] = {express = true}
            end

            -- The times at which animation happen for rotation
            ---@type table<integer,number>
            animation.timesrotation = {}

            local _owo_,rtimes = clonetable(animation.rotation)
            if rtimes then
                table.sort(rtimes)
            end
---@diagnostic disable-next-line: assign-type-mismatch
            animation.timesrotation = rtimes

            if rtimes and rfix then
                animation.rotation[0] = clonetable(animation.rotation[rtimes[#rtimes]])
            end

            -- The times at which animation happen for the offset
            ---@type table<integer,number>
            animation.timesoffset = {}

            local _uwu_,otimes = clonetable(animation.offset)
            if otimes then
                table.sort(otimes)
            end
---@diagnostic disable-next-line: assign-type-mismatch
            animation.timesoffset = otimes

            if otimes and ofix then
                animation.offset[0] = clonetable(animation.offset[otimes[#otimes]])
            end


            -- The times at which animation happen for the pivot point
            ---@type table<integer,number>
            animation.timespivot = {}

            local _ovo_,ptimes = clonetable(animation.pivot)
            if ptimes then
                table.sort(ptimes)
            end
---@diagnostic disable-next-line: assign-type-mismatch
            animation.timespivot = ptimes

            if ptimes and pfix then
                animation.pivot[0] = clonetable(animation.pivot[ptimes[#ptimes]])
            end


            -- The times at which animation happen for the direction
            ---@type table<integer,number>
            animation.timesdirection = {}

            local _uvu_,dtimes = clonetable(animation.direction)
            if dtimes then
                table.sort(dtimes)
            end
---@diagnostic disable-next-line: assign-type-mismatch
            animation.timesdirection = dtimes

            if dtimes and dfix then
                animation.direction[0] = clonetable(animation.direction[dtimes[#dtimes]])
            end

            local _83_,ytimes = clonetable(animation.priority)
            if ytimes then
                table.sort(ytimes)
            end
---@diagnostic disable-next-line: assign-type-mismatch
            animation.timespriority = ytimes

            if ytimes and yfix then
                animation.priority[0] = clonetable(animation.priority[ytimes[#ytimes]])
            end
        end
    end

    -- Function that runs before the regular puppet updating function. Passes the puppet.
    ---@type function|nil
    settings.onUpdate = args.onUpdate

    -- Function that runs after the regular puppet updating function. Passes the puppet.
    ---@type function|nil
    settings.onPostUpdate = args.onPostUpdate

    -- Function that runs when the puppet draws. Passes the puppet and additional arguments that puppet:draw() recieves.
    ---@type function|nil
    settings.onDraw = args.onDraw

    -- If offset and pivot variables should be effected by the direction of the puppet
    ---@type boolean
    settings.offsetDirection = true
    if type(args.offsetDirection) ~= "nil" then
        settings.offsetDirection = args.offsetDirection
    elseif type(args.offsetIgnoreDirection) ~= "nil" then
        settings.offsetDirection = (not args.offsetIgnoreDirection)
    end

    -- Functional ID of the puppet (or it's name if no id is present)
    ---@type string|number
    settings.id = args.id or args.name
    -- Name of the puppet (or it's id if no name is present)
    ---@type string|number
    settings.name = args.name or args.id

    -- Animations to play at the start of the puppet's existence
    ---@type table
    settings.startAnimations = args.startAnimations or {}

    if args.startAnimation then
        settings.startAnimations[#settings.startAnimations+1] = args.startAnimation
    end

    puppet.settings[args.id or args.name] = settings

    return settings
end

-- A function that runs `puppet.registerPuppet`
function puppet.register(args)
    return puppet.registerPuppet(args)
end

-- just put everything in the correct slot and everything should be good, okay?
---comment
---@param puppy Puppet
---@param animate PuppetAnimation
---@param animation PuppetPartAnimation
---@param data table
---@param asettings PuppetAnimationSettings
---@param york table<integer,number>
---@param truetime number|nil
---@param efunk any|nil
---@return number gotta
---@return number min
---@return number max
---@return number dist
local function animateDoohickey(puppy,animate,animation,data,york,asettings,truetime,efunk)
    local dist = 0
    local min = 0
    local max = 0
    local adata = animate.data._base

    truetime = truetime or (animate.time/asettings.time)
    efunk = efunk or asettings.easing

    asettings = asettings or puppy.settings.animations

    local newyork = york[#york]

    if #york == 1 then
        return 0,0,0,0
    end

    local oldyork = york[1]
    local overshot = false
    local undershot = false

    -- Runs special things for animation things
    local function animeFunks(ttime,af)
        if adata.stopped or adata.paused or type(animation[ttime]) ~= "table" then return end
        if animation[ttime].finish then
            data.finished = af
        end
        if animation[ttime].stop --[[or animation[ttime].finish]] or animation[ttime].terminate then
            adata.stopped = true
            if animation[ttime].terminate then
                adata.terminate = true
                if animation[ttime].terminatefunction then
                    adata.terminatefunction = animation[ttime].terminatefunction
                end
            else
                if type(animation[ttime].stopfunction) == "function" then
                    animation[ttime].stopfunction(animate)
                end
            end
        elseif animation[ttime].pause then
            adata.paused = true
            if type(animation[ttime].pausefunction) == "function" then
                animation[ttime].pausefunction(animate)
            end
        end
        if animation[ttime].transform or animation[ttime].animation then
            animate.animation = animation[ttime].animation or animation[ttime].transform
            if animation[ttime].transform then
                animate.time = 0
            end
            adata.transformed = true
        end
        if animation[ttime].time then
            animate.time = animation[ttime].time*asettings.time
        end
    end

    local offness = 0
    data.offness = data.offness or 0

    while truetime > newyork do
        overshot = true
        offness = offness + 1
        truetime = truetime - newyork
    end
    while truetime < 0 do
        undershot = true
        offness = offness - 1
        truetime = truetime + newyork
    end
    if offness ~= data.offness then
        if offness > data.offness then
            animeFunks(newyork,#york)
        end
        if offness < data.offness then
            animeFunks(oldyork,1)
        end
        data.offness = offness
    end
    if data.finished then
        min = york[data.finished]
        max = york[data.finished]
        dist = 1
    else
        for af = 1, #york do
            local ttime = york[af]
            if truetime <= ttime then
                min = york[math.max(af-1,1)]
                max = york[math.min(af,#york)]
                local ruby = (max-min)
                if ruby == 0 then
                    ruby = 1
                end
                dist = (truetime-min)/ruby
                break
            else
                animeFunks(ttime,af)
                --Text.print(af,100,200)
            end
        end
    end
    if adata.transformed then
        adata.transformed = false
        asettings = puppy.settings.animations[animate.animation]
        return animateDoohickey(puppy,animate,animation,data,york,asettings,truetime,efunk)
    end
    local gotta = getNearest(truetime,min,max)

    local ease = efunk
    if type(ease) ~= "function" and ease ~= "nil" then
        ease = easing[efunk]
    end

    local animConfig = animation[gotta]

    if type(animConfig) == "table" then
        if animConfig.snap == "start" then
            gotta = min
        elseif animConfig.snap == "end" then
            gotta = max
        elseif not animConfig.snap then
            if asettings.easestart then
                gotta = min
            elseif asettings.easeend then
                gotta = max
            end
        end
    else
        if asettings.easestart then
            gotta = min
        elseif asettings.easeend then
            gotta = max
        end
    end
    if type(animConfig) == "table" then
        if type(animConfig.easing) == "function" or animConfig.easing == "nil" then
            ease = animConfig.easing
        elseif type(animConfig.easing) == "string" then
            ease = easing[animConfig.easing]
        end
    end

    if ease == "nil" then
        ease = function (idk,abc,onetwothree,everybodydotheflop)
            if gotta == min then
                return 0
            elseif gotta == max then
                return 1
            end
            return 0.5
        end
    end

    dist = ease(dist,0,1,1)

    return gotta,min,max,dist
end

-- Spawns a part for a puppet
---@param pal Puppet
---@param partname string|number
---@param pettings PuppetPartSettings
---@param pidx integer
function puppet.spawnPart(pal,partname,pettings,pidx)
    pal.part[partname] = {}
    ---@class PuppetPart
    local part = pal.part[partname]
    -- index of the part on its creation
    ---@type integer
    part.idx = pidx
    -- Name of the part
    ---@type string|number?
    part.name = pettings.name
    -- ID of the part
    ---@type string|number?
    part.id = pettings.id
    -- The part's data table
    ---@type table
    part.data = {
        -- Data used in the base of the script
        ---@type table
        _base = {},
        -- Data that gets altered every drawing frame
        ---@type table
        _draw = {},
    }
    -- X position of the part relative to the puppet/its parent
    ---@type number
    part.x = pettings.pos.x
    -- Y position of the part relative to the puppet/its parent
    ---@type number
    part.y = pettings.pos.y
    -- If the part is currently centered
    ---@type boolean
    part.centered = pettings.centered
    -- If the part is currently a circle
    ---@type boolean
    part.isCircle = pettings.isCircle
    -- If the part can be a solid color
    ---@type boolean
    part.solidColor = pettings.solidColor
    -- Parent of the part which is itself a part.
    ---@type string|number|nil
    part.parent = pettings.parent
    -- If the part should ignore the parent position and other values when set
    ---@type boolean
    part.ignoreparentpos = false
    -- If the part should ignore the puppet's position and other values when set
    ---@type boolean
    part.ignorepuppetpos = false
    -- Rendering priority of the part
    ---@type number
    part.priority = pettings.priority
    -- If the part's rendering priority should be the master priority
    ---@type boolean
    part.indiepriority = pettings.indiepriority
    -- Frame of the part
    ---@type Vector2
    part.frame = vector(pettings.frame.x,pettings.frame.y)
    -- Framespeed of the part
    ---@type Vector2
    part.framespeed = vector(pettings.framespeed.x,pettings.framespeed.y)
    -- Frametimer of the part
    ---@type Vector2
    part.frametimer = vector(0,0)
    -- The part's ultimate position (gets updated each draw frame)
    ---@type Vector2
    part.pos = vector(pal.x+part.x,pal.y+part.y)
    -- The part's rotation
    ---@type number
    part.rotation = pettings.rotation
    -- The limit of rotation that will snap back to 0 when reached
    ---@type number
    part.rotationlimit = pettings.rotationlimit
    -- If the part should update its frame animation
    ---@type boolean
    part.updateFrames = true
    -- If the part should tick up its frametimer
    ---@type boolean
    part.updateTimer = true

    -- If the direction of the part should also effect its rendering when drawing
    ---@type boolean
    part.paper = pettings.paper

    -- If the direction of the part should also effect its scale when drawing
    ---@type boolean
    part.paperdims = pettings.paperdims

    -- If the direction of the part should also effect its rotation when drawing
    ---@type boolean
    part.paperangle = pettings.paperangle

    -- If the direction of the part should make mirroring happen if paper is set to true
    ---@type boolean
    part.paperflip = pettings.paperflip

    -- The puppet this is attached to
    ---@type Puppet
    part.puppet = pal
    -- If the part should update and draw
    ---@type boolean
    part.isValid = true
    -- If the part shouldn't draw on the screen by default means
    ---@type boolean
    part.isHidden = pettings.isHidden

    -- Width of the part
    ---@type number
    part.width = pettings.width

    -- Height of the part
    ---@type number
    part.height = pettings.height

    -- The tint color of the part
    ---@type Color
    part.color = pettings.color

    -- Scale of the part
    ---@type Vector2
    part.scale = vector(pettings.scale.x,pettings.scale.y)

    -- Scale of the part GFX wise
    ---@type Vector2
    part.gfxscale = vector(pettings.gfxscale.x,pettings.gfxscale.y)

    -- Scale of the part's offset
    ---@type Vector2
    part.offsetScale = vector(pettings.offsetScale.x,pettings.offsetScale.y)

    -- If true, the part will ignore animation rotation
    ---@type boolean
    part.gfxignorerotation = false
    -- If true, the part's pivot point will ignore animation rotation
    ---@type boolean
    part.pivotignorerotation = false
    -- If true, the part's position will be corrected after it's been pivoted (it will go around its center)
    ---@type boolean
    part.correctPivot = false

    -- Settings of the part
    ---@type PuppetPartSettings
    part.settings = pettings

    -- If true, then the part will ignore all animation things
    ---@type boolean
    part.ignoreanimation = false

    -- The part's type
    ---@type "Part"
    part.__type = "Part"

    -- Independent direction of the puppet that multiplies the part poses
    ---@type Vector2
    part.direction = vector(pettings.direction.x,pettings.direction.y)

    -- If the part's rendering direction offset shouldn't be effected by the puppet's direction
    ---@type boolean
    part.ignorePupDirection = pettings.ignorePupDirection

    -- If the part's rendering direction offset shouldn't be effected by its own direction
    ---@type boolean
    part.ignoreDirection = pettings.ignoreDirection

    -- If offset and pivot variables should be effected by the direction of the part.
    ---@type boolean
    part.offsetDirection = pettings.offsetDirection

    -- If the part's framespeed should be set by animation
    ---@type boolean
    part.setframespeed = false

    -- Update the part
    function part:update()
        local ettings = self.settings
        if not ettings then return end
        self.rotation = self.rotation % ettings.rotationlimit
        if type(self.settings.onUpdate) == "function" then
            ettings.onUpdate(self)
        end

        local pup = self.puppet
        if pup then
            local petting = pup.settings
            if petting and not self.ignoreanimation then
                local addframespeed = false
                local addedspeed = vector(0,0)
                local deframespeed = vector(ettings.framespeed.x,ettings.framespeed.y)
                -- Iterating through all of the active animations the puppet has
                for layer,animate in pairs(pup.animations) do
                    if not animate.data._parts then
                        animate.data._parts = {}
                    end
                    local adata = animate.data._base
                    ---@type PuppetAnimationSettings
                    local asettings = petting.animations[animate.animation]
                    if asettings then
                        -- Checking to see if the settings of the animation have a part ID that matches the part ID of the part.
                        ---@type PuppetPartAnimation
                        local animation = asettings.part[self.id]
                        if animation then
                            if not animate.data._parts[self.id] then
                                animate.data._parts[self.id] = {}
                            end
                            -- Animation data table for the part (Everything)
                            local padata = animate.data._parts[self.id]
                            if not padata._base then
                                padata._base = {}
                            end
                            -- Animation data table for the part (Base script stuff)
                            local pbdata = padata._base
                            --local dist = 0
                            --local truetime = animate.time/asettings.time
                            local york = asettings.times[self.id]
                            --local efunk = asettings.easing

                            local gotta, min, max, dist = animateDoohickey(pup,animate,animation,pbdata,york,asettings--[[,truetime,efunk]])
                            local animConfigMin = animation[min]
                            local animConfigMax = animation[max]
                            if animConfigMin.framespeed or animConfigMin.frameSpeed or animConfigMin.framespeedx or animConfigMin.frameSpeedX or animConfigMin.framespeedy or animConfigMin.frameSpeedY or
                            animConfigMax.framespeed or animConfigMax.frameSpeed or animConfigMax.framespeedx or animConfigMax.frameSpeedX or animConfigMax.framespeedy or animConfigMax.frameSpeedY then
                                addframespeed = true
                                local mzeron = vector(0,0)
                                local mzerox = vector(0,0)
                                local setframespeed = checkSet(animation[gotta],"framespeed")
                                if setframespeed then
                                    mzeron = vector(deframespeed.x,deframespeed.y)
                                    mzerox = vector(deframespeed.x,deframespeed.y)
                                end

                                local fsmn = animConfigMin.framespeed or vector(animConfigMin.framespeedx or animConfigMin.frameSpeedX or mzeron.x,animConfigMin.framespeedy or animConfigMin.frameSpeedY or mzeron.y)
                                local fsmx = animConfigMax.framespeed or vector(animConfigMax.framespeedx or animConfigMax.frameSpeedX or mzerox.x,animConfigMax.framespeedy or animConfigMax.frameSpeedY or mzerox.y)
                                local fs = math.lerp(fsmn,fsmx,dist)

                                if setframespeed then
                                    deframespeed = fs
                                else
                                    addedspeed = addedspeed+fs
                                end
                            end
                        end
                    end
                end

                if addframespeed or self.setframespeed then
                    self.framespeed = deframespeed+addedspeed
                    if addframespeed then
                        self.setframespeed = true
                    else
                        self.setframespeed = false
                    end
                end

                puppet.checkForTerminations(pup.animations)
            end
        end


        if self.updateFrames then
            -- Ticking
            if self.updateTimer and (self.framespeed.x ~= 0 or self.framespeed.y ~= 0) then
                self.frametimer = self.frametimer + 1
            end
            if self.framespeed.x == 0 then
                self.frametimer.x = 0
            end
            if self.framespeed.y == 0 then
                self.frametimer.y = 0
            end
            -- Forwards 
            if self.framespeed.x ~= 0 and self.frametimer.x >= self.framespeed.x then
                self.frametimer.x = self.frametimer.x - self.framespeed.x
                self.frame.x = self.frame.x+1
                if self.frame.x > ettings.frames.x then
                    self.frame.x = self.frame.x-ettings.frames.x
                end
            end
            if self.framespeed.y ~= 0 and self.frametimer.y >= self.framespeed.y then
                self.frametimer.y = self.frametimer.y - self.framespeed.y
                self.frame.y = self.frame.y+1
                if self.frame.y > ettings.frames.y then
                    self.frame.y = self.frame.y-ettings.frames.y
                end
            end
            -- Backwards
            if self.framespeed.x ~= 0 and self.frametimer.x < 0 then
                self.frametimer.x = self.frametimer.x + self.framespeed.x
                self.frame.x = self.frame.x-1
                if self.frame.x < 1 then
                    self.frame.x = self.frame.x+ettings.frames.x
                end
            end
            if self.framespeed.y ~= 0 and self.frametimer.y < 0 then
                self.frametimer.y = self.frametimer.y + self.framespeed.y
                self.frame.y = self.frame.y-1
                if self.frame.y < 1 then
                    self.frame.y = self.frame.y+ettings.frames.y
                end
            end
        end
        if not self.settings then return end
        ---@type PuppetPartSettings
        local settings = self.settings
        if type(settings.onPostUpdate) == "function" then
            settings.onPostUpdate(self)
        end
    end

    -- If the part is currently visible
    ---@type boolean
    part.visible = pettings.visible

    -- Draw the part. (Without this function, this script is meaningless)
    ---@param dargs table|nil possible overrides
    function part:draw(dargs)
        dargs = dargs or {}
        local argsempty = true
        for _,__ in pairs(dargs) do
            argsempty = false
        end
        if not self.settings then return end
        ---@type PuppetPartSettings
        local settings = dargs.settings or self.settings
        local onDraw = settings.onDraw or self.settings.onDraw
        if type(onDraw) == "function" then
            onDraw(self,dargs)
        end
        local debugMode = dargs.debugMode or dargs.debug or settings.debugMode
        local ddata = self.data._draw
        -- Oh holy macaroni this is a lot
        -- Framestyle
        ---@type Vector2
        local framestyle = dargs.framestyle or settings.framestyle or self.settings.framestyle
        framestyle = vector(framestyle.x,framestyle.y)
        -- Frames
        ---@type Vector2
        local frames = dargs.frames or settings.framse or self.settings.frames
        frames = vector(frames.x,frames.y)
        -- Rotation limit
        ---@type number
        local rotationlimit = self.rotationlimit
        -- Primitive
        ---@type PrimitiveType|nil
        local primitive = dargs.primitive or self.primitive
        -- Uniforms
        ---@type table|nil
        local uniforms = dargs.uniforms or self.uniforms
        -- Attributes
        ---@type table|nil
        local attributes = dargs.attributes or self.attributes
        -- Capture Buffer
        ---@type CaptureBuffer|nil
        local captureBuffer = dargs.CBTarget or dargs.captureBuffer or dargs.capturebuffer or dargs.CB or self.CBTarget
        -- Render width
        ---@type number
        local width = dargs.width or self.width or settings.width or self.settings.width
        -- Render height
        ---@type number
        local height = dargs.height or self.height or settings.height or self.settings.height
        -- Frame width
        ---@type number
        local gfxwidth = dargs.gfxwidth or dargs.sourceWidth or dargs.width or settings.gfxwidth or settings.width or self.settings.gfxwidth or width
        -- Frame height
        ---@type number
        local gfxheight = dargs.gfxheight or dargs.sourceWHeight or dargs.height or settings.gfxheight or settings.height or self.settings.gfxheight or height
        -- Rotation
        ---@type number
        local rotation = dargs.rotation or self.rotation
        -- Render rotation offset
        ---@type number
        local rotationOffset = dargs.rotationoffset or dargs.rotationOffset or settings.rotationoffset or self.settings.rotationoffset
        -- Render position
        ---@type Vector2
        local pos = dargs.pos or vector(dargs.x or self.x,dargs.y or self.y)
        pos = vector(pos.x,pos.y)
        -- Render frame
        ---@type Vector2
        local frame = vector(dargs.frameX or dargs.framex or self.frame.x,dargs.frameY or dargs.framey or self.frame.y)
        if dargs.frame then
            if type(dargs.frame) == "number" then
                frame = vector(1,dargs.frame)
            else
                frame = dargs.frame
            end
        end
        frame = vector(frame.x,frame.y)
        -- Source offset
        ---@type Vector2
        local sourceOffset = dargs.sourceOffset or settings.sourceOffset or settings.sourceOffset or self.settings.sourceOffset
        sourceOffset = vector(sourceOffset.x,sourceOffset.y)
        -- Direction
        ---@type Vector2
        local direction = dargs.direction or self.direction
        direction = vector(direction.x,direction.y)
        -- Render Offset
        ---@type Vector2
        local offset = dargs.offset or vector(dargs.offsetX or dargs.offsetx or dargs.Xoffset or dargs.xoffset or settings.offset.x or self.settings.offset.x,
        dargs.offsetY or dargs.offsety or dargs.Yoffset or dargs.yoffset or settings.offset.y or self.settings.offset.y)
        offset = vector(offset.x,offset.y)
        -- If a puppet's direction should be ignored
        ---@type boolean
        local ignorePupDirection = self.ignorePupDirection
        if type(dargs.ignorePupDirection) ~= "nil" then
            ignorePupDirection = dargs.ignorePupDirection
        end
        -- If the direction should be ignored
        ---@type boolean
        local ignoreDirection = self.ignoreDirection
        if type(dargs.ignoreDirection) ~= "nil" then
            ignoreDirection = dargs.ignoreDirection
        end
        -- If offset should be effected by dirction
        ---@type boolean
        local offsetDirection = self.offsetDirection
        if type(dargs.offsetDirection) ~= "nil" then
            offsetDirection = dargs.offsetDirection
        end
        -- If framestyle should act like it does in the basegame...kinda
        ---@type boolean
        local legacyframestyle = settings.legacyframestyle
        if type(dargs.legacyframestyle) ~= "nil" then
            legacyframestyle = dargs.legacyframestyle
        end
        -- If X and Y frames should be swapped before rendering
        ---@type boolean
        local XYFrameSwap = settings.XYFrameSwap
        if type(dargs.XYFrameSwap) ~= "nil" then
            XYFrameSwap = dargs.XYFrameSwap
        end
        -- The rendering shader
        ---@type Shader|nil
        local shader = dargs.shader or self.shader
        -- Spacing inbetween the frames in the graphics
        ---@type Vector2
        local spacing = dargs.sourceSpacing or vector(dargs.sourceSpacingX or settings.sourceSpacing.x or self.settings.sourceSpacing.x
        ,dargs.sourceSpacingY or settings.sourceSpacing.y or self.settings.sourceSpacing.y)
        if type(spacing) == "number" then
            spacing = vector(spacing,spacing)
        else
            spacing = vector(spacing.x,spacing.y)
        end
        -- Dimensions of a frame
        ---@type Vector2
        local framedims = dargs.framedims or vector(dargs.framedimsx or (width+spacing.x*2),dargs.framedimsy or (height+spacing.y*2))
        framedims = vector(framedims.x,framedims.y)
        -- Default frame dimensions
        local defaultdims = framedims*(frame-1)
        defaultdims = defaultdims+spacing+sourceOffset
        -- Dimensions
        ---@type Vector2
        local dims = defaultdims

        -- Texture
        ---@type Texture|nil
        local texture = dargs.texture or settings.texture or self.settings.texture

        -- Color
        ---@type Color
        local color = dargs.color or Color(self.color.r,self.color.g,self.color.b,self.color.a)

        -- Centered
        ---@type boolean
        local center = self.centered

        if type(dargs.centered) ~= "nil" then
            center = dargs.centered
        end

        -- Solid Color
        ---@type boolean
        local solid = self.solidColor

        if type(dargs.solid) ~= "nil" then
            solid = dargs.solid
        elseif type(dargs.solidColor) ~= "nil" then
            solid = dargs.solidColor
        end

        -- Circular
        ---@type boolean
        local isCircle = self.isCircle

        if type(dargs.isCircle) ~= "nil" then
            isCircle = dargs.isCircle
        elseif type(dargs.iscircle) ~= "nil" then
            isCircle = dargs.iscircle
        end

        -- Use scene coordinates
        ---@type boolean
        local sceneCoords = true

        if type(dargs.sceneCoords) ~= "nil" then
            sceneCoords = dargs.sceneCoords
        end
        -- Paper effects
        ---@type boolean
        local paper = self.paper
        if type(dargs.paper) ~= "nil" then
            paper = dargs.paper
        end
        -- Paper dimensions
        ---@type boolean
        local paperdims = self.paperdims
        if type(dargs.paperdims) ~= "nil" then
            paperdims = dargs.paperdims
        end
        -- Paper rotation
        ---@type boolean
        local paperangle = self.paperangle
        if type(dargs.paperangle) ~= "nil" then
            paperangle = dargs.paperangle
        end
        -- Paper flipping
        ---@type boolean
        local paperflip = self.paperflip
        if type(dargs.paperflip) ~= "nil" then
            paperflip = dargs.paperflip
        end
        -- Ignore regular animations
        ---@type boolean
        local ignoreanimation = self.ignoreanimation
        if type(dargs.ignoreanimation) ~= "nil" then
            ignoreanimation = dargs.ignoreanimation
        end

        -- Dimensions scale
        ---@type Vector2
        local scale = dargs.scale or self.scale
        scale = vector(scale.x,scale.y)

        -- Rendering scale
        ---@type Vector2
        local gfxscale = dargs.gfxscale or self.gfxscale
        gfxscale = vector(gfxscale.x,gfxscale.y)
        

        -- If the GFX scale should multiply the regular scale when rendering
        ---@type boolean
        local mgfxs = self.settings.multiplygfxscale
        if type(dargs.mgfxs) ~= "nil" then
            mgfxs = dargs.mgfxs
        elseif type(dargs.multiplygfxscale) ~= "nil" then
            mgfxs = dargs.multiplygfxscale
        elseif type(settings.multiplygfxscale) ~= "nil" then
            mgfxs = settings.multiplygfxscale
        end

        -- Offset scale
        ---@type Vector2
        local offsetScale = dargs.offsetScale or self.offsetScale
        offsetScale = vector(offsetScale.x,offsetScale.y)

        -- Render priority
        ---@type number
        local priority = dargs.priority or self.priority

        -- If the rendering priority is independent
        ---@type boolean
        local indiepriority = self.indiepriority
        if type(dargs.indiepriority) ~= "nil" then
            indiepriority = dargs.indiepriority
        end
        -- The Part's puppet
        ---@type Puppet
        local pup = dargs.puppet or self.puppet
        -- If the part should ignore the puppet's pos
        ---@type boolean
        local ignorepuppetpos = self.ignorepuppetpos
        if type(dargs.ignorepuppetpos) ~= "nil" then
            ignorepuppetpos = dargs.ignorepuppetpos
        end
        -- Vertex Coords
        ---@type table|nil
        local vcoords = clonetable(self.vertexCoords)
        -- Texture Coords
        ---@type table|nil
        local tcoords = clonetable(self.textureCoords)
        -- Vertex Colors
        ---@type table|nil
        local vcolors = clonetable(self.vertexColors)

        -- If the part is visible and should be rendered (doesnt effect debug things)
        ---@type boolean
        local visible = self.visible

        -- if the function should recalculate dimensions entirely
        ---@type boolean
        local dimcalc = false
        -- if the function should recalculate frame dimensions
        ---@type boolean
        local framecalc = false

        if pup then
            local afterscale = nil
            if self.parent and pup.part[self.parent] and not self.ignoreparentpos then
                ---@type PuppetPart
                local mama = pup.part[self.parent]
                if mama.data._draw.initialized then
                    local ref = mama.data._draw
                    ddata.waitingInLine = false
                    afterscale = ref.scale
                    scale = scale*ref.scale
                    pos = pos*ref.scale
                    pos.x = pos.x+ref.pos.x
                    pos.y = pos.y+ref.pos.y
                    rotation = rotation+ref.rotation
                    priority = priority+ref.priority
                    visible = visible and ref.visible
                    direction = ref.direction*direction
                    offsetScale = offsetScale*ref.offsetScale
                elseif argsempty then
                    ddata.waitingInLine = true
                    return
                end
            end

            -- Add this to rotation limit
            local noscope = 0
            -- Add this to rotation
            local rotary = 0
            -- Add this to rotation offset
            local rotaroff = 0
            -- Add this to priority
            local prions = 0
            -- Multiply this with scale
            local scalar = vector(1,1)
            -- Multiply this with gfxscale
            local fattyfatfat = vector(1,1)
            -- Multiply this with offsetScale
            local oddscale = vector(1,1)
            -- Multiply this with the direction
            local pirection = vector(1,1)
            -- Add this to pos
            local posession = vector(0,0)
            -- Add this to offset
            local offsession = vector(0,0)

            local petting = pup.settings
            if petting and not ignoreanimation then
                -- Iterating through all of the active animations the puppet has
                for layer,animate in pairs(pup.animations) do
                    if not animate.data._parts then
                        animate.data._parts = {}
                    end
                    local adata = animate.data._base
                    ---@type PuppetAnimationSettings
                    local asettings = petting.animations[animate.animation]
                    if asettings then
                        -- Checking to see if the settings of the animation have a part ID that matches the part ID of the part.

                        ---@type PuppetPartAnimation
                        local animation = asettings.part[self.id]
                        if animation then
                            if not animate.data._parts[self.id] then
                                animate.data._parts[self.id] = {}
                            end
                            -- Animation data table for the part (Everything)
                            local padata = animate.data._parts[self.id]
                            if not padata._base then
                                padata._base = {}
                            end
                            -- Animation data table for the part (Base script stuff)
                            local pbdata = padata._base
                            --local dist = 0
                            --local truetime = animate.time/asettings.time
                            local york = asettings.times[self.id]
                            --local efunk = asettings.easing

                            local gotta, min, max, dist = animateDoohickey(pup,animate,animation,pbdata,york,asettings--[[,truetime,efunk]])

                            local animConfig = animation[gotta]
                            local animConfigMin = animation[min]
                            local animConfigMax = animation[max]

                            -- Centered
                            if type(animConfig.centered) ~= "nil" then
                                center = animConfig.centered
                            end

                            -- Solid Color
                            if type(animConfig.solid) ~= "nil" then
                                solid = animConfig.solid
                            elseif type(animConfig.solidColor) ~= "nil" then
                                solid = animConfig.solidColor
                            end

                            -- Circular
                            if type(animConfig.isCircle) ~= "nil" then
                                isCircle = animConfig.isCircle
                            elseif type(animConfig.iscircle) ~= "nil" then
                                isCircle = animConfig.iscircle
                            end

                            -- Paper values
                            if type(animConfig.paper) ~= "nil" then
                                paper = animConfig.paper
                            end

                            if type(animConfig.paperdims) ~= "nil" then
                                paperdims = animConfig.paperdims
                            end

                            if type(animConfig.paperangle) ~= "nil" then
                                paperangle = animConfig.paperangle
                            end

                            -- visibility
                            if type(animConfig.visible) ~= "nil" then
                                visible = animConfig.visible
                            elseif type(animConfig.invisible) ~= "nil" then
                                visible = (not animConfig.invisible)
                            end

                            -- Other booleans
                            if type(animConfig.ignorePupDirection) ~= "nil" then
                                ignorePupDirection = animConfig.ignorePupDirection
                            end

                            if type(animConfig.ignoreDirection) ~= "nil" then
                                ignoreDirection = animConfig.ignoreDirection
                            end

                            if type(animConfig.XYFrameSwap) ~= "nil" then
                                XYFrameSwap = animConfig.XYFrameSwap
                            end

                            if type(animConfig.offsetDirection) ~= "nil" then
                                offsetDirection = animConfig.offsetDirection
                            end

                            -- Graphic things

                            if animConfig.texture then
                                texture = animConfig.texture
                                framecalc = true
                            end

                            if animConfig.shader then
                                shader = animConfig.shader
                            end

                            if animConfig.uniforms then
                                uniforms = animConfig.uniforms
                            end

                            if animConfig.attributes then
                                attributes = animConfig.attributes
                            end

                            if animConfig.captureBuffer then
                                captureBuffer = animConfig.captureBuffer
                            end

                            -- Frame
                            if animConfig.frame then
                                framecalc = true
                                if type(animConfig.frame) == "number" then
                                    frame.y = animConfig.frame
                                else
                                    frame = vector(animConfig.frame.x,animConfig.frame.y)
                                end
                            end

                            if animConfig.frameX or animConfig.framex then
                                framecalc = true
                                frame.x = animConfig.frameX or animConfig.framex
                            end
                            if animConfig.frameY or animConfig.framey then
                                framecalc = true
                                frame.y = animConfig.frameY or animConfig.framey
                            end

                            -- GFX dimensions
                            if animConfig.gfxwidth or animConfig.sourceWidth then
                                framecalc = true
                                gfxwidth = animConfig.gfxwidth or animConfig.sourceWidth
                            end
                            if animConfig.gfxheight or animConfig.sourceHeight then
                                framecalc = true
                                gfxheight = animConfig.gfxheight or animConfig.sourceHeight
                            end

                            if animConfig.framedims or animConfig.framedimsX or animConfig.framedimsY then
                                framecalc = true
                                framedims = animConfig.framedims or vector(animConfig.framedimsX or framedims.x,animConfig.framedimsY or framedims.y)
                            end

                            if animConfig.sourceOffset or animConfig.sourceOffsetX or animConfig.sourceOffsetY then
                                framecalc = true
                                sourceOffset = animConfig.sourceOffset or vector(animConfig.sourceOffsetX or sourceOffset.x,animConfig.sourceOffsetY or sourceOffset.y)
                            end

                            if animConfig.dims or animConfig.dimsx or animConfig.dimsy then
                                dimcalc = true
                                dims = animConfig.dims or vector(animConfig.dimsx or dims.x,animConfig.dimsy or dims.y)
                            end

                            local cdist = math.clamp(dist)

                            -- Rotation

                            if checkSet(animConfig,"rotation") then
                                rotation = math.lerp(animConfigMin.rotation or animConfigMin.angle or rotation,animConfigMax.rotation or animConfigMax.angle or rotation,dist)
                            else
                                rotary = rotary+math.lerp(animConfigMin.rotation or animConfigMin.angle or 0,animConfigMax.rotation or animConfigMax.angle or 0,dist)
                            end

                            -- Rotation offset

                            if checkSet(animConfig,"rotationOffset") then
                                rotationOffset = math.lerp(animConfigMin.rotationOffset or animConfigMin.rotationoffset or rotationOffset,animConfigMax.rotationOffset or animConfigMax.rotationoffset or rotationOffset,dist)
                            else
                                rotaroff = rotaroff+math.lerp(animConfigMin.rotationOffset or animConfigMin.rotationoffset or 0,animConfigMax.rotationOffset or animConfigMax.rotationoffset or 0,dist)
                            end

                            -- Rotation Limit

                            if checkSet(animConfig,"rotation") then
                                rotationlimit = math.lerp(animConfigMin.rotationlimit or animConfigMin.angle or rotationlimit,animConfigMax.rotationlimit or animConfigMax.angle or rotationlimit,dist)
                            else
                                noscope = noscope+math.lerp(animConfigMin.rotationlimit or animConfigMin.angle or 0,animConfigMax.rotationlimit or animConfigMax.angle or 0,dist)
                            end

                            -- Priority

                            if checkSet(animConfig,"priority") then
                                priority = math.lerp(animConfigMin.priority or animConfigMin.prior or priority,animConfigMax.priority or animConfigMax.prior or priority,dist)
                            else
                                prions = prions+math.lerp(animConfigMin.priority or animConfigMin.prior or 0,animConfigMax.priority or animConfigMax.prior or 0,dist)
                            end

                            -- Color

                            local clrmn = {
                                r = color.r,
                                g = color.g,
                                b = color.b,
                                a = color.a,
                            }
                            local clrmx = clonetable(clrmn)

                            if animConfigMin.color then
                                clrmn.r = animConfigMin.color.r or animConfigMin.color.red or animConfigMin.color.R or animConfigMin.color.Red or clrmn.r
                                clrmn.g = animConfigMin.color.g or animConfigMin.color.green or animConfigMin.color.G or animConfigMin.color.Green or clrmn.g
                                clrmn.b = animConfigMin.color.b or animConfigMin.color.blue or animConfigMin.color.B or animConfigMin.color.Blue or clrmn.b
                                clrmn.a = animConfigMin.color.a or animConfigMin.color.alpha or animConfigMin.color.A or animConfigMin.color.Alpha or clrmn.a
                            end
                            clrmn.r = animConfigMin.RED or animConfigMin.red or animConfigMin.Red or animConfigMin.colorr or animConfigMin.colorred or animConfigMin.colorR or animConfigMin.colorRed or clrmn.r
                            clrmn.g = animConfigMin.GREEN or animConfigMin.green or animConfigMin.Green or animConfigMin.colorg or animConfigMin.colorgreen or animConfigMin.colorG or animConfigMin.colorGreen or clrmn.g
                            clrmn.b = animConfigMin.BLUE or animConfigMin.blue or animConfigMin.Blue or animConfigMin.colorb or animConfigMin.colorblue or animConfigMin.colorB or animConfigMin.colorBlue or clrmn.b
                            clrmn.a = animConfigMin.ALPHA or animConfigMin.alpha or animConfigMin.Alpha or animConfigMin.colora or animConfigMin.coloralpha or animConfigMin.colorA or animConfigMin.colorAlpha or clrmn.a
                            if animConfigMax.color then
                                clrmx.r = animConfigMax.color.r or animConfigMax.color.red or animConfigMax.color.R or animConfigMax.color.Red or clrmx.r
                                clrmx.g = animConfigMax.color.g or animConfigMax.color.green or animConfigMax.color.G or animConfigMax.color.Green or clrmx.g
                                clrmx.b = animConfigMax.color.b or animConfigMax.color.blue or animConfigMax.color.B or animConfigMax.color.Blue or clrmx.b
                                clrmx.a = animConfigMax.color.a or animConfigMax.color.alpha or animConfigMax.color.A or animConfigMax.color.Alpha or clrmx.a
                            end
                            clrmx.r = animConfigMax.RED or animConfigMax.red or animConfigMax.Red or animConfigMax.colorr or animConfigMax.colorred or animConfigMax.colorR or animConfigMax.colorRed or clrmx.r
                            clrmx.g = animConfigMax.GREEN or animConfigMax.green or animConfigMax.Green or animConfigMax.colorg or animConfigMax.colorgreen or animConfigMax.colorG or animConfigMax.colorGreen or clrmx.g
                            clrmx.b = animConfigMax.BLUE or animConfigMax.blue or animConfigMax.Blue or animConfigMax.colorb or animConfigMax.colorblue or animConfigMax.colorB or animConfigMax.colorBlue or clrmx.b
                            clrmx.a = animConfigMax.ALPHA or animConfigMax.alpha or animConfigMax.Alpha or animConfigMax.colora or animConfigMax.coloralpha or animConfigMax.colorA or animConfigMax.colorAlpha or clrmx.a

                            local cr = math.clamp(math.lerp(clrmn.r,clrmx.r,dist))
                            local cg = math.clamp(math.lerp(clrmn.g,clrmx.g,dist))
                            local cb = math.clamp(math.lerp(clrmn.b,clrmx.b,dist))
                            local ca = math.clamp(math.lerp(clrmn.a,clrmx.a,dist))

                            color = Color(cr,cg,cb,ca)

                            -- Position

                            local ps = vector(1,1)
                            local pcx = checkSet(animConfig,"pos") or checkSet(animConfig,"position") or checkSet(animConfig,"posx") or checkSet(animConfig,"posX") or checkSet(animConfig,"x")
                            local pcy = checkSet(animConfig,"pos") or checkSet(animConfig,"position") or checkSet(animConfig,"posy") or checkSet(animConfig,"posY") or checkSet(animConfig,"y")
                            if pcx then
                                ps.x = pos.x
                            end
                            if pcy then
                                ps.y = pos.y
                            end

                            local mnp = vector(animConfigMin.x or 0,animConfigMin.y or 0)
                            if animConfigMin.pos or animConfigMin.position then
                                mnp = animConfigMin.pos or animConfigMin.position
                            end
                            local mxp = vector(animConfigMax.x or 0,animConfigMax.y or 0)
                            if animConfigMax.pos or animConfigMax.position then
                                mxp = animConfigMax.pos or animConfigMax.position
                            end
                            local pp = math.lerp(mnp,mxp,dist)

                            if checkSet(animConfig,"pos") or checkSet(animConfig,"position") then
                                pos = ps
                            elseif pcx then
                                pos.x = ps.x
                                posession.y = posession.y+pp.y
                            elseif pcy then
                                pos.y = ps.y
                                posession.x = posession.x+pp.x
                            else
                                posession = posession+pp
                            end

                            -- Offset

                            ps = vector(1,1)
                            pcx = checkSet(animConfig,"off") or checkSet(animConfig,"offset") or checkSet(animConfig,"offsetx") or checkSet(animConfig,"offsetX") or checkSet(animConfig,"xoffset")
                            pcy = checkSet(animConfig,"off") or checkSet(animConfig,"offset") or checkSet(animConfig,"offsety") or checkSet(animConfig,"offsetY") or checkSet(animConfig,"yoffset")
                            if pcx then
                                ps.x = offset.x
                            end
                            if pcy then
                                ps.y = offset.y
                            end

                            mnp = vector(animConfigMin.x or 0,animConfigMin.y or 0)
                            if animConfigMin.off or animConfigMin.offset then
                                mnp = animConfigMin.off or animConfigMin.offset
                            end
                            mxp = vector(animConfigMax.x or 0,animConfigMax.y or 0)
                            if animConfigMax.off or animConfigMax.offset then
                                mxp = animConfigMax.off or animConfigMax.offset
                            end
                            pp = math.lerp(mnp,mxp,dist)

                            if checkSet(animConfig,"off") or checkSet(animConfig,"offset") then
                                offset = ps
                            elseif pcx then
                                offset.x = ps.x
                                offsession.y = offsession.y+pp.y
                            elseif pcy then
                                offset.y = ps.y
                                offsession.x = offsession.x+pp.x
                            else
                                offsession = offsession+pp
                            end

                            -- Dimensions

                            local mnwh = vector(animConfigMin.width or width,animConfigMin.height or height)
                            if animConfigMin.dimensions then
                                mnp = animConfigMin.dimensions
                            end
                            local mxwh = vector(animConfigMax.width or width,animConfigMax.height or height)
                            if animConfigMax.dimensions then
                                mxwh = animConfigMax.dimensions
                            end
                            local wh = math.lerp(mnwh,mxwh,dist)
                            width = wh.x
                            height = wh.y

                            -- Scale

                            local s = vector(1,1)
                            local scx = checkSet(animConfig,"scale") or checkSet(animConfig,"scalex") or checkSet(animConfig,"scaleX")
                            local scy = checkSet(animConfig,"scale") or checkSet(animConfig,"scaley") or checkSet(animConfig,"scaleY")
                            if scx then
                                s.x = scale.x
                            end
                            if scy then
                                s.y = scale.y
                            end

                            local mns = vector(animConfigMin.scaleX or animConfigMin.scalex or s.x,animConfigMin.scaleY or animConfigMin.scaley or s.y)
                            if animConfigMin.scale then
                                if type(animConfigMin.scale) == "number" then
                                    mns = vector(animConfigMin.scale,animConfigMin.scale)
                                else
                                    mns = animConfigMin.scale
                                end
                            end
                            local mxs = vector(animConfigMax.scaleX or animConfigMax.scalex or s.x,animConfigMax.scaleY or animConfigMax.scaley or s.y)
                            if animConfigMax.scale then
                                if type(animConfigMax.scale) == "number" then
                                    mxs = vector(animConfigMax.scale,animConfigMax.scale)
                                else
                                    mxs = animConfigMax.scale
                                end
                            end
                            local sc = math.lerp(mns,mxs,dist)

                            if checkSet(animConfig,"scale") then
                                scale = sc
                            elseif scx then
                                scale.x = sc.x
                                scalar.y = scalar.y*sc.y
                            elseif scy then
                                scale.y = sc.y
                                scalar.x = scalar.x*sc.x
                            else
                                scalar = scalar*sc
                            end

                            -- GFX Scale

                            s = vector(1,1)
                            scx = checkSet(animConfig,"gfxscale") or checkSet(animConfig,"gfxscalex") or checkSet(animConfig,"gfxScaleX")
                            scy = checkSet(animConfig,"gfxscale") or checkSet(animConfig,"gfxscaley") or checkSet(animConfig,"gfxScaleY")
                            if checkSet(animConfig,"gfxscale") then
                                s = gfxscale
                            end

                            local gmns = vector(animConfigMin.gfxscalex or animConfigMin.gfxScaleX or s.x,animConfigMin.gfxscaley or animConfigMin.gfxScaleY or s.y)
                            if animConfigMin.gfxscale then
                                if type(animConfigMin.gfxscale) == "number" then
                                    gmns = vector(animConfigMin.gfxscale,animConfigMin.gfxscale)
                                else
                                    gmns = animConfigMin.gfxscale
                                end
                            end
                            local gmxs = vector(animConfigMax.gfxscalex or animConfigMax.gfxScaleX or s.x,animConfigMax.gfxscaley or animConfigMax.gfxScaleY or s.y)
                            if animConfigMax.gfxscale then
                                if type(animConfigMax.gfxscale) == "number" then
                                    gmxs = vector(animConfigMax.gfxscale,animConfigMax.gfxscale)
                                else
                                    gmxs = animConfigMax.gfxscale
                                end
                            end
                            local gsc = math.lerp(gmns,gmxs,dist)

                            if checkSet(animConfig,"gfxscale") then
                                gfxscale = gsc
                            elseif scx then
                                gfxscale.x = gsc.x
                                fattyfatfat.y = fattyfatfat.y*gsc.y
                            elseif scy then
                                gfxscale.y = gsc.y
                                fattyfatfat.x = fattyfatfat.x*gsc.x
                            else
                                fattyfatfat = fattyfatfat*gsc
                            end

                            -- Offset Scale

                            s = vector(1,1)
                            scx = checkSet(animConfig,"offsetscale") or checkSet(animConfig,"offsetScale") or checkSet(animConfig,"offsetscalex") or checkSet(animConfig,"offsetScaleX")
                            scy = checkSet(animConfig,"offsetscale") or checkSet(animConfig,"offsetScale") or checkSet(animConfig,"offsetscaley") or checkSet(animConfig,"offsetScaleY")

                            if checkSet(animConfig,"offsetscale") or checkSet(animConfig,"offsetScale") then
                                s = offsetScale
                            end

                            gmns = vector(animConfigMin.offsetscalex or animConfigMin.offsetScaleX or s.x,animConfigMin.offsetscaley or animConfigMin.offsetScaleY or s.y)

                            local oofscal = animConfigMin.offsetScale or animConfigMin.offsetscale

                            if oofscal then
                                if type(oofscal) == "number" then
                                    gmns = vector(oofscal,oofscal)
                                else
                                    gmns = oofscal
                                end
                            end

                            gmxs = vector(animConfigMax.offsetscalex or animConfigMax.offsetScaleX or s.x,animConfigMax.offsetscaley or animConfigMax.offsetScaleY or s.y)

                            oofscal = animConfigMax.offsetScale or animConfigMax.offsetscale

                            if oofscal then
                                if type(oofscal) == "number" then
                                    gmxs = vector(oofscal,oofscal)
                                else
                                    gmxs = oofscal
                                end
                            end
                            gsc = math.lerp(gmns,gmxs,dist)

                            if checkSet(animConfig,"offsetscale") or checkSet(animConfig,"offsetScale") then
                                offsetScale = gsc
                            elseif scx then
                                offsetScale.x = gsc.x
                                oddscale.y = oddscale.y*gsc.y
                            elseif scy then
                                offsetScale.y = gsc.y
                                oddscale.x = oddscale.x*gsc.x
                            else
                                oddscale = oddscale*gsc
                            end

                            -- Directions

                            s = vector(1,1)
                            scx = checkSet(animConfig,"direction") or checkSet(animConfig,"directionX") or checkSet(animConfig,"directionx")
                            scy = checkSet(animConfig,"direction") or checkSet(animConfig,"directionY") or checkSet(animConfig,"directiony")
                            if checkSet(animConfig,"direction") then
                                s = direction
                            end

                            local mnd = vector(animConfigMin.directionX or animConfigMin.directionx or s.x,animConfigMin.directionY or animConfigMin.directiony or s.y)
                            if animConfigMin.direction then
                                if type(animConfigMin.direction) == "number" then
                                    mnd = vector(animConfigMin.direction,1)
                                else
                                    mnd = animConfigMin.direction
                                end
                            end
                            local mxd = vector(animConfigMax.directionX or animConfigMax.directionx or s.x,animConfigMax.directionY or animConfigMax.directiony or s.y)
                            if animConfigMax.direction then
                                if type(animConfigMax.direction) == "number" then
                                    mxd = vector(animConfigMax.direction,1)
                                else
                                    mxd = animConfigMax.direction
                                end
                            end
                            local dir = math.lerp(mnd,mxd,dist)
                            direction = direction*dir

                            if checkSet(animConfig,"direction") then
                                direction = dir
                            elseif scx then
                                direction.x = dir.x
                                pirection.y = pirection.y*dir.y
                            elseif scy then
                                direction.y = dir.y
                                pirection.x = pirection.x*dir.x
                            else
                                pirection = pirection*dir
                            end

                            -- Vertex Coords
                            if vcoords and (animConfigMin.vertexCoords or animConfigMax.vertexCoords) then
                                for i,coord in ipairs(vcoords) do
                                    local mimin = coord
                                    local mamax = coord
                                    if animConfigMin.vertexCoords and animConfigMin.vertexCoords[i] then
                                        mimin = animConfigMin.vertexCoords[i]
                                    end
                                    if animConfigMax.vertexCoords and animConfigMax.vertexCoords[i] then
                                        mamax = animConfigMax.vertexCoords[i]
                                    end
                                    vcoords[i] = math.lerp(mimin,mamax,dist)
                                end
                            end
                            -- Texture Coords
                            if tcoords and (animConfigMin.textureCoords or animConfigMax.textureCoords) then
                                for i,coord in ipairs(tcoords) do
                                    local mimin = coord
                                    local mamax = coord
                                    if animConfigMin.textureCoords and animConfigMin.textureCoords[i] then
                                        mimin = animConfigMin.textureCoords[i]
                                    end
                                    if animConfigMax.textureCoords and animConfigMax.textureCoords[i] then
                                        mamax = animConfigMax.textureCoords[i]
                                    end
                                    tcoords[i] = math.lerp(mimin,mamax,dist)
                                end
                            end
                            -- Vertex Colors
                            if vcolors and (animConfigMin.vertexColors or animConfigMax.vertexColors) then
                                for i,coord in ipairs(tcoords) do
                                    local mimin = coord
                                    local mamax = coord
                                    if animConfigMin.vertexColors and animConfigMin.vertexColors[i] then
                                        mimin = animConfigMin.vertexColors[i]
                                    end
                                    if animConfigMax.vertexColors and animConfigMax.vertexColors[i] then
                                        mamax = animConfigMax.vertexColors[i]
                                    end
                                    vcolors[i] = math.lerp(mimin,mamax,dist)
                                end
                            end
                        end
                    end
                end
            end

            --Text.print(offsetScale,100,80)
            --Text.print(oddscale,100,100)

            rotation = rotation+rotary
            rotationlimit = rotationlimit+noscope
            rotationOffset = rotationOffset+rotaroff
            priority = priority+prions
            scale = scale*scalar
            gfxscale = gfxscale*fattyfatfat
            offsetScale = offsetScale*oddscale
            direction = direction*pirection
            pos = pos+posession
            offset = offset+offsession

            if not indiepriority then
                priority = priority+pup.priority
            end
        end

        if not dimcalc then
            if (framestyle.x ~= 0 or framestyle.y ~= 0) then
                framecalc = true
                local direct = vector(1,1)

                local fs = vector(framestyle.x,framestyle.y)
                if legacyframestyle then
                    local storex = framestyle.x
                    fs.x = framestyle.y
                    fs.y = storex
                    --local storex = direct.x
                    --dire.x = direct.y
                    --dire.y = storex
                end

                if fs.x == 2 or fs.x == 3 then
                    direct.x = direct.x*direction.x
                end
                if fs.y == 2 or fs.y == 3 then
                    direct.y = direct.y*direction.y
                end
                if pup then
                    if fs.x == 1 or fs.x == 3 then
                        direct.x = direct.x*pup.direction.x
                    end
                    if fs.y == 1 or fs.y == 3 then
                        direct.y = direct.y*pup.direction.y
                        --SFX.play(1)
                    end
                end

                local dire = vector(direct.x,direct.y)

                if legacyframestyle then
                    --local storex = framestyle.x
                    --fs.x = framestyle.y
                    --fs.y = storex
                    --local storex = direct.x
                    --dire.x = direct.y
                    --dire.y = storex
                end

                if debugMode then
                    Text.print(framestyle.x,100,100)
                    Text.print(framestyle.y,100,120)
                    Text.print(fs.x,200,100)
                    Text.print(fs.y,200,120)
                    Text.print(pup.direction.x,300,100)
                    Text.print(pup.direction.y,300,120)
                    Text.print(dire.x,400,100)
                    Text.print(dire.y,400,120)
                end

                if fs.x ~= 0 then
                    if dire.x > 0 then
                        if legacyframestyle then
                            frame.y = frame.y+frames.y
                        else
                            frame.x = frame.x+frames.x
                        end
                        framecalc = true
                    end
                end
                if fs.y ~= 0 then
                    if dire.y > 0 then
                        if legacyframestyle then
                            frame.y = frame.y+frames.y*2
                        else
                            frame.y = frame.y+frames.y
                        end
                        framecalc = true
                    end
                end
            end
            if XYFrameSwap then
                frame = vector(frame.y,frame.x)
                framecalc = true
            end
            if framecalc then
                -- For the sake of the me, all of these are vectors, btw.
                dims = framedims*(frame-1)+spacing+sourceOffset
            end
        end


        if self.gfxignorerotation then
            rotation = self.rotation
        end

        if argsempty then
            self.pos = pos
            ddata.initialized = true
            ddata.pos = vector(pos.x,pos.y):rotate(rotation)
            ddata.scale = scale
            ddata.rotation = rotation
            ddata.priority = priority-self.priority
            ddata.visible = visible
            ddata.offsetScale = offsetScale
            if pup and not indiepriority then
                ddata.priority = ddata.priority-pup.priority
            end
            ddata.direction = direction
        end

        --if self.pivotignorerotation then
        --    pos = pos:rotate(rotation)
        --end

        if not self.pivotignorerotation then
            offset = offset:rotate(rotation)
        end

        if offsetDirection then
            offset = offset*direction
        end

        pos = pos+offset*offsetScale

        --if not self.pivotignorerotation then
        --    pos = pos:rotate(rotation)
        --end

        local dir = vector(direction.x,direction.y)

        if pup and not ignorepuppetpos then
            local offerset = vector(pup.offset.x,pup.offset.y)
            local pivot = vector(pup.pivot.x,pup.pivot.y)
            local rpivot = vector(pup.rpivot.x,pup.rpivot.y)
            pos = pos:rotate(pup.rotation)+rpivot
            if offsetDirection then
                offerset = offerset*direction
                pivot = pivot*direction
                rpivot = rpivot*direction
            end
            pos = pos+offerset
            if self.correctPivot then
                pos = pos-pivot
            end
            rotation = rotation+pup.rotation
            local wtfdir = vector(dir.x,dir.y)
            if ignoreDirection then
                wtfdir = vector(1,1)
            end
            if not ignorePupDirection then
                dir = dir*pup.direction
                wtfdir = vector(dir.x,dir.y)
            end
            pos = pos*wtfdir
            -- Point of no return for the pos
            pos.x = pos.x+pup.x
            pos.y = pos.y+pup.y
        end

        local s = vector(gfxscale.x,gfxscale.y)

        if mgfxs then
            s = scale*s
        end

        local rwidth
        local rheight
        local posx
        local posy

        if not vcoords then
            rwidth = width*s.x
            rheight = height*s.y
            if paper or paperdims then
                --SFX.play(1)
                rwidth = rwidth*dir.x
                rheight = rheight*dir.y
                if not paperflip then
                    rwidth = math.abs(rwidth)
                    rheight = math.abs(rheight)
                end
            end
            posx = pos.x
            posy = pos.y
        end
        rotation = (rotation % rotationlimit) + rotationOffset
        if paper or paperangle then
            rotation = rotation*dir.x*dir.y
        end
        local dimx
        local dimy
        if (not tcoords) or #tcoords <= 0 then
            dimx = dims.x
            dimy = dims.y
        else
---@diagnostic disable-next-line: cast-local-type
            gfxwidth = nil
---@diagnostic disable-next-line: cast-local-type
            gfxheight = nil
        end
        --if debugMode then
        --    Text.printWP(direction.x,pos.x-(16+camera.x),pos.y-(16+camera.y),priority+10)
        --    Text.printWP(direction.y,pos.x-(16+camera.x),pos.y-(camera.y),priority+10)
        --    Text.printWP(self.direction.x,pos.x+50-(16+camera.x),pos.y-(16+camera.y),priority+10)
        --    Text.printWP(self.direction.y,pos.x+50-(16+camera.x),pos.y-(camera.y),priority+10)
        --end
        if debugMode then
            Graphics.drawCircle{
                x = pos.x,
                y = pos.y,
                sceneCoords = true,
                radius = 4,
                priority = math.max(-10,priority+1),
                color = Color(1,0,0,0.75)
            }
        end

        if not visible then return end

        if not texture then
            if solid then
                texture = nil
            else
                return
            end
        end

        local glDrew = {sceneCoords = sceneCoords,
            priority = priority,

            color = color,
            shader = shader,
---@diagnostic disable-next-line: assign-type-mismatch
            vertexCoords = vcoords,
            vertexColors = vcolors,
            textureCoords = tcoords,
            primitive = primitive,
            uniforms = uniforms,
            attributes = attributes,
            captureBuffer = captureBuffer,
        }

        local boxDrew = {
            texture = texture,
            x = posx,
            y = posy,
            sourceX = dimx,
            sourceY = dimy,
            sourceWidth = gfxwidth,
            sourceHeight = gfxheight,
            width = rwidth,
            height = rheight,
            centered = center,
            rotation = rotation,
        }

        local rs = 0
        if not center then
            rs = -(rwidth+rheight)/4
        end
        
        local circleDrew = {
            texture = texture,
            x = posx+rs,
            y = posy+rs,
            sourceX = dimx,
            sourceY = dimy,
            sourceWidth = gfxwidth,
            sourceHeight = gfxheight,
            radius = (rwidth+rheight)/4,
            centered = center,
            rotation = rotation,
        }

        if isCircle then
            Graphics.drawCircle(table.join(glDrew,circleDrew))
        else
            Graphics.drawBox(table.join(glDrew,boxDrew))
        end
        

        
    end

    -- vertexCoords of the part
    ---@type table<integer,number>|nil
    part.vertexCoords = pettings.vertexCoords

    -- primitive of the part
    ---@type PrimitiveType|nil
    part.primitive = pettings.primitive

    -- textureCoords of the part
    ---@type table<integer,number>|nil
    part.textureCoords = pettings.textureCoords

    -- textureCoords of the part
    ---@type table<integer,number>|nil
    part.vertexColors = pettings.vertexColors

    -- texture of the part
    ---@type Shader|nil
    part.shader = pettings.shader

    -- Uniforms for the part
    ---@type table
    part.uniforms = pettings.uniforms

    -- Attributes for the part
    ---@type table
    part.attributes = pettings.attributes

    -- CaptureBuffer Target of the part
    ---@type CaptureBuffer|nil
    part.CBTarget = pettings.CBTarget
end


-- Spawns in a new puppet object based on a registered puppet `id`.
---@param args table
---@return Puppet
function puppet.spawnPuppet(args)
    ---@class Puppet
    local pal = {
        -- Functional ID of the puppet (or it's name if no id is present)
        ---@type string|number?
        id = args.id or args.name,
    }

    if not pal.id then
        error("No puppet ID specified")
    end

    if not puppet.settings[pal.id] then
        error("The puppet ID \""..tostring(args.id).."\" isn't registered")
    end

    -- Settings of the puppet, which default to the settings that were registered when puppet.register was called
    ---@type PuppetSettings
    pal.settings = clonetable(puppet.settings[pal.id])

    -- Name of the puppet (or it's id if no name is present) For asthetic/sorting purposes only
    ---@type string|number?
    pal.name = args.name or pal.settings.name or pal.id

    -- Parent of the puppet. Requires at least x and y values, but can have other values as well.
    ---@type {x:number,y:number}|nil
    pal.parent = args.parent

    -- X position of the puppet
    ---@type number
    pal.x = args.x or 0
    -- Y position of the puppet
    ---@type number
    pal.y = args.y or 0

    -- Global rotation of the puppet
    pal.rotation = args.rotation or args.angle or 0

    -- True if the center point should be the parent's direct X and Y (only a thing if width and height exist too)
    ---@type boolean
    pal.parentcentered = args.parentcentered or false

    -- Rendering offset of the puppet
    ---@type Vector2
    pal.offset = args.offset or vector(args.offsetX or args.offsetx or pal.settings.offset.x, args.offsetY or args.offsety or pal.settings.offset.y)
    pal.offset = vector(pal.offset.x,pal.offset.y)
    if pal.parent then
        pal.offset.x = pal.offset.x+pal.x
        pal.offset.y = pal.offset.y+pal.y
        pal.x = 0
        pal.y = 0
    end

    -- Pivoting (rotational) point of the puppet. Think of it like a second offset
    ---@type Vector2
    pal.pivot = args.pivot or vector(args.pivotX or args.pivotx or pal.settings.pivot.x, args.pivotY or args.pivoty or pal.settings.pivot.y)
    pal.pivot = vector(pal.pivot.x,pal.pivot.y)

    -- The pivot point after it has been rotated
    ---@type Vector2
    pal.rpivot = pal.pivot:rotate(pal.rotation)
    pal.rpivot = vector(pal.rpivot.x,pal.rpivot.y)

    -- Facing direction of the puppet that multiplies the part poses
    ---@type Vector2
    pal.direction = vector(1,1)

    -- Rendering priority of the pupet
    ---@type number
    pal.priority = args.priority or pal.settings.priority

    -- Update the position of the puppet if it has a parent
    function pal:parentPosUpdate()
        if self.parent and (self.parent.isValid == nil or self.parent.isValid) --[[and (self.parent.isHidden == nil or not self.parent.isHidden)]] then
            self.x = self.parent.x
            self.y = self.parent.y
            if not self.parentcentered then
                if self.parent.width then
                    self.x = self.x+self.parent.width/2
                end
                if self.parent.height then
                    self.y = self.y+self.parent.height/2
                end
            end
            if type(self.parent.isValid) ~= "nil" then
                if not self.parent.isValid then
                    self.parent = nil
                end
            end
        end
    end

    pal:parentPosUpdate()

    -- If set to true, then the puppet will no longer render
    ---@type boolean
    pal.isHidden = false

    -- If set to false, then the puppet will no longer be drawn or updated
    ---@type boolean
    pal.isValid = true

    -- The puppet's type
    ---@type "Puppet"
    pal.__type = "Puppet"

    -- The puppet's data table
    ---@type table
    pal.data = {
        -- Data used in the base of the script
        ---@type table
        _base = {},
        -- Data that gets altered every drawing frame
        ---@type table
        _draw = {},
    }

    -- Table of all the parts the puppet has
    ---@type table<string|number,PuppetPart>
    pal.part = {}

    local pidx = 0
    for partname, pettings in pairs(pal.settings.parts) do
        pidx = pidx + 1
        puppet.spawnPart(pal,partname,pettings,pidx)
    end

    -- How many parts does the puppet have
    ---@type integer
    pal.partcount = pidx

    -- Layers of currently active animations and their time values
    ---@type table<string|number,PuppetAnimation>
    pal.animations = {}

    -- Timer since existence, ticks up each frame
    pal.timer = 0

    -- If the puppet should update its part animations
    pal.updateParts = true

    -- If the puppet should update its timer
    pal.updateTimer = true

    -- The piece of resistance: set the animation of a puppet.
    ---@param animation string|number animation to play on the layer.
    ---@param index string|number|nil layer of the animation. Defaults to 0.
    ---@param offset number|nil time offset of the animation in animation ticks.
    ---@param speed number|nil The speed multiplier of the animation
    function pal:setAnimation(animation,index,offset,speed)
        index = index or 0
        offset = offset or 0
        speed = speed or 1
        self.animations[index] = {}
        ---@class PuppetAnimation
        local anime = self.animations[index]
        -- The animation of this animation
        ---@type string|number
        anime.animation = animation
        -- Time since the animation has started in game ticks
        ---@type number
        anime.time = offset*self.settings.animations[animation].time
        -- Data table for the animation
        ---@type table
        anime.data = {
            -- Base data used for animation in the script
            _base = {}
        }
        -- The puppet that the animation is playing on
        ---@type Puppet
        anime.puppet = self

        -- Speed of the animation
        ---@type number
        anime.speed = speed
    end

    -- `setAnimation` but the `animation` and `index` values have swapped places along with `speed` and `offset`
    ---@param animation string|number animation to play on the layer.
    ---@param index string|number layer of the animation. Defaults to 0.
    ---@param offset number|nil time offset of the animation.
    ---@param speed number|nil The speed multiplier of the animation
    function pal:animationSet(index,animation,speed,offset)
        self:setAnimation(animation,index,offset,speed)
    end

    -- Set the animation of a puppet if the layer isn't already taken.
    ---@param animation string|number animation to play on the layer.
    ---@param index string|number|nil layer of the animation. Defaults to 0.
    ---@param offset number|nil time offset of the animation.
    ---@param speed number|nil The speed multiplier of the animation
    function pal:setAnimationOnce(animation,index,offset,speed)
        if not self:checkAnimation(index) then
            self:setAnimation(animation,index,offset,speed)
        end
    end

    -- `setAnimationOnce` but the `animation` and `index` values have swapped places along with `speed` and `offset`
    ---@param animation string|number animation to play on the layer.
    ---@param index string|number layer of the animation. Defaults to 0.
    ---@param offset number|nil time offset of the animation.
    ---@param speed number|nil The speed multiplier of the animation
    function pal:animationSetOnce(index,animation,speed,offset)
        if not self:checkAnimation(index) then
            self:setAnimation(animation,index,offset,speed)
        end
    end


    -- Plays an animation that has been paused or stopped. If it has been stopped, then it'll restart the animation.
    ---@param index string|number layer of the animation.
    ---@param speed number|nil The speed multiplier of the animation
    function pal:playAnimation(index,speed)
        speed = speed or 1
        if not self.animations[index] then return end
        local anime = self.animations[index]
        if anime.data._base.stopped then
            self:setAnimation(anime.animation,index,0,speed)
            return
        else
            anime.data._base.paused = false
            anime.speed = speed
        end
    end

    -- Sets the animation speed of an animation
    ---@param index string|number layer of the animation.
    ---@param speed number|nil The speed multiplier of the animation
    function pal:setAnimationSpeed(index,speed)
        speed = speed or 1
        if not self.animations[index] then return end
        local anime = self.animations[index]
        anime.speed = speed
    end

    -- Erases the animaton layer from the puppet.
    ---@param index string|number layer of the animation.
    function pal:terminateAnimation(index)
        self.animations[index] = nil
    end

    -- Returns the animation currently on the layer. Returns nil if no animation is in said layer.
    ---@param index string|number layer of the animation.
    ---@return PuppetAnimation|nil
    function pal:getAnimation(index)
        return self.animations[index]
    end

    -- Returns the animation NAME currently on the layer. Returns nil if no animation is in said layer.
    ---@param index string|number layer of the animation.
    ---@return string|number|nil
    function pal:getAnimationName(index)
        if self.animations[index] then
            return self.animations[index].animation
        else
            return nil
        end
    end

    -- Changes the animation of the layer to something different without changing any of the values of said layer
    ---@param index string|number layer of the animation.
    ---@param timefix boolean|nil if true, the animation will attempt to fix its own time to be in line with the new one
    ---@param animation string|number
    function pal:transformAnimation(index,animation,timefix)
        if timefix then
            local asettings = self.settings.animations[animation]
            self.animations[index].time = self.animations[index].time % asettings.time
        end
        self.animations[index].animation = animation
    end

    -- Checks if the layer is currently in use of any animation
    ---@param index string|number layer of the animation.
    ---@return boolean
    function pal:checkAnimation(index)
        if self:getAnimation(index) then
            return true
        end
        return false
    end

    -- Returns the animation settings of the animation `name`. Returns nil if none is present
    ---@param name string|number
    ---@return PuppetAnimationSettings|nil
    function pal:getAnimationSettings(name)
        return self.settings.animations[name]
    end

    -- Checks if the puppet has an animation with this `name`
    ---@param name string|number
    ---@return boolean
    function pal:hasAnimation(name)
        if self:getAnimationSettings(name) then
            return true
        end
        return false
    end

    -- Checks if the puppet has an animation with this `name`
    ---@param name string|number
    ---@return boolean
    function pal:checkAnimationSettings(name)
        return self:hasAnimation(name)
    end

    -- Erases the animaton layer from the puppet.
    ---@param index string|number layer of the animation.
    function pal:eraseAnimation(index)
        self:terminateAnimation(index)
    end

    -- Pause (not stop) the animation. Cannot be paused if the animation is stopped
    ---@param index string|number layer of the animation.
    function pal:pauseAnimation(index)
        if not self.animations[index] then return end
        local anime = self.animations[index]
        if not anime.data._base.stopped then
            anime.data._base.paused = true
        end
    end

    -- Unpauses the animation of the puppet. Cannot be unpaused if it's been stopped.
    ---@param index string|number layer of the animation.
    function pal:unpauseAnimation(index)
        if not self.animations[index] then return end
        local anime = self.animations[index]
        if not anime.data._base.stopped then
            anime.data._base.paused = false
        end
    end

    -- Resumes the animation of the puppet. Cannot be resumed if it's been stopped.
    ---@param index string|number layer of the animation.
    function pal:resumeAnimation(index)
        self:unpauseAnimation(index)
    end

    -- Stops the animation, it unable to be unpaused anymore.
    ---@param index string|number layer of the animation.
    function pal:stopAnimation(index)
        if not self.animations[index] then return end
        local anime = self.animations[index]
        anime.data._base.stopped = true
    end

    -- If the puppet is currently following its parents position. This does NOT include direction
    ---@type boolean
    pal.followparent = true
    if type(args.followparent) ~= "nil" then
        pal.followparent = args.followparent
    end

    -- If the puppet is copying the direction of the parent
    ---@type boolean
    pal.pointparent = pal.settings.pointparent
    if type(args.pointparent) ~= "nil" then
        pal.pointparent = args.pointparent
    end

    -- If the puppet should ignore its own base animations (rotation, pivot, ect...)
    ---@type boolean
    pal.ignoreanimation = false

    -- Spawns an effect on the pal
    function pal:spawnEffect(effect)
        local settings = self.settings
        effect = effect or settings.effect
        local offset = vector(settings.effectoffset.x,settings.effectoffset.y)
        if settings.offsetDirection then
            offset = offset*self.direction
        end
        Effect.spawn(settings.effect,self.x+offset.x,self.y+offset.y)
    end

    -- Hides the pal with isHidden and spawns in its effect
    ---@param spawnEffect boolean|nil
    function pal:hide(spawnEffect)
        if self.isHidden then return end
        self.isHidden = true
        if spawnEffect then
            self:spawnEffect()
        end
    end

    -- Shows the pal with isHidden and spawns in its effect
    ---@param spawnEffect boolean|nil
    function pal:show(spawnEffect)
        if not self.isHidden then return end
        self.isHidden = false
        if spawnEffect then
            self:spawnEffect()
        end
    end

    -- Toggles the pals visibility with isHidden and spawns in its effect
    ---@param spawnEffect boolean|nil
    function pal:toggle(spawnEffect)
        if self.isHidden then
            self:show(spawnEffect)
        else
            self:hide(spawnEffect)
        end
    end

    -- Despawns the puppet in a sense, turning its isValid false and hiding it
    function pal:despawn(spawnEffect)
        self:hide(spawnEffect)
        self.isValid = false
    end

    -- if the puppet is hiding because of its parent
    ---@type boolean
    pal.parentHidden = true

    -- Updates the puppet
    function pal:update()
        local settings = self.settings
        self.rotation = self.rotation % settings.rotationlimit
        self.rpivot = self.pivot:rotate(self.rotation)
        if type(settings.onUpdate) == "function" then
            settings.onUpdate(self)
        end
        local mom = self.parent
        if self.followparent then
            self:parentPosUpdate()
            if mom then
                if (mom.isValid == nil or mom.isValid) then
                    if (mom.isHidden or mom.invisible or (mom.despawnTimer and mom.despawnTimer < 0)) then
                        self.isHidden = true
                        self.parentHidden = true
                    end
                    if self.parentHidden and not (mom.isHidden or mom.invisible or (mom.despawnTimer and mom.despawnTimer < 0)) then
                        self.isHidden = false
                        self.parentHidden = false
                    end
                else
                    self.isHidden = true
                    self.isValid = false
                    return
                end
            end
        end

        if self.updateTimer and not (settings.effectedByFreeze and defines.levelFreeze) then
            self.timer = self.timer + 1
        end

        for name,anim in pairs(self.animations) do
            if not (anim.data._base.stopped or anim.data._base.paused) then
                anim.time = anim.time + (anim.speed or 1)
            end
        end

        for name,part in pairs(self.part) do
            part.name = name
            part.id = name
            part.puppet = self
            if self.updateParts and part.isValid then
                part:update()
            end
        end
        local addr = 0
        local addo = vector(0,0)
        local addp = vector(0,0)
        local addd = vector(1,1)
        local addy = 0
        local addme = {r = false,o = false,p = false, d = false, y = false}
        local setme = {
            r = settings.rotation,
            o = vector(settings.offset.x,settings.offset.y),
            p = vector(settings.pivot.x,settings.pivot.y),
            d = vector(settings.direction.x,settings.direction.y),
            y = settings.priority,
        }
        -- Iterating through all of the active animations the puppet has and go through the rotation, offset, and pivot
        for layer,animate in pairs(self.animations) do
            local adata = animate.data._base
            ---@type PuppetAnimationSettings
            local asettings = settings.animations[animate.animation]
            if type(asettings) == "nil" then
                error("Attempted to play animation: \""..tostring(animate.animation).."\" (No animation was found.)")
            end
            if asettings.rotation then
                local animation = asettings.rotation
                if not animate.data._rotation then
                    animate.data._rotation = {}
                end
                local bata = animate.data._rotation
                local york = asettings.timesrotation

                local gotta, min, max, dist = animateDoohickey(self,animate,animation,bata,york,asettings--[[,truetime,efunk]])

                local animConfig = animation[gotta]
                local animConfigMin = animation[min]
                local animConfigMax = animation[max]


                local rmin = animConfigMin
                if type(rmin) ~= "number" then
                    rmin = animConfigMin.rotation or animConfigMin.angle or animConfigMin[1] or 0
                end
                local rmax = animConfigMax
                if type(rmax) ~= "number" then
                    rmax = animConfigMax.rotation or animConfigMax.angle or animConfigMax[1] or 0
                end

                local rot = math.lerp(rmin,rmax,dist)

                local setted = false
                addme.r = true
                local rgot = animConfig
                if type(rgot) ~= "number" then
                    if rgot.set then
                        setme.r = rot
                        setted = true
                    end
                end
                if not setted then
                    addr = addr+rot
                end

                if asettings.debugMode then
                    Text.print("Rotation",100,80)
                    for _,y in ipairs(york) do
                        Text.print(y,300,80+_*20)
                    end
                    Text.print(min,100,100)
                    Text.print(gotta,100,120)
                    Text.print(max,200,100)
                end
            end
            if asettings.offset then
                local animation = asettings.offset
                if not animate.data._offset then
                    animate.data._offset = {}
                end
                local bata = animate.data._offset
                local york = asettings.timesoffset

                local gotta, min, max, dist = animateDoohickey(self,animate,animation,bata,york,asettings--[[,truetime,efunk]])

                local animConfig = animation[gotta]
                local animConfigMin = animation[min]
                local animConfigMax = animation[max]

                local mnp = vector(animConfigMin.x or 0,animConfigMin.y or 0)
                if animConfigMin.pos then
                    mnp = animConfigMin.pos
                end
                local mxp = vector(animConfigMax.x or 0,animConfigMax.y or 0)
                if animConfigMax.pos then
                    mxp = animConfigMax.pos
                end
                local pp = math.lerp(mnp,mxp,dist)

                local setted = false
                local mgp = animConfig
                if mgp.set then
                    setme.o.x = mgp.x or setme.o.x
                    setme.o.y = mgp.y or setme.o.y
                    if mgp.pos then
                        setme.o.x = mgp.pos.x
                        setme.o.y = mgp.pos.y
                    end
                    setted = true
                end
                if not setted then
                    addo = addo+pp
                end
                addme.o = true

                if asettings.debugMode then
                    Text.print("Offset",500,80)
                    for _,y in ipairs(york) do
                        Text.print(y,700,80+_*20)
                    end
                    Text.print(min,500,100)
                    Text.print(gotta,500,120)
                    Text.print(max,600,100)
                end
            end
            if asettings.pivot then
                local animation = asettings.pivot
                if not animate.data._pivot then
                    animate.data._pivot = {}
                end
                local bata = animate.data._pivot
                local york = asettings.timespivot

                local gotta, min, max, dist = animateDoohickey(self,animate,animation,bata,york,asettings--[[,truetime,efunk]])

                local animConfig = animation[gotta]
                local animConfigMin = animation[min]
                local animConfigMax = animation[max]


                local mnp = vector(animConfigMin.x or 0,animConfigMin.y or 0)
                if animConfigMin.pos then
                    mnp = animConfigMin.pos
                end
                local mxp = vector(animConfigMax.x or 0,animConfigMax.y or 0)
                if animConfigMax.pos then
                    mxp = animConfigMax.pos
                end
                local pp = math.lerp(mnp,mxp,dist)
                local setted = false
                local mgp = animConfig
                if mgp.set then
                    setme.p.x = mgp.x or setme.p.x
                    setme.p.y = mgp.y or setme.p.y
                    if mgp.pos then
                        setme.p.x = mgp.pos.x
                        setme.p.y = mgp.pos.y
                    end
                    setted = true
                end
                if not setted then
                    addp = addp+pp
                end
                addme.p = true
            end
            if asettings.direction then
                local animation = asettings.direction
                if not animate.data._direction then
                    animate.data._direction = {}
                end
                local bata = animate.data._direction
                local york = asettings.timesdirection

                local gotta, min, max, dist = animateDoohickey(self,animate,animation,bata,york,asettings--[[,truetime,efunk]])

                local animConfig = animation[gotta]
                local animConfigMin = animation[min]
                local animConfigMax = animation[max]

                local mnp = animConfigMin
                if type(mnp) == "number" then
                    mnp = vector(mnp,1)
                else
                    mnp = vector(animConfigMin.x or 1,animConfigMin.y or 1)
                    if animConfigMin.pos then
                        mnp = animConfigMin.pos
                    end
                end
                
                local mxp = animConfigMax
                if type(mxp) == "number" then
                    mxp = vector(mxp,1)
                else
                    mxp = vector(animConfigMax.x or 1,animConfigMax.y or 1)
                    if animConfigMax.pos then
                        mxp = animConfigMax.pos
                    end
                end

                local pp = math.lerp(mnp,mxp,dist)
                local setted = false
                local mgp = animConfig
                if type(mgp) ~= "number" then
                    if mgp.set then
                        setme.d.x = mgp.x or setme.d.x
                        setme.d.y = mgp.y or setme.d.y
                        if mgp.pos then
                            setme.d.x = mgp.pos.x
                            setme.d.y = mgp.pos.y
                        end
                        setted = true
                    end
                end
                if not setted then
                    addd = addd*pp
                end
                addme.d = true
            end
            if asettings.priority then
                local animation = asettings.priority
                if not animate.data._priority then
                    animate.data._priority = {}
                end
                local bata = animate.data._priority
                local york = asettings.timespriority

                local gotta, min, max, dist = animateDoohickey(self,animate,animation,bata,york,asettings--[[,truetime,efunk]])

                local animConfig = animation[gotta]
                local animConfigMin = animation[min]
                local animConfigMax = animation[max]

                local rmin = animConfigMin
                if type(rmin) ~= "number" then
                    rmin = animConfigMin.priority or animConfigMin.prior or animConfigMin[1] or 0
                end
                local rmax = animConfigMax
                if type(rmax) ~= "number" then
                    rmax = animConfigMax.priority or animConfigMax.prior or animConfigMax[1] or 0
                end

                local setted = false
                local rot = math.lerp(rmin,rmax,dist)
                addme.y = true
                local rgot = animConfig
                if type(rgot) ~= "number" then
                    if rgot.set then
                        setme.y = rot
                        setted = true
                    end
                end
                if not setted then
                    addr = addr+rot
                end
            end
        end
        if not self.ignoreanimation then
            if addme.r then
                self.rotation = setme.r+addr
            end
            if addme.o then
                self.offset = setme.o+addo
            end
            if addme.p then
                self.pivot = setme.p+addp
            end
            if addme.d then
                self.direction = setme.d*addd
            end
            if addme.y then
                self.priority = setme.y*addy
            end
        end
        if settings.offsetDirection then
            if addme.o then
                self.offset = self.offset*self.direction
            else
                self.offset = setme.p*self.direction
            end
            if addme.p then
                self.pivot = self.pivot*self.direction
            else
                self.pivot = setme.p*self.direction
            end
        end

        if self.pointparent and self.parent.direction then
            if type(self.parent.direction) == "number" then
                if addme.d then
                    self.direction.x = self.direction.x*self.parent.direction
                else
                    self.direction.x = self.settings.direction.x*self.parent.direction
                end
            else
                if addme.d then
                    self.direction = self.direction*self.parent.direction
                else
                    self.direction = self.settings.direction*self.parent.direction
                end
            end
        end

        puppet.checkForTerminations(self.animations)
    end

    function pal:draw()
        local settings = self.settings
        if settings.debugMode then
            Graphics.drawCircle{
                x = self.x,
                y = self.y,
                sceneCoords = true,
                radius = 8,
                priority = math.max(-10,self.priority+1),
                color = Color(0,1,0,0.75)
            }
            Text.printWP(self.idx,self.x-(16+camera.x),self.y-(16+camera.y),self.priority+10)
        end
        if type(settings.onDraw) == "function" then
            settings.onDraw(self)
        end
        local line = {}
        for name,part in pairs(self.part) do
            if part.isValid and not part.isHidden then
                part:draw()
                if part.data._draw.waitingInLine then
                    line[name] = part
                end
            end
        end
        local attempts = 0
        local empty = false
        while (not empty) and attempts < 1000 do
            empty = true
            local homicide = {}
            attempts = attempts + 1
            for name,part in pairs(line) do
                empty = false
                part:draw()
                if part.data._draw.initialized then
                    homicide[#homicide+1] = name
                end
            end
            for _,name in ipairs(homicide) do
                line[name] = nil
            end
        end
        if attempts >= 1000 then
            SFX.play(2)
            Text.printWP("DID SOMEBODY SAY INFINITE PARENT LOOP?!?!?!?!?!",0,0,1000)
        end
        --Text.print(self.rotation,100,100)
        --if self.animations[5] then
        --    Text.print(self.animations[5].time,100,120)
        --    Text.print((self.animations[5].time/settings.animations[self.animations[5].animation].time),100,140)
        --end
        if type(settings.onPostUpdate) == "function" then
            settings.onPostUpdate(self)
        end
    end

    function pal:undraw()
        for name,part in pairs(self.part) do
            part.data._draw.initialized = false
        end
    end

    if not args.noStartAnimations then
        for index,animation in pairs(pal.settings.startAnimations) do
            pal:setAnimation(animation,index)
        end
    end

    -- Animations to play at the start of the puppet's existence
    ---@type table
    args.animations = args.animations or {}

    for index,animation in pairs(args.animations) do
        pal:setAnimation(animation,index)
    end


    -- If set to true, then the puppet will not be added to the list of puppets and thus will not be drawn by default
    ---@type boolean
    args.dontadd = args.dontadd

    -- The index of the puppet in the `puppets` list. Is nil if `dontadd` is true
    ---@type integer|nil
    pal.idx = nil

    if not args.dontadd then
        puppet.puppets[#puppet.puppets+1] = pal
        pal.idx = #puppet.puppets
    end

    return pal
end

-- List of all the puppet effects
---@type table<integer,PuppetEffect>
puppet.effects = {}

-- Creates a new "effect" that carries off a puppet args must at least have "puppet"
function puppet.spawnEffect(args)
    ---@class PuppetEffect
    local effect = {}

    -- The puppet this effect is guiding
    ---@type Puppet
    effect.puppet = args.puppet

    -- The position of the effect
    ---@type Vector2
    effect.pos = args.pos or vector(args.x or args.puppet.x,args.y or args.puppet.y)
    effect.pos = vector(effect.pos.x,effect.pos.y)
    
    effect.puppet.parent = effect.pos
    effect.puppet:parentPosUpdate()

    -- The X position of the effect
    ---@type number
    effect.x = effect.pos.x

    -- The Y position of the effect
    ---@type number
    effect.y = effect.pos.y

    -- The X speed of the effect
    ---@type number
    effect.speedX = args.speedX or 0

    -- The Y speed of the effect
    ---@type number
    effect.speedY = args.speedY or 0

    -- The rotational speed of the effect
    effect.speedR = args.speedR or args.rotationSpeed or args.rotationspeed or 0

    -- The rotation of the effect
    effect.rotation = args.rotation or 0

    -- The X acceleration of the effect
    ---@type number
    effect.gravityX = args.gravityX or 0

    -- The Y acceleration of the effect
    ---@type number
    effect.gravityY = args.gravityY or 0

    -- The Horizontal Terminal Velocity of the effect
    ---@type number
    effect.terminalVX = math.abs(args.terminalVX or args.terminalvelocityx or defines.gravity)

    -- The Horizontal Terminal Velocity of the effect
    ---@type number
    effect.terminalVY = math.abs(args.termianlVY or args.terminalvelocityy or args.terminalvelocity or defines.gravity)

    -- The animaton to play for the puppet when it gets killed
    ---@type string|number
    effect.animation = args.animation

    -- The layer of the death animation
    ---@type string|number
    effect.animationlayer = args.animationlayer or 0

    if effect.animation and effect.puppet:hasAnimation(effect.animation) then
        effect.puppet:setAnimation(effect.animation,effect.animationlayer,args.animationoffset)
    end

    -- Lifetime of the effect
    ---@type number
    effect.lifetime = args.lifetime or 160

    -- If the puppet's effect should spawn once it despawns
    ---@type boolean
    effect.spawnEffect = true
    if type(args.spawnEffect) ~= "nil" then
        effect.spawnEffect = args.spawnEffect
    elseif type(args.noEffect) ~= "nil" then
        effect.spawnEffect = (not args.noEffect)
    elseif type(args.noEffects) ~= "nil" then
        effect.spawnEffect = (not args.noEffects)
    elseif type(args.hideEffect) ~= "nil" then
        effect.spawnEffect = (not args.hideEffect)
    end

    function effect:updatePos()
        self.speedX = math.clamp(self.speedX+self.gravityX,-self.terminalVX,self.terminalVX)
        self.speedY = math.clamp(self.speedY+self.gravityY,-self.terminalVY,self.terminalVY)
        self.x = self.x+self.speedX
        self.y = self.y+self.speedY
        self.pos.x = self.x
        self.pos.y = self.y
        self.rotation = self.rotation + self.speedR
    end

    -- if the effect is valid and should be updated each frame. Cannot be valid if its puppet is invalid
    ---@type boolean
    effect.isValid = true

    function effect:update()
        self:updatePos()
        self.puppet.parent = self.pos
        if self.puppet.isValid then
            self.lifetime = self.lifetime - 1
            if self.lifetime <= 0 then
                self.puppet:despawn(self.spawnEffect)
            end
            self.puppet.rotation = self.puppet.settings.rotation+self.rotation
        end
        self.isValid = self.isValid and self.puppet.isValid
    end

    if not args.dontadd then
        puppet.effects[#puppet.effects+1] = effect
        effect.idx = #puppet.effects
    end

    return effect
end

-- A function that runs `puppet.spawnpuppet`
---@param args table
---@return Puppet
function puppet.spawn(args)
    return puppet.spawnPuppet(args)
end

function puppet.onInitAPI()
	registerEvent(puppet, "onTickEnd")
	registerEvent(puppet, "onDraw")
end

function puppet.onTickEnd()
    for idx,pal in ipairs(puppet.puppets) do
        if pal.isValid then
            pal:update()
        end
    end
    for idx,effect in ipairs(puppet.effects) do
        if effect.isValid then
            effect:update()
        end
    end
end

function puppet.onDraw()
    for idx,pal in ipairs(puppet.puppets) do
        if pal.isValid and not pal.isHidden then
            pal:draw()
        end
    end
end

function puppet.onDrawEnd()
    for idx,pal in ipairs(puppet.puppets) do
        pal:undraw()
    end
end

-- A few default animations to make your life probably easier
---@type table
puppet.D_animations = {
    paperturnleft = {
        time = 20,
        direction = {
            [0] = {x = 1},
            [1] = {x = -1, finish = true},
            [1.1] = {x = -1},
        },
    },
    paperturnright = {
        time = 20,
        direction = {
            [0] = {x = -1},
            [1] = {x = 1, finish = true},
            [1.1] = {x = 1},
        },
    },
    left = {
        time = 20,
        direction = {
            [0] = {x = -1},
        },
    },
    right = {
        time = 20,
        direction = {
            [0] = {x = 1},
        },
    },
    paperturnup = {
        time = 20,
        direction = {
            [0] = {y = 1},
            [1] = {y = -1, finish = true},
            [1.1] = {y = -1},
        },
    },
    paperturndown = {
        time = 20,
        direction = {
            [0] = {y = -1},
            [1] = {y = 1, finish = true},
            [1.1] = {y = 1},
        },
    },
    up = {
        time = 20,
        direction = {
            [0] = {y = -1},
        },
    },
    down = {
        time = 20,
        direction = {
            [0] = {y = 1},
        },
    },
    deatheffect = {
        priority = {
            [0] = {
                prior = -15,
                set = true,
            }
        },
        direction = {
            [0] = {
                y = -1,
                set = true,
            },
        },
    },
    coinLeft = {
        easing = "inOutSine",
        direction = {
            [1] = -1,
            [2] = 1,
        },
    },
    coinRight = {
        easing = "inOutSine",
        direction = {
            [1] = 1,
            [2] = -1,
        },
    }
}

return puppet
--3288 lines of code lez goooooooooo