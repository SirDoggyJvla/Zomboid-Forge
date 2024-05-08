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

--- Import functions localy for performances reasons
local table = table -- Lua's table module
local ipairs = ipairs -- ipairs function
local pairs = pairs -- pairs function
local ZombRand = ZombRand -- java function
local print = print -- print function
local tostring = tostring --tostring function

--- import module
local ZomboidForge_server = require "ZomboidForgeServer_module"

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

ZomboidForge_server.Commands.ZombieHandler.DamageZombie = function(player,args)
	-- get zombie data
	local ZFModData = ModData.getOrCreate("ZomboidForge")
	if not ZFModData.PersistentZData then
		ZFModData.PersistentZData = {}
	end
	local PersistentZData = ZFModData.PersistentZData[args.trueID]
	if not PersistentZData then
		PersistentZData = {}
	end

	-- get zombie HP
	local HP = PersistentZData.HP or args.defaultHP

	-- apply damage
	HP = HP - args.damage

	-- determine if zombie gets killed
	local kill = HP <= 0

	-- ask clients to handle the zombie HP/killing
	args = {
		attacker = player:getOnlineID(),
		zombie = args.zombie,
		kill = kill,
		HP = 1000,
	}
	sendServerCommand('ZombieHandler', 'SetZombieHP', args)

	-- delete persistent data about this zombie if it gets killed
	-- else update HP counter
	if kill then
		PersistentZData = nil
	else
		-- update the HP counter of PersistentZData
		PersistentZData.HP = HP
	end
end

--#endregion