--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

This file defines the module of Zomboid Forge

]]--
--[[ ================================================ ]]--

--- main module for use in storing informations and pass along other files
local ZomboidForge
ZomboidForge = {
    -- basic dictionaries for storing data
    ZTypes =                    {},
    ShowNametag =               {},
    NonPersistentZData =        {},
    TrueID =                    {},
    HatFallen =                 {},

    -- command functions
    Commands = {
        ZombieHandler =         {},
    },

    -- Counter of the ZomboidForge framework. Updates every OnTick
    counter =                   500, -- default value, replaced OnGameStart

    -- default FOV for zombies
    defaultFOV = {
        [1] = -0.7,
        [2] = -0.8,
        [3] = -0.9,
    },

    -- used to set the various visuals/data of zombies
    ZombieData = {
        ["outfit"] = {
            current = function(zombie)
                return zombie:getOutfitName()
            end,
            apply = function(zombie,choice)
                zombie:dressInNamedOutfit(choice)
                zombie:reloadOutfit()
            end,
        },

        ["hair"] = {
            current = function(zombie)
                return zombie:getHumanVisual():getHairModel()
            end,
            apply = function(zombie,choice)
                zombie:getHumanVisual():setHairModel(choice)
            end,
        },

        ["hairColor"] = {
            current = function(zombie)
                return zombie:getHumanVisual():getHairColor()
            end,
            apply = function(zombie,choice)
                zombie:getHumanVisual():setHairColor(choice)
            end,
        },

        ["beard"] = {
            current = function(zombie)
                return zombie:getHumanVisual():getBeardModel()
            end,
            apply = function(zombie,choice)
                zombie:getHumanVisual():setBeardModel(choice)
            end,
        },

        ["beardColor"] = {
            current = function(zombie)
                return zombie:getHumanVisual():getBeardColor()
            end,
            apply = function(zombie,choice)
                zombie:getHumanVisual():setBeardColor(choice)
            end,
        },
    },
    ZombieData_boolean = {
        ["animationVariable"] = {
            update = function(zombie,choice)
                if not zombie:getVariableBoolean(choice) then
                    zombie:setVariable(choice,'true')
                end
            end,
        },

        ["skeleton"] = {
            update = function(zombie,choice)
                if zombie:isSkeleton() ~= choice then
                    zombie:setSkeleton(choice)
                end
            end,
        },

        ["customEmitter"] = {
            update = function(zombie,choice)
                local zombieEmitter = zombie:getEmitter()
                if not zombieEmitter:isPlaying(choice) then
                    zombieEmitter:stopAll() -- makes sure old emitters get removed first
                    zombieEmitter:playVocals(choice)
                end
            end,
        },
    },

    BooleanResult = {
        ["nil"] = function(data,zombie,ZType) return nil end,
        ["boolean"] = function(data,zombie,ZType) return data end,
        ["function"] = function(data,zombie,ZType) return data(zombie,ZType) end,
        ["string"] = function(data,zombie,ZType) return ZomboidForge[data](zombie,ZType) end,
    },

    --- Stats for each zombies. `key` of `Stats` are the variable to 
    -- define with `key`'s `value` from `returnValue`. The `value` of `returnValue` 
    -- associated to a `key` is the compared one with what the game returns 
    -- from `IsoZombie class fields`.
    Stats_classField = {
        -- defines walk speed of zombie
        walktype = {
            setSandboxOption = "ZombieLore.Speed",
            classField = "speedType",
            returnValue = {
                [1] = 1, -- sprinter
                [2] = 2, -- fast shambler
                [3] = 3, -- shambler
                [4] = 2, -- crawlers, speed doesn't matter
            },
        },

        -- defines the sight setting
        sight = {
            setSandboxOption = "ZombieLore.Sight",
            classField = "sight",
            returnValue = {
                [1] = 1, -- Eagle
                [2] = 2, -- Normal 
                [3] = 3, -- Poor
                --[4] = ZomboidForge.coinFlip(),
            },
        },

        -- defines the sight setting
        hearing = {
            setSandboxOption = "ZombieLore.Hearing",
            classField = "hearing",
            returnValue = {
                [1] = 1, -- Pinpoint
                [2] = 2, -- Normal 
                [3] = 3, -- Poor
                --[4] = ZomboidForge.coinFlip(),
            },
        },

        -- defines cognition aka navigation of zombie
        --
        -- navigate = basic navigate.
        -- It's a lie from the base game so doesn't matter which one you chose
        cognition = {
            setSandboxOption = "ZombieLore.Cognition",
            classField = "cognition",
            returnValue = {
                [1] = 1, -- can open doors (navigate + use doors)
                [2] = -1, -- navigate 
                [3] = -1, -- basic navigate
                --[4] = ZomboidForge.coinFlip(),
            },
        },
    },

    --- UNVERIFIABLE STATS
    -- these stats can't be checked if already updated because
    -- of how the fields are updated or if they don't have any
    -- class fields to check them.
    Stats_nonClassField = {
        -- defines the memory setting
        memory = {
            setSandboxOption = "ZombieLore.Memory",
            --classField = "memory",
            returnValue = {
                [1] = 1250, -- long
                [2] = 800, -- normal 
                [3] = 500, -- short
                [4] = 25, -- none
            },
        },

        -- defines strength of zombie
        -- undefined, causes issues when toughness is modified
        strength = {
            setSandboxOption = "ZombieLore.Strength",
            --classField = "strength",
            returnValue = {
                [1] = 5, -- Superhuman
                [2] = 3, -- Normal
                [3] = 1, -- Weak
            },
        },

        -- defines toughness of zombie
        -- undefined
        toughness = {
            setSandboxOption = "ZombieLore.Toughness",
            --classField = missing,
            returnValue = {
                [1] = 1,
                [2] = 2,
                [3] = 3,
            },
        },
    },
}

return ZomboidForge