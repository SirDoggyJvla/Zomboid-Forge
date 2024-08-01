--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

This file defines the module of Zomboid Forge server side

]]--
--[[ ================================================ ]]--

if not isServer() then return end

--- Import functions localy for performances reasons
local table = table -- Lua's table module
local ipairs = ipairs -- ipairs function
local pairs = pairs -- pairs function
local ZombRand = ZombRand -- java function
local tostring = tostring --tostring function

--- main module for use in storing informations and pass along other files
local ZomboidForge_server = {
    Commands = {
        ZombieHandler = {},
    },
}

-- Retrieves the zombie via its onlineID.
---@param onlineID          int
---@return IsoZombie|nil
ZomboidForge_server.getZombieByOnlineID = function(player,onlineID)
    local zombieList = player:getCell():getZombieList()

    -- get zombie if in player's cell
    for i = 0,zombieList:size()-1 do
        local zombie = zombieList:get(i)
        if zombie:getOnlineID() == onlineID then
            return zombie
        end
    end

    return nil
end

return ZomboidForge_server