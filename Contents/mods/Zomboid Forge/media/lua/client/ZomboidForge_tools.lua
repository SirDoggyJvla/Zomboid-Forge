--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

This file defines the core of the mod Zomboid Forge

]]--
--[[ ================================================ ]]--

--- Import functions localy for performances reasons
local table = table -- Lua's table module
local ipairs = ipairs -- ipairs function
local pairs = pairs -- pairs function
local ZombRand = ZombRand -- java function
local print = print -- print function
local tostring = tostring --tostring function
local Long = Long --Long for pID

--- import module from ZomboidForge
local ZomboidForge = require "ZomboidForge_module"

local A1, A2 = 727595, 798405  -- 5^17=D20*A1+A2
local D20, D40 = 1048576, 1099511627776  -- 2^20, 2^40
-- Seeded random used in determining the `ZType` of a zombie.
---@param trueID        int
function ZomboidForge.seededRand(trueID)
    trueID = math.abs(trueID)
    local V = (trueID*A2 + A1) % D20
    V = (V*D20 + A2) % D40
    return (math.floor((V/D40) * ZomboidForge.TotalChance) + 1)
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

--- Used to set the various data of a zombie, skipping the unneeded parts or already done. 
--
-- Order of data set:
--
--          `Zombie stats`
--          `Zombie outfit`
--          `Set Zombie to skeleton`
--          `Zombie hair`
--          `Zombie hair color`
--          `Zombie beard`
--          `Zombie beard color`
--          `HP`
--          `Zombie animation variable`
--
---@param zombie        IsoZombie
---@param ZType         string|nil [opt] Zombie Type ID
ZomboidForge.SetZombieData = function(zombie,ZType)
    local trueID = ZomboidForge.pID(zombie)
    -- zombie did not get initialized by the game yet so don't touch that zombie
    if trueID == 0 then return end

    local nonPersistentZData = ZomboidForge.GetNonPersistentZData(trueID)

    -- if no ZType given, access it
    if not ZType then

        if not nonPersistentZData.ZType then
            ZomboidForge.ZombieInitiliaze(zombie,true,true)
            return
        end
        ZType = nonPersistentZData.ZType
    end

    -- if still no ZType then skip again
    if not ZType then return end

    -- get ZType data
    local ZombieTable = ZomboidForge.ZTypes[ZType]
    -- update zombie stats
    if not nonPersistentZData.GlobalCheck then
        ZomboidForge.UpdateZombieStats(zombie,ZType)
    end

    -- set zombie clothing
    if #ZombieTable.outfit > 0 then
        local currentOutfit = zombie:getOutfitName()
        local outfitChoice = ZomboidForge.RandomizeTable(ZombieTable,"outfit",currentOutfit)
        if outfitChoice then
            zombie:dressInNamedOutfit(outfitChoice)
	        zombie:reloadOutfit()
        end
    end

    --- update zombie visuals
    -- set to skeleton
    if ZombieTable.skeleton and not zombie:isSkeleton() then
        zombie:setSkeleton(true)
    end

    -- set hair
    if ZombieTable.hair then
        local key = "male"
        if zombie:isFemale() then
            key = "female"
        end
        local ZDataTable = ZombieTable.hair
        local zombieVisual = zombie:getHumanVisual()
        local currentHair = zombieVisual:getHairModel()
        local hairChoice = nil
        if ZDataTable[key] then
            hairChoice = ZomboidForge.RandomizeTable(ZDataTable,key,currentHair)
        end
        if hairChoice then
            zombieVisual:setHairModel(hairChoice)
            zombie:resetModel()
        end
    end

    -- set hair color
    if #ZombieTable.hairColor > 0 then
        local zombieVisual = zombie:getHumanVisual()
        local currentHairColor = zombieVisual:getHairColor()
        local hairColorChoice = ZomboidForge.RandomizeTable(ZombieTable,"hairColor",currentHairColor)
        if hairColorChoice then
            zombieVisual:setHairColor(hairColorChoice)
            zombie:resetModel()
        end
    end

    -- set beard if male
    if #ZombieTable.beard > 0 and not zombie:isFemale() then
        local zombieVisual = zombie:getHumanVisual()
        local currentBeard = zombieVisual:getBeardModel()
        local beardChoice = ZomboidForge.RandomizeTable(ZombieTable,"beard",currentBeard)
        if beardChoice then
            zombieVisual:setBeardModel(beardChoice)
            zombie:resetModel()
        end
    end

    -- set beard color if male
    if #ZombieTable.beardColor > 0 and not zombie:isFemale() then
        local zombieVisual = zombie:getHumanVisual()
        local currentBeardColor = zombieVisual:getHairColor()
        local beardColorChoice = ZomboidForge.RandomizeTable(ZombieTable,"beardColor",currentBeardColor)
        if beardColorChoice or true then
            zombieVisual:setHairColor(beardColorChoice)
            zombie:resetModel()
        end
    end

    -- set zombie HP extremely high to make sure it doesn't get oneshoted if it has custom
    -- HP, handled via the attack functions
    if ZombieTable.HP and ZombieTable.HP ~= 1 and zombie:isAlive() then
        if zombie:getHealth() ~= 1000 then
            zombie:setHealth(1000)
        end
    end
    
    -- custom animation variable
    local animVariable = ZombieTable.animationVariable
    if animVariable then
        if not zombie:getVariableBoolean(animVariable) then
            zombie:setVariable(animVariable,'true')
            if isClient() then
                sendClientCommand('ZombieHandler', 'SetAnimationVariable', {animationVariable = ZombieTable.animationVariable, zombie = zombie:getOnlineID()})
            end
        end
    end

    -- run custom data if any
    for i = 1,#ZombieTable.customData do
        ZomboidForge[ZombieTable.customData[i]](zombie,ZType)
    end
end

--- Randomly choses a `Zombie` `ZData` within a ZType data table if current is not already in the table.
---@param ZDataTable    table       --Zombie Table to randomize
---@param ZData         string      --Chosen data in ZType table
---@param current       any         --[opt] Used to verify `current` from `Zombie` is not in table
---@return any                      --Random choice within ZData
ZomboidForge.RandomizeTable = function(ZDataTable,ZData,current)
    local ZDataTable_get = ZDataTable[ZData]; if not ZDataTable_get then return end
    local size = #ZDataTable_get

    local check = false
    if current then
        for i = 1,size do
            if current == ZDataTable_get[i] then
                check = true
                break
            end
        end
    end
    if not check then
        return ZDataTable_get[ZombRand(1,size)]
    end
    return false
end

-- Updates stats of `Zombie`.
-- Stats are checked and updated if needed 10 times. They are updated every `timeStatCheck` ticks.
--
-- Some stats can be checked like walktype or sight, those are verifiable stats and 
-- are not updated every check.
-- The other stats can't be checked so they are updated every checks, they are unverifiable stats.
--
-- Once every stats went through the 10 checks and are actually correct then
---@param zombie        IsoZombie
---@param ZType         string      --Zombie Type ID
ZomboidForge.UpdateZombieStats = function(zombie,ZType)
    -- get zombie info
    local trueID = ZomboidForge.pID(zombie)
    local nonPersistentZData = ZomboidForge.NonPersistentZData[trueID]

    -- GlobalCheck, if true then stats are already checked
    if nonPersistentZData.GlobalCheck then return end

    -- get info if stat already checked for each stats
    -- else initialize it
    local statChecked = nonPersistentZData.statChecked
    if not statChecked then
        nonPersistentZData.statChecked = {}
        statChecked = nonPersistentZData.statChecked
    end

    -- for every stats available to update
    local ZombieTable = ZomboidForge.ZTypes[ZType]
    for k,_ in pairs(ZomboidForge.Stats) do
        local classField = ZomboidForge.Stats[k].classField
        -- verifiable stats
        if classField then
            -- for walktype, 4 = crawler
            if k == "walktype" and ZombieTable[k] and ZombieTable[k] == 4 then
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

            -- verify current stats are the correct one, else update them
            local stat = zombie[classField]
            local value = ZomboidForge.Stats[k].returnValue[ZombieTable[k]]
            if not (stat == value) and ZombieTable[k] then
                local sandboxOption = ZomboidForge.Stats[k].setSandboxOption
                getSandboxOptions():set(sandboxOption,ZombieTable[k])
            end

        -- unverifiable stats
        elseif not classField then
            local sandboxOption = ZomboidForge.Stats[k].setSandboxOption
            getSandboxOptions():set(sandboxOption,ZombieTable[k])
        end
    end
    zombie:makeInactive(true)
    zombie:makeInactive(false)
    -- update multiCheck counter for each stats
    local multiCheck = nonPersistentZData.multiCheck
    if not multiCheck then
        multiCheck = 0
    end
    if multiCheck >= 10 then
        -- stop checking stats for this zombie
        nonPersistentZData.GlobalCheck = true
        nonPersistentZData.multiCheck = nil
    else
        -- increment multiCheck counter
        multiCheck = multiCheck + 1
        nonPersistentZData.multiCheck = multiCheck
    end
end

--#region Tools

-- Gives the persistent data of an `IsoZombie` based on its given `trueID`.
---@param trueID        int
---@return table
ZomboidForge.GetPersistentZData = function(trueID)
    local ZFModData = ModData.getOrCreate("ZomboidForge")
    if not ZFModData.PersistentZData then
        ZFModData.PersistentZData = {}
    end
    if not ZFModData.PersistentZData[trueID] then
        ZFModData.PersistentZData[trueID] = {}
    end

    return ZFModData.PersistentZData[trueID]
end

-- Gives the non persistent data of an `IsoZombie` based on its given `trueID`.
---@param trueID        int
---@return table
ZomboidForge.GetNonPersistentZData = function(trueID)
    if not ZomboidForge.NonPersistentZData[trueID] then
        ZomboidForge.NonPersistentZData[trueID] = {}
    end

    return ZomboidForge.NonPersistentZData[trueID]
end

-- Reset all data of an `IsoZombie` based on its given `trueID`.
---@param trueID        int
ZomboidForge.ResetZombieData = function(trueID)
    -- reset non persistent zombie data
    ZomboidForge.NonPersistentZData[trueID] = {}

    -- reset persistent zombie data
    local ZFModData = ModData.getOrCreate("ZomboidForge")
    local PersistentZData = ZFModData.PersistentZData
    if PersistentZData and PersistentZData[trueID] then
        PersistentZData[trueID] = {}
    end
end

-- Delete all data of an `IsoZombie` based on its given `trueID`.
---@param trueID        int
ZomboidForge.DeleteZombieData = function(trueID)
    -- delete non persistent zombie data
    ZomboidForge.NonPersistentZData[trueID] = nil

    -- delete persistent zombie data
    local ZFModData = ModData.getOrCreate("ZomboidForge")
    local PersistentZData = ZFModData.PersistentZData
    if PersistentZData and PersistentZData[trueID] then
        PersistentZData[trueID] = nil
    end
end

-- Based on Chuck's and I work. Outputs the `trueID` of a `Zombie`.
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

-- Global counter that is used by the framework to delay updates on specific stuff like stats but can be used
-- by other addons to delay update some stuff.
-- Added to OnTick.
ZomboidForge.counterUpdater = function()
    ZomboidForge.counter = ZomboidForge.counter - 1
    if ZomboidForge.counter < 0 then
        ZomboidForge.counter = SandboxVars.ZomboidForge.tickUpdater
    end
end
--#endregion

--#region Nametag handling

-- Shows `Zombie` name with this command, can be triggered anytime. 
-- Can also be called outside of the framework by addons.
---@param player        IsoPlayer
---@param zombie        IsoZombie
ZomboidForge.ShowZombieName = function(player,zombie)
	if (ZombieForgeOptions and ZombieForgeOptions.NameTag)or(ZombieForgeOptions==nil) then
		if player:isLocalPlayer() then
            local trueID = ZomboidForge.pID(zombie)
			ZomboidForge.ShowNametag[trueID] = {zombie,100}
		end
    end
end

-- Get `Zombie` on `Player` cursor.
-- If `Zombie` found then update `ShowZombieName`.
---@param player        IsoPlayer
ZomboidForge.GetZombieOnPlayerMouse = function(player)
	if ZombieForgeOptions and ZombieForgeOptions.NameTag or not ZombieForgeOptions then
		if player:isLocalPlayer() and player:isAiming() then
			local playerX = player:getX()
			local playerY = player:getY()
			local playerZ = player:getZ()
			local mouseX, mouseY = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), 0)
			local targetMouseX = mouseX+1.5
			local targetMouseY = mouseY+1.5
			local direction = (math.atan2(targetMouseY-playerY, targetMouseX-playerX))

			local feetDirection = player:getDir():toAngle()
			if feetDirection < 2 then
				feetDirection = -(feetDirection+(math.pi*0.5))
			else
				feetDirection = (math.pi*2)-(feetDirection+(math.pi*0.5))
			end
			if math.cos(direction - feetDirection) < math.cos(67.5) then
				if math.sin(direction - feetDirection) < 0 then
					direction = feetDirection - (math.pi/4)
				else
					direction = feetDirection + (math.pi/4)
				end
			end --Avoids an aiming angle pointing behind the person
			local cell = getWorld():getCell()
			local square = cell:getGridSquare(math.floor(targetMouseX), math.floor(targetMouseY), playerZ)
			if playerZ > 0 then
				for i=math.floor(playerZ), 1, -1 do
					square = cell:getGridSquare(math.floor(mouseX+1.5)+(i*3), math.floor(mouseY+1.5)+(i*3), i)
					if square and square:isSolidFloor() then
						targetMouseX = mouseX+1.5+i
						targetMouseY = mouseY+1.5+i
						break
					end
				end
			end
			if square then
				local movingObjects = square:getMovingObjects()
				if movingObjects then
					for i=0, movingObjects:size()-1 do
						local zombie = movingObjects:get(i)
						if zombie and instanceof(zombie, "IsoZombie") and zombie:isAlive() then
                            -- get zombie data
                            local trueID = ZomboidForge.pID(zombie)
                            local nonPersistentZData = ZomboidForge.GetNonPersistentZData(trueID)
                            local ZType = nonPersistentZData.ZType

							if ZomboidForge.ZTypes[ZType] and player:CanSee(zombie) then
								ZomboidForge.ShowNametag[trueID] = {zombie,100}
							end
						end
					end
				end
			end
		end
	end
end


-- Updates zombie tag showing for each players. 
-- Could probably be improved upon since currently the behavior is possibly not perfect in multiplayer.
-- Specifically with `ShowZombieName`.
--
-- From CDDA Zombies.
ZomboidForge.UpdateNametag = function()
	for trueID,ZData in pairs(ZomboidForge.ShowNametag) do
		local zombie = ZData[1]
		local interval = ZData[2]

        -- get zombie data
        local nonPersistentZData = ZomboidForge.GetNonPersistentZData(trueID)

        if not nonPersistentZData then
            ZomboidForge.ShowNametag[trueID] = nil
            return
        end

        -- get zombie data
        local ZType = nonPersistentZData.ZType
        local ZombieTable = ZomboidForge.ZTypes[ZType]
		if interval>0 and ZombieTable then
			local player = getPlayer()
			if zombie:isAlive() and player:CanSee(zombie) then
				zombie:getModData().userName = zombie:getModData().userName or TextDrawObject.new()
				zombie:getModData().userName:setDefaultColors(ZombieTable.color[1]/255,ZombieTable.color[2]/255,ZombieTable.color[3]/255,interval/100)
				zombie:getModData().userName:setOutlineColors(ZombieTable.outline[1]/255,ZombieTable.outline[2]/255,ZombieTable.outline[3]/255,interval/100)
				zombie:getModData().userName:ReadString(UIFont.Small, getText(ZombieTable.name), -1)
				local sx = IsoUtils.XToScreen(zombie:getX(), zombie:getY(), zombie:getZ(), 0)
				local sy = IsoUtils.YToScreen(zombie:getX(), zombie:getY(), zombie:getZ(), 0)
				sx = sx - IsoCamera.getOffX() - zombie:getOffsetX()
				sy = sy - IsoCamera.getOffY() - zombie:getOffsetY()
				if ZombieForgeOptions and ZombieForgeOptions.TextHeight then
					sy = sy - 228 + 48*ZombieForgeOptions.TextHeight + 20*ZombieForgeOptions.HeightOffset
				else
					sy = sy - 180
				end
				sx = sx / getCore():getZoom(0)
				sy = sy / getCore():getZoom(0)
				sy = sy - zombie:getModData().userName:getHeight()
				zombie:getModData().userName:AddBatchedDraw(sx, sy, true)
				ZomboidForge.ShowNametag[trueID][2] = ZomboidForge.ShowNametag[trueID][2] - 1
			else
				ZomboidForge.ShowNametag[trueID] = nil
			end
        else
            ZomboidForge.ShowNametag[trueID] = nil
		end
	end
end

--#endregion
