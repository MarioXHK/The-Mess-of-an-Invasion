local actors = {}

actors.princessAnimations = {
    idle = {1, defaultFrameY = 1},
    walk = {1,2, defaultFrameY = 1,frameDelay = 8},
    air = {2, defaultFrameY = 1},
    eyeclose = {3, defaultFrameY = 1},
    behind = {4, defaultFrameY = 1},
    lookbehind = {4, defaultFrameY = 1},
    lookdown = {1, defaultFrameY = 2},
    cry = {1,2,1,3, defaultFrameY = 2,frameDelay = 16},
    crylook = {1,3,4, defaultFrameY = 2,frameDelay = 16,loops = false},
    side = {1, defaultFrameY = 3},
    kneel = {1,2, defaultFrameY = 3,frameDelay = 8,loops = false},
    kiss = {2,3,4,4,3,2, defaultFrameY = 3,frameDelay = 8,loops = false},
    pose = {1, defaultFrameY = 4},
    lay = {2, defaultFrameY = 4},
    panic = {3, defaultFrameY = 4},
    panicking = {3,4, defaultFrameY = 4,frameDelay = 5},
}

actors.peachImg = Graphics.loadImageResolved("resources/peach.png")

actors.daisyImg = Graphics.loadImageResolved("resources/daisy.png")

local princessidx = {}

local function spawnPrincess(scene,x,y,args,princess)
    
    args = args or {}
    if tonumber(args) then
        args = {
            priority = tonumber(args)
        }
    elseif type(args) == "string" then
        args = {
            startAnimation = args
        }
    end
    args.startAnimation = args.startAnimation or "idle"
    -- Spawn an actor.
    -- It is a "child" of the scene rather than a global one, so it will be removed when the scene ends.
    local actor = scene:spawnChildActor(x,y)

    -- Set up properties for the actor
    actor.image = actors[princess.."Img"]
    actor.spriteOffset = vector(0,0)
    actor.spritePivotOffset = vector(0,0)
    actor:setFrameSize(40,40)
    actor:setSize(32,64)
    actor.priority = args.priority or -45

    actor.useAutoFloor = true
    actor.gravity = defines.npc_grav
    actor.terminalVelocity = defines.gravity*(2/3)

    actor.imageDirection = DIR_LEFT
    actor.direction = DIR_LEFT

    actor.spriteScale = vector(2,2)

    -- Set up an actor's animations, using the same arguments as animationPal.createAnimator.
    actor:setUpAnimator{
        animationSet = actors.princessAnimations,
        startAnimation = args.startAnimation,
    }

    -- Add it to the scene's data table (which is of course optional) and return.
    if not scene.data[princess] then
        scene.data[princess] = {}
    end
    princessidx[princess] = (princessidx[princess] or 0) + 1
    scene.data[princess][princessidx[princess]] = actor

    return actor
end

function actors.spawnPeach(scene,x,y,args)
    return spawnPrincess(scene,x,y,args,"peach")
end

function actors.spawnDaisy(scene,x,y,args)
    return spawnPrincess(scene,x,y,args,"daisy")
end


return actors