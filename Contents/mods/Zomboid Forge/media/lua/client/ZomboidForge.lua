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
local player = getPlayer()
local zombieList
local function initTLOU_OnGameStart(playerIndex, player_init)
	player = getPlayer()
    zombieList = player:getCell():getZombieList()
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

--- Initialize a zombie. `fullResetZ` will completely wipe the zombie data while
-- `rollZType` rolls a new ZType.
---@param zombie        IsoZombie
---@param fullResetZ    boolean
---@param rollZType     boolean
ZomboidForge.ZombieInitiliaze = function(zombie,fullResetZ,rollZType)
    -- get zombie trueID
    local trueID = ZomboidForge.pID(zombie)

    -- fully reset the stats of the zombie
    if fullResetZ then
        ZomboidForge.ResetZombieData(trueID)
    end

    -- get zombie data
    local nonPersistentZData = ZomboidForge.GetNonPersistentZData(trueID)

    -- attribute zombie type if not set by weighted random already
    if rollZType then
        local ZType = ZomboidForge.GetZType(trueID)
        if not ZType or not ZomboidForge.ZTypes[ZType] then
            nonPersistentZData.ZType = ZomboidForge.RollZType(trueID)
        end
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

    -- update visuals
    ZomboidForge.UpdateVisuals(zombie,ZombieTable,ZType)

    -- update stats that can be verified
    ZomboidForge.UpdateZombieStatsVerifiable(zombie,ZombieTable)

    -- set combat data
    ZomboidForge.SetZombieCombatData(zombie, ZombieTable, ZType, trueID)

    -- update nametag
    if SandboxVars.ZomboidForge.Nametags and ZFModOptions.NameTag.value then
        ZomboidForge.UpdateNametag(zombie,ZombieTable)
    end

    -- run custom behavior functions for this zombie
    if ZombieTable.customBehavior then
        for i = 1,#ZombieTable.customBehavior do
            ZomboidForge[ZombieTable.customBehavior[i]](zombie,ZType)
        end
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

local zeroTick = 0
local time_before_update = 10 -- seconds
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
        zombieList = player:getCell():getZombieList()
    end

    local zombieList_size = zombieList:size()
    local tick_fraction = math.floor((time_before_update*60/zombieList_size)+0.5)

    -- Update zombie stats
    local zombieIndex = (tick - zeroTick)/tick_fraction
    if zombieIndex >= 0 and zombieIndex%1 == 0 then
        if zombieList_size > zombieIndex then
            local zombie = zombieList:get(zombieIndex)
            if ZomboidForge.IsZombieValid(zombie) then
                ZomboidForge.SetZombieData(zombie,nil)
            end
        else
            zeroTick = tick + 1
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
    ZomboidForge.DeleteZombieData(trueID)
end