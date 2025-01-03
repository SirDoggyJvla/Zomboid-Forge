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

-- caching
local IsZombieValid = ZomboidForge.IsZombieValid
local zombieList
local client_player = getPlayer()


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
    -- initialize zombieList
    if not zombieList then
        zombieList = getCell():getZombieList()
    end
    local zombieList_size = zombieList:size()

    -- Update things than need to be updated every ticks
    local showNametag = SandboxVars.ZomboidForge.Nametags and ZFModOptions.NameTag.value
    local zombiesOnCursor
    local zombiesInFov = {}
    if showNametag then
        -- get zombies on cursor
        zombiesOnCursor = ZomboidForge.GetZombiesOnCursor()

        -- get zombies in FOV in a key-table for easy check
        local spottedMovingObjects = client_player:getSpottedList()

        if spottedMovingObjects then
            for i = 0, spottedMovingObjects:size() - 1 do
                local spottedMovingObject = spottedMovingObjects:get(i)
                if instanceof(spottedMovingObject, "IsoZombie") then
                    zombiesInFov[spottedMovingObject] = true
                end
            end
        end
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
            -- if ZombieTable.customBehavior then
            --     for j = 1,#ZombieTable.customBehavior do
            --         ZomboidForge[ZombieTable.customBehavior[j]](zombie,ZType,ZombieTable,tick)
            --     end
            -- end

            -- update nametag, needs to be updated OnTick bcs if zombie
            -- gets staggered it doesn't get updated with OnZombieUpdate
            if showNametag and ZombieTable.name then
                local isBehind = not zombiesInFov[zombie]
                local valid = ZomboidForge.IsZombieValidForNametag(zombie,zombiesOnCursor,isBehind)

                ZomboidForge.UpdateNametag(zombie,ZombieTable,tick,valid,isBehind)
            end
        end
    end
end