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

--- import module from ZomboidForge
local ZomboidForge = require "ZomboidForge_module"
local ZFModOptions = require "ZomboidForge_ClientOption"
ZFModOptions = ZFModOptions.options_data

-- localy initialize player
local client_player = getPlayer()
local function initTLOU_OnGameStart(_, _)
	client_player = getPlayer()
end
Events.OnCreatePlayer.Remove(initTLOU_OnGameStart)
Events.OnCreatePlayer.Add(initTLOU_OnGameStart)

--#region Handle damage system

-- `zombie` has agro on an `IsoGameCharacter`. 
-- - Trigger `zombieAgroCharacter` of `zombie` on `target`.
-- - Triggers `onHit_zombie2player` if `zombie` attacks `target` and `target` has `hitReaction`.
-- - Triggers `onHit_zombieAttacking` if `zombie` attacks `target`, even when `target` does have `hitReaction`.
--
-- `data`:
-- - `zombie` IsoZombie
-- - `target` IsoCharacter
-- - `ZombieTable` table [opt]
-- - `trueID` int [opt]
-- - `ZType` string [opt]
---@param data table
ZomboidForge.ZombieAgro = function(data)
    -- get attack data
    local zombie = data.zombie
    local target = data.target

    -- if target is a character
    if target:isCharacter() and not target:isZombie() then
        ---@cast target IsoGameCharacter

        -- get zombie info
        local ZType = data.ZType
        if not ZType then
            local trueID = data.trueID or ZomboidForge.pID(zombie)
            ZType = ZomboidForge.GetZType(trueID)
        end
        local ZombieTable = data.ZombieTable or ZomboidForge.ZTypes[ZType]

        -- trigger custom agro behavior
        if ZombieTable.zombieAgroCharacter then
            for i=1,#ZombieTable.zombieAgroCharacter do
                ZomboidForge[ZombieTable.zombieAgroCharacter[i]](ZType,target,zombie)
            end
        end

        -- trigger zombie hitting player behavior
        if zombie:isAttacking() then
            local attackOutcome = zombie:getVariableString("AttackOutcome")

            -- custom on hit functions
            if ZombieTable.onHit_zombieAttacking then
                for i=1,#ZombieTable.onHit_zombieAttacking do
                    ZomboidForge[ZombieTable.onHit_zombieAttacking[i]]({
                        ZType = ZType,
                        zombie = zombie,
                        victim = target,
                        attackOutcome = attackOutcome,
                    })
                end
            end

            if target:hasHitReaction() then
                -- custom on hit functions
                if ZombieTable.onHit_zombie2player then
                    for i=1,#ZombieTable.onHit_zombie2player do
                        ZomboidForge[ZombieTable.onHit_zombie2player[i]]({
                            ZType = ZType,
                            zombie = zombie,
                            victim = target,
                            attackOutcome = attackOutcome,
                            hitReaction = target:getHitReaction()
                        })
                    end
                end
            end
        end
    end
end

-- Handles `damage` to `zombie` from `attacker`.
--
-- `data`:
-- - `attacker` IsoPlayer
-- - `zombie` IsoZombie
-- - `handWeapon` HandWeapon
-- - `damage` float
-- - `ZombieTable` table [opt]
-- - `trueID` int [opt]
-- - `ZType` string [opt]
---@param data table
ZomboidForge.DamageZombie = function(data)
    -- get attack data
    local attacker = data.attacker
    local zombie = data.zombie
    local handWeapon = data.handWeapon
    local damage = data.damage

    -- get zombie info
    local ZType = data.ZType
    if not ZType then
        local trueID = data.trueID or ZomboidForge.pID(zombie)
        ZType = ZomboidForge.GetZType(trueID)
    end
    local ZombieTable = data.ZombieTable or ZomboidForge.ZTypes[ZType]

    -- intiialize data to send to combat data setter
    local args = {
        zombie = zombie,
        ZombieTable = ZombieTable,
        ZType = ZType,
        onHit = {
            attacker = attacker,
            handWeapon = handWeapon,
            damage = damage,
        },
    }

    -- checks if player is handpushing zombie or barefoot attack
    -- this is done by checking the weapon are hands and if damage is close to 0
    local handPush
    local footStomp
    if handWeapon:getFullType() == "Base.BareHands" then
        -- hand push
        if math.floor(damage) <= 0 then
            handPush = true

        -- foot stomp
        else
            footStomp = true
        end
    end

    -- get zombie info and apply combat data
    args = ZomboidForge.SetZombieCombatData({
        zombie = zombie,
        ZombieTable = ZombieTable,
        ZType = ZType,
        onHit = {
            attacker = attacker,
            handWeapon = handWeapon,
            damage = damage,
            handPush = handPush,
            footStomp = footStomp,
            knifeDeath = zombie:isKnifeDeath(),
        },
    })

    -- skip if zombie is not valid for custom damage
    if args.shouldUseDamageSystem and not handPush then
        -- get HP
        local HP = zombie:getHealth()

        -- apply custom damage if any
        local customDamage = args.customDamage
        if customDamage then
            damage = ZomboidForge[customDamage]({
                ZType = ZType,
                ZombieTable = ZombieTable,
                attacker = attacker,
                zombie = zombie,
                handWeapon = handWeapon,
                damage = damage,
                HP = HP,
                handPush = handPush,
                footStomp = footStomp,
            })
        end

        -- apply damage
        HP = HP - damage/10

        -- a zombie goes stale if it has a too high difference of HP server side and client side
        -- update only if attacker is client to send a single call to the server to update health
        if attacker == client_player then
            ZomboidForge.SyncZombieHealth(zombie,attacker,HP)
        end

        -- kill zombie if zombie should die or apply damage
        if HP > 0 then
            zombie:setHealth(HP)
        else
            ZomboidForge.KillZombie(zombie,attacker)
        end
    end

    -- check if zombie should get pushed back
    if args.shouldAvoidDamage and not args.shouldIgnoreStagger then
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
            "UpdateZombieHealth",
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

    if attacker == client_player then
        ZomboidForge.SyncZombieHealth(zombie,attacker,0)
    end

    -- remove emitters
    zombie:getEmitter():stopAll()

    -- kill zombie, cannot use zombie:Kill(attacker) bcs it doesn't do the job right
    zombie:setHealth(0)
    -- zombie:changeState(ZombieOnGroundState.instance())
    zombie:setAttackedBy(attacker)
    -- zombie:becomeCorpse()
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
---@param data table
---@return table
ZomboidForge.SetZombieCombatData = function(data)
    -- process inputs
    local zombie = data.zombie
    local ZType = data.ZType
    if not ZType then
        local trueID = data.trueID or ZomboidForge.pID(zombie)
        ZType = ZomboidForge.GetZType(trueID)
    end
    local ZombieTable = data.ZombieTable or ZomboidForge.ZTypes[ZType]

    local onHit = data.onHit
    local currentHitTime = zombie:getHitTime()
    if onHit then
        onHit.currentHitTime = currentHitTime
    end

    -- get zombie data
    local tag = table.newarray(
        "shouldIgnoreStagger",
        "shouldAvoidDamage",
        "onlyJawStab",
        "hitTime",
        "fireKillRate",
        "noTeeth",
        "jawStabImmune",
        "canCrawlUnderVehicles"
    )
    local args = ZomboidForge.GetBooleanResult(zombie,ZType,tag,ZombieTable,onHit)


    local hitTime = args.hitTime
    local fireKillRate = args.fireKillRate
    local jawStabImmune = args.jawStabImmune
    local canCrawlUnderVehicles = args.canCrawlUnderVehicles

    -- initialize locals
    local noTeeth
    local shouldIgnoreStagger
    local shouldAvoidDamage
    local onlyJawStab

    -- don't force update the zombie, it is not necessary
    if not onHit then
        shouldIgnoreStagger = args.shouldIgnoreStagger
        shouldAvoidDamage = args.shouldAvoidDamage
        onlyJawStab = args.onlyJawStab
        noTeeth = args.noTeeth

    -- force update the zombie to make sure it has proper reaction to attack even if recycled
    else
        shouldIgnoreStagger = args.shouldIgnoreStagger or false
        shouldAvoidDamage = args.shouldAvoidDamage or false
        onlyJawStab = args.onlyJawStab or false
        noTeeth = args.noTeeth or false
    end

    shouldIgnoreStagger = false

    -- get data related to using custom damage or setting health
    local defaultHP = ZombieTable.HP
    local customDamage = ZombieTable.customDamage
    local shouldUseCustomHP = defaultHP and defaultHP ~= 0
    local shouldUseDamageSystem = shouldUseCustomHP or customDamage or jawStabImmune
    local shouldSetNoDamage = shouldUseDamageSystem or shouldAvoidDamage

    if onHit and jawStabImmune and onHit.knifeDeath then
        shouldUseDamageSystem = false
        shouldAvoidDamage = true
        zombie:setKnifeDeath(false)
    end

    -- resetHitTime
    -- this sets the damage ramp up
    if hitTime then
        if type(hitTime) == "number" then
            if currentHitTime ~= hitTime then
                zombie:setHitTime(hitTime)
            end
        elseif currentHitTime ~= 0 then
            zombie:setHitTime(0)
        end
    end

    -- canCrawlUnderVehicles
    if canCrawlUnderVehicles ~= nil and canCrawlUnderVehicles ~= zombie:isCanCrawlUnderVehicle() then
        zombie:setCanCrawlUnderVehicle(canCrawlUnderVehicles)
    end

    -- fireKillRate
    -- damage by fire
    if fireKillRate and zombie:getFireKillRate() ~= fireKillRate then
        zombie:setFireKillRate(fireKillRate)
    end

    -- check if zombie should only take jawstabs
    if onlyJawStab ~= nil and zombie:isOnlyJawStab() ~= onlyJawStab then
        zombie:setOnlyJawStab(onlyJawStab)
    end

    -- check if zombie should avoid staggers (requires manual handling of damage)
    if shouldIgnoreStagger ~= nil and zombie:avoidDamage() ~= shouldIgnoreStagger then
        zombie:setAvoidDamage(shouldIgnoreStagger)
    end

    -- check if zombie should avoid damage
    if shouldSetNoDamage ~= nil and zombie:getNoDamage() ~= shouldSetNoDamage then
        zombie:setNoDamage(shouldSetNoDamage)
    end

    -- check if zombie should have no teeth (can't bite)
    if noTeeth ~= nil and zombie:isNoTeeth() ~= noTeeth then
        zombie:setNoTeeth(noTeeth)
    end

    -- initialize zombie custom health/damage
    if shouldUseCustomHP and not zombie:getVariableBoolean("ZF_HealthSet") then
        if zombie:getHealth() == defaultHP then
            zombie:setVariable("ZF_HealthSet",true)
        else
            zombie:setHealth(defaultHP)
        end

        -- makes sure zombies have high health amounts server side to not get stale
        -- only the owner player sends the call to properly sync HP of zombie
        local ownerPlayer = zombie.authOwnerPlayer
        if ownerPlayer and ownerPlayer == client_player then
            ZomboidForge.SyncZombieHealth(zombie,client_player,defaultHP)
        end
    end

    return {
        shouldAvoidDamage = shouldAvoidDamage,
        shouldIgnoreStagger = shouldIgnoreStagger,
        customDamage = customDamage,
        shouldUseDamageSystem = shouldUseDamageSystem,
        jawStabImmune = jawStabImmune,
    }
end


--#endregion

--#region Determine Hit Reaction for zombies in multiplayer

local randHitReaction = newrandom()
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
---@param attacker IsoGameCharacter
---@param zombie IsoZombie
---@param handWeapon HandWeapon
ZomboidForge.DetermineHitReaction = function(attacker, zombie, handWeapon)
    local attackerHitReaction = attacker:getVariableString("ZombieHitReaction")

    local hitReaction = ""
    -- if gun/ranged
    if attackerHitReaction == "Shot" then
        -- Roll crit hit
        attacker:setCriticalHit(randHitReaction:random(0,100) < client_player:calculateCritChance(zombie))

        -- default to ShotBelly and get hit direction
        hitReaction = "ShotBelly";
        local hitDirection = ZomboidForge.DetermineHitDirection(attacker, zombie, handWeapon)

        -- if N then roll for variation
        if (hitDirection == "N" and (zombie:isHitFromBehind() or randHitReaction:random(0,1) == 1))
            or (hitDirection == "S")
        then
            hitReaction = "ShotBellyStep"
        end

        -- if R or L get hit reaction
        if hitDirection == "R" or hitDirection == "L" then
            if zombie:isHitFromBehind() then
                hitReaction = direction_side[randHitReaction:random(0,2)]
            else
                hitReaction = direction_side[randHitReaction:random(0,4)]
            end

            hitReaction = hitReaction..hitDirection
        end

        -- verify critical hit
        if attacker:isCriticalHit() then
            if hitDirection == "S" then
                hitReaction = "ShotHeadFwd"
            elseif (hitDirection == "N")
                or ((hitDirection == "L" or hitDirection == "R") and randHitReaction:random(0,3) == 0)
            then
                hitReaction = "ShotHeadBwd"
            end
        end

        -- supposed to be the part that handles blood but that can wait

        -- roll to have a variation in ShotHead reaction
        if hitReaction == "ShotHeadFwd" and randHitReaction:random(0,1) == 0 then
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
        if randHitReaction:random(0,8) > 6 then
            hitDirection = "L"
        elseif randHitReaction:random(0,8) > 4 then
            hitDirection = "R"
        end
    elseif var12 < 90 then
        zombie:setHitFromBehind(true)
        if randHitReaction:random(0,3) == 0 then
            hitDirection = "S"
        else
            hitDirection = "R"
        end
    elseif var12 < 135 then
        hitDirection = "R"
    elseif var12 < 180 then
        if randHitReaction:random(0,3) == 0 then
            hitDirection = "N"
        else
            hitDirection = "R"
        end
    elseif var12 < 225 then
        hitDirection = "N"
        if randHitReaction:random(0,8) > 4 then
            hitDirection = "R"
        elseif randHitReaction:random(0,8) > 6 then
            hitDirection = "L"
        end
    elseif var12 < 270 then
        if randHitReaction:random(0,3) == 0 then
            hitDirection = "N"
        else
            hitDirection = "L"
        end
    elseif var12 < 315 then
        zombie:setHitFromBehind(true)
        hitDirection = "L"
    else
        if randHitReaction:random(0,3) == 0 then
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