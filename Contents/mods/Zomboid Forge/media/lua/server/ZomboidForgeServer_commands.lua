--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

This file defines the server side lua of ZomboidForge.

]]--
--[[ ================================================ ]]--

if not isServer() then return end

--- Import functions localy for performances reasons
local table = table -- Lua's table module
local ipairs = ipairs -- ipairs function
local pairs = pairs -- pairs function
local ZombRand = ZombRand -- java function
local tostring = tostring --tostring function

--- import module
local ZomboidForge_server = require "ZomboidForgeServer_module"
local ZFModData = ModData.getOrCreate("ZomboidForge")

ZomboidForge_server.initModData_ZomboidForgeServer_commands = function()
    ZFModData = ModData.getOrCreate("ZomboidForge")
end

--#region Server side commands
-- ZomboidForge.Commands.module.command

-- Updates animation variables of zombies for every single clients.
ZomboidForge_server.Commands.ZombieHandler.SetAnimationVariable = function(player, args)
	sendServerCommand('ZombieHandler', 'SetAnimationVariable', {id = player:getOnlineID(), animationVariable = args.animationVariable, zombie =  args.zombie, state = args.state})
end

-- Updates animation variables of zombies for every single clients.
ZomboidForge_server.Commands.ZombieHandler.RemoveEmitters = function(player, args)
	sendServerCommand('ZombieHandler', 'RemoveEmitters', {id = player:getOnlineID(),zombie = args.zombie})
end

ZomboidForge_server.Commands.ZombieHandler.KillZombie = function(player,args)
	sendServerCommand(
		"ZombieHandler",
		"DamageZombie",
		{
			attacker = player:getOnlineID(),
			kill = true,
			zombie = args.zombieOnlineID,
		}
	)
end

ZomboidForge_server.Commands.ZombieHandler.UpdateHealth = function(player,args)
	local zombie = ZomboidForge_server.getZombieByOnlineID(getPlayerByOnlineID(args.attackerOnlineID),args.zombieOnlineID)
	if not zombie then return end

	zombie:setHealth(args.defaultHP)
end

--#endregion