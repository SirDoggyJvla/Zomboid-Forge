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
---@param module string
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



    --- SET STATS ---

    ZomboidForge.SetStats(zombie,ZombieTable,female)



    --- SET VISUALS ---

    -- remove bandages
    if ZombieTable.removeBandages then
        ZomboidForge.RemoveBandages(zombie)
    end

    
    -- necessary to show the various visual changes
    zombie:resetModel()

    -- register the zombie data
    local nonPersistentZData = {
        ZType = ZType,
    }
    ZomboidForge.NonPersistentZData[zombie] = nonPersistentZData
    return nonPersistentZData
end

---Sets the classic Zombie Lore sandbox option stats as well as walktype which can have various options.
---@param zombie IsoZombie
---@param ZombieTable table
---@param female boolean
ZomboidForge.SetStats = function(zombie,ZombieTable,female)
    -- set every stats for the zombie
    for sandboxOptionName,sandboxOptionData in pairs(ZomboidForge.SandboxOptionsStats) do
        local value = ZomboidForge.ChoseInData(ZombieTable[sandboxOptionName],female)
        getSandboxOptions():set(sandboxOptionData.setSandboxOption,value)
    end

    -- update zombie stats
    zombie:makeInactive(true)
    zombie:makeInactive(false)

    -- set walktype
    local walkType = ZombieTable.walkType
    if walkType then
        local choice = ZomboidForge.ChoseInData(walkType,female)
        zombie:setWalkType(choice)
    end
end

---Unique datas are different from the classic Zombie Lore sandbox options.
---@param zombie IsoZombie
---@param ZombieTable table
---@param female boolean
ZomboidForge.SetUniqueData = function(zombie,ZombieTable,female)
    for key,data in pairs(ZomboidForge.ZombieDataToSet) do
        -- access the data and skip if none exists for this ZType
        local ZData = ZombieTable[key]
        if ZData ~= nil then
            -- retrieve current, if a function for current exists for this data type
            local current = data.current and data.current(zombie)

            -- retrieve the choice and apply it
            local choice = ZomboidForge.ChoseInData(ZData,female,current)
            if choice ~= nil then
                data.apply(zombie,choice)
            end
        end
    end
end


--- VISUALS ---

---Remove visual bandages from a zombie.
---@param zombie IsoZombie
ZomboidForge.RemoveBandages = function(zombie)
    -- Remove bandages
    local bodyVisuals = zombie:getHumanVisual():getBodyVisuals()
    if bodyVisuals and bodyVisuals:size() > 0 then
        zombie:getHumanVisual():getBodyVisuals():clear()
    end
end

ZomboidForge.ChangeVisuals = function(zombie,visualSettings,female)
    -- get visuals and skip if none (possibly useless safeguard)
    local visuals = zombie:getItemVisuals()
    if not visuals then return end

    -- remove new visuals
    local locations = ZomboidForge.ChoseInData(visualSettings.remove,female)
    if locations then
        ZomboidForge.RemoveClothingVisuals(zombie,ZType,visuals,locations)
    end

    -- set new visuals
    local locations = ZomboidForge.ChoseInData(visualSettings.set,female)
    if locations then
        ZomboidForge.AddvisualSettings(visuals,locations,gender)
    end

    -- add dirt, blood or holes
    local blood = visualSettings.bloody
    local bloody = ZomboidForge.ChoseInData(blood,female)
    bloody = type(bloody) == "boolean" and 1 or bloody

    local dirt = visualSettings.dirty
    local dirty = ZomboidForge.ChoseInData(dirt,female)
    dirty = type(dirty) == "boolean" and 1 or dirty

    local hole = visualSettings.holes
    local holes = ZomboidForge.ChoseInData(hole,female)
    holes = type(holes) == "boolean" and 1 or holes

    if bloody or dirty or holes then
        ZomboidForge.ModifyvisualSettings(zombie,ZType,visuals,bloody,dirty,holes)
    end
end


-- This function will remove clothing visuals from the `zombie` for each clothing `locations`.
---@param visuals ItemVisuals
---@param locations table
ZomboidForge.RemoveClothingVisuals = function(visuals,locations)
    -- cycle backward to not have any fuck up in index whenever one is removed
    for i = visuals:size() - 1, 0, -1 do
        local item = visuals:get(i)
        if item then
            local scriptItem = item:getScriptItem()
            if scriptItem then
                local location = scriptItem:getBodyLocation()
                local location_remove = locations[location]
                if location_remove then
                    visuals:remove(item)
                end
            end
        end
    end
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