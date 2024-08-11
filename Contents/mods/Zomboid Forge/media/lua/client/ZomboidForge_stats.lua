--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

This file defines the functions used to update the stats of zombies

]]--
--[[ ================================================ ]]--

--- Import functions localy for performances reasons
local table = table -- Lua's table module
local ipairs = ipairs -- ipairs function
local pairs = pairs -- pairs function
local ZombRand = ZombRand -- java function
local Long = Long --Long for pID

--- import module from ZomboidForge
local ZomboidForge = require "ZomboidForge_module"
local ZFModData = ModData.getOrCreate("ZomboidForge")
local ZFModOptions = require "ZomboidForge_ClientOption"
ZFModOptions = ZFModOptions.options_data

-- localy initialize player
local client_player = getPlayer()
local function initTLOU_OnGameStart(_, _)
	client_player = getPlayer()
end
Events.OnCreatePlayer.Remove(initTLOU_OnGameStart)
Events.OnCreatePlayer.Add(initTLOU_OnGameStart)

-- localy initialize ModData
local function initModData()
    ZFModData = ModData.getOrCreate("ZomboidForge")
end
Events.OnInitGlobalModData.Remove(initModData)
Events.OnInitGlobalModData.Add(initModData)


--#region ZType definition

local A1, A2 = 727595, 798405  -- 5^17=D20*A1+A2
local D20, D40 = 1048576, 1099511627776  -- 2^20, 2^40
-- Seeded random used in determining the `ZType` of a zombie.
---@param trueID        int
ZomboidForge.seededRand = function(trueID)
    trueID = math.abs(trueID)
    local V = (trueID*A2 + A1) % D20
    V = (V*D20 + A2) % D40
    return math.floor((V/D40) * ZomboidForge.TotalChance) + 1
end

--- Rolls the `ZType` of a zombie.
---@param trueID        int
ZomboidForge.RollZType = function(trueID)
    -- chose a seeded random number based on max total weight
    local rand = ZomboidForge.seededRand(trueID)

    -- test one by one each types and attribute if pass
    for ZType,ZombieTable in pairs(ZomboidForge.ZTypes) do
        rand = rand - ZombieTable.chance
        if rand <= 0 then
            -- attribute a ZType to the zombie
            return ZType
        end
    end
end

-- Get the ZType of a zombie.
---@param trueID            int
ZomboidForge.GetZType = function(trueID)
    local nonPersistentZData = ZomboidForge.GetNonPersistentZData(trueID)

    local ZType = nonPersistentZData.ZType
    -- initialize zombie if no ZType
    if not ZType then
        nonPersistentZData.ZType = ZomboidForge.RollZType(trueID)
    end
    ZType = nonPersistentZData.ZType

    return ZType
end

-- Sets the `ZType` of a specified `zombie`.
---@param trueID            int
---@param ZType             string
ZomboidForge.SetZType = function(trueID,ZType)
    -- get PersistentZData if not given
    local NonPersistentZData = ZomboidForge.GetNonPersistentZData(trueID)

    -- set ZType
    NonPersistentZData.ZType = ZType
end

--#endregion

--#region Update zombie stats

ZomboidForge.UpdateZombieStats = function(zombie,ZombieTable,forceUpdate)
    -- skip if zombie was already set
    if zombie:getVariableBoolean("ZF_StatsUpdated") then return end

    -- update zombie stats
    ZomboidForge.UpdateZombieStatsNonVerifiable(zombie,ZombieTable)

    -- update stats that can be verified
    local shouldUpdate = ZomboidForge.UpdateZombieStatsVerifiable(zombie, ZombieTable)

    -- update stats if should update
    if shouldUpdate or forceUpdate then
        zombie:makeInactive(true)
        zombie:makeInactive(false)

    -- else set zombie has updated
    else
        zombie:setVariable("ZF_StatsUpdated",true)
    end
end

-- Updates stats of `zombie` which can be verified, making sure they don't get updated for nothing.
---@param zombie IsoZombie
---@param ZombieTable table
ZomboidForge.UpdateZombieStatsVerifiable = function(zombie,ZombieTable)
    -- for every stats available to update
    local stats = ZomboidForge.Stats_classField
    local shouldUpdate

    -- iterate through every stats
    for stat_name,stat_data in pairs(stats) do
        -- get stat to set
        local classField = stat_data.classField
        local stat2set = ZombieTable[stat_name]

        -- walktype needs to check if it needs to have crawlers
        local walktype = stat_name == "walktype"
        if not walktype or walktype and stat2set ~= 4 then
            -- verify current stats are the correct one, else update them
            if not (zombie[classField] == stat_data.returnValue[stat2set]) and stat2set then
                getSandboxOptions():set(stat_data.setSandboxOption,stat2set)
                shouldUpdate = true
            end
        else
            if zombie:isCanWalk() then
                zombie:setCanWalk(false)
            end
            if not zombie:isProne() then
                zombie:setFallOnFront(true)
            end
            if not zombie:isCrawling() then
                zombie:toggleCrawling()
            end
        end
    end

    return shouldUpdate
end

-- Updates stats of `Zombie` which can't be verified. These need to be update not too often
-- or it could cause problems.
---@param zombie IsoZombie
---@param ZombieTable table
ZomboidForge.UpdateZombieStatsNonVerifiable = function(zombie,ZombieTable)
    -- for every stats available to update
    for stat_name,stat_data in pairs(ZomboidForge.Stats_nonClassField) do
        getSandboxOptions():set(stat_data.setSandboxOption,ZombieTable[stat_name])
    end
end

--#endregion

--#region Zombie data

-- Gives the persistent data of an `IsoZombie` based on its given `trueID`.
---@param trueID        int
---@return table    
ZomboidForge.GetPersistentZData = function(trueID,module)
    -- initialize PersistentZData if needed
    if not ZFModData.PersistentZData then
        ZFModData.PersistentZData = {}
    end

    -- initialize table if needed
    if not ZFModData.PersistentZData[trueID] then
        ZFModData.PersistentZData[trueID] = {}
    end

    -- if module asked
    -- return desired GetPersistentZData
    if module then
        if not ZFModData.PersistentZData[trueID][module] then
            ZFModData.PersistentZData[trueID][module] = {}
        end
        return ZFModData.PersistentZData[trueID][module]
    else
        return ZFModData.PersistentZData[trueID]
    end
end

-- Gives the non persistent data of an `IsoZombie` based on its given `trueID`.
---@param trueID        int
---@return table
ZomboidForge.GetNonPersistentZData = function(trueID,module)
    -- initialize data if needed
    if not ZomboidForge.NonPersistentZData[trueID] then
        ZomboidForge.NonPersistentZData[trueID] = {}
    end

    -- if module asked
    -- return desired GetNonPersistentZData
    if module then
        if not ZomboidForge.NonPersistentZData[trueID][module] then
            ZomboidForge.NonPersistentZData[trueID][module] = {}
        end
        return ZomboidForge.NonPersistentZData[trueID][module]
    else
        return ZomboidForge.NonPersistentZData[trueID]
    end
end

-- Reset all data of an `IsoZombie` based on its given `trueID`.
---@param trueID        int
ZomboidForge.ResetZombieData = function(trueID)
    -- reset non persistent zombie data
    ZomboidForge.NonPersistentZData[trueID] = {}

    -- reset persistent zombie data
    local PersistentZData = ZFModData.PersistentZData
    if PersistentZData and PersistentZData[trueID] then
        PersistentZData[trueID] = {}
    end
end

-- Delete all data of an `IsoZombie` based on its given `trueID`.
---@param trueID        int
ZomboidForge.DeleteZombieData = function(zombie,trueID)
    -- delete non persistent zombie data
    ZomboidForge.NonPersistentZData[trueID] = nil

    -- delete persistent zombie data
    local PersistentZData = ZFModData.PersistentZData
    if PersistentZData and PersistentZData[trueID] then
        PersistentZData[trueID] = nil
    end

    ZomboidForge.DeleteNametag(zombie)
end

--#endregion

--#region Stat retrieve tools

-- Retrieves from ZombieTable `tag` then `gender` specific data or
-- `Unique` if no gender specific data.
-- ```lua
--  ZombieTable = {
--      tag = {
--          gender = {
--              NonWeighted|Weighted|Unique = {...},
--          },
--      },
--      ...
--  }
-- ```
-- or
-- ```lua
--  ZombieTable = {
--      tag = {
--          NonWeighted|Weighted|Unique = {...},
--      },
--      ...
--  }
-- ```
-- or
-- ```lua
--  ZombieTable = {
--      ...
--      tag = "outfit",
--      ...
--  }
-- ```
---@param ZombieTable   table
---@param tag           string
---@param gender        string
---@return any
ZomboidForge.RetrieveDataFromTable = function(ZombieTable,tag,gender)
    -- verify tag exists
    local ZTag = ZombieTable[tag]
    if not ZTag then return end

    local ZData = type(ZTag) == "table" and ZTag[gender] or ZTag

    -- if ZData is a string, it's a unique value table
    if ZData == nil then
        return nil
    elseif type(ZData) ~= "table" then
        return ZData
    end

    -- try for Unique
    local tryRecurseFind = ZomboidForge.RecurseTableFind(ZData,"Unique")
    if tryRecurseFind then
        return  {["Unique"] = tryRecurseFind}
    end

    -- try for NonWeighted
    tryRecurseFind = ZomboidForge.RecurseTableFind(ZData,"NonWeighted")
    if tryRecurseFind then
        return  {["NonWeighted"] = tryRecurseFind}
    end

    -- try for Weighted
    tryRecurseFind = ZomboidForge.RecurseTableFind(ZData,"Weighted")
    if tryRecurseFind then
        return  {["Weighted"] = tryRecurseFind}
    end

    return ZData
end

-- Choses a value in a table organized in a specific way and skips if `current` is 
-- already in table:
-- ```lua
--  {
--      NonWeighted = {
--          "tag1",
--          "tag2",
--          "tag3",
--          ...
--      }
--  }
-- ```
-- or
-- ```lua
--  {
--      Weighted = {
--          {
--              name = "tag1",
--              weight = int,
--          },
--          {
--              name = "tag2",
--              weight = int,
--          },
--          {
--              name = "tag3",
--              weight = int,
--          },
--          ...
--      }
--  }
-- ```
-- or
-- ```lua
--  {
--      Unique = "tagUnique",
--  }
-- ```
---@param tbl           table
---@param current       any
---@return any
ZomboidForge.ChoseInTable = function(tbl,current)
    if type(tbl) ~= "table" then
        if current and tbl == current then
            return nil
        end

        return tbl
    end

    local key, value
    if ZomboidForge.isArray(tbl) then
        key = "NonWeighted"
        value = tbl
    else
        -- retrieve the table to be chosen
        for k,v in pairs(tbl) do
            key = k
            value = v
            break
        end
    end

    -- verify current is not in value
    if current and ZomboidForge.CheckInTable(value,current) then return end

    -- If unique then return unique
    if key == "Unique" then return value end

    -- else go through weighted or non-weighted
    return ZomboidForge[key.."Table"](value)
end

-- Test that a value is present within an array-like table.
---@param tbl           table
---@param value         any
ZomboidForge.CheckInTable = function(tbl,value)
    -- early skip, nothing to check for
    if not value then return false end

    -- check for UniqueTable
    if type(tbl) ~= "table" then
        if tbl == value then
            return true
        else
            return false
        end
    end

    -- check for value in non-weighted and weighted table
    for _, v in ipairs(tbl) do
        if v == value or type(v) == "table" and v.name == value then
            return true
        end
    end
    return false
end

--- Randomly choses a tag within a table.
-- ```lua
--  {
--      NonWeighted = {
--          "tag1",
--          "tag2",
--          "tag3",
--          ...
--      }
--  }
-- ```
---@param tbl           table
---@return string
ZomboidForge.NonWeightedTable = function(tbl)
    return tbl[ZombRand(1,#tbl+1)]
end

--- Randomly choses a tag within a table with weights.
-- ```lua
--  {
--      Weighted = {
--          {
--              name = "tag1",
--              weight = int,
--          }
--          {
--              name = "tag2",
--              weight = int,
--          }
--          {
--              name = "tag3",
--              weight = int,
--          }
--          ...
--      }
--  }
-- ```
---@param tbl           table
---@return string
ZomboidForge.WeightedTable = function(tbl)
    -- get totalWeight
    local totalWeight = 0
    for _,v in ipairs(tbl) do
        totalWeight = totalWeight + v.weight
    end

    -- chose a seeded random number based on max total weight
    local rand = ZombRand(1,totalWeight)

    -- test one by one each types and attribute if pass
    for _,v in ipairs(tbl) do
        rand = rand - v.weight
        if rand <= 0 then
            return v.name
        end
    end

    return ""
end

-- Retrieves the tag within `ZombieTable` and runs the function if it is, or if just a boolean
-- then retrieve the boolean.
---@param zombie IsoZombie
---@param ZType string
---@param data any
---@param tag string
---@return nil|boolean
ZomboidForge.GetBooleanResult = function(zombie, ZType, data, tag)
    if not data then return end

    local type = type(data)

    local booleanResult = ZomboidForge.BooleanResult[type]
    if booleanResult then
        return booleanResult(data,zombie,ZType)
    else
        print("ERORR: ZomboidForge, invalid "..tag.." entry detected for "..ZType..". Make sure to have either a boolean, a function or a key of ZomboidForge linked to a function.")
        return nil
    end
end

--#endregion