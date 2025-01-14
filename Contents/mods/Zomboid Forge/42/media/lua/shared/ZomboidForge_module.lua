--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

Module of ZomboidForge

]]--
--[[ ================================================ ]]--

-- Custom event to adding your own custom ZTypes
LuaEventManager.AddEvent("OnLoadZTypes")
LuaEventManager.AddEvent("OnZombieHitCharacter")
LuaEventManager.AddEvent("OnZombieThump")

local ZomboidForge = {
    TrueID = {},
    HatFallen = {},
    NonPersistentZData = {},
    ZTypes = {},

    --- INITIALIZING ZOMBIE ---
    ZombiesWaitingForInitialization = {},
    ZombiesChangeVisualsNextTick = {},


    --- MOD OPTIONS ---

    Configs = {
        FONT_LIST = {
            "Handwritten",
            "Small",
            "Medium",
            "Large",
            "Massive",
            "MainMenu1",
            "MainMenu2",
            "Cred1",
            "Cred2",
            "NewSmall",
            "NewMedium",
            "NewLarge",
            "Code",
            "MediumNew",
            "AutoNormSmall",
            "AutoNormMedium",
            "AutoNormLarge",
            "Dialogue",
            "Intro",
            "DebugConsole",
            "Title",
            "SdfRegular",
            "SdfBold",
            "SdfItalic",
            "SdfBoldItalic",
            "SdfOldRegular",
            "SdfOldBold",
            "SdfOldItalic",
            "SdfOldBoldItalic",
            "SdfRobertoSans",
            "SdfCaveat",
        }
    },

    --- NAMETAG ---

    nametagList = {},
    zombiesInFov = {},
    zombiesOnCursor = {},


    --- ZOMBIE STATS ---

    -- Sandbox option equivalent to walkType variables
    SpeedOptionToWalktype = {
        -- sprinter
        [1] = {"sprint1","sprint2","sprint3","sprint4","sprint5"},
        -- fast shambler
        [2] = {"1","2","3","4","5"},
        -- shambler
        [3] = {"slow1","slow2","slow3"},
        -- random, equal weighted
        [4] = {
            ["sprint1"] = 18,
            ["sprint2"] = 18,
            ["sprint3"] = 18,
            ["sprint4"] = 18,
            ["sprint5"] = 18,
            ["1"] = 18,
            ["2"] = 18,
            ["3"] = 18,
            ["4"] = 18,
            ["5"] = 18,
            ["slow1"] = 30,
            ["slow2"] = 30,
            ["slow3"] = 30,
        }
    },

    SandboxOptionsStats = {
        -- defines the sight setting
        sight = {
            setSandboxOption = "ZombieLore.Sight",
            classField = "sight",
            returnValue = {
                [1] = 1, -- Eagle
                [2] = 2, -- Normal 
                [3] = 3, -- Poor
            },
        },

        -- defines the hearing setting
        hearing = {
            setSandboxOption = "ZombieLore.Hearing",
            classField = "hearing",
            returnValue = {
                [1] = 1, -- Pinpoint
                [2] = 2, -- Normal 
                [3] = 3, -- Poor
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
            },
        },

        -- defines the memory setting
        memory = {
            setSandboxOption = "ZombieLore.Memory",
            classField = "memory",
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
            classField = "strength",
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
            --classField = MISSING,
            returnValue = {
                [1] = 1,
                [2] = 2,
                [3] = 3,
            },
        },
    },


    -- used to set the various visuals/data of zombies
    ZombieDataToSet = {
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

        ["HP"] = {
            current = function(zombie)
                return zombie:getHealth()
            end,
            apply = function(zombie,choice)
                zombie:setHealth(choice)
            end,
        },

        ["fireKillRate"] = {
            current = function(zombie)
                return zombie:getFireKillRate()
            end,
            apply = function(zombie,choice)
                zombie:setFireKillRate(choice)
            end,
        },

        ["onlyJawStab"] = {
            current = function(zombie)
                return zombie:isOnlyJawStab()
            end,
            apply = function(zombie,choice)
                zombie:setOnlyJawStab(choice)
            end,
        },

        ["canCrawlUnderVehicles"] = {
            current = function(zombie)
                return zombie:isCanCrawlUnderVehicle()
            end,
            apply = function(zombie,choice)
                zombie:setCanCrawlUnderVehicle(choice)
            end,
        },

        ["noDamage"] = {
            current = function(zombie)
                return zombie:getNoDamage()
            end,
            apply = function(zombie,choice)
                zombie:setNoDamage(choice)
            end,
        },

        ["avoidDamage"] = {
            current = function(zombie)
                return zombie:avoidDamage()
            end,
            apply = function(zombie,choice)
                zombie:setAvoidDamage(choice)
            end,
        },

        ["noTeeth"] = {
            current = function(zombie)
                return zombie:isNoTeeth()
            end,
            apply = function(zombie,choice)
                zombie:setNoTeeth(choice)
            end,
        },

        ["animationVariable"] = {
            apply = function(zombie,choice)
                if not zombie:getVariableBoolean(choice) then
                    zombie:setVariable(choice,'true')
                end
            end,
        },

        ["skeleton"] = {
            apply = function(zombie,choice)
                if zombie:isSkeleton() ~= choice then
                    zombie:setSkeleton(choice)
                end
            end,
        },

        ["customEmitter"] = {
            apply = function(zombie,choice)
                local zombieEmitter = zombie:getEmitter()
                if not zombieEmitter:isPlaying(choice) then
                    zombieEmitter:stopAll() -- makes sure old emitters get removed first
                    zombieEmitter:playVocals(choice)
                end
            end,
        },
    },


    --- DEBUGING ---
    Debug = {},
    DEBUG_ZombiePannel = {
        Stats = false,
        RegisterNametags = false,
        ZombieTable = false,
        ShowHealth = false,
    },
}

return ZomboidForge