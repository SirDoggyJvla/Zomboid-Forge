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

-- skip non debug clients
if not isDebugEnabled() then return end

-- requirements
local ZomboidForge = require "ZomboidForge_module"

ZomboidForge.PrintZTypes = function()
    print("ZTypes:")
    for k,v in pairs(ZomboidForge.ZTypes) do
        print(k..": chance = "..tostring(v.chance))
    end
end

ZomboidForge.Debug.OnFillWorldObjectContextMenu = function(playerIndex, context, worldObjects, test)
    -- access the first square found
    local worldObject,square
    for i = 1,#worldObjects do
        worldObject = worldObjects[i]
        square = worldObject:getSquare()
        if square then
            break
        end
    end

    -- skip if no square found
    if not square then return end

    -- create the submenu for Immersive Hunting debug
    local option = context:addOptionOnTop("Zomboid Forge: Debug")
    local subMenu = context:getNew(context)
    context:addSubMenu(option, subMenu)

    option.iconTexture = getTexture("media/ui/ZomboidForge_icon.png")

    local cellX = square:getX() / getCellSizeInSquares()
    local cellY = square:getY() / getCellSizeInSquares()
    cellX = math.floor(cellX)
    cellY = math.floor(cellY)

    --- CLEAR CELL ZOMBIES ---
    local name = "Clear Cell Zombies: " .. tostring(cellX) .. "," .. tostring(cellY)
    option = subMenu:addOption(name,cellX,function(cellX,cellY) zpopClearZombies(cellX,cellY) end,cellY)


    --- ZOMBIE PANNEL ---
    option = subMenu:addOptionOnTop("Zombie Pannel")
    local menu_ZombiePannel = subMenu:getNew(subMenu)
    context:addSubMenu(option, menu_ZombiePannel)

    local DEBUG_ZombiePannel = ZomboidForge.DEBUG_ZombiePannel
    for k,v in pairs(DEBUG_ZombiePannel) do
        option = menu_ZombiePannel:addOption(k,k,function(key,boolean) DEBUG_ZombiePannel[key] = ZomboidForge.SwapBoolean(boolean) end,v)
        subMenu:setOptionChecked(option, v)
    end


    --- RELOAD ZTYPES ---
    subMenu:addOption("Reload ZTypes",nil,ZomboidForge.OnLoad)



    --- READ AVAILABLE ZTYPES ---
    subMenu:addOption("Print ZTypes",nil,ZomboidForge.PrintZTypes)
    subMenu:addOption("Print TotalChance",nil,function() print("TotalChance = "..tostring(ZomboidForge.TotalChance)) end)
end