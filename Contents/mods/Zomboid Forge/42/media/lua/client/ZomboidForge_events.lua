--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

This file defines the events used by Zomboid Forge

]]--
--[[ ================================================ ]]--

--- import module
require "ZomboidForge"
require "ZomboidForge_tools"
require "ZomboidForge_visuals"
local ZomboidForge = require "ZomboidForge_module"

--- On start Events
Events.OnLoad.Add(ZomboidForge.OnLoad)
Events.OnGameStart.Add(ZomboidForge.OnGameStart)

--- Main Events handling
Events.OnZombieUpdate.Add(ZomboidForge.ZombieUpdate)
Events.OnWeaponHitCharacter.Add(ZomboidForge.OnHit)
Events.OnZombieDead.Add(ZomboidForge.OnDeath)

--- Counter updater
Events.OnTick.Add(ZomboidForge.OnTick)

--- handling of commands sent 
Events.OnServerCommand.Add(function(module, command, args)
	if ZomboidForge.Commands[module] and ZomboidForge.Commands[module][command] then
		ZomboidForge.Commands[module][command](args)
	end
end)