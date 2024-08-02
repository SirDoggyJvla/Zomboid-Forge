--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

This file defines the tools to change combat related stuff of zombies for the mod Zomboid Forge

]]--
--[[ ================================================ ]]--

--- Import functions localy for performances reasons
local table = table -- Lua's table module
local ipairs = ipairs -- ipairs function
local pairs = pairs -- pairs function
local ZombRand = ZombRand -- java function

--- import module from ZomboidForge
local ZomboidForge = require "ZomboidForge_module"
local ZFModOptions = require "ZomboidForge_ClientOption"
ZFModOptions = ZFModOptions.options_data

-- localy initialize player
local player = getPlayer()
local function initTLOU_OnGameStart(playerIndex, player_init)
	player = getPlayer()
end
Events.OnCreatePlayer.Remove(initTLOU_OnGameStart)
Events.OnCreatePlayer.Add(initTLOU_OnGameStart)

--#region Handle damage system

--- `Zombie` has agro on an `IsoGameCharacter`. 
-- 
-- Trigger `zombieAgro` of `Zombie` depending on `ZType`.
---@param zombie IsoZombie
---@param ZType string
ZomboidForge.ZombieAgro = function(zombie,ZType)
    -- check if zombie has a target
    local target = zombie:getTarget()
    if target then
        -- get zombie data
        local ZombieTable = ZomboidForge.ZTypes[ZType]

        -- if target is a character
        if target:isCharacter() and not target:isZombie() then
            ---@cast target IsoGameCharacter

            -- trigger custom agro behavior
            if ZombieTable.zombieAgroCharacter then
                for i=1,#ZombieTable.zombieAgroCharacter do
                    ZomboidForge[ZombieTable.zombieAgroCharacter[i]](ZType,target,zombie)
                end
            end

            -- trigger zombie hitting player behavior
            if target:hasHitReaction() then
                ZomboidForge.ZombieAttacksPlayer(zombie, ZType, ZombieTable, target, nil)
            end

        -- if target is a vehicle
        -- elseif instanceof(target,"BaseVehicle") then
        --     if ZombieTable.zombieAgroVehicle then
        --         for i=1,#ZombieTable.zombieAgroVehicle do
        --             ZomboidForge[ZombieTable.zombieAgroVehicle[i]](ZType,target,zombie)
        --         end
        --     end
        end
    end
end

-- `zombie` attacking `player`. Triggers custom attack reaction behavior of ZType.
---@param zombie IsoZombie
---@param ZType string
---@param ZombieTable table
---@param victim IsoPlayer
---@param handWeapon HandWeapon
ZomboidForge.ZombieAttacksPlayer = function(zombie, ZType, ZombieTable, victim, handWeapon)
    -- get zombie data
    if not ZType then
        local trueID = ZomboidForge.pID(zombie)
        ZType = ZomboidForge.GetZType(trueID)
    end
    if not ZombieTable then
        ZombieTable = ZomboidForge.ZTypes[ZType]
    end

    -- custom on hit functions
    if ZombieTable.onHit_zombie2player then
        for i=1,#ZombieTable.onHit_zombie2player do
            ZomboidForge[ZombieTable.onHit_zombie2player[i]](ZType,zombie, victim, handWeapon)
        end
    end
end

-- `player` attacking `zombie`. Triggers custom attack reaction behavior of ZType.
-- Also handles damage taken by zombie if he has any custom damage or HP.
---@param attacker IsoPlayer
---@param zombie IsoZombie
---@param handWeapon HandWeapon
---@param damage float
ZomboidForge.PlayerAttacksZombie = function(attacker, zombie, handWeapon, damage)
    -- get zombie data
    local trueID = ZomboidForge.pID(zombie)
    local ZType = ZomboidForge.GetZType(trueID)
    local ZombieTable = ZomboidForge.ZTypes[ZType]

    -- show nametag
    if ZFModOptions.WhenZombieIsAttacking.value then
        ZomboidForge.ShowZombieNametag(zombie,trueID)
    end

    -- custom on hit functions
    if ZombieTable.onHit_player2zombie then
        for i=1,#ZombieTable.onHit_player2zombie do
            ZomboidForge[ZombieTable.onHit_player2zombie[i]](ZType,attacker, zombie, handWeapon, damage)
        end
    end

    -- Handle damage to zombie
    ZomboidForge.DamageZombie(attacker, zombie, handWeapon, damage,ZombieTable,trueID,ZType)
end

-- Handles damage to `zombie` from `attacker`.
---@param attacker IsoPlayer
---@param zombie IsoZombie
---@param handWeapon HandWeapon
---@param damage float
---@param ZombieTable table
---@param trueID int
---@param ZType string
ZomboidForge.DamageZombie = function(attacker, zombie, handWeapon, damage,ZombieTable,trueID,ZType)
    -- get zombie info and apply combat data
    local defaultHP = ZombieTable.HP
    local args = ZomboidForge.SetZombieCombatData(zombie, ZombieTable, ZType, trueID)

    -- skip if zombie is not valid for custom damage
    if args.isValidForCustomDamage then
        -- makes sure zombies have high health amounts server side to not get stale
        ZomboidForge.SyncZombieHealth(zombie,attacker,defaultHP)

        -- checks if player is handpushing zombie
        -- this is done by checking the weapon are hands and that damage is close to 0
        local handPush = false
        if handWeapon:getFullType() == "Base.BareHands" and math.floor(damage) <= 0 then
            handPush = true
        end

        -- apply damages
        if zombie:isKnifeDeath() and not ZombieTable.jawStabImmune then
            ZomboidForge.KillZombie(zombie,attacker)
        elseif not handPush then
            -- apply custom damage if any
            if ZombieTable.customDamage then
                damage = ZomboidForge[ZombieTable.customDamage](ZType,attacker, zombie, handWeapon, damage)
            end

            -- get HP and apply damage
            local HP = zombie:getHealth()
            HP = HP - damage

            -- kill zombie if zombie should die or apply damage
            if HP > 0 then
                zombie:setHealth(HP)
            else
                ZomboidForge.KillZombie(zombie,attacker)
            end
        end
    end

    -- check if zombie should get pushed back
    if args.setAvoidDamage and not args.shouldIgnoreStagger then
        ZomboidForge.StaggerZombie(zombie,attacker,handWeapon, nil)
    end
end

-- Syncs the zombie server side to have the custom health. This makes sure it doesn't go stale
-- when dealing damage client side.
---@param zombie IsoZombie
---@param character IsoGameCharacter
---@param HP float
ZomboidForge.SyncZombieHealth = function(zombie,character,HP)
    if isClient() then
        sendClientCommand(
            "ZombieHandler",
            "UpdateHealth",
            {
                zombieOnlineID = zombie:getOnlineID(),
                defaultHP = HP,
                attackerOnlineID = character:getOnlineID(),
            }
        )
    end
end


-- Staggers the `zombie` based on a given `hitReaction` or determines it thanks to the `handWeapon`.
---@param zombie IsoZombie
---@param attacker IsoGameCharacter
---@param handWeapon HandWeapon
---@param hitReaction string
ZomboidForge.StaggerZombie = function(zombie,attacker,handWeapon,hitReaction)
    hitReaction = hitReaction or ZomboidForge.DetermineHitReaction(attacker, zombie, handWeapon)
    ZomboidForge.ApplyHitReaction(zombie,attacker,hitReaction)
end

-- Kills `IsoZombie` based and update attacker stats.
---@param zombie IsoZombie
---@param attacker IsoPlayer
ZomboidForge.KillZombie = function(zombie,attacker)
    if not zombie:isAlive() then return end

    ZomboidForge.SyncZombieHealth(zombie,attacker,0)

    -- remove emitters
    zombie:getEmitter():stopAll()

    -- kill zombie, cannot use zombie:Kill(attacker) bcs it doesn't do the job right
    zombie:setHealth(0)
    zombie:changeState(ZombieOnGroundState.instance())
    zombie:setAttackedBy(attacker)
    zombie:becomeCorpse()
    -- attacker:setZombieKills(attacker:getZombieKills()+1)

    ZomboidForge.DeleteZombieData(zombie,ZomboidForge.pID(zombie))
end

--#endregion

--#region Zombie combat data tools

-- Sets `zombie` combat related data. If zombie should use the custom health system,
-- `setAvoidDamage` is true. This is used to make sure ZomboidForge handles any damage dealt to
-- the zombie.
--
-- Outputs a table with:
-- - `shouldAvoidDamage`
-- - `shouldIgnoreStagger`
-- - `isValidForCustomDamage`
-- - `setAvoidDamage`
---@param zombie IsoZombie
---@param ZombieTable table
---@param trueID int
---@return table
ZomboidForge.SetZombieCombatData = function(zombie, ZombieTable, ZType, trueID)
    -- get zombie data
    local shouldIgnoreStagger = ZomboidForge.GetBooleanResult(zombie,ZType,ZombieTable.shouldIgnoreStagger,"shouldIgnoreStagger")
    local shouldAvoidDamage = ZomboidForge.GetBooleanResult(zombie,ZType,ZombieTable.shouldAvoidDamage,"shouldAvoidDamage")
    local onlyJawStab = ZomboidForge.GetBooleanResult(zombie,ZType,ZombieTable.onlyJawStab,"onlyJawStab")
    local defaultHP = ZombieTable.HP or 0
    local isValidForCustomDamage = not (shouldAvoidDamage == true) and defaultHP ~= 0
    local setAvoidDamage = shouldAvoidDamage or isValidForCustomDamage

    -- resetHitTime
    -- this makes sure damage doesn't ramp up
    if ZomboidForge.GetBooleanResult(zombie,ZType,ZombieTable.resetHitTime,"resetHitTime") then
        zombie:setHitTime(0)
    end

    -- check if zombie should ignore stagger
    if shouldIgnoreStagger ~= nil and zombie:isIgnoreStaggerBack() ~= shouldIgnoreStagger then
        zombie:setIgnoreStaggerBack(shouldIgnoreStagger)
    end

    -- check if zombie should only take jawstabs
    if onlyJawStab ~= nil and zombie:isOnlyJawStab() ~= onlyJawStab then
        zombie:setOnlyJawStab(onlyJawStab)
    end

    -- check if zombie should avoid damage
    if setAvoidDamage ~= nil and zombie:avoidDamage() ~= setAvoidDamage then
        zombie:setAvoidDamage(setAvoidDamage)
    end

    -- initialize zombie custom damage
    if isValidForCustomDamage then
        local NonPersistentZData = ZomboidForge.GetNonPersistentZData(trueID)
        local initHP = NonPersistentZData.initHP
        if not initHP then
            zombie:setHealth(defaultHP)
            NonPersistentZData.initHP = true
        end
    end

    return {
        shouldAvoidDamage = shouldAvoidDamage,
        shouldIgnoreStagger = shouldIgnoreStagger,
        isValidForCustomDamage = isValidForCustomDamage,
        setAvoidDamage = setAvoidDamage,
    }
end


--#endregion

--#region Determine Hit Reaction for zombies in multiplayer

-- used to retrieve R and L shots
local direction_side = {
    [0] = "ShotChest",
    [1] = "ShotLeg",
    [2] = "ShotShoulderStep",
    [3] = "ShotChestStep",
    [4] = "ShotShoulder",
}
-- Determine hit reaction for a zombie. This is used in multiplayer to trigger to correct stagger.
--
-- This is a complete recreation of `processHitDirection` from `IsoZombie.java` class.
---@param attacker IsoPlayer
---@param zombie IsoZombie
---@param handWeapon HandWeapon
ZomboidForge.DetermineHitReaction = function(attacker, zombie, handWeapon)
    local attackerHitReaction = attacker:getVariableString("ZombieHitReaction")

    local hitReaction = ""
    -- if gun/ranged
    if attackerHitReaction == "Shot" then
        -- Roll crit hit
        attacker:setCriticalHit(ZombRand(100) < player:calculateCritChance(zombie))

        -- default to ShotBelly and get hit direction
        hitReaction = "ShotBelly";
        local hitDirection = ZomboidForge.DetermineHitDirection(attacker, zombie, handWeapon)

        -- if N then roll for variation
        if (hitDirection == "N" and (zombie:isHitFromBehind() or ZombRand(2) == 1))
            or (hitDirection == "S")
        then
            hitReaction = "ShotBellyStep"
        end

        -- if R or L get hit reaction
        if hitDirection == "R" or hitDirection == "L" then
            if zombie:isHitFromBehind() then
                hitReaction = direction_side[ZombRand(3)]
            else
                hitReaction = direction_side[ZombRand(5)]
            end

            hitReaction = hitReaction..hitDirection
        end

        -- verify critical hit
        if attacker:isCriticalHit() then
            if hitDirection == "S" then
                hitReaction = "ShotHeadFwd"
            elseif (hitDirection == "N")
                or ((hitDirection == "L" or hitDirection == "R") and ZombRand(4) == 0)
            then
                hitReaction = "ShotHeadBwd"
            end
        end

        -- supposed to be the part that handles blood but that can wait

        -- roll to have a variation in ShotHead reaction
        if hitReaction == "ShotHeadFwd" and ZombRand(2) == 0 then
            hitReaction = "ShotHeadFwd02"
        end

    --[[ used to add blood, will be done later if needed
    else
        local categories = handWeapon:getCategories()
        if categories:contains("Blunt") then
            
        elseif not categories:contains("Unarmed") then

        else
        end
        ]]
    end

    -- check for eating body
    if zombie:getEatBodyTarget() then
        if zombie:getVariableBoolean("onknees") then
            hitReaction = "OnKnees"
        else
            hitReaction = "Eating"
        end
    end

    --[[
        need to find how to use equalsIgnoreCase in lua
        the original function is not exposed

    if ("Floor".equalsIgnoreCase(var3) && this.isCurrentState(ZombieGetUpState.instance()) && this.isFallOnFront()) {
        var3 = "GettingUpFront";
    }
    ]]

    return hitReaction
end

-- This part adapts a part of `processHitDirection` from `IsoZombie.java` class
-- which determines the angle of the attack and makes the zombie react to it
---@param attacker IsoPlayer
---@param zombie IsoZombie
---@param handWeapon HandWeapon
ZomboidForge.DetermineHitDirection = function(attacker, zombie, handWeapon)
    -- This seems to determine the angle from which the zombie got shot
    local playerAngle = attacker:getForwardDirection();
    local p_x = playerAngle:getX()
    local p_y = playerAngle:getY()

    local zombieHitAngle = zombie:getHitAngle();
    local z_x = zombieHitAngle:getX()
    local z_y = zombieHitAngle:getY()

    local var6 = (p_x * z_x - p_y * z_y);

    local var8 = -1
    if var6 >= 0 then
        var8 = 1
    end

    local var10 = (p_x * z_y + p_y * z_x);
    local var12 = Math.acos(var10) * var8;

    if var12 < 0 then
        var12 = var12 + 6.283185307179586;
    end
    var12 = Math.toDegrees(var12)

    -- Determine hitDirection based on angle
    local hitDirection = ""

    -- Check for south
    if var12 < 45 then
        zombie:setHitFromBehind(true)
        hitDirection = "S"
        if ZombRand(9) > 6 then
            hitDirection = "L"
        elseif ZombRand(9) > 4 then
            hitDirection = "R"
        end
    elseif var12 < 90 then
        zombie:setHitFromBehind(true)
        if ZombRand(4) == 0 then
            hitDirection = "S"
        else
            hitDirection = "R"
        end
    elseif var12 < 135 then
        hitDirection = "R"
    elseif var12 < 180 then
        if ZombRand(4) == 0 then
            hitDirection = "N"
        else
            hitDirection = "R"
        end
    elseif var12 < 225 then
        hitDirection = "N"
        if ZombRand(9) > 4 then
            hitDirection = "R"
        elseif ZombRand(9) > 6 then
            hitDirection = "L"
        end
    elseif var12 < 270 then
        if ZombRand(4) == 0 then
            hitDirection = "N"
        else
            hitDirection = "L"
        end
    elseif var12 < 315 then
        zombie:setHitFromBehind(true)
        hitDirection = "L"
    else
        if ZombRand(4) == 0 then
            hitDirection = "S"
        else
            hitDirection = "L"
        end
    end

    return hitDirection
end

-- Applies `hitReaction` to the `zombie` from `attacker`. 
--
-- `hitReaction` needs to be either a specific hit reaction available or an empty string. If
-- it's an empty string, `victim` needs to be a zombie.
---@param victim IsoGameCharacter
---@param attacker IsoGameCharacter
---@param hitReaction string
ZomboidForge.ApplyHitReaction = function(victim,attacker,hitReaction)
    -- check for hitReaction and apply it
    -- else default to "" and simple stagger
    if hitReaction and hitReaction ~= "" then
        victim:setHitReaction(hitReaction)
    elseif victim:isZombie() then
        ---@cast victim IsoZombie

        victim:setStaggerBack(true)
        victim:setHitReaction("")

        -- remove critical hit
        local attackPosition = victim:getPlayerAttackPosition()
        if attackPosition == "LEFT" or attackPosition == "RIGHT" then
            attacker:setCriticalHit(false)
        end
    else
        print("ERROR: Zomboid Forge, wrong utilization of `ApplyHitReaction`")
    end
end

--#endregion