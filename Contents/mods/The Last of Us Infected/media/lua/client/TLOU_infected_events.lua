--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

This file defines the events used by The Last of Us Infected based on Zomboid Forge framework.

]]--
--[[ ================================================ ]]--

--- Makes sure TLOU_infected is loaded before
require "TLOU_infected"

--- Import ZomboidForge module
local ZomboidForge = require "ZomboidForge_module"

--- ZomboidForge.TLOU_infected functions
Events.OnGameStart.Add(ZomboidForge.Initialize_TLOUInfected)

--- Add buildings to the list of buildings available to check for zombies
Events.LoadGridsquare.Add(ZomboidForge.TLOU_infected.AddBuildingList)

--- Add a check if it's day every hours
Events.EveryHours.Add(ZomboidForge.TLOU_infected.IsDay)