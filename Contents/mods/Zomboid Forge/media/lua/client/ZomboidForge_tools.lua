--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

This file defines the tools of the mod Zomboid Forge

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

--#region Small tools

-- Function to check if a table is a key table (dictionary)
---@param tbl table
---@param find any
---@return any
ZomboidForge.RecurseTableFind = function(tbl,find)
    for k,v in pairs(tbl) do
        if k == find then
            return v
        elseif type(v) == "table" then
            return ZomboidForge.RecurseTableFind(v,find)
        end
    end
end

-- Function to check if a table is an array
ZomboidForge.isArray = function(t)
    -- Check if the table has only integer keys starting from 1 without gaps
    if type(t) ~= "table" then
        return false
    end

    local i = 1
    for _ in pairs(t) do
        if t[i] == nil then
            return false
        end
        i = i + 1
    end
    return true
end

-- Function to check if a table is a key table (dictionary)
ZomboidForge.isKeyTable = function(t)
    -- A table is a key table if it's not an array
    return not ZomboidForge.isArray(t)
end

ZomboidForge.IsZombieValid = function(zombie)
    local notValid
    for k,funct in pairs(ZomboidForge.checkValid) do
        if k then
            if getActivatedMods():contains(k) then
                notValid = funct(zombie)
            end
        else
            notValid = funct(zombie)
        end

        if notValid then
            return false
        end
    end

    return true
end

-- Based on Chuck's work. Outputs the `trueID` of a `Zombie`.
-- Thx to the help of Shurutsue, Albion and probably others.
--
-- When hat of a zombie falls off, it changes it's `persistentOutfitID` but those two `pIDs` are linked.
-- This allows to access the trueID of a `Zombie` (the original pID with hat) from both pIDs.
-- The trueID is stored to improve performances and is accessed from the fallen hat pID and the pID sent
-- through this function detects if it's the trueID.
---@param zombie        IsoZombie
---@return integer      trueID
ZomboidForge.pID = function(zombie)
    local pID = zombie:getPersistentOutfitID()

    -- if zombie is not yet initialized by the game, force it to be initialized so no issues can arise from unset zombies
    if pID == 0 then
        zombie:dressInRandomOutfit();
        pID = zombie:getPersistentOutfitID()
    end

    local found = ZomboidForge.TrueID[pID] and pID or ZomboidForge.HatFallen[pID]
    if found then
        return found
    end

    local bits = string.split(string.reverse(Long.toUnsignedString(pID, 2)), "")
    while #bits < 16 do bits[#bits+1] = "0" end

    -- trueID
    bits[16] = "0"
    local trueID = Long.parseUnsignedLong(string.reverse(table.concat(bits, "")), 2)
    ZomboidForge.TrueID[trueID] = true

    -- hatFallenID
    bits[16] = "1"
    ZomboidForge.HatFallen[Long.parseUnsignedLong(string.reverse(table.concat(bits, "")), 2)] = trueID

    --ZomboidForge.TrueID[pID] = trueID
    return trueID
end

-- Determines the gender of the `zombie`:
-- - `"male"`
-- - `"female"`
---@param zombie        IsoZombie
---@return string       gender
ZomboidForge.GetGender = function(zombie)
    return zombie:isFemale() and "female" or "male"
end

--#endregion

--#region FOV tools

-- Function to check if the character has all the traits in a combination.
---@param character IsoGameCharacter
---@param traits table
---@return boolean
ZomboidForge.hasAllTraits = function(character, traits)
    for _, trait in ipairs(traits) do
        if not character:HasTrait(trait) then
            return false
        end
    end
    return true
end

-- Normalize angles to be within [-180, 180] range
---@param angle number
---@return number
ZomboidForge.NormalizeAngle = function(angle)
    while angle > 180 do angle = angle - 360 end
    while angle < -180 do angle = angle + 360 end
    return angle
end

-- Checks that `observer` has `target` in its `FOV`
---comment
---@param observer IsoGameCharacter
---@param target IsoGameCharacter
---@param FOV number
---@return boolean
ZomboidForge.IsInFOV = function(observer, target, FOV)
    -- get angle data
    local omega = observer:getDirectionAngle()
    local delta_x = target:getX() - observer:getX()
    local delta_y = target:getY() - observer:getY()
    local theta = math.deg(math.atan2(delta_y, delta_x))

    omega = ZomboidForge.NormalizeAngle(omega)
    theta = ZomboidForge.NormalizeAngle(theta)

    -- check if the absolute difference is within half of the FOV
    if math.abs(ZomboidForge.NormalizeAngle(theta - omega)) <= FOV/2 then
        return true
    else
        return false
    end
end

-- Checks if `zombie` is behind `character`.
---@param zombie IsoZombie
---@param character IsoGameCharacter
---@return boolean
ZomboidForge.IsZombieBehind = function(zombie,character)
    local vector_ZP = Vector2.new(zombie:getX() - character:getX(),zombie:getY() - character:getY())
    local vector_P = character:getLookVector(Vector2.new())
    local angle = math.deg(vector_ZP:angleBetween(vector_P))

    return angle > 90 and zombie:getDistanceSq(character) > 2.5
end

-- Checks if the `zombie` is on the cursor or not of local player.
---@param zombie IsoZombie
---@return boolean
ZomboidForge.IsZombieOnCursor = function(zombie)
    local aiming = client_player:isAiming()
    if not aiming and not ZFModOptions.NoAimingNeeded.value then return false end

    -- get cursor coordinates
    local mouseX, mouseY = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), 0)
    mouseX = aiming and mouseX + 1.5 or mouseX
    mouseY = aiming and mouseY + 1.5 or mouseY

    -- get zombie coordinates
    local x = zombie:getX()
    local y = zombie:getY()
    local z = zombie:getZ()

    -- get radius and distance between zombie and cursor
    local d = math.sqrt( (mouseX + z*3 - x)^2 + (mouseY + z*3 - y)^2 )
    local radius = ZFModOptions.Radius.value - 0.5

    if d <= radius then
        return true
    end

    return false
end

-- Zombies that are around the client radius cursor will be valid to show their nametags.
---@return table
ZomboidForge.GetZombiesOnCursor = function()
    local zombiesOnCursor = {}

    local aiming = client_player:isAiming()
    if not ZFModOptions.NoAimingNeeded.value and not aiming then return zombiesOnCursor end

    -- get cursor coordinates
    local mouseX, mouseY = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), 0)
    mouseX = aiming and mouseX + 1.5 or mouseX
    mouseY = aiming and mouseY + 1.5 or mouseY

    local r = ZFModOptions.Radius.value
    local square
    local movingObjects
    local zombie

    for z = 0,7 do
        for x = mouseX - r, mouseX + r do
            for y = mouseY - r, mouseY + r do
                if (x - mouseX) * (x - mouseX) + (y - mouseY) * (y - mouseY) <= r * r then
                    square = getSquare(x+ z*3, y+ z*3, z)
                    if square then
                        movingObjects = square:getMovingObjects()
                        for i = 0, movingObjects:size() -1 do
                            zombie = movingObjects:get(i)
                            if zombie and instanceof(zombie,"IsoZombie") then
                                zombiesOnCursor[zombie] = true
                            end
                        end
                    end
                end
            end
        end
    end

    return zombiesOnCursor
end

--#endregion
