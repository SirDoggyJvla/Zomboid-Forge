--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

This file defines the core of the mod Zomboid Forge

]]--
--[[ ================================================ ]]--

--- Import functions localy for performances reasons
local table = table -- Lua's table module
local ipairs = ipairs -- ipairs function
local pairs = pairs -- pairs function
local ZombRand = ZombRand -- java function
local tostring = tostring --tostring function
local player = getPlayer() --is initialized later, set here for in-game reloads

--- import module from ZomboidForge
local ZomboidForge = require "ZomboidForge_module"

-- Initialize player
ZomboidForge.OnCreatePlayerInitializations.ZomboidForge_commands = function()
    player = getPlayer()
end

local zombieList
---@param onlineID          int
---@return IsoZombie|nil
ZomboidForge.getZombieByOnlineID = function(onlineID)
    -- initialize zombie list
    if not zombieList then
        zombieList = player:getCell():getZombieList()
    end

    -- get zombie if in player's cell
    for i = 0,zombieList:size()-1 do
        local zombie = zombieList:get(i)
        if zombie:getOnlineID() == onlineID then
            return zombie
        end
    end

    return nil
end

-- Sends a request to server to update every clients animationVariable for every clients.
---@param args          table
ZomboidForge.Commands.ZombieHandler.SetAnimationVariable = function(args)
    if player ~= getPlayerByOnlineID(args.id) then
        -- retrieve zombie
        local zombie = ZomboidForge.getZombieByOnlineID(args.zombie)
        if zombie then
            zombie:setVariable(args.animationVariable,args.state)
        end
    end
end

-- Kill zombie if told to do so. Else just set the HP to the given value
ZomboidForge.Commands.ZombieHandler.DamageZombie = function(args)
    -- get zombie info
    local zombie = ZomboidForge.getZombieByOnlineID(args.zombie)
    if zombie then
        -- retrieve attacker IsoPlayer
        local attacker = getPlayerByOnlineID(args.attacker)

        -- kill if need to kill
        -- else stagger with proper HitReaction
        if args.kill then
            -- kill zombie
            ZomboidForge.KillZombie(zombie,attacker)

            -- add the death animation
            zombie:setHitReaction("EndDeath")
        else
            if not zombie:avoidDamage() then
                zombie:setAvoidDamage(true)
            end

            if not args.shouldNotStagger then
                ZomboidForge.ApplyHitReaction(zombie,attacker,args.hitReaction)
            end
        end
    end
end

-- Sends a request to server to update every clients animationVariable for every clients.
---@param args          table
ZomboidForge.Commands.ZombieHandler.RemoveEmitters = function(args)
    if player == getPlayerByOnlineID(args.id) then return end
    -- get zombie info
    local zombie = ZomboidForge.getZombieByOnlineID(args.zombie)
    if zombie then
        zombie:getEmitter():stopAll()
    end
end