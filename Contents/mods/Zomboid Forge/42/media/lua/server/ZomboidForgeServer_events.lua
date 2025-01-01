--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

This file defines the events of Zomboid Forge server side

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

Events.OnInitGlobalModData.Add(ZomboidForge_server.initModData_ZomboidForgeServer_commands)

Events.OnClientCommand.Add(function(module, command, player, args)
	if ZomboidForge_server.Commands[module] and ZomboidForge_server.Commands[module][command] then
	    ZomboidForge_server.Commands[module][command](player, args)
	end
end)