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
		"KillZombie",
		{
			attacker = player:getOnlineID(),
			zombie = args.zombieOnlineID,
		}
	)
end

ZomboidForge_server.Commands.ZombieHandler.PathToSound = function(player,args)
	sendServerCommand(
		"ZombieHandler",
		"PathToSound",
		args
	)
end

ZomboidForge_server.Commands.ZombieHandler.UpdateZombieHealth = function(player,args)
	-- only update if call from attacker
	local attackerOnlineID = args.attackerOnlineID
	local attacker = getPlayerByOnlineID(attackerOnlineID)

	-- get zombie
	local zombieOnlineID = args.zombieOnlineID
	local zombie = ZomboidForge_server.getZombieByOnlineID(attacker,zombieOnlineID)
	if not zombie then return end

	-- set zombie health if needed
	local HP = args.defaultHP
	if zombie:getHealth() ~= HP then
		zombie:setHealth(HP)
		zombie:setAttackedBy(attacker)
	end

	-- kill zombie if zombie should die
	if HP > 0 then
		sendServerCommand(
			"ZombieHandler",
			"UpdateZombieHealth",
			{
				HP = HP,
				attackerOnlineID = attackerOnlineID,
				zombieOnlineID = zombieOnlineID,
			}
		)
	else
		sendServerCommand(
			"ZombieHandler",
			"KillZombie",
			{
				attacker = attackerOnlineID,
				zombie = zombieOnlineID,
			}
		)

		zombie:changeState(ZombieOnGroundState.instance())
		zombie:becomeCorpse()
	end
end

--#endregion