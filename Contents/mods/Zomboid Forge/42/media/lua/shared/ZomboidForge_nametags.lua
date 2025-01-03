--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

Handle nametags for ZomboidForge

]]--
--[[ ================================================ ]]--

-- requirements
local ZomboidForge = require "ZomboidForge_module"
require "ISUI/ZombieNametag"

-- caching
local ZombieNametag = ZombieNametag
local Configs = ZomboidForge.Configs

-- localy initialize player
local client_player = getPlayer()
local function initTLOU_OnGameStart(_, _)
	client_player = getPlayer()
end
Events.OnCreatePlayer.Remove(initTLOU_OnGameStart)
Events.OnCreatePlayer.Add(initTLOU_OnGameStart)


-- Checks if the `zombie` is valid to have its nametag displayed for local player.
---@param zombie IsoZombie
---@return boolean
ZomboidForge.IsZombieValidForNametag = function(zombie,isBehind,isOnCursor)
    -- test for each options
    -- 1. draw nametag if should always be on
    if Configs.AlwaysOn
    and (not isClient() or SandboxVars.ZomboidForge.NametagsAlwaysOn)
    and not isBehind and client_player:CanSee(zombie)
    then
        return true

    -- 2. don't draw if player can't see zombie
    elseif not client_player:CanSee(zombie)
    or isBehind
    then
        return false

    -- -- 3. draw if zombie is attacking and option for it is on
    -- elseif ZFModOptions.WhenZombieIsTargeting.value and zombie:getTarget() then

    --     -- verify the zombie has a target and the player is the target
    --     local target = zombie:getTarget()
    --     if target and target == client_player then
    --         return true
    --     end

    -- 4. draw if zombie is in radius of cursor detection
    elseif isOnCursor then
        return true
    end

    -- else return false, zombie is not valid
    return false
end

