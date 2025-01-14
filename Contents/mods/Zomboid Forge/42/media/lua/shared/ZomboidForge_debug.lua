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

ZomboidForge.HandleDebuggingOnTick = function(zombie,tick)
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

        if DEBUG_ZombiePannel.ZombieTable then
            zombiePannel = zombiePannel.."\nZOMBIE TABLE STATS:\n"

            zombiePannel = zombiePannel.."memory = "..tostring(ZombieTable.memory).."\n"
            zombiePannel = zombiePannel.."sight = "..tostring(ZombieTable.sight).."\n"
            zombiePannel = zombiePannel.."hearing = "..tostring(ZombieTable.hearing).."\n"
            zombiePannel = zombiePannel.."cognition = "..tostring(ZombieTable.cognition).."\n"
            zombiePannel = zombiePannel.."strength = "..tostring(ZombieTable.strength).."\n"
            zombiePannel = zombiePannel.."toughness = "..tostring(ZombieTable.toughness).."\n"
        end

        if DEBUG_ZombiePannel.ShowHealth then
            zombiePannel = zombiePannel.."\nZOMBIE HEALTH:\n"

            zombiePannel = zombiePannel.."health = "..tostring(zombie:getHealth()).."\n"
        end

        zombie:addLineChatElement(zombiePannel)
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