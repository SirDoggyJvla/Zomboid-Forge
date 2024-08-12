--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

This file defines the tools to change visuals of zombies for the mod Zomboid Forge

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
local ZFModOptions = require "ZomboidForge_ClientOption"
ZFModOptions = ZFModOptions.options_data

-- localy initialize player
local client_player = getPlayer()
local function initTLOU_OnGameStart(_, _)
	client_player = getPlayer()
end
Events.OnCreatePlayer.Remove(initTLOU_OnGameStart)
Events.OnCreatePlayer.Add(initTLOU_OnGameStart)


--#region Update Zombie visuals

ZomboidForge.UpdateVisuals = function(zombie,ZombieTable,ZType)
    -- if zombie:getVariableBoolean("ZF_VisualsUpdated") then return end

    -- get zombie data
    local gender = zombie:isFemale() and "female" or "male"
    local ZData

    -- set ZombieData
    for key,data in pairs(ZomboidForge.ZombieData) do
        ZData = ZomboidForge.RetrieveDataFromTable(ZombieTable,key,gender)

        -- if data for this ZTypes found then
        if ZData then
            -- get current and do a choice
            local current = data.current(zombie)
            local choice = ZomboidForge.ChoseInTable(ZData,current)

            -- verify data was found in the list to chose or current is not choice
            if choice ~= nil then
                data.apply(zombie,choice)
            end
        end
    end

    -- set ZombieData_boolean
    for key,data in pairs(ZomboidForge.ZombieData_boolean) do
        ZData = ZomboidForge.RetrieveDataFromTable(ZombieTable,key,gender)

        -- if data for this ZTypes found then
        if ZData then
            -- do a choice
            local choice = ZomboidForge.ChoseInTable(ZData,nil)

            -- verify data was found in the list to chose or current is not choice
            if choice ~= nil then
                data.update(zombie,choice)
            end
        end
    end

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
    if ZomboidForge.GetBooleanResult(zombie,ZType,ZombieTable.removeBandages,"removeBandages") then
        -- Remove bandages
        local bodyVisuals = zombie:getHumanVisual():getBodyVisuals()
        if bodyVisuals and bodyVisuals:size() > 0 then
            zombie:getHumanVisual():getBodyVisuals():clear()
        end
    end

    -- zombie clothing visuals
    local clothingVisuals = ZombieTable.clothingVisuals
    if clothingVisuals then
        -- get visuals and skip if none
        local visuals = zombie:getItemVisuals()
        if visuals then
            -- remove new visuals
            local locations = clothingVisuals.remove
            if locations then
                ZomboidForge.RemoveClothingVisuals(zombie,ZType,visuals,locations)
            end

            -- set new visuals
            locations = clothingVisuals.set
            if locations then
                ZomboidForge.AddClothingVisuals(visuals,locations,gender)
            end

            -- add dirt, blood or holes
            local blood = clothingVisuals.bloody
            local bloody = ZomboidForge.GetBooleanResult(zombie,ZType,blood,"remove "..tostring(blood))
            bloody = type(bloody) == "boolean" and 1 or bloody
            local dirt = clothingVisuals.dirty
            local dirty = ZomboidForge.GetBooleanResult(zombie,ZType,dirt,"remove "..tostring(dirt))
            dirty = type(dirty) == "boolean" and 1 or dirty
            local hole = clothingVisuals.holes
            hole = hole and 1 or false
            local holes = ZomboidForge.GetBooleanResult(zombie,ZType,hole,"remove "..tostring(hole))
            if bloody or dirty or holes then
                ZomboidForge.ModifyClothingVisuals(zombie,ZType,visuals,bloody,dirty,holes)
            end
        end
    end

    zombie:resetModel()

    -- zombie:setVariable("ZF_VisualsUpdated",true)
end

-- This function will remove clothing visuals from the `zombie` for each clothing `locations`.
---@param visuals ItemVisuals
---@param locations table
ZomboidForge.RemoveClothingVisuals = function(zombie,ZType,visuals,locations)
    -- cycle backward to not have any fuck up in index whenever one is removed
    for i = visuals:size() - 1, 0, -1 do
        local item = visuals:get(i)
        if item then
            local scriptItem = item:getScriptItem()
            if scriptItem then
                local location = scriptItem:getBodyLocation()
                local location_remove = locations[location]
                if location_remove then
                    local getRemove = ZomboidForge.GetBooleanResult(zombie,ZType,location_remove,"remove "..tostring(location_remove))
                    if getRemove then
                        visuals:remove(item)
                    end
                end
            end
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
ZomboidForge.AddClothingVisuals = function(visuals,locations,gender)
    -- replace visuals that are at the same body locations and check for already set visuals
    local replace = {}
    local ZData
    local choice
    local location
    local item
    for i = visuals:size() - 1, 0, -1 do
        item = visuals:get(i)
        location = item:getScriptItem():getBodyLocation()

        if locations[location] then
            ZData = ZomboidForge.RetrieveDataFromTable(locations,location,gender)

            -- if data for this ZTypes found then
            if ZData then
                -- get current and do a choice
                local scriptItem = item:getScriptItem()
                local current = scriptItem:getModuleName().."."..scriptItem:getName()

                -- chose item if current not in ZData
                choice = ZomboidForge.ChoseInTable(ZData,current)

                -- verify data was found in the list to chose or current is not choice
                if choice then
                    item:setItemType(choice)
                    item:setClothingItemName(choice)
                end

                -- location already exists so skip adding it
                replace[location] = item
            end
        end
    end

    -- check for visuals that need to be added and add them
    for location,item in pairs(locations) do
        if not replace[location] then
            ZData = ZomboidForge.RetrieveDataFromTable(locations,location,gender)
            choice = ZomboidForge.ChoseInTable(ZData,item)

            local itemVisual = ItemVisual.new()
            itemVisual:setItemType(choice)
            itemVisual:setClothingItemName(choice)
            visuals:add(itemVisual)
        end
    end
end

-- This function will add dirt or/and blood to clothing visuals from the `zombie` for each clothing `locations`.
ZomboidForge.ModifyClothingVisuals = function(zombie,ZType,visuals,bloody,dirty,holes)
    -- cycle backward to not have any fuck up in index whenever one is removed
    for i = visuals:size() - 1, 0, -1 do
        local item = visuals:get(i)
        if item then
            local scriptItem = item:getScriptItem()
            if scriptItem then
                local blood = scriptItem:getBloodClothingType()
                if blood and blood:size() >= 1 then
                    local coveredParts = BloodClothingType.getCoveredParts(blood)
                    for j = 0, coveredParts:size() - 1 do
                        local bloodPart = coveredParts:get(j)
                        if bloody and item:getBlood(bloodPart) ~= bloody then
                            item:setBlood(bloodPart,bloody)
                        end
                        if dirty and item:getDirt(bloodPart) ~= dirty then
                            item:setDirt(bloodPart,dirty)
                        end
                        if holes and item:getHole(bloodPart) ~= holes then
                            item:setHole(bloodPart)
                        end
                    end
                end
            end
        end
    end
end

--#endregion

--#region Nametag handling

-- Permits access to the value associated to the option `ZFModOptions.Ticks`.
-- Used in `ZomboidForge.GetNametagTickValue`.
local TicksOption = {
    10,
    50,
    100,
    200,
    500,
    1000,
    10000,
}

-- Returns the `ticks` value. This value can be forced via a zombie type, else it's based
-- on client options.
---@param ZombieTable table
---@return int
ZomboidForge.GetNametagTickValue = function(ZombieTable)
    return ZombieTable.ticks or TicksOption[ZFModOptions.Ticks.value]
end

-- Shows the nametag of the `zombie`. Can be triggered anytime and will automatically
-- the `ticks` value and apply it to the `zombie`.
---@param zombie IsoZombie
---@param trueID int [opt]
---@param ZombieTable table [opt]
ZomboidForge.ShowZombieNametag = function(zombie,trueID,ZombieTable)
    -- get zombie informations
    trueID = trueID or ZomboidForge.pID(zombie)
    if not ZombieTable then
        local ZType = ZomboidForge.GetZType(trueID)
        ZombieTable = ZomboidForge.ZTypes[ZType]
    end

    local zombieModData = zombie:getModData()
    ZomboidForge.TriggerNametag(zombieModData,ZombieTable)
    zombieModData.ticks = ZomboidForge.GetNametagTickValue(ZombieTable)
end

ZomboidForge.TriggerNametag = function(zombieModData,ZombieTable)
    zombieModData.nametag = TextDrawObject.new()
    local nametag = zombieModData.nametag

    zombieModData.color = ZombieTable.color or {255,255,255}
    zombieModData.outline = ZombieTable.outline or {255,255,255}
    zombieModData.VerticalPlacement = ZFModOptions.VerticalPlacement.value

    -- apply string with font
    local fonts = ZFModOptions.Fonts
    nametag:ReadString(UIFont[fonts[fonts.value]], getText(ZombieTable.name), -1)

    if ZFModOptions.Background.value then
        nametag:setDrawBackground(true)
    end
end

-- Updates the nametag of the `zombie` if valid.
---@param zombie IsoZombie
---@param ZombieTable table
ZomboidForge.UpdateNametag = function(zombie,ZombieTable,ticks,valid)
    -- if not ticks then checks that nametag should be shown
    if not ticks then
        if not valid then
            return
        end

        ticks = ZomboidForge.GetNametagTickValue(ZombieTable)
    elseif valid then
        ticks = ZomboidForge.GetNametagTickValue(ZombieTable)
    end

    -- draw nametag
    ZomboidForge.DrawNameTag(zombie,ZombieTable,ticks)

    local zombieModData = zombie:getModData()
    -- reduce value of nametag or delete it
    if ticks <= 0 then
        zombieModData.ticks = nil

        ZomboidForge.DeleteNametag(zombie)
    elseif ZomboidForge.IsZombieBehind(zombie,client_player) then
        ticks = math.min(ticks,100)
        zombieModData.ticks = ticks - 5
    else
        zombieModData.ticks = ticks - 1
    end
end

ZomboidForge.DeleteNametag = function(zombie)
    local zombieModData = zombie:getModData()
    zombieModData.nametag = nil
    zombieModData.color = nil
    zombieModData.outline = nil
    zombieModData.VerticalPlacement = nil
end

-- Draws the nametag of the `zombie` based on the `ticks` value.
---@param zombie IsoZombie
---@param ZombieTable table
---@param ticks int
ZomboidForge.DrawNameTag = function(zombie,ZombieTable,ticks)
    local zombieModData = zombie:getModData()

    -- get zombie nametag
    local nametag = zombieModData.nametag
    -- initialize nametag
    if not nametag then
        ZomboidForge.TriggerNametag(zombieModData,ZombieTable)
        nametag = zombieModData.nametag
    end

    -- get initial position of zombie
    local x = zombie:getX()
    local y = zombie:getY()
    local z = zombie:getZ()

    local sx = IsoUtils.XToScreen(x, y, z, 0)
    local sy = IsoUtils.YToScreen(x, y, z, 0)

    -- apply offset
    sx = sx - IsoCamera.getOffX() - zombie:getOffsetX()
    sy = sy - IsoCamera.getOffY() - zombie:getOffsetY()

    -- apply client vertical placement
    sy = sy - 190 + 20*zombieModData.VerticalPlacement

    -- apply zoom level
    local zoom = getCore():getZoom(0)
    sx = sx / zoom
    sy = sy / zoom
    sy = sy - nametag:getHeight()

    -- apply visuals
    local color = zombieModData.color
    local outline = zombieModData.outline
    nametag:setDefaultColors(color[1]/255,color[2]/255,color[3]/255,ticks/100)
    nametag:setOutlineColors(outline[1]/255,outline[2]/255,outline[3]/255,ticks/100)

    -- Draw nametag
    nametag:AddBatchedDraw(sx, sy, true)
end

-- Checks if the `zombie` is valid to have its nametag displayed for local player.
---@param zombie IsoZombie
---@return boolean
ZomboidForge.IsZombieValidForNametag = function(zombie,zombiesOnCursor)
    -- retrieve zombie info
    local isBehind = ZomboidForge.IsZombieBehind(zombie,client_player)

    -- test for each options
    -- 1. draw nametag if should always be on
    if ZFModOptions.AlwaysOn.value
    and (isClient() and SandboxVars.ZomboidForge.NametagsAlwaysOn or true)
    and not isBehind and client_player:CanSee(zombie)
    then
        return true

    -- 2. don't draw if player can't see zombie
    elseif not client_player:CanSee(zombie)
    or isBehind
    then
        return false

    -- 3. draw if zombie is attacking and option for it is on
    elseif ZFModOptions.WhenZombieIsTargeting.value and zombie:getTarget() then

        -- verify the zombie has a target and the player is the target
        local target = zombie:getTarget()
        if target and target == client_player then
            return true
        end

    -- 4. draw if zombie is in radius of cursor detection
    elseif zombiesOnCursor[zombie] then
        return true
    end

    -- else return false, zombie is not valid
    return false
end

--#endregion