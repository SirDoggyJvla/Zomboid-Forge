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

--- import module from ZomboidForge
local ZomboidForge = require "ZomboidForge_module"

local zombieList
---@param onlineID          int
---@return IsoZombie|nil
ZomboidForge.getZombieByOnlineID = function(onlineID)
    -- initialize zombie list
    if not zombieList then
        zombieList = getPlayer():getCell():getZombieList()
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
    if getPlayer() ~= getPlayerByOnlineID(args.id) then
        -- retrieve zombie
        local zombie = ZomboidForge.getZombieByOnlineID(args.zombie)
        if zombie then
            zombie:setVariable(args.animationVariable,args.state)
        end
    end
end

local killXP
-- Kill zombie if told to do so. Else just set the HP to the given value
ZomboidForge.Commands.ZombieHandler.DamageZombie = function(args)
    -- get zombie info
    local zombie = ZomboidForge.getZombieByOnlineID(args.zombie)
    if zombie then
        if args.kill then
            local player = getPlayerByOnlineID(args.attacker)
            zombie:setHealth(0)
            zombie:changeState(ZombieOnGroundState.instance())
            zombie:setAttackedBy(player)
            zombie:becomeCorpse()

            zombie:setHitReaction("EndDeath")
            --[[
            if getActivatedMods():contains("Advanced_Trajectorys_Realistic_Overhaul") and player == getPlayer() then
                player:setZombieKills(player:getZombieKills()+1)

                if not Advanced_trajectory.hasFlameWeapon then
                    killXP = killXP or getSandboxOptions():getOptionByName("Advanced_trajectory.XPKillModifier"):getValue()
                    -- multiplier to 0.67
                    triggerEvent("OnWeaponHitXp",player, player:getPrimaryHandItem(), zombie, args.damage) -- OnWeaponHitXp From "KillCount",used(wielder,weapon,victim,damage)
                    Events.OnWeaponHitXp.Add(player:getXp():AddXP(Perks.Aiming, killXP));
                end
            end]]
        else
            if not zombie:avoidDamage() then
                zombie:setAvoidDamage(true)
            end

            if not args.shouldNotStagger then
                zombie:setHitReaction("HitReaction")
            end
        end
    end
end

-- Sends a request to server to update every clients animationVariable for every clients.
---@param args          table
ZomboidForge.Commands.ZombieHandler.RemoveEmitters = function(args)
    if getPlayer() == getPlayerByOnlineID(args.id) then return end
    -- get zombie info
    local zombie = ZomboidForge.getZombieByOnlineID(args.zombie)
    if zombie then
        zombie:getEmitter():stopAll()
    end
end