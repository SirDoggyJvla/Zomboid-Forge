--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

Debuging tools used for ZomboidForge

]]--
--[[ ================================================ ]]--

-- requirements
local ZomboidForge = require "ZomboidForge_module"

-- global caching
local Long = Long
local toUnsignedString = Long.toUnsignedString --[[@as Function]]
local parseUnsignedLong = Long.parseUnsignedLong --[[@as Function]]

local string = string
local table = table

-- check for activated mods
local activatedMod_Bandits = getActivatedMods():contains("\\Bandits")




--- ZOMBIE IDENTIFICATION ---

-- Check if zombie is valid to be handled by Zomboid Forge.
-- - `zombie` is not reanimated
-- - `zombie` is not a bandit (Bandits mod)
ZomboidForge.IsZombieValid = function(zombie)
    -- check if zombie is reanimated
    if zombie:isReanimatedPlayer() then
        return false
    end

    -- check if `zombie` is a bandit
    if activatedMod_Bandits then
        local brain = BanditBrain.Get(zombie)
        if zombie:getVariableBoolean("Bandit") or brain then
            return false
        end
        local gmd = GetBanditModData()
        if gmd.Queue[BanditUtils.GetCharacterID(zombie)] then
            return false
        end
    end

    -- `zombie` passes every checks
    return true
end

-- Based on Chuck's work. Outputs the `trueID` of a `Zombie`.
-- Thx to the help of Shurutsue, Albion and possibly others.
--
-- When hat of a zombie falls off, it changes it's `persistentOutfitID` but those two `pIDs` are linked.
-- This allows to access the trueID of a `Zombie` (the original pID with hat) from both pIDs.
-- The trueID is stored to improve performances and is accessed from the fallen hat pID and the pID sent
-- through this function detects if it's the trueID.
---@param zombie IsoZombie
---@return integer trueID
ZomboidForge.getTrueID = function(zombie)
    -- retrieve zombie pID
    local pID = zombie:getPersistentOutfitID()

    -- if zombie is not yet initialized by the game, force it to be initialized so no issues can arise from unset zombies
    if pID == 0 then
        zombie:dressInRandomOutfit()
        pID = zombie:getPersistentOutfitID()
    end

    -- verify if trueID is cached
    local found = ZomboidForge.TrueID[pID] and pID or ZomboidForge.HatFallen[pID]
    if found then
        return found
    end

    -- transform the pID into bits
    local bits = string.split(string.reverse(toUnsignedString(pID, 2)), "")
    while #bits < 16 do bits[#bits+1] = "0" end

    -- trueID
    bits[16] = "0"
    local trueID = parseUnsignedLong(string.reverse(table.concat(bits, "")), 2)
    ZomboidForge.TrueID[trueID] = true

    -- hatFallenID
    bits[16] = "1"
    ZomboidForge.HatFallen[parseUnsignedLong(string.reverse(table.concat(bits, "")), 2)] = trueID

    return trueID
end

-- Gives the non persistent data of an `IsoZombie` based on its given `trueID`.
---@param zombie IsoZombie
---@return table
ZomboidForge.GetNonPersistentZData = function(zombie,module)
    -- initialize data if needed
    if not ZomboidForge.NonPersistentZData[zombie] then
        ZomboidForge.NonPersistentZData[zombie] = {}
    end

    -- if module asked
    -- return desired GetNonPersistentZData
    if not module then
        return ZomboidForge.NonPersistentZData[zombie]
    else
        if not ZomboidForge.NonPersistentZData[zombie][module] then
            ZomboidForge.NonPersistentZData[zombie][module] = {}
        end

        return ZomboidForge.NonPersistentZData[zombie][module]
    end
end





--- SETTING ZOMBIE

ZomboidForge.InitializeZombie = function(zombie)
    -- get zombie type
    local ZType = ZomboidForge.GetZType(zombie)
    local ZombieTable = ZomboidForge.ZTypes[ZType]
    local female = zombie:isFemale()


    -- set walktype
    local walkType = ZombieTable.walkType
    if walkType then
        local choice = ZomboidForge.ChoseInData(walkType,female)
        print(choice)
        zombie:setWalkType(choice)
    end



    -- register the zombie data
    local nonPersistentZData = {
        ZType = ZType,
    }

    ZomboidForge.NonPersistentZData[zombie] = nonPersistentZData

    return nonPersistentZData
end





--- ZType ---

--- Get the `ZType` of a zombie.
---@param zombie IsoZombie
ZomboidForge.GetZType = function(zombie)
    local trueID = ZomboidForge.getTrueID(zombie)

    -- chose a seeded random number based on max total weight
    local rand = ZomboidForge.seededRand(trueID,ZomboidForge.TotalChance)

    -- test one by one each types and attribute if pass
    for ZType,ZombieTable in pairs(ZomboidForge.ZTypes) do
        rand = rand - ZombieTable.chance
        if rand <= 0 then
            -- attribute a ZType to the zombie
            return ZType
        end
    end
end