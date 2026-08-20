local whimsy = {}

local npcManager = require("npcManager")

local puppet = require("puppet")

local npcutils = require("npcs/npcutils")

local easing = require("ext/easing")

local shroomIDs = {}

local sporeIDs = {}

-- The event that triggets when whimsy starts
---@type string
whimsy.startEvent = "Whimsy - Start"

-- An event that will always trigger when collecting a shroom
---@type string
whimsy.beginEvent = "Whimsy - Begin"

-- The event that triggets when whimsy stops
---@type string
whimsy.stopEvent = "Whimsy - Stop"

-- An event that will always trigger when collecting a spore
---@type string
whimsy.endEvent = "Whimsy - End"

-- Mapped table of events that stop the whimsy screen effects
---@type table<string,boolean>
whimsy.stopEvents = {}

whimsy.fadeMusic = true

function whimsy.registerActivator(id)
    shroomIDs[id] = true
    npcManager.registerEvent(id, whimsy, "onTickNPC", "onTickShroom")
	npcManager.registerEvent(id, whimsy, "onTickEndNPC", "onTickEndShroom")
	npcManager.registerEvent(id, whimsy, "onDrawNPC", "onDrawShroom")
end

function whimsy.registerDeactivator(id)
    shroomIDs[id] = true
    npcManager.registerEvent(id, whimsy, "onTickNPC", "onTickSpore")
	npcManager.registerEvent(id, whimsy, "onTickEndNPC", "onTickEndSpore")
	npcManager.registerEvent(id, whimsy, "onDrawNPC", "onDrawSpore")
end

local function findDistance(a,b)
    if not (a or b) then return end
    a = a or vector(0,0)
    b = b or vector(0,0)

    return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2)
end

function whimsy.onInitAPI()
	--registerEvent(whimsy, "onNPCHarm")
	registerEvent(whimsy, "onNPCKill")
	--registerEvent(whimsy, "onPostNPCHarm")
	--registerEvent(whimsy, "onPostNPCKill")
	registerEvent(whimsy, "onNPCCollect")
	--registerEvent(whimsy, "onPostNPCCollect")
end

whimsy.colors = {
    rim = Color.fromHexRGB(0xC00010),
    reg = Color.fromHexRGB(0xF81810),
    blm = Color.fromHexRGB(0xF88010),
    eyc = Color.fromHexRGB(0x282828),
    eyc1 = Color.fromHexRGB(0x282828),
    eyc2 = Color.fromHexRGB(0x282828),
    eyc3 = Color.fromHexRGB(0x282828),
    eyc4 = Color.fromHexRGB(0x282828),
    spt = Color.fromHexRGB(0xF8F8F8),
    stm = Color.fromHexRGB(0xF8F8F8),
    stmr = Color.fromHexRGB(0xF8C078),
    dark = Color(0,0,0,1),
    darkoutline = Color(1,1,1,1),
}

local function changeColor(a,b)
    if not (a and b) then return end
    a.r = b.r or a.r
    a.g = b.g or a.g
    a.b = b.b or a.b
    a.a = b.a or a.a
end

-- Change the colors of the Whimsy mushroom
---@param regular Color? Color of the main ball
---@param rim Color? Color of the rim
---@param bloom Color? Color of the highlight
---@param spots Color? Color of the spots
---@param stem Color? Color of the stem
---@param stemrim Color? Color of the stem's shadow
---@param eyes Color? Color of all the eyes
---@param eye1 Color? Color of the first pair of eyes
---@param eye2 Color? Color of the second pair of eyes
---@param eye3 Color? Color of the third pair of eyes
---@param eye4 Color? Color of the fourth pair of eyes
function whimsy.changeColors(regular,rim,bloom,spots,stem,stemrim,eyes,eye1,eye2,eye3,eye4)
    changeColor(whimsy.colors.reg,regular)
    changeColor(whimsy.colors.rim,rim)
    changeColor(whimsy.colors.blm,bloom)
    changeColor(whimsy.colors.spt,spots)
    changeColor(whimsy.colors.stm,stem)
    changeColor(whimsy.colors.stmr,stemrim)
    changeColor(whimsy.colors.eyc,(eyes or eye1 or eye2 or eye3 or eye4))
    changeColor(whimsy.colors.eyc1,(eye1 or eyes))
    changeColor(whimsy.colors.eyc2,(eye2 or eyes))
    changeColor(whimsy.colors.eyc3,(eye3 or eyes))
    changeColor(whimsy.colors.eyc4,(eye4 or eyes))
end

-- Change the colors of the darkness caused by whimsy
---@param darkness Color?
---@param edge Color?
function whimsy.changeDarkness(darkness,edge)
    changeColor(whimsy.colors.dark,darkness)
    changeColor(whimsy.colors.darkoutline,edge)
end

whimsy.shroomprior = -10

puppet.registerPuppet{
	id = "whimsyshroom",
	root = "wshroom",
	pointparent = false,
	priority = whimsy.shroomprior,

	parts = {
        scale = {
            texture = "",
            scale = 1,
        },
		{
			parent = "arrows1",
			texture = "arrow",
			offsetX = 20,
			rotationOffset = 0,
			color = whimsy.colors.reg,
		},
		{
			parent = "arrows2",
			texture = "arrow",
			offsetY = 20,
			rotationOffset = 90,
			color = whimsy.colors.blm,
		},
		{
			parent = "arrows1",
			texture = "arrow",
			offsetX = -20,
			rotationOffset = 180,
			color = whimsy.colors.reg,
		},
		{
			parent = "arrows2",
			texture = "arrow",
			offsetY = -20,
			rotationOffset = 270,
			color = whimsy.colors.blm,
		},
		arrowbase = {
            parent = "scale",
			scale = 2,
		},
		arrows1 = {
			parent = "arrowbase",
			priorityOffset = -0.025,
		},
		arrows2 = {
			parent = "arrowbase",
			priorityOffset = -0.02,
		},
		head = {
            parent = "scale",
			scale = 2,
			color = whimsy.colors.reg,
		},
		rim = {
			parent = "head",
			priorityOffset = 0.001,
			color = whimsy.colors.rim,
		},
		bulb = {
			parent = "head",
			color = whimsy.colors.blm,
			priorityOffset = 0.002,
		},
		eyes = {
			parent = "head",
			texture = "",
			color = whimsy.colors.eyc,
		},
		spots = {
			parent = "head",
			priorityOffset = 0.01,
			color = whimsy.colors.spt,
		},
		eye1 = {
			parent = "eyes",
			--texture = "eyes",
			--sourceX = 0,
			--sourceY = 0,
			--sourceWidth = 8,
			--sourceHeight = 8,
			offsetX = -8,
			offsetY = -8,
			priorityOffset = 0.015,
			color = whimsy.colors.eyc1,
		},
		eye2 = {
			parent = "eyes",
			--texture = "eyes",
			--sourceX = 8,
			--sourceY = 0,
			--sourceWidth = 8,
			--sourceHeight = 8,
			offsetX = 8,
			offsetY = -8,
			priorityOffset = 0.015,
			color = whimsy.colors.eyc2,
		},
		eye3 = {
			parent = "eyes",
			--texture = "eyes",
			--sourceX = 0,
			--sourceY = 8,
			--sourceWidth = 8,
			--sourceHeight = 8,
			offsetX = -8,
			offsetY = 8,
			priorityOffset = 0.015,
			color = whimsy.colors.eyc3,
		},
		eye4 = {
			parent = "eyes",
			--texture = "eyes",
			--sourceX = 8,
			--sourceY = 8,
			--sourceWidth = 8,
			--sourceHeight = 8,
			offsetX = 8,
			offsetY = 8,
			priorityOffset = 0.015,
			color = whimsy.colors.eyc4,
		},
		stem = {
            parent = "scale",
			scale = 2,
			offsetY = 14,
			priorityOffset = -0.01,
            color = whimsy.colors.stm,
		},
		stemrim = {
            parent = "stem",
			offsetY = 14,
			priorityOffset = -0.009,
            color = whimsy.colors.stmr,
		},
	},
	animations = {
		idle = {
			parts = {
				head = {
					[0] = {
						rotation = 0,
					},
					[7.5] = {
						rotation = 360,
					}
				},
				stem = {
					[3.5] = {
						rotation = -25,
						easing = "inOutCubic"
					},
					[7] = {
						rotation = 25,
						easing = "inOutCubic"
					},
				},
				arrows1 = {
					[0] = {
						rotation = 0,
					},
					[5] = {
						rotation = 360,
					}
				},
				arrows2 = {
					[0] = {
						rotation = 0,
					},
					[3.75] = {
						rotation = -360,
					}
				},
			},
		},
        pulse = {
            time = 160,
            easing = "inOutSine",
            parts = {
                scale = {
                    [1] = {
                        scale = vector(1.5,1.5)
                    },
                    [2] = {
                        scale = 1
                    },
                    [3] = {
                        scale = vector(1.4,1.6)
                    },
                    [4] = {
                        scale = 1
                    },
                    [5] = {
                        scale = vector(1.6,1.5)
                    },
                    [6] = {
                        scale = 1
                    },
                },
                arrows1 = {
                    [1] = {
                        scale = 1.25,
                        offsetScale = 1.75,
                    },
                    [2] = {
                        scale = 1,
                        offsetScale = 1,
                    },
                },
                arrows2 = {
                    [1] = {
                        scale = 1.25,
                        offsetScale = 1.6,
                    },
                    [2] = {
                        scale = 1,
                        offsetScale = 1,
                    },
                },
                eyes = {
                    [1] = {
                        offsetScale = 1.5,
                    },
                    [2] = {
                        offsetScale = 1,
                    },
                },
            }
        },
        blink = {
            easestart = true,
            time = 16,
            parts = {
                eye1 = {
                    [0] = {
                        visible = true,
                    },
                    [1] = {
                        visible = false,
                    },
                    [2] = {
                        visible = true,
                    }
                },
                eye2 = {
                    [0] = {
                        visible = true,
                    },
                    [1.25] = {
                        visible = false,
                    },
                    [2.25] = {
                        visible = true,
                    }
                },
                eye3 = {
                    [0] = {
                        visible = true,
                    },
                    [1.5] = {
                        visible = false,
                    },
                    [2.5] = {
                        visible = true,
                    }
                },
                eye4 = {
                    [0] = {
                        visible = true,
                    },
                    [1.75] = {
                        visible = false,
                    },
                    [2.75] = {
                        visible = true,
                    },
                    [3] = {
                        terminate = true,
                    }
                },
            }
        },
        blink0 = {
            easestart = true,
            time = 16,
            parts = {
                eye1 = {
                    [0] = {
                        visible = true,
                    },
                    [1] = {
                        visible = false,
                    },
                    [2] = {
                        visible = true,
                        stop = true,
                    }
                },
                eye2 = {
                    [0] = {
                        visible = true,
                    },
                    [1] = {
                        visible = false,
                    },
                    [2] = {
                        visible = true,
                        stop = true,
                    }
                },
                eye3 = {
                    [0] = {
                        visible = true,
                    },
                    [1] = {
                        visible = false,
                    },
                    [2] = {
                        visible = true,
                        stop = true,
                    }
                },
                eye4 = {
                    [0] = {
                        visible = true,
                    },
                    [1] = {
                        visible = false,
                    },
                    [2] = {
                        visible = true,
                        terminate = true,
                    }
                },
            }
        },
        blink1 = {
            easestart = true,
            time = 16,
            parts = {
                eye1 = {
                    [0] = {
                        visible = true,
                    },
                    [1] = {
                        visible = false,
                    },
                    [2] = {
                        visible = true,
                        terminate = true,
                    }
                }
            }
        },
        blink2 = {
            easestart = true,
            time = 16,
            parts = {
                eye2 = {
                    [0] = {
                        visible = true,
                    },
                    [1] = {
                        visible = false,
                    },
                    [2] = {
                        visible = true,
                        terminate = true,
                    }
                }
            }
        },
        blink3 = {
            easestart = true,
            time = 16,
            parts = {
                eye3 = {
                    [0] = {
                        visible = true,
                    },
                    [1] = {
                        visible = false,
                    },
                    [2] = {
                        visible = true,
                        terminate = true,
                    }
                }
            }
        },
        blink4 = {
            easestart = true,
            time = 16,
            parts = {
                eye4 = {
                    [0] = {
                        visible = true,
                    },
                    [1] = {
                        visible = false,
                    },
                    [2] = {
                        visible = true,
                        terminate = true,
                    }
                }
            }
        },
        collect1 = {
            easestart = true,
            easing = "inOutQuint",
            parts = {
                head = {
                    [0] = {
                        --easing = "outQuint",
                        y = 0,
                    },
                    [1.5] = {
                        --easing = "outQuint",
                        y = -64,
                    },
                    [2.5] = {
                        --easing = "inQuint",
                        y = -48,
                        visible = false,
                        pause = true,
                    },
                    [2.75] = {
                        --easing = "inQuint",
                        y = 0,
                        visible = false,
                        pause = true,
                    }
                },
            }
        },
        collect2 = {
            easestart = true,
            easing = "inOutQuad",
            parts = {
                head = {
                    [0] = {
                        easing = "inQuad",
                        rotation = 0,
                        scale = 1,
                    },
                    [5] = {
                        easing = "inQuad",
                        rotation = 5000,
                        scale = 5,
                    },
                },
                stem = {
                    [0] = {
                        y = 0,
                    },
                    [2.5] = {
                        y = -8,
                        visible = false
                    },
                    [10] = {
                        y = -8,
                        visible = false
                    },
                },
                arrows1 = {
                    [0] = {
                        scale = 1,
                        offsetScale = 1,
                    },
                    [0.5] = {
                        scale = 2,
                        offsetScale = 4,
                    },
                    [1] = {
                        scale = 1,
                        offsetScale = 3,
                    },
                    [1.5] = {
                        scale = 3,
                        offsetScale = 8,
                    },
                    [2] = {
                        scale = 2,
                        offsetScale = 6,
                    },
                    [2.5] = {
                        scale = 5,
                        offsetScale = 15,
                    },
                    [3] = {
                        scale = 4.5,
                        offsetScale = 13,
                    },
                    [3.5] = {
                        scale = 10,
                        offsetScale = 30,
                    },
                    [5] = {
                        scale = 50,
                        offsetScale = 100,
                    },
                },
            }
        },
        collect3 = {
            easestart = true,
            easing = "inOutQuad",
            parts = {
                arrows1 = {
                    [0] = {
                        easing = "inQuad",
                        rotation = 0,
                    },
                    [5] = {
                        easing = "inQuad",
                        rotation = 4000,
                    },
                },
                arrows2 = {
                    [0] = {
                        easing = "inQuad",
                        rotation = 0,
                        scale = 1,
                    },
                    [5] = {
                        easing = "inQuad",
                        rotation = -3000,
                        scale = 25,
                        offsetScale = 100,
                    },
                },
            }
        }
	},
	startAnimations = {"idle","pulse"}
}

whimsy.darkpriority = -30

-- Darkness surrounds you

puppet.registerPuppet{
    id = "darkcircle",
    priority = whimsy.darkpriority,
    pointparent = false,

    parts = {
        inner = {
            radius = 12,
            color = whimsy.colors.dark,
            solid = true,
            isCircle = true,
        },
        outer = {
            parent = "inner",
            radius = 14,
            color = whimsy.colors.darkoutline,
            solid = true,
            isCircle = true,
            priorityOffset = -0.1,
        },
    },

    animations = {
        spawn = {
            easestart = true,
            easing = "outQuad",
            parts = {
                inner = {
                    [0] = {
                        scale = 0,
                    },
                    [1] = {
                        scale = 1,
                        transform = "pulse",
                    }
                },
            }
        },
        pulse = {
            easing = "inOutQuad",
            parts = {
                inner = {
                    [1] = {
                        scale = 1.75,
                    },
                    [2] = {
                        scale = 1,
                    },
                },
                --outer = {
                --    [1] = {
                --        scale = 1,
                --    },
                --    [2] = {
                --        scale = 0.9,
                --    },
                --},
            }
        },
        grow = {
            easing = "inOutQuad",
            easestart = true,
            time = 32,
            parts = {
                inner = {
                    [0] = {
                        scale = 1,
                    },
                    [1] = {
                        scale = 3,
                    },
                    [2] = {
                        scale = 2,
                    },
                    [3] = {
                        scale = 5,
                    },
                    [4] = {
                        scale = 3,
                    },
                    [5] = {
                        scale = 6,
                    },
                    [6] = {
                        scale = 4.5,
                    },
                    [7] = {
                        scale = 8,
                        transform = "beat",
                    },
                },
            }
        },
        beat = {
            easing = "inOutQuad",
            time = 32,
            parts = {
                inner = {
                    [1] = {
                        scale = 6,
                    },
                    [2] = {
                        scale = 8,
                    },
                },
            }
        }
    }
}

puppet.registerPuppet{
	id = "whimsyspore",
	root = "wspore",
	pointparent = false,
	priority = whimsy.shroomprior,

	parts = {
        {
            parent = "arrows1",
            texture = "arrow",
            x = -7,
            y = -7,
            rotationOffset = 0,
            color = whimsy.colors.stm,
        },
        {
            parent = "arrows1",
            texture = "arrow",
            x = 7,
            y = 7,
            rotationOffset = 180,
            color = whimsy.colors.stm,
        },
        {
            parent = "arrows2",
            texture = "arrow",
            x = 7,
            y = -7,
            rotationOffset = 90,
            color = whimsy.colors.stmr,
        },
        {
            parent = "arrows2",
            texture = "arrow",
            x = -7,
            y = 7,
            rotationOffset = 270,
            color = whimsy.colors.stmr,
        },
        arrows = {
            scale = 2,
            texture = "",
        },
        arrows1 = {
            parent = "arrows",
            texture = "",
        },
        arrows2 = {
            parent = "arrows",
            texture = "",
        },
        base = {
            scale = 2,
            color = whimsy.colors.reg,
        },
		rim = {
			parent = "base",
			color = whimsy.colors.rim,
		},
		bloom = {
			parent = "base",
			color = whimsy.colors.blm,
			priorityOffset = 0.001,
		},
		spots = {
			parent = "base",
			priorityOffset = 0.002,
			color = whimsy.colors.spt,
		},
        bulb = {
            parent = "base",
            color = whimsy.colors.stm,
            priorityOffset = 0.01,
        },
        sprouts = {
            parent = "bulb",
            color = whimsy.colors.stmr,
            priorityOffset = 0.011,
        },
        eyes = {
            parent = "bulb",
            color = whimsy.colors.eyc,
            priorityOffset = 0.012,
            x = -2,
            y = -1,
        },
    },

    animations = {
        idle = {
            time = 112,
            easing = "inOutSine",
            parts = {
                base = {
                    [1] = {
                        rotation = -30,
                    },
                    [2] = {
                        rotation = 30,
                    },
                },
                arrows1 = {
                    [1.5] = {
                        scale = 2,
                        offsetScale = 1.75,
                    },
                    [3] = {
                        scale = 1,
                        offsetScale = 1,
                    },
                },
                arrows2 = {
                    [2] = {
                        scale = 2,
                        offsetScale = 1.5,
                    },
                    [4] = {
                        scale = 1,
                        offsetScale = 1,
                    },
                }
            },
        },
        arrowspin = {
            time = 244,
            parts = {
                arrows1 = {
                    [0] = {
                        rotation = 0
                    },
                    [1] = {
                        rotation = -360
                    },
                },
                arrows2 = {
                    [0] = {
                        rotation = 0
                    },
                    [1.23] = {
                        rotation = -360
                    },
                },
            },
        },
        pointin = {
            easestart = true,
            easing = "outQuad",
            time = 32,
            parts = {
                {
                    [0] = {
                        rotationOffset = 0,
                    },
                    [1] = {
                        rotationOffset = 180,
                    },
                },
                {
                    [0] = {
                        rotationOffset = 0,
                    },
                    [1] = {
                        rotationOffset = -180,
                    },
                },
                {
                    [0] = {
                        rotationOffset = 0,
                    },
                    [1] = {
                        rotationOffset = 180,
                    },
                },
                {
                    [0] = {
                        rotationOffset = 0,
                },
                    [1] = {
                        rotationOffset = -180,
                    },
                },
                arrows = {
                    [0] = {
                        scale = 1,
                    },
                    [1] = {
                        scale = 2,
                        transform = "point",
                    },
                },
            }
        },
        point = {
            parts = {
                {
                    [0] = {
                        rotationOffset = 180,
                    },
                },
                {
                    [0] = {
                        rotationOffset = 180,
                    },
                },
                {
                    [0] = {
                        rotationOffset = 180,
                    },
                },
                {
                    [0] = {
                        rotationOffset = 180,
                    },
                },
                arrows = {
                    [0] = {
                        scale = 2,
                    },
                },
            }
        },
        pointout = {
            easestart = true,
            easing = "outQuad",
            parts = {
                {
                    [1] = {
                        rotationOffset = 0,
                    },
                    [0] = {
                        rotationOffset = 180,
                    },
                },
                {
                    [1] = {
                        rotationOffset = 0,
                    },
                    [0] = {
                        rotationOffset = -180,
                    },
                },
                {
                    [1] = {
                        rotationOffset = 0,
                    },
                    [0] = {
                        rotationOffset = 180,
                    },
                },
                {
                    [1] = {
                        rotationOffset = 0,
                    },
                    [0] = {
                        rotationOffset = -180,
                    },
                },
                arrows = {
                    [0] = {
                        scale = 2,
                    },
                    [1] = {
                        scale = 1,
                        terminate = true,
                    },
                },
            }
        },
    },

    startAnimations = {
        "idle",
        arrow = "arrowspin"
    }
}

whimsy.shroomsfx = "whimsy"
whimsy.wooshsfx = "snd_revival_quick"

whimsy.altsfx = "wonder"

whimsy.sealsfx = "snd_revival"
whimsy.getsfx = "snd_great_shine"

whimsy.sporesfx = 52

whimsy.path = "resources/"

whimsy.EFFECT_TYPE = {
    NONE = 0,
    SWIRL = 1,
    AURA = 2,
    RAIN = 3,
    FOG = 4,
    DARK = 5,
    DRUG = 6,
}

whimsy.effect = whimsy.EFFECT_TYPE.NONE

local effectTimer = 0

whimsy.startEffect = whimsy.EFFECT_TYPE.SWIRL

local resolvedSoundFiles = {}

-- A function that plays an SFX. Returns what SFX.play does
---@param theSFX (string|number|table)?
---@return SoundEffect?
local function trySFX(theSFX)
    if not theSFX then return end
    if type(theSFX) == "number" then
        return SFX.play(theSFX)
    elseif type(theSFX) == "table" then
        -- I love recursion
        return trySFX(RNG.randomEntry(theSFX))
    elseif type(theSFX) == "function" then
        return theSFX()
	else
        if not resolvedSoundFiles[theSFX] then
            if Misc.resolveSoundFile(whimsy.path..tostring(theSFX)) then
                resolvedSoundFiles[theSFX] = Misc.resolveSoundFile(whimsy.path..tostring(theSFX))
            elseif Misc.resolveSoundFile(theSFX) then
                resolvedSoundFiles[theSFX] = Misc.resolveSoundFile(theSFX)
            end
        end

        if resolvedSoundFiles[theSFX] then
            return SFX.play(resolvedSoundFiles[theSFX])
        end
    end
end

local ogmusic = nil
local ogsection = nil

whimsy.music = nil

function whimsy.start()
    effectTimer = 0
    whimsy.effect = whimsy.startEffect
    if whimsy.music then
        if not ogmusic then
            ogmusic = player.sectionObj.music
        end
        player.sectionObj.music = whimsy.music
        ogsection = player.section
    end
    triggerEvent(whimsy.startEvent)
end

function whimsy.stop()
    whimsy.effect = whimsy.EFFECT_TYPE.NONE
    if ogmusic then
        Section(ogsection or player.section).music = ogmusic
        ogmusic = nil
        ogsection = nil
    end
    triggerEvent(whimsy.stopEvent)
end


-- Mushroom AI


-- The function that every game tick for the Whimsy Mushroom `v`
---@param v NPC
function whimsy.onTickShroom(v)
	if Defines.levelFreeze then return end

	local data = v.data -- NPC's data
	local config = NPC.config[v.id] -- NPC config
	local settings = data._settings -- Custom extra settings

	if v.despawnTimer <= 0 then
		data.initialized = false
        if data.puppet then
            data.puppet:despawn(false)
        end
        if data.particles then
            for _,d in ipairs(data.particles) do
                d:despawn(false)
            end
        end
        data.puppet = nil
        data.particles = nil
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
        data.activating = false
        data.activated = false
        data.playedWoosh = false
        data.iCanDie = false
        data.ppos = {}
        data.player = nil
		data.puppet = puppet.spawn{
			id = config.puppet or "whimsyshroom",
			parent = v
		}
		data.timer = 0
        ---@type table<integer,Puppet>
        data.particles = {}
        local parts = 64
        for i = 1, parts do
            data.particles[#data.particles+1] = puppet.spawn{
                id = "darkcircle",
                parent = v,
            }

            local part = data.particles[#data.particles]
            part.data.offset = vector(RNG.random()*v.width/2,RNG.random()*v.height/2)

            part.data.rotation = i*(360/parts)

            part:setAnimation("spawn",nil,RNG.random(-config.speed,config.speed),RNG.random(0.5,1.25))
        end
	end

    if data.activating then
        if not data.activated then
            data.timer = 0
            data.activated = true
            trySFX(whimsy.shroomsfx)
            data.player = data.player or player
            for _,p in ipairs(Player.get()) do
                if p.isValid then
                    if p.section ~= data.player.section then
                        p.section = data.player.section
                        p.x = data.player.x
                        p.y = data.player.y
                    end
                    data.ppos[_] = vector(p.centerX,p.centerY)
                end
            end
            if whimsy.fadeMusic then
                ogmusic = data.player.sectionObj.music
                Audio.MusicFadeOut(player.section,100)
            end

            data.puppet:terminateAnimation("blink")
            for i = 1,4 do
                data.puppet:terminateAnimation("blink"..tostring(i))
            end


            data.puppet:terminateAnimation(2)
            data.puppet:terminateAnimation(1)

            data.puppet:setAnimation("collect1",1)
            data.puppet:setAnimation("collect2",2)
            data.puppet:setAnimation("collect3",3)

            for _,d in ipairs(data.particles) do
                d:setAnimation("grow",nil,nil,RNG.random(0.5,1.25))
            end
        end
        data.timer = data.timer + 1

        if data.timer >= lunatime.toTicks(4) then
            for _,p in ipairs(Player.get()) do
                if p.isValid then
                    if p.forcedState == FORCEDSTATE_INVISIBLE then
                        p.forcedState = FORCEDSTATE_NONE
                    end
                    p.speedX = 0
                    p.speedY = 0
                end
            end
            whimsy.start()
            data.iCanDie = true
            v:collect(data.player)
        else
            for _,p in ipairs(Player.get()) do
                if p.isValid then
                    p.forcedState = FORCEDSTATE_INVISIBLE
                    if data.ppos[_] then
                        local larp = math.lerp(data.ppos[_],v.center,math.clamp(data.timer/lunatime.toTicks(4)))
                        p.x = (larp.x-p.width/2) + p.width*(1-_)*1.5
                        p.y = larp.y-p.height/2
                    end
                end
            end
            if data.timer >= lunatime.toTicks(3) and not data.playedWoosh then
                data.playedWoosh = true
                trySFX(whimsy.wooshsfx)
            end
        end

        return
    end

	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		data.timer = 0
        return
	end
	data.timer = data.timer + 1
end

-- Function that runs after onTick and internal smbx code for the Whimsy Mushroom `v`
---@param v NPC
function whimsy.onTickEndShroom(v)
	if not v.data.initialized then return end
	local data = v.data
	local config = NPC.config[v.id]
	local settings = data._settings

    local darkradius = config.darkradius or (config.width+config.height)

    if data.activated then
        darkradius = darkradius+easing.outInBack(data.timer,0,400,224,3)
    else
        data.puppet.y = v.y+math.cos(data.timer/config.framespeed)*config.speed
    end

    for _,d in ipairs(data.particles) do
        d.data.rotation = d.data.rotation + 0.65
        local vec = vector(darkradius,0):rotate(d.data.rotation)
        d.x = d.x+vec.x+d.data.offset.x-v.width/4
        d.y = d.y+vec.y+d.data.offset.y-v.height/4

        --Text.print(d:getAnimationName(0),100,100)
    end


    if (not data.activated) and RNG.random() <= (config.blinkchance or 0.1)/lunatime.toTicks(1/math.max(config.frames,1)) then
        local unoccupied = true
        for i = 1, 4 do
            if data.puppet:getAnimation("blink"..tostring(i)) then
                unoccupied = false
                break
            end
        end
        if unoccupied and RNG.randomInt(1,3) == 3 and not data.puppet:getAnimation("blink") then
            data.puppet:setAnimation("blink","blink")
        else
            local fl = RNG.randomInt(1,4)
            local eb = "blink"..tostring(fl)
            --SFX.play(fl)
            if not data.puppet:getAnimation(eb) then
                data.puppet:setAnimation(eb,eb)
            end
        end
    end
end

-- Function that runs every time the screen is drawn for the Whimsy Mushroom `v`
---@param v NPC
function whimsy.onDrawShroom(v)
	if not v.data.initialized then return end
	local data = v.data
	local config = NPC.config[v.id]
	local settings = data._settings
	npcutils.hideNPC(v)

    local darkradius = config.darkradius or (config.width+config.height)
    local mull = (math.cos(data.timer/(config.framespeed*0.75))+1)/2

    if data.activated then
        mull = math.clamp(1-math.max(data.timer-192,0)/64)*1.25
        darkradius = darkradius+easing.outInBack(data.timer,0,400,224,3)
    end

    if mull > 0 then
        Graphics.drawCircle{
            x = v.centerX,
            y = v.centerY,
            sceneCoords = true,
            radius = darkradius,
            priority = whimsy.darkpriority-1,
            color = Color(whimsy.colors.dark.r,whimsy.colors.dark.g,whimsy.colors.dark.b,math.clamp((whimsy.colors.dark.a/2)*mull))
        }
    end
end


-- Spore AI


-- The function that every game tick for the Whimsy Spore `v`
---@param v NPC
function whimsy.onTickSpore(v)
	if Defines.levelFreeze then return end

	local data = v.data -- NPC's data
	local config = NPC.config[v.id] -- NPC config
	local settings = data._settings -- Custom extra settings

	if v.despawnTimer <= 0 then
		data.initialized = false
        if data.puppet then
            data.puppet:despawn(false)
        end
        if data.particles then
            for _,d in ipairs(data.particles) do
                d:despawn(false)
            end
        end
        data.puppet = nil
        data.particles = nil
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
        data.activating = false
        data.activated = false
        data.playedWoosh = false
        data.iCanDie = false
        data.timer = lunatime.toTicks(4)
        data.ppos = {}
        data.particles = {}
        data.puppet = puppet.spawn{
			id = config.puppet or "whimsyspore",
			parent = v
		}
	end
    
    if data.activating then
        if not data.activated then
            data.timer = lunatime.toTicks(4)
            data.activated = true
            trySFX(whimsy.sporesfx)
            data.player = data.player or player
            for _,p in ipairs(Player.get()) do
                if p.isValid then
                    if p.section ~= data.player.section then
                        p.section = data.player.section
                        p.x = data.player.x
                        p.y = data.player.y
                    end
                    data.ppos[_] = vector(p.centerX,p.centerY)
                end
            end

            local parts = 64
            for i = 1, parts do
                data.particles[#data.particles+1] = puppet.spawn{
                    id = "darkcircle",
                    parent = v,
                }

                local part = data.particles[#data.particles]
                part.data.offset = vector(RNG.random()*v.width/2,RNG.random()*v.height/2)

                part.data.rotation = i*(360/parts)

                part:setAnimation("pulse",nil,RNG.random(-config.speed,config.speed),RNG.random(0.5,1.25))
            end

            if whimsy.music then
                Audio.MusicFadeOut(player.section,100)
            end
        end

        data.timer = data.timer - 1.25

        if data.timer <= 0 then
            for _,p in ipairs(Player.get()) do
                if p.isValid then
                    if p.forcedState == FORCEDSTATE_INVISIBLE then
                        p.forcedState = FORCEDSTATE_NONE
                    end
                    p.speedX = 0
                    p.speedY = 0
                end
            end
            whimsy.stop()
            data.iCanDie = true
            v:collect(data.player)
        else
            for _,p in ipairs(Player.get()) do
                if p.isValid then
                    --p.forcedState = FORCEDSTATE_INVISIBLE
                    if data.ppos[_] then
                        local larp = data.ppos[_]
                        p.x = (larp.x-p.width/2) + p.width*(1-_)*1.5
                        p.y = larp.y-p.height/2
                    end
                end
            end
            if data.timer <= lunatime.toTicks(1) and not data.playedWoosh then
                data.playedWoosh = true
                trySFX(whimsy.wooshsfx)
            end
        end
    else
        local pointing = false
        for _,p in ipairs(Player.get()) do
            if p.isValid and (not p:isDead()) and (findDistance(v.center,p.center) <= 128) then
                pointing = true
                break
            end
        end

        if pointing then
            if data.puppet:getAnimationName("point") ~= "pointin" and data.puppet:getAnimationName("point") ~= "point" then
                data.puppet:setAnimation("pointin","point")
            end
        else
            if data.puppet:getAnimation("point") and data.puppet:getAnimationName("point") ~= "pointout" then
                data.puppet:setAnimation("pointout","point")
            end
        end
    end

	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		return
	end
end

-- Function that runs after onTick and internal smbx code for the Whimsy Spore `v`
---@param v NPC
function whimsy.onTickEndSpore(v)
    if not v.data.initialized then return end
	local data = v.data
	local config = NPC.config[v.id]
	local settings = data._settings

    local darkradius = 0--config.darkradius or (config.width+config.height)

    if data.activated then
        darkradius = darkradius+easing.outInBack(data.timer,0,400,224,3)
    else
        data.puppet.y = v.y+math.cos(data.timer/config.framespeed)*config.speed
    end

    if data.particles then
        for _,d in ipairs(data.particles) do
            d.data.rotation = d.data.rotation - 0.8
            local vec = vector(darkradius,0):rotate(d.data.rotation)
            d.x = d.x+vec.x+d.data.offset.x-v.width/4
            d.y = d.y+vec.y+d.data.offset.y-v.height/4

            --Text.print(d:getAnimationName(0),100,100)
        end
    end
    
end

-- Function that runs every time the screen is drawn for the Whimsy Spore `v`
---@param v NPC
function whimsy.onDrawSpore(v)
    if not v.data.initialized then return end
	local data = v.data
	local config = NPC.config[v.id]
	local settings = data._settings
	npcutils.hideNPC(v)

    local darkradius = 0--config.darkradius or (config.width+config.height)
    local mull = 0

    if data.activated then
        mull = math.clamp(1-math.max(data.timer-192,0)/64)*1.25
        darkradius = darkradius+easing.outInBack(data.timer,0,400,224,3)
    end

    if mull > 0 then
        Graphics.drawCircle{
            x = v.centerX,
            y = v.centerY,
            sceneCoords = true,
            radius = darkradius,
            priority = whimsy.darkpriority-1,
            color = Color(whimsy.colors.darkoutline.r,whimsy.colors.darkoutline.g,whimsy.colors.darkoutline.b,math.clamp((whimsy.colors.darkoutline.a/2)*mull))
        }
    end
end





-- Executes when the NPC `v` gets harmed by `r` reason. It also gives the eventToken `e` and the culprit `n`
---@param e EventToken
---@param v NPC
---@param r number
---@param n Player|NPC|nil
function whimsy.onNPCHarm(e,v,r,n)
	if not shroomIDs[v.id] then return end
end

-- Executes when the NPC `v` gets killed by `r` reason. It also gives the eventToken `e`
---@param e EventToken
---@param v NPC
---@param r number
function whimsy.onNPCKill(e,v,r)
	if not shroomIDs[v.id] then return end
    --if not v.data.activated then
    --    e.cancelled = true
    --    return
    --end
end

--Executes *immediately* when any NPC takes damage. Passes the NPC `v`, the harm type causing the damage `r`, and any culprit `n` if it exists.
---@param v NPC
---@param r number
---@param n Player|NPC|nil
function whimsy.onPostNPCHarm(v,r,n)
	if not shroomIDs[v.id] then return end
end

-- Executes when the NPC `v` gets killed by `r` reason without being cancelled.
---@param v NPC
---@param r number
function whimsy.onPostNPCKill(v,r)
	if not shroomIDs[v.id] then return end
end

--Executes *immediately* when any NPC is collected. Passes the NPC `v`, the player that collected it `p`, and a token `e` that can be used to cancel the death.
---@param e EventToken
---@param v NPC
---@param p Player
function whimsy.onNPCCollect(e,v,p)
    if e.cancelled then return end

    local data = v.data

    if (shroomIDs[v.id] or sporeIDs[v.id]) and not data.iCanDie then
        e.cancelled = true
        if not data.activating then
            data.activating = true
            data.player = p
            trySFX(whimsy.getsfx)
        end
        if shroomIDs[v.id] then
            triggerEvent(whimsy.beginEvent)
        else
            triggerEvent(whimsy.endEvent)
        end
    end
end

--Executes *immediately* when any NPC is collected. Passes the NPC `v` and the player `p` that collected it. Since this event runs only when onNPCCollect was not cancelled, it is useful for running code that should happen only when NPCs were actually collected.
---@param v NPC
---@param p Player
function whimsy.onPostNPCCollect(v,p)
    if not shroomIDs[v.id] then return end
end

return whimsy