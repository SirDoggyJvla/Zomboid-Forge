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
local ZFModData = ModData.getOrCreate("ZomboidForge")
local ZFModOptions = require "ZomboidForge_ClientOption"
ZFModOptions = ZFModOptions.options_data

-- localy initialize player and zombie list
local client_player = getPlayer()
local zombieList
local function initTLOU_OnGameStart(_, _)
	client_player = getPlayer()
    zombieList = client_player:getCell():getZombieList()
end
Events.OnCreatePlayer.Remove(initTLOU_OnGameStart)
Events.OnCreatePlayer.Add(initTLOU_OnGameStart)

-- localy initialize ModData
local function initModData()
    ZFModData = ModData.getOrCreate("ZomboidForge")
end
Events.OnInitGlobalModData.Remove(initModData)
Events.OnInitGlobalModData.Add(initModData)

--- OnLoad function to initialize the mod
ZomboidForge.OnLoad = function()
    -- initialize ModData
    if not ZFModData.PersistentZData then
        ZFModData.PersistentZData = {}
    end

    -- reset non persistent data
    ZomboidForge.nonPersistentZData = {}

    -- calculate total chance
    ZomboidForge.TotalChance = 0
    for _,ZombieTable in pairs(ZomboidForge.ZTypes) do
        ZomboidForge.TotalChance = ZomboidForge.TotalChance + ZombieTable.chance
    end
end

--- OnLoad function to initialize the mod
ZomboidForge.OnGameStart = function()
    -- Zomboid (base game zombies)
	if SandboxVars.ZomboidForge.ZomboidSpawn then
        ZomboidForge.AddZomboids()
	end
end

-- Handles the custom behaviors of the Zombies and triggers attack behavior.
-- Steps of Zombie update:
--
--      `Initialize zombie type if needed`
--      `Update zombie visuals`
--      `Updates stats that can verified`
--      `Set combat data`
--      `Update nametag`
--      `Run custom behavior`
--      `OnThump behavior`
--      `Run zombie attack function`
---@param zombie IsoZombie
ZomboidForge.ZombieUpdate = function(zombie)
    if not ZomboidForge.IsZombieValid(zombie) then return end

    -- get zombie data
    local trueID = ZomboidForge.pID(zombie)
    local ZType = ZomboidForge.GetZType(trueID)
    local ZombieTable = ZomboidForge.ZTypes[ZType]

    -- run custom behavior functions for this zombie
    if ZombieTable.customBehavior then
        for i = 1,#ZombieTable.customBehavior do
            ZomboidForge[ZombieTable.customBehavior[i]](zombie,ZType)
        end
    end

    if zombie:isOnFire() then
        zombie:setHealth(zombie:getHealth() - zombie:getFireKillRate())
    end

    -- run onThump functions
    if ZombieTable.onThump then
        -- run code if zombie has thumping target
        local thumped = zombie:getThumpTarget()
        if thumped then
            local PersistentZData = ZomboidForge.GetPersistentZData(trueID,nil)

            -- check for thump
            -- update thumped only if zombie is thumping
            -- getThumpTarget outputs the target as long as the zombie is in thumping animation
            -- but we want to make sure we run onThump only if a hit is sent
            local timeThumping = zombie:getTimeThumping()
            if PersistentZData.thumpCheck ~= timeThumping and timeThumping ~= 0 then
                PersistentZData.thumpCheck = timeThumping

                for i = 1,#ZombieTable.onThump do
                    ZomboidForge[ZombieTable.onThump[i]](zombie,ZType,thumped)
                end
            end
        end
    end

    -- run zombie attack functions
    if zombie:isAttacking() then
        ZomboidForge.ZombieAgro(zombie,ZType)
    end
end


local tickAmount = 0
-- Handles the updating of the stats of every zombies as well as initializing them. zombieList is initialized
-- for the client and doesn't need to be changed after. The code goes through every zombie index and updates
-- the stats of each zombies at a rate of every `time_before_update` seconds and one after the other. A formula was made to update
-- zombies based on that time
--
-- The part updating one zombie per tick was made by `Albion`.
--
-- Added to `OnTick`.
---@param tick          int
ZomboidForge.OnTick = function(tick)
    -- initialize zombieList
    if not zombieList then
        zombieList = client_player:getCell():getZombieList()
    end
    local zombieList_size = zombieList:size()

    -- Update things than need to be updated every ticks
    local showNametag = SandboxVars.ZomboidForge.Nametags and ZFModOptions.NameTag.value
    local zombiesOnCursor
    if showNametag then
        zombiesOnCursor = ZomboidForge.GetZombiesOnCursor()
    end

    -- Define the fraction variable
    local UpdateRate = math.min(ZomboidForge.UpdateRate[ZFModOptions.UpdateRate.value],zombieList_size)
    tickAmount = tickAmount < UpdateRate - 1 and tickAmount + 1 or 0

    -- update every zombies
    local zombie
    for i = 0, zombieList_size - 1 do
        -- get zombie and verify it's valid
        zombie = zombieList:get(i)
        if ZomboidForge.IsZombieValid(zombie) then
            -- get zombie data
            local trueID = ZomboidForge.pID(zombie)
            local ZType = ZomboidForge.GetZType(trueID)
            local ZombieTable = ZomboidForge.ZTypes[ZType]

            -- Perform these operations for 1/variable of the zombies each tick
            if i%UpdateRate == tickAmount then
                if client_player:CanSee(zombie) then
                    -- update visuals
                    ZomboidForge.UpdateVisuals(zombie, ZombieTable, ZType)

                    -- update stats that can be verified
                    ZomboidForge.UpdateZombieStats(zombie, ZombieTable)

                    -- set combat data
                    ZomboidForge.SetZombieCombatData(zombie, ZombieTable, ZType, trueID)

                    -- run custom data if any
                    if ZombieTable.customData then
                        for _, customData in ipairs(ZombieTable.customData) do
                            ZomboidForge[customData](zombie,ZType)
                        end
                    end
                end
            end

            -- update nametag, needs to be updated OnTick bcs if zombie
            -- gets staggered it doesn't get updated with OnZombieUpdate
            if showNametag and ZombieTable.name then
                local ticks = zombie:getModData().ticks
                local valid = ZomboidForge.IsZombieValidForNametag(zombie, zombiesOnCursor)

                ZomboidForge.UpdateNametag(zombie, ZombieTable, ticks, valid)
            end
        end
    end
end

-- Trigger `OnHit` behavior of `Zombie` depending on `ZType`.
-- Handles the custom HP of zombies and apply custom damage depending on the customDamage function.
---@param attacker      IsoGameCharacter
---@param victim        IsoGameCharacter
---@param handWeapon    HandWeapon
---@param damage        float
ZomboidForge.OnHit = function(attacker, victim, handWeapon, damage)
    if not victim:isAlive() then return end

    if not attacker:isZombie() and victim:isZombie() then
        if not ZomboidForge.IsZombieValid(victim) then return end

        ZomboidForge.PlayerAttacksZombie(attacker, victim, handWeapon, damage)
    end
end

--- OnDeath functions
---@param zombie        IsoZombie
ZomboidForge.OnDeath = function(zombie)
    if not ZomboidForge.IsZombieValid(zombie) then return end

    -- get zombie data
    local trueID = ZomboidForge.pID(zombie)
    local ZType = ZomboidForge.GetZType(trueID)

    local ZombieTable = ZomboidForge.ZTypes[ZType]
    if ZombieTable.zombieDeath then
        -- run custom behavior functions for this zombie
        for i = 1,#ZombieTable.zombieDeath do
            ZomboidForge[ZombieTable.zombieDeath[i]](zombie,ZType)
        end
    end

    -- reset emitters
    zombie:getEmitter():stopAll()

    -- delete zombie data
    ZomboidForge.DeleteZombieData(zombie,trueID)
end