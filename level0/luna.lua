local cutscenePal = require("cutscenePal")
local handycam = require("handycam")
local easing = require("ext/easing")
local actors = require("actors")
local dialogue = require("littleDialogue")

local introScene = cutscenePal.newScene("hiimdaisy")

SaveData[Level.filename()] = SaveData[Level.filename()] or {}
GameData[Level.filename()] = GameData[Level.filename()] or {}

local save = SaveData[Level.filename()]
local game = GameData[Level.filename()]

function introScene:mainRoutineFunc()
    local daisy = actors.spawnDaisy(self,-179248,-180096,{
        startAnimation = "panicking",
        priority = -25,
    })
    daisy.direction = -1
    daisy:talkAndWait{
        "<tremble><characterNameSingle upper>!</tremble>",
    }
    handycam[1]:transition{
        ease = handycam.ease(easing.inOutQuad),
        time = 2,
        targets = {player,daisy,player2},
        xOffset = 0,
        yOffset = -64,
        zoom = 2,
    }
    if player.x > player.width*2-179616 then
        daisy:walkAndWait{
            goal = player.x+100,speed = 3.5,setDirection = true,
            walkAnimation = "walk",stopAnimation = "idle",
        }
    else
        daisy:walkAndWait{
            goal = -179616,speed = 4,setDirection = true,
            walkAnimation = "walk",stopAnimation = "idle",
        }
    end
    
    daisy:talkAndWait{
        "<wave 2>Huff...</wave> I'm sorry if I'm interrupting something, but I have to talk to you.",
        "Don't look at me like that... Something bad is happening!",
    }
    daisy:setAnimation("behind")
    daisy:talkAndWait{
        "Bowser has joined forces with villians from entirely different realities",
    }
    daisy:setAnimation("panic")
    daisy:talkAndWait{
        "All across the lands strange things are happening everywhere!",
        "All kinds of <size 1.5>Absurd Oddities</size> are showing up randomly.",
    }
    daisy:setAnimation("panicking")
    daisy:talkAndWait{
        "All in an effort for one giant <size 2>Invasion 2</size> the mushroom kingdom!",
    }
    local captured = true
    for _,p in ipairs(Player.get()) do
        if p.isValid and p.character == CHARACTER_PEACH then
            captured = false
        end
    end
    if captured then
        daisy:setAnimation("cry")
        daisy:talkAndWait{
            "Oh, and he probably kidnapped Princess Peach as well.",
            "Who knows what's going on, it's all chaos!"
        }
    end
    daisy:setAnimation("idle")
    daisy:talkAndWait{
        "Please go foil Bowser's plans like you always do.",
        "But be prepared for anything!"
    }
    handycam[1]:transition{
        ease = handycam.ease(easing.inOutQuad),
        time = 2,
        targets = {player,player2},
        xOffset = 0,
        yOffset = 0,
        zoom = 1,
    }
    daisy:walkAndWait{
        goal = -179248,speed = 4,setDirection = true,
        walkAnimation = "walk",stopAnimation = "idle",
    }
    Routine.wait(1)
end

function introScene:stopFunc()
    handycam[1]:release()
    save.introed = true
end

function onPostEventDirect(event)
    if event == "hereComesAPrincess" and not save.introed then
        introScene:start()
    end
end