local whimsy = {}

local npcManager = require("npcManager")

local puppet = require("puppet")

local npcutils = require("npcs/npcutils")

local shroomIDs = {}

function whimsy.registerActivator(id)
    shroomIDs[id] = true
    npcManager.registerEvent(id, whimsy, "onTickNPC")
	npcManager.registerEvent(id, whimsy, "onTickEndNPC")
	npcManager.registerEvent(id, whimsy, "onDrawNPC")
end

function whimsy.onInitAPI()
	--registerEvent(whimsy, "onNPCHarm")
	--registerEvent(whimsy, "onNPCKill")
	--registerEvent(whimsy, "onPostNPCHarm")
	--registerEvent(whimsy, "onPostNPCKill")
	--registerEvent(whimsy, "onNPCCollect")
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
---@param eye1 Color? Color of the first pair of eyes
---@param eye2 Color? Color of the second pair of eyes
---@param eye3 Color? Color of the third pair of eyes
---@param eye4 Color? Color of the fourth pair of eyes
function whimsy.changeColors(regular,rim,bloom,spots,stem,stemrim,eye1,eye2,eye3,eye4)
    changeColor(whimsy.colors.reg,regular)
    changeColor(whimsy.colors.rim,rim)
    changeColor(whimsy.colors.blm,bloom)
    changeColor(whimsy.colors.spt,spots)
    changeColor(whimsy.colors.stm,stem)
    changeColor(whimsy.colors.stmr,stemrim)
    changeColor(whimsy.colors.eyc1,eye1)
    changeColor(whimsy.colors.eyc2,eye2)
    changeColor(whimsy.colors.eyc3,eye3)
    changeColor(whimsy.colors.eyc4,eye4)
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
		}
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
        }
	},
	startAnimations = {"idle","pulse"}
}

-- The function that every game tick for the NPC `v`
---@param v NPC
function whimsy.onTickNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data -- NPC's data
	local config = NPC.config[v.id] -- NPC config
	local settings = data._settings -- Custom extra settings

	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.puppet = puppet.spawn{
			id = "whimsyshroom",
			parent = v
		}
		data.timer = 0
	end

	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		data.timer = 0
	end
	data.timer = data.timer + 1
end

-- Function that runs after onTick and internal smbx code for the NPC `v`
---@param v NPC
function whimsy.onTickEndNPC(v)
	if not v.data.initialized then return end
	local data = v.data
	local config = NPC.config[v.id]
	local settings = data._settings


    ---@type Puppet
    data.puppet = data.puppet

	data.puppet.y = v.y+math.cos(data.timer/config.framespeed)*config.speed

    if RNG.random() <= (config.blinkchance or 0.1)/lunatime.toTicks(1/math.max(config.frames,1)) then
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

-- Function that runs every time the screen is drawn for the NPC `v`
---@param v NPC
function whimsy.onDrawNPC(v)
	if not v.data.initialized then return end
	local data = v.data
	local config = NPC.config[v.id]
	local settings = data._settings
	npcutils.hideNPC(v)
end

-- Executes when the NPC `v` gets harmed by `r` reason. It also gives the eventToken `e` and the culprit `n`
---@param e EventToken
---@param v NPC
---@param r number
---@param n Player|NPC|nil
function whimsy.onNPCHarm(e,v,r,n)
	if shroomIDs[v.id] then return end
end

-- Executes when the NPC `v` gets killed by `r` reason. It also gives the eventToken `e`
---@param e EventToken
---@param v NPC
---@param r number
function whimsy.onNPCKill(e,v,r)
	if shroomIDs[v.id] then return end
end

--Executes *immediately* when any NPC takes damage. Passes the NPC `v`, the harm type causing the damage `r`, and any culprit `n` if it exists.
---@param v NPC
---@param r number
---@param n Player|NPC|nil
function whimsy.onPostNPCHarm(v,r,n)
	if shroomIDs[v.id] then return end
end

-- Executes when the NPC `v` gets killed by `r` reason without being cancelled.
---@param v NPC
---@param r number
function whimsy.onPostNPCKill(v,r)
	if shroomIDs[v.id] then return end
end

--Executes *immediately* when any NPC is collected. Passes the NPC `v`, the player that collected it `p`, and a token `e` that can be used to cancel the death.
---@param e EventToken
---@param v NPC
---@param p Player
function whimsy.onNPCCollect(e,v,p)
    if shroomIDs[v.id] then return end
end

--Executes *immediately* when any NPC is collected. Passes the NPC `v` and the player `p` that collected it. Since this event runs only when onNPCCollect was not cancelled, it is useful for running code that should happen only when NPCs were actually collected.
---@param v NPC
---@param p Player
function whimsy.onPostNPCCollect(v,p)
    if shroomIDs[v.id] then return end
end

return whimsy