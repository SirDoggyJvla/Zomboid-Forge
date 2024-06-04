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
local tostring = tostring --tostring function
local Long = Long --Long for pID
local player = getPlayer()

--- import module from ZomboidForge
local ZomboidForge = require "ZomboidForge_module"
local ZFModData = ModData.getOrCreate("ZomboidForge")

-- Initialize player
ZomboidForge.OnCreatePlayerInitializations.ZomboidForge_tools = function()
    player = getPlayer()
end

ZomboidForge.initModData_ZomboidForge_tools = function()
    ZFModData = ModData.getOrCreate("ZomboidForge")
end

local A1, A2 = 727595, 798405  -- 5^17=D20*A1+A2
local D20, D40 = 1048576, 1099511627776  -- 2^20, 2^40
-- Seeded random used in determining the `ZType` of a zombie.
---@param trueID        int
ZomboidForge.seededRand = function(trueID)
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
    local nonPersistentZData = ZomboidForge.GetNonPersistentZData(trueID)

    -- if no ZType given, access it
    if not ZType then
        if not nonPersistentZData.ZType then
            ZomboidForge.ZombieInitiliaze(zombie,true,true)
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
    if ZombieTable.outfit then
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
        end
    end

    -- set hair color
    if ZombieTable.hairColor then
        local zombieVisual = zombie:getHumanVisual()
        local currentHairColor = zombieVisual:getHairColor()
        local hairColorChoice = ZomboidForge.RandomizeTable(ZombieTable,"hairColor",currentHairColor)
        if hairColorChoice then
            zombieVisual:setHairColor(hairColorChoice)
        end
    end

    -- set beard if male
    if ZombieTable.beard and not zombie:isFemale() then
        local zombieVisual = zombie:getHumanVisual()
        local currentBeard = zombieVisual:getBeardModel()
        local beardChoice = ZomboidForge.RandomizeTable(ZombieTable,"beard",currentBeard)
        if beardChoice then
            zombieVisual:setBeardModel(beardChoice)
        end
    end

    -- set beard color if male
    if ZombieTable.beardColor and not zombie:isFemale() then
        local zombieVisual = zombie:getHumanVisual()
        local currentBeardColor = zombieVisual:getHairColor()
        local beardColorChoice = ZomboidForge.RandomizeTable(ZombieTable,"beardColor",currentBeardColor)
        if beardColorChoice or true then
            zombieVisual:setHairColor(beardColorChoice)
        end
    end

    -- set zombie HP extremely high to make sure it doesn't get oneshoted if it has custom
    -- HP, handled via the attack functions
    if ZombieTable.HP and ZombieTable.HP ~= 1 then
        if isClient() then
            zombie:setAvoidDamage(true)
        elseif zombie:getHealth() ~= ZomboidForge.InfiniteHP then
            ZomboidForge.InfiniteHP = 300
            zombie:setHealth(ZomboidForge.InfiniteHP)
        end
    end

    -- custom animation variable
    local animVariable = ZombieTable.animationVariable
    if animVariable then
        if not zombie:getVariableBoolean(animVariable) then
            zombie:setVariable(animVariable,'true')
        end
    end

    -- set only Jaw Stabs
    local jaw_stab = ZombieTable.onlyJawStab or false
    zombie:setOnlyJawStab(jaw_stab)

    -- set custom emitters if any
    local customEmitter = ZombieTable.customEmitter
    if customEmitter then
        -- retreive emitter
        local emitter = customEmitter.general
            or zombie:isFemale() and customEmitter.female
            or customEmitter.male

        if emitter then
            local zombieEmitter = zombie:getEmitter()
            if not zombieEmitter:isPlaying(emitter) then
                zombieEmitter:stopAll()
                zombieEmitter:playVocals(emitter)
            end
        end
    end

    -- remove bandages
    if ZombieTable.removeBandages then
        -- Remove bandages
        local bodyVisuals = zombie:getHumanVisual():getBodyVisuals()
        if bodyVisuals and bodyVisuals:size() > 0 then
            zombie:getHumanVisual():getBodyVisuals():clear()
        end
    end

    -- zombie clothing visuals
    local clothingVisuals = ZombieTable.clothingVisuals
    if clothingVisuals then
        -- get visuals and skip of none
        local visuals = zombie:getItemVisuals()
        if visuals then
            -- remove new visuals
            local locations = clothingVisuals.remove
            if locations then
                ZomboidForge.RemoveClothingVisuals(visuals,locations)
            end

            -- set new visuals
            locations = clothingVisuals.set
            if locations then
                ZomboidForge.AddClothingVisuals(visuals,locations)
            end
        end
    end

    -- run custom data if any
    if ZombieTable.customData then
        for _, customData in ipairs(ZombieTable.customData) do
            ZomboidForge[customData](zombie,ZType)
        end
    end

    zombie:resetModel()
end

-- Test that a value is present within an array-like table.
---@param table         table
---@param value         any
ZomboidForge.CheckInTable = function(table,value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

--- Randomly choses a `Zombie` `ZData` within a ZType data table if current is not already in the table.
---@param ZDataTable    table       --Zombie Table to randomize
---@param ZData         string      --Chosen data in ZType table
---@param current       any         --[opt] Used to verify `current` from `Zombie` is not in table
---@return boolean                  --Random choice within ZData
ZomboidForge.RandomizeTable = function(ZDataTable,ZData,current)
    local ZDataTable_get = ZDataTable[ZData]; if not ZDataTable_get then return false end
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
end


-- This function will remove clothing visuals from the `zombie` for each clothing `locations`.
---@param visuals       ItemVisuals
---@param locations     table      --Zombie Type ID
ZomboidForge.RemoveClothingVisuals = function(visuals,locations)
    -- cycle backward to not have any fuck up in index whenever one is removed
    for i = visuals:size() - 1, 0, -1 do
        local item = visuals:get(i)
        local getRemove = locations[item:getScriptItem():getBodyLocation()]
        if getRemove and getRemove ~= item then
            visuals:remove(item)
        end
    end
end

-- This function will replace or add clothing visuals from the `zombie` for each 
-- clothing `locations` specified. 
--
--      `1: checks for bodyLocations that fit locations`
--      `2: replaces bodyLocation item if not already the proper item`
--      `3: add visuals that need to get added`
---@param visuals       ItemVisuals
---@param locations     table      --Zombie Type ID
ZomboidForge.AddClothingVisuals = function(visuals,locations)
    -- replace visuals that are at the same body locations and check for already set visuals
    local replace = {}
    for i = visuals:size() - 1, 0, -1 do
        local item = visuals:get(i)
        local location = item:getScriptItem():getBodyLocation()
        local getReplacement = locations[location]
        if getReplacement then
            if getReplacement ~= item then
                item:setItemType(getReplacement)
			    item:setClothingItemName(getReplacement)
            end
            replace[location] = item
        end
    end

    -- check for visuals that need to be added and add them
    for location,item in pairs(locations) do
        if not replace[location] then
            local itemVisual = ItemVisual.new()
            itemVisual:setItemType(item)
            itemVisual:setClothingItemName(item)
            visuals:add(itemVisual)
        end
    end
end

--#region Tools

-- Gives the persistent data of an `IsoZombie` based on its given `trueID`.
---@param trueID        int
---@return table
ZomboidForge.GetPersistentZData = function(trueID)
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
    local PersistentZData = ZFModData.PersistentZData
    if PersistentZData and PersistentZData[trueID] then
        PersistentZData[trueID] = nil
    end
end

--#region Determine Hit Reaction for zombies in multiplayer

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
---@param attacker      IsoPlayer
---@param zombie        IsoZombie
---@param handWeapon    HandWeapon
ZomboidForge.DetermineHitReaction = function(attacker, zombie, handWeapon)
    local attackerHitReaction = attacker:getVariableString("ZombieHitReaction")

    local hitReaction = ""
    -- if gun/ranged
    if attackerHitReaction == "Shot" then
        -- Roll crit hit
        attacker:setCriticalHit(ZombRand(100) < player:calculateCritChance(zombie))

        -- default to ShotBelly and get hit direction
        hitReaction = "ShotBelly";
        local hitDirection = ZomboidForge.DetermineHitDirection(attacker, zombie, handWeapon)

        -- if N then roll for variation
        if (hitDirection == "N" and (zombie:isHitFromBehind() or ZombRand(2) == 1))
            or (hitDirection == "S")
        then
            hitReaction = "ShotBellyStep"
        end

        -- if R or L get hit reaction
        if hitDirection == "R" or hitDirection == "L" then
            if zombie:isHitFromBehind() then
                hitReaction = direction_side[ZombRand(3)]
            else
                hitReaction = direction_side[ZombRand(5)]
            end

            hitReaction = hitReaction..hitDirection
        end

        -- verify critical hit
        if attacker:isCriticalHit() then
            if hitDirection == "S" then
                hitReaction = "ShotHeadFwd"
            elseif (hitDirection == "N")
                or ((hitDirection == "L" or hitDirection == "R") and ZombRand(4) == 0)
            then
                hitReaction = "ShotHeadBwd"
            end
        end

        -- supposed to be the part that handles blood but that can wait

        -- roll to have a variation in ShotHead reaction
        if hitReaction == "ShotHeadFwd" and ZombRand(2) == 0 then
            hitReaction = "ShotHeadFwd02"
        end

    --[[ used to add blood, will be done later if needed
    else
        local categories = handWeapon:getCategories()
        -- if blunt
        if categories:contains("Blunt") then
            zombie:addLineChatElement("Blunt")
        -- unarmed
        elseif not categories:contains("Unarmed") then
            zombie:addLineChatElement("Else")
        else
            zombie:addLineChatElement("Unarmed")
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
---@param attacker      IsoPlayer
---@param zombie        IsoZombie
---@param handWeapon    HandWeapon
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
        if ZombRand(9) > 6 then
            hitDirection = "L"
        elseif ZombRand(9) > 4 then
            hitDirection = "R"
        end
    elseif var12 < 90 then
        zombie:setHitFromBehind(true)
        if ZombRand(4) == 0 then
            hitDirection = "S"
        else
            hitDirection = "R"
        end
    elseif var12 < 135 then
        hitDirection = "R"
    elseif var12 < 180 then
        if ZombRand(4) == 0 then
            hitDirection = "N"
        else
            hitDirection = "R"
        end
    elseif var12 < 225 then
        hitDirection = "N"
        if ZombRand(9) > 4 then
            hitDirection = "R"
        elseif ZombRand(9) > 6 then
            hitDirection = "L"
        end
    elseif var12 < 270 then
        if ZombRand(4) == 0 then
            hitDirection = "N"
        else
            hitDirection = "L"
        end
    elseif var12 < 315 then
        zombie:setHitFromBehind(true)
        hitDirection = "L"
    else
        if ZombRand(4) == 0 then
            hitDirection = "S"
        else
            hitDirection = "L"
        end
    end

    return hitDirection
end

ZomboidForge.ApplyHitReaction = function(zombie,attacker,hitReaction)
    -- check for hitReaction and apply it
    -- else default to "" and simple stagger
    if hitReaction and hitReaction ~= "" then
        zombie:setHitReaction(hitReaction)
    else
        zombie:setStaggerBack(true)
        zombie:setHitReaction("")

        -- remove critical hit
        if (zombie:getPlayerAttackPosition() == "LEFT" or zombie:getPlayerAttackPosition() == "RIGHT")    
        then
            attacker:setCriticalHit(false)
        end
    end
end

--#endregion

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
                            local ZType = ZomboidForge.GetZType(trueID)

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
        local ZType = ZomboidForge.GetZType(trueID)
        local ZombieTable = ZomboidForge.ZTypes[ZType]
		if interval>0 and ZombieTable then
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
