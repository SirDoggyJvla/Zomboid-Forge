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

if isClient() then return end

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

ZomboidForge_server.Commands.ZombieHandler.DamageZombie = function(player,args)
	local trueID = args.trueID
	-- get zombie data
	if not ZFModData.PersistentZData then
		ZFModData.PersistentZData = {}
	end
	local PersistentZData = ZFModData.PersistentZData[trueID]
	if not PersistentZData then
		ZFModData.PersistentZData[trueID] = {}
		PersistentZData = ZFModData.PersistentZData[trueID]
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
		shouldNotStagger = args.shouldNotStagger,
	}
	sendServerCommand('ZombieHandler', 'DamageZombie', args)

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