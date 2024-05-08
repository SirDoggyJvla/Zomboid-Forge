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
local ZomboidForge = {
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


    --- Stats for each zombies. `key` of `Stats` are the variable to 
    -- define with `key` value from `returnValue`. The `value` of `returnValue` 
    -- associated to a `key` is the compared one with what the game returns 
    -- from `isoZombie class fields`.
    Stats = {
        -- defines walk speed of zombie
        walktype = {
            setSandboxOption = "ZombieLore.Speed",
            --classField = "speedType",
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
                [1] = 1, -- can open doors
                [2] = -1, -- navigate 
                [3] = -1, -- basic navigate
                --[4] = ZomboidForge.coinFlip(),
            },
        },
    
        --- UNVERIFIABLE STATS
        -- these stats can't be checked if already updated because
        -- of how the fields are updated or if they don't have any
        -- class fields to check them.
        
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
    
        -- defines the transmission setting
        transmission = {
            setSandboxOption = "ZombieLore.Transmission",
            --classField = missing,
            returnValue = {
                [1] = 1, -- can open doors
                [2] = 2, -- navigate 
                [3] = 3, -- basic navigate
                --[4] = ZomboidForge.coinFlip(),
            },
        },
    }
}

return ZomboidForge