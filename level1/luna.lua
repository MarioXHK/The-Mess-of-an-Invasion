SaveData[Level.filename()] = SaveData[Level.filename()] or {}
GameData[Level.filename()] = GameData[Level.filename()] or {}

local save = SaveData[Level.filename()]
local game = GameData[Level.filename()]

function onStart()
    local toad = Layer.get("Toad 1")
    local todd = Layer.get("Toad 3")
    local treasure = Layer.get("Treasure")
    if save.chested then
        todd:show(true)
        toad:hide(true)
        treasure:hide(true)
    else
        toad:show(true)
        todd:hide(true)
    end
end

function onPostEventDirect(event)
    if event == "Treasure" then
        save.chested = true
    end
end