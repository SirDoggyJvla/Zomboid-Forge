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

-- delayed actions
local UpdateDelayedActions = ZomboidForge.DelayedActions.UpdateDelayedActions

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

--- INITIALIZATION FUNCTIONS ---

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
end


--- INITIALIZE ZOMBIE

---Detect when a zombie gets loaded in and initialize it.
---@param zombie IsoZombie
ZomboidForge.OnZombieCreate = function(zombie)
    if not IsZombieValid(zombie) then return end

    local nonPersistentZData = ZomboidForge.InitializeZombie(zombie)
    local ZType = nonPersistentZData.ZType
    local ZombieTable = ZomboidForge.ZTypes[ZType]
end


---
---@param zombie IsoZombie
ZomboidForge.OnZombieUpdate = function(zombie)
    if not IsZombieValid(zombie) then return end

    -- get zombie type
    local ZType = ZomboidForge.GetZType(zombie)
    local ZombieTable = ZomboidForge.ZTypes[ZType]

    --- DEBUGGING ---
    if not isDebugEnabled() then return end

    --- ZOMBIE PANNEL ---
    local DEBUG_ZombiePannel = ZomboidForge.DEBUG_ZombiePannel
    if ZomboidForge.CountTrueInTable(DEBUG_ZombiePannel) > 0 then
        local zombiePannel = ""

        if DEBUG_ZombiePannel.Stats then
            zombiePannel = zombiePannel.."\nSTATS:\n"

            zombiePannel = zombiePannel.."memory = "..tostring(zombie.memory).."\n"
            zombiePannel = zombiePannel.."sight = "..tostring(zombie.sight).."\n"
            zombiePannel = zombiePannel.."hearing = "..tostring(zombie.hearing).."\n"
            zombiePannel = zombiePannel.."cognition = "..tostring(zombie.cognition).."\n"
            zombiePannel = zombiePannel.."strength = "..tostring(zombie.strength).."\n"
            zombiePannel = zombiePannel.."speedType = "..tostring(zombie.speedType).."\n"
            zombiePannel = zombiePannel.."walkVariant = "..tostring(zombie.walkVariant).."\n"
        end

        if DEBUG_ZombiePannel.ZombieTable then
            zombiePannel = zombiePannel.."\nZOMBIE TABLE STATS:\n"

            zombiePannel = zombiePannel.."memory = "..tostring(ZombieTable.memory).."\n"
            zombiePannel = zombiePannel.."sight = "..tostring(ZombieTable.sight).."\n"
            zombiePannel = zombiePannel.."hearing = "..tostring(ZombieTable.hearing).."\n"
            zombiePannel = zombiePannel.."cognition = "..tostring(ZombieTable.cognition).."\n"
            zombiePannel = zombiePannel.."strength = "..tostring(ZombieTable.strength).."\n"
            zombiePannel = zombiePannel.."toughness = "..tostring(ZombieTable.toughness).."\n"
        end

        zombie:addLineChatElement(zombiePannel)
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
    -- update delayed actions
    UpdateDelayedActions()

    -- initialize zombieList
    if not zombieList then
        zombieList = getCell():getZombieList()
    end
    local zombieList_size = zombieList:size()

    --- HANDLE NAMETAG VARIABLES ---
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
    for i = 0, zombieList_size - 1 do
        -- get zombie and verify it's valid
        local zombie = zombieList:get(i)
        if ZomboidForge.IsZombieValid(zombie) and zombie:isAlive() then
            -- get zombie data
            local ZType = ZomboidForge.GetZType(zombie)
            local ZombieTable = ZomboidForge.ZTypes[ZType]

            -- run custom behavior functions for this zombie
            local onTick = ZombieTable.onTick
            if onTick then
                for j = 1,#onTick do
                    onTick[j](zombie,ZType,ZombieTable,tick)
                end
            end

            -- update nametag, needs to be updated OnTick bcs if zombie
            -- gets staggered it doesn't get updated with OnZombieUpdate
            if showNametag and ZombieTable.name then
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
            end
        end
    end
end

---Handle the death of custom zombies.
---@param zombie IsoZombie
ZomboidForge.OnZombieDead = function(zombie)
    if not IsZombieValid(zombie) then return end


    -- get zombie data
    local nonPersistentZData = ZomboidForge.GetNonPersistentZData(zombie)
    local ZType = nonPersistentZData.ZType
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