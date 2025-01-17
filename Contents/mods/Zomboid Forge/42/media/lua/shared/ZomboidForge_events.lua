--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

Events of ZomboidForge

]]--
--[[ ================================================ ]]--

local ZomboidForge = require "ZomboidForge_module"

--- On start Events
Events.OnInitGlobalModData.Add(ZomboidForge.OnLoad)

-- Initialize zombie
Events.OnZombieCreate.Add(ZomboidForge.OnZombieCreate)

-- Real time handling of zombies
Events.OnZombieUpdate.Add(ZomboidForge.OnZombieUpdate)
Events.OnTick.Add(ZomboidForge.OnTick)

-- Death of zombie
Events.OnZombieDead.Add(ZomboidForge.OnZombieDead)

-- Hitting zombie
Events.OnWeaponHitCharacter.Add(ZomboidForge.OnCharacterHitZombie)
Events.OnZombieHitCharacter.Add(ZomboidForge.OnZombieHitCharacter)
Events.OnZombieThump.Add(ZomboidForge.OnZombieThump)
Events.OnWeaponHitXp.Add(ZomboidForge.OnWeaponHitXp)

-- debug client specific events
if isDebugEnabled() then
    Events.OnFillWorldObjectContextMenu.Add(ZomboidForge.Debug.OnFillWorldObjectContextMenu)
end