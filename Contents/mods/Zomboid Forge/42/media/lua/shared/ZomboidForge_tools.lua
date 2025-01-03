--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

Tools of ZomboidForge

]]--
--[[ ================================================ ]]--

-- requirements
local ZomboidForge = require "ZomboidForge_module"
local random = newrandom()


--- RANDOM ---

local A1, A2 = 727595, 798405  -- 5^17=D20*A1+A2
local D20, D40 = 1048576, 1099511627776  -- 2^20, 2^40
-- Seeded random used in determining the `ZType` of a zombie.
---@param trueID        int
ZomboidForge.seededRand = function(trueID,max)
    trueID = trueID < 0 and -trueID or trueID
    local V = (trueID*A2 + A1) % D20
    V = (V*D20 + A2) % D40
    V = (V/D40) * max
    return V - V % 1 + 1
end




--- BOOLEAN HANDLER ---
ZomboidForge.SwapBoolean = function(boolean)
    if boolean then
        return false
    end

    return true
end

ZomboidForge.CountTrueInTable = function(tbl)
    local count = 0
    for _,v in pairs(tbl) do
        if type(v) == "boolean" and v then
            count = count + 1
        end
    end

    return count
end




--- TABLE TOOLS ---

ZomboidForge.RandomWeighted = function(tbl)
    -- get totalWeight
    local totalWeight = 0
    for _,v in pairs(tbl) do
        totalWeight = totalWeight + v
    end

    -- chose a seeded random number based on max total weight
    local rand = random:random(0,totalWeight)

    -- test one by one each types and attribute if pass
    for k,v in pairs(tbl) do
        rand = rand - v
        if rand <= 0 then
            return k
        end
    end
end

-- Function to check if a table is an array
---@param t table
---@return boolean
ZomboidForge.isArray = function(t)
    -- Check if the table has only integer keys starting from 1 without gaps
    if type(t) ~= "table" then
        return false
    end

    -- Check for any non-integer keys that might exist outside the numeric sequence
    for k, _ in pairs(t) do
        if type(k) ~= "number" or k % 1 ~= 0 or k < 1 then
            return false
        end
    end
    return true
end

-- Function to check if a table is a key table (dictionary)
---@param t table
---@return boolean
ZomboidForge.isKeyTable = function(t)
    if type(t) ~= "table" then
        return false
    end

    -- If we find any non-integer key, it's a key table (dictionary)
    for k, _ in pairs(t) do
        if type(k) ~= "number" or k % 1 ~= 0 or k < 1 then
            return true
        end
    end

    return false
end





--- STAT RETRIEVE TOOLS ---

ZomboidForge.ChoseInData = function(data,female,current)
    -- handle unique data
    if type(data) ~= "table" then
        if data == current then return nil end

        return data
    elseif #data == 1 then
        local data = data[1]
        if data == current then return nil end

        return data
    end

    data = female and data.female or not female and data.male or data

    -- handle array
    if ZomboidForge.isArray(data) then
        return data[random:random(1,#data)]
    end

    -- handle key table, which means weighted
    return ZomboidForge.RandomWeighted(data)
end



--- ZOMBIE TOOLS ---


-- Zombies that are around the client radius cursor will be valid to show their nametags.
-- This takes into account zombies on different levels.
---@return table
ZomboidForge.GetZombiesOnCursor = function(radius)
    local zombiesOnCursor = {}

    local aiming = client_player:isAiming()
    -- if not ZFModOptions.NoAimingNeeded.value and not aiming then return zombiesOnCursor end

    -- get cursor coordinates
    local mouseX, mouseY = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), 0)
    mouseX = aiming and mouseX + 1.5 or mouseX
    mouseY = aiming and mouseY + 1.5 or mouseY

    local r = radius

    for z = 0,7 do
        for x = mouseX - r, mouseX + r do
            for y = mouseY - r, mouseY + r do
                if (x - mouseX) * (x - mouseX) + (y - mouseY) * (y - mouseY) <= r * r then
                    local square = getSquare(x+ z*3, y+ z*3, z)
                    if square then
                        local movingObjects = square:getMovingObjects()
                        for i = 0, movingObjects:size() -1 do
                            local zombie = movingObjects:get(i)
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