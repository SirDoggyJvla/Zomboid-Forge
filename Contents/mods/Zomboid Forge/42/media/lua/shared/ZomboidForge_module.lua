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

local ZomboidForge = {
    TrueID = {},
    HatFallen = {},
    NonPersistentZData = {},
    ZTypes = {},


    SpeedOptionToWalktype = {
        -- sprinter
        [1] = {"sprint1","sprint2","sprint3","sprint4","sprint5"},
        -- fast shambler
        [2] = {"1","2","3","4","5"},
        -- shambler
        [3] = {"slow1","slow2","slow3"},
        -- random, weighted table
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

    --- DEBUGING ---
    Debug = {},
    DEBUG_ZombiePannel = {
        Stats = false,
    },
}

return ZomboidForge