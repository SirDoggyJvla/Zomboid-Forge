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

ZomboidForge.initModData_ZomboidForge = function()
    ZFModData = ModData.getOrCreate("ZomboidForge")
end

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
--      `Run custom behavior`
--      `Run zombie attack function`
---@param zombie        IsoZombie
ZomboidForge.ZombieUpdate = function(zombie)
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

    -- run zombie attack functions
    if zombie:isAttacking() then
        ZomboidForge.ZombieAgro(zombie,ZType)
    end
end

local zombieList
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
        zombieList = getPlayer():getCell():getZombieList()
    end

    local zombieList_size = zombieList:size()
    local tick_fraction = math.floor((time_before_update*60/zombieList_size)+0.5)

    -- Update zombie stats
    local zombieIndex = (tick - zeroTick)/tick_fraction
    if zombieIndex >= 0 and zombieIndex%1 == 0 then
        if zombieList_size > zombieIndex then
            local zombie = zombieList:get(zombieIndex)
            ZomboidForge.SetZombieData(zombie,nil)
        else
            zeroTick = tick + 1
        end
    end

    -- if players are allowed to use nametags
    if SandboxVars.ZomboidForge.Nametags then
        ZomboidForge.UpdateNametag()
    end
end

--- `Zombie` has agro on an `IsoGameCharacter`. 
-- 
-- Trigger `zombieAgro` of `Zombie` depending on `ZType`.
---@param zombie        IsoZombie
---@param ZType         string
ZomboidForge.ZombieAgro = function(zombie,ZType)
    local target = zombie:getTarget()
    if target and target:isCharacter() then
        local ZombieTable = ZomboidForge.ZTypes[ZType]
        if instanceof(target, "IsoPlayer") then
            ---@cast target IsoPlayer
            ZomboidForge.ShowZombieName(target, zombie)
        end
        if ZombieTable.zombieAgro then
            for i=1,#ZombieTable.zombieAgro do
                ZomboidForge[ZombieTable.zombieAgro[i]](ZType,target,zombie)
            end
        end
    end
end

--- `Player` attacking `Zombie`. 
-- 
-- Trigger `funconhit` of `Zombie` depending on `ZType`.
--
-- Handles the custom HP of zombies and apply custom damage depending on the customDamage function.
---@param attacker      IsoPlayer
---@param zombie        IsoZombie
ZomboidForge.OnHit = function(attacker, zombie, handWeapon, damage)
    if zombie:isZombie() and zombie:isAlive() then
        -- show nametag
        ZomboidForge.ShowZombieName(attacker, zombie)

        -- get zombie data
        local trueID = ZomboidForge.pID(zombie)
        local ZType = ZomboidForge.GetZType(trueID)
        local ZombieTable = ZomboidForge.ZTypes[ZType]

        -- resetHitTime
        if ZombieTable.resetHitTime then
            zombie:setHitTime(0)
        end

        -- shouldAvoidDamage
        local shouldAvoidDamage = ZombieTable.shouldAvoidDamage or false
        if zombie:avoidDamage() ~= shouldAvoidDamage and (ZombieTable.HP and ZombieTable.HP == 1 or not ZombieTable.HP) then
            zombie:setAvoidDamage(shouldAvoidDamage)
        end

        -- custom on hit functions
        if ZombieTable.zombieOnHit then
            for i=1,#ZombieTable.zombieOnHit do
                ZomboidForge[ZombieTable.zombieOnHit[i]](ZType,attacker, zombie, handWeapon, damage)
            end
        end

        if attacker == getPlayer() then
            -- skip if no HP stat or HP is 1
            local HP = ZombieTable.HP
            if HP and HP ~= 1 then
                -- use custom damage function if exists
                if ZombieTable.customDamage then
                    damage = ZomboidForge[ZombieTable.customDamage](ZType,attacker, zombie, handWeapon, damage)
                end

                -- set zombie health or kill zombie
                if isClient() then
                    local args = {
                        damage = damage,
                        trueID = trueID,
                        zombie = zombie:getOnlineID(),
                        defaultHP = HP,
                        shouldNotStagger = ZombieTable.shouldNotStagger,
                    }

                    zombie:setAvoidDamage(true)

                    if handWeapon:getFullType() == "Base.BareHands" then
                        args.damage = 0
                    end

                    sendClientCommand('ZombieHandler', 'DamageZombie', args)
                elseif handWeapon:getFullType() ~= "Base.BareHands" then
                    -- get zombie persistent data
                    local PersistentZData = ZomboidForge.GetPersistentZData(trueID)

                    HP = PersistentZData.HP or HP
                    HP = HP - damage

                    if HP <= 0 then
                        -- reset emitters
                        zombie:getEmitter():stopAll()

                        -- for some reason doing `zombie:Kill(attacker)` doesn't make sure the zombie dies
                        zombie:setHealth(0)
                        zombie:changeState(ZombieOnGroundState.instance())
                        zombie:setAttackedBy(attacker)
                        zombie:becomeCorpse()

                        PersistentZData.HP = nil
                        
                        --[[ god this shit is awful, fuck you with your mod ATRO
                        if getActivatedMods():contains("Advanced_Trajectorys_Realistic_Overhaul") then
                            local player = getPlayer()
                            player:setZombieKills(player:getZombieKills()+1)
                            if not Advanced_trajectory.hasFlameWeapon then
                                killXP = killXP or getSandboxOptions():getOptionByName("Advanced_trajectory.XPKillModifier"):getValue()
                                -- multiplier to 0.67
                                triggerEvent("OnWeaponHitXp",player, player:getPrimaryHandItem(), zombie, args.damage) -- OnWeaponHitXp From "KillCount",used(wielder,weapon,victim,damage)
                                Events.OnWeaponHitXp.Add(player:getXp():AddXP(Perks.Aiming, killXP));
                            end
                        end]]
                    else
                        -- Makes sure the Zombie doesn't get oneshoted by whatever bullshit weapon
                        -- someone might use.
                        -- Updates the HP counter of PersistentZData
                        zombie:setHealth(ZomboidForge.InfiniteHP)
                        PersistentZData.HP = HP
                    end
                end
            end

            -- ATRO patch
            -- display damage done to zombie from bullet
            if getActivatedMods():contains("Advanced_Trajectorys_Realistic_Overhaul") then
                if getSandboxOptions():getOptionByName("ATY_damagedisplay"):getValue() then
                    displayDamageOnZom(damage, zombie) -- ATRO global function
                end
            end
        end
    end
end

--- OnDeath functions
---@param zombie        IsoZombie
ZomboidForge.OnDeath = function(zombie)
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
