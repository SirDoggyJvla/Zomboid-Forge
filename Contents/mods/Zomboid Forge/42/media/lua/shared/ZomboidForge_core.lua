--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

Core of ZomboidForge

]]--
--[[ ================================================ ]]--

-- requirements
local ZomboidForge = require "ZomboidForge_module"
require "ZomboidForge_stats"
require "ZomboidForge_ModOptions"
require "ISUI/ZombieNametag"
require "Tools/DelayedActions"

--- CACHING ---
-- initialize zombies
local InitializeZombiesVisuals = ZomboidForge.InitializeZombiesVisuals

-- delayed actions
local UpdateDelayedActions = ZomboidForge.DelayedActions.UpdateDelayedActions
local AddNewDelayedAction = ZomboidForge.DelayedActions.AddNewAction

-- Check for zombie valid
local IsZombieValid = ZomboidForge.IsZombieValid

-- Nametag updater
local ZombieNametag = ZomboidForge.ZombieNametag
local isValidForNametag = ZombieNametag.isValidForNametag

-- Mod Options
local Configs = ZomboidForge.Configs

-- other
local zombieList

-- localy initialize player
local client_player = getPlayer()
local function initTLOU_OnGameStart(_, _)
	client_player = getPlayer()
end
Events.OnCreatePlayer.Remove(initTLOU_OnGameStart)
Events.OnCreatePlayer.Add(initTLOU_OnGameStart)




--[[ ================================================ ]]--
--- INITIALIZATION FUNCTIONS ---
--[[ ================================================ ]]--

--- OnLoad function to initialize the mod
ZomboidForge.OnLoad = function()
    -- reset ZTypes
    ZomboidForge.ZTypes = {}

    -- ask for addons to add their zombie types
    triggerEvent("OnLoadZTypes",ZomboidForge.ZTypes)

    -- add zomboids if they should be activated
	if SandboxVars.ZomboidForge.ZomboidSpawn then
        ZomboidForge.AddZomboids()
	end

    -- calculate total chance
    ZomboidForge.TotalChance = 0
    for _,ZombieTable in pairs(ZomboidForge.ZTypes) do
        ZomboidForge.TotalChance = ZomboidForge.TotalChance + ZombieTable.chance
    end

    if isDebugEnabled() then
        print("ZTypes loaded.")
    end
end




--[[ ================================================ ]]--
--- INITIALIZE ZOMBIE
--[[ ================================================ ]]--

---Detect when a zombie gets loaded in and initialize it.
---@param zombie IsoZombie
ZomboidForge.OnZombieCreate = function(zombie)
    if not IsZombieValid(zombie) then return end

    -- delay initialization until pID is properly initialized by the game
    AddNewDelayedAction({
        fct = ZomboidForge.InitializeZombie,
        args = {zombie},
        _ticksDelay = 1,
    })

    -- delay setting visuals
    table.insert(ZomboidForge.ZombiesWaitingForInitialization,zombie)
end



--[[ ================================================ ]]--
--- ON ZOMBIE UPDATE ---
--[[ ================================================ ]]--


---Handle everything related to zombie updates.
---@param zombie IsoZombie
ZomboidForge.OnZombieUpdate = function(zombie)
    if not IsZombieValid(zombie) then return end

    -- get zombie type
    local ZType = ZomboidForge.GetZType(zombie)
    local ZombieTable = ZomboidForge.ZTypes[ZType]
    local nonPersistentZData = ZomboidForge.GetNonPersistentZData(zombie)

    -- run custom onZombieUpdate function
    local onZombieUpdate = ZombieTable.onZombieUpdate
    if onZombieUpdate then
        for j = 1,#onZombieUpdate do
            onZombieUpdate[j](zombie,ZType,ZombieTable)
        end
    end



    --- DETECTING THUMP ---

    if ZombieTable.onZombieThump then
        -- run code if zombie has thumping target
        local thumped = zombie:getThumpTarget()
        if thumped then
            -- check for thump
            -- update thumped only if zombie is thumping
            -- getThumpTarget outputs the target as long as the zombie is in thumping animation
            -- but we want to make sure we run onThump only if a hit is sent
            local timeThumping = zombie:getTimeThumping()
            if nonPersistentZData.thumpCheck ~= timeThumping and timeThumping ~= 0 then
                nonPersistentZData.thumpCheck = timeThumping

                LuaEventManager.triggerEvent("OnZombieThump",zombie,ZType,ZombieTable,thumped,timeThumping)
            end
        end
    end



    --- DETECTING ZOMBIE ATTACKS ---

    local target = zombie:getTarget()
    local attackOutcome = nonPersistentZData.attackOutcome
    -- local currentAttackOutcome = zombie:getVariableString("AttackOutcome")
    if target then
        local currentAttackOutcome = zombie:getVariableString("AttackOutcome")
        if currentAttackOutcome ~= "" and attackOutcome ~= currentAttackOutcome then
            nonPersistentZData.attackOutcome = currentAttackOutcome
            triggerEvent("OnZombieHitCharacter",zombie,target,currentAttackOutcome)
        end
    elseif attackOutcome then
        nonPersistentZData.attackOutcome = nil
    end
end





--[[ ================================================ ]]--
--- ON TICK ---
--[[ ================================================ ]]--

---Handles nametag and updating delayed actions.
---@param tick int
ZomboidForge.OnTick = function(tick)
    -- update delayed actions
    UpdateDelayedActions()

    -- update zombies that need to get initialized
    InitializeZombiesVisuals()

    -- initialize zombieList
    if not zombieList then
        zombieList = getCell():getZombieList()
    end
    local zombieList_size = zombieList:size()

    --- UPDATE NAMETAG VARIABLES ---
    local showNametag = SandboxVars.ZomboidForge.Nametags and Configs.ShowNametag
    if showNametag then
        -- zombies on cursor
        ZomboidForge.zombiesOnCursor = ZomboidForge.GetZombiesOnCursor(Configs.Radius)

        -- visible zombies
        local zombiesInFov = {}
        local spottedMovingObjects = client_player:getSpottedList()

        -- check the objects which are visible zombies
        for i = 0, spottedMovingObjects:size() - 1 do
            local spottedMovingObject = spottedMovingObjects:get(i)
            if instanceof(spottedMovingObject, "IsoZombie") then
                zombiesInFov[spottedMovingObject] = true
            end
        end

        ZomboidForge.zombiesInFov = zombiesInFov
    end



    -- update every zombies
    for i = 0, zombieList_size - 1 do repeat
        -- get zombie and verify it's valid
        local zombie = zombieList:get(i)
        if not ZomboidForge.IsZombieValid(zombie) or not zombie:isAlive() then break end

        -- get zombie data
        local ZType = ZomboidForge.GetZType(zombie)
        local ZombieTable = ZomboidForge.ZTypes[ZType]

        --- ONTICK CUSTOM BEHAVIOR ---

        -- run custom behavior functions for this zombie
        local onTick = ZombieTable.onTick
        if onTick then
            for j = 1,#onTick do
                onTick[j](zombie,ZType,ZombieTable,tick)
            end
        end

        if isDebugEnabled() then ZomboidForge.HandleDebuggingOnTick(zombie) end

        --- NAMETAG ---

        -- update nametag, needs to be updated OnTick bcs if zombie
        -- gets staggered it doesn't get updated with OnZombieUpdate
        if not showNametag or not ZombieTable.name then break end

        -- check if zombie should update
        local isBehind = not ZomboidForge.zombiesInFov[zombie]
        local isOnCursor = ZomboidForge.zombiesOnCursor[zombie]
        local valid = isValidForNametag(zombie,isBehind,isOnCursor)

        local zombieNametag = ZomboidForge.nametagList[zombie]
        if zombieNametag then
            zombieNametag:update(valid,isBehind)
        elseif valid then
            ZomboidForge.nametagList[zombie] = ZombieNametag:new(zombie,ZombieTable)
        end
    until true end
end



--[[ ================================================ ]]--
--- ON DEATH ---
--[[ ================================================ ]]--


---Handle the death of custom zombies.
---@param zombie IsoZombie
ZomboidForge.OnZombieDead = function(zombie)
    if not IsZombieValid(zombie) then return end

    -- get zombie data
    local nonPersistentZData = ZomboidForge.GetNonPersistentZData(zombie)
    local ZType = ZomboidForge.GetZType(zombie)
    local ZombieTable = ZomboidForge.ZTypes[ZType]

    -- run custom death functions
    local onZombieDead = ZombieTable.onZombieDead
    if onZombieDead then
        -- run custom behavior functions for this zombie
        for i = 1,#onZombieDead do
            onZombieDead[i](zombie,ZType,ZombieTable)
        end
    end

    -- reset emitters
    zombie:getEmitter():stopAll()

    -- delete zombie data
    ZomboidForge.ResetNonPersistentZData(zombie)
end



--[[ ================================================ ]]--
--- ATTACK REACTION FUNCTION ---
--[[ ================================================ ]]--

---Triggers whenever a character hits another character and we ignore the case where victim is not a zombie.
---Delay a check after zombie taking damage.
---@param attacker IsoGameCharacter
---@param zombie IsoGameCharacter
---@param handWeapon HandWeapon
---@param damage float
ZomboidForge.OnCharacterHitZombie = function(attacker, zombie, handWeapon, damage)
    if not instanceof(zombie,"IsoZombie") or not zombie:isAlive() then return end
    ---@cast zombie IsoZombie

    -- get zombie informations
    local nonPersistentZData = ZomboidForge.GetNonPersistentZData(zombie)
    local ZType = ZomboidForge.GetZType(zombie)
    local ZombieTable = ZomboidForge.ZTypes[ZType]

    -- note HP
    local HP = zombie:getHealth()
    nonPersistentZData.HP = HP

    -- checks if player is handpushing zombie or barefoot attack
    -- this is done by checking the weapon are hands and if damage is close to 0
    local handPush = false
    local footStomp = false
    if handWeapon:getFullType() == "Base.BareHands" then
        -- hand push
        if math.floor(damage) <= 0 then
            handPush = true

        -- foot stomp
        else
            footStomp = true
        end
    end

    -- stop knife death if should be immune
    if zombie:isKnifeDeath() and ZomboidForge.ChoseInData(ZombieTable.jawStabImmune,zombie:isFemale()) then
        zombie:setKnifeDeath(false)
        zombie:setAvoidDamage(true)
    end

    AddNewDelayedAction({
        fct = ZomboidForge.AfterZombieGetHit,
        args = {zombie},
        _ticksDelay = 1,
    })

    -- run custom behavior functions for this zombie
    local onCharacterHitZombie = ZombieTable.onCharacterHitZombie
    if onCharacterHitZombie then
        for i = 1,#onCharacterHitZombie do
            onCharacterHitZombie[i](zombie,ZType,ZombieTable,attacker,handWeapon,HP,damage,handPush,footStomp)
        end
    end
end

ZomboidForge.AfterZombieGetHit = function(zombie)
    if not zombie:isAlive() then return end
    local damage = ZomboidForge.GetNonPersistentZData(zombie).HP - zombie:getHealth()

    local ZType = ZomboidForge.GetZType(zombie)
    local ZombieTable = ZomboidForge.ZTypes[ZType]

    -- show nametag
    if SandboxVars.ZomboidForge.Nametags and Configs.ShowNametag then
        ZomboidForge.nametagList[zombie] = ZombieNametag:new(zombie,ZombieTable)
    end

    -- run custom behavior functions for this zombie
    local afterZombieGetHit = ZombieTable.afterZombieGetHit
    if afterZombieGetHit then
        for i = 1,#afterZombieGetHit do
            afterZombieGetHit[i](zombie,ZType,ZombieTable,damage)
        end
    end
end


ZomboidForge.OnZombieHitCharacter = function(zombie,victim,attackOutcome)
    local ZType = ZomboidForge.GetZType(zombie)
    local ZombieTable = ZomboidForge.ZTypes[ZType]

    -- show nametag
    if attackOutcome == "start" and SandboxVars.ZomboidForge.Nametags and Configs.ShowNametag and Configs.WhenZombieIsAttacking then
        ZomboidForge.nametagList[zombie] = ZombieNametag:new(zombie,ZombieTable)
    end

    -- run custom behavior functions for this zombie
    local onZombieHitCharacter = ZombieTable.onZombieHitCharacter
    if onZombieHitCharacter then
        for i = 1,#onZombieHitCharacter do
            onZombieHitCharacter[i](zombie,victim,attackOutcome,victim:getHitReaction())
        end
    end
end


---Trigger custom behavior related to zombies thumping.
---@param zombie IsoZombie
---@param ZType string
---@param ZombieTable table
---@param thumped any
---@param timeThumping integer
ZomboidForge.OnZombieThump = function(zombie,ZType,ZombieTable,thumped,timeThumping)
    -- run custom behavior functions for this zombie
    local onZombieThump = ZombieTable.onZombieThump
    for i = 1,#onZombieThump do
        onZombieThump[i](zombie,ZType,ZombieTable,thumped,timeThumping)
    end
end