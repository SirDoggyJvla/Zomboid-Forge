--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

This file patches base functions of the game to make sure emitters of zombies are removed once
the zombies are deleted via the admin and debug tools.

This allows modders to implement their own custom vocals and emitters without having any issues.

]]--
--[[ ================================================ ]]--
--- Import functions localy for performances reasons
local table = table -- Lua's table module
local ipairs = ipairs -- ipairs function
local pairs = pairs -- pairs function
local ZombRand = ZombRand -- java function
local print = print -- print function
local tostring = tostring --tostring function

--- import module from ZomboidForge
local ZomboidForge = require "ZomboidForge_module"

--- Import original methods and keep them stored
ZomboidForge.Patcher = {}
ZomboidForge.Patcher.DebugContextMenu = {}
ZomboidForge.Patcher.AdminContextMenu = {}

ZomboidForge.Patcher.DebugContextMenu.OnRemoveAllZombies = DebugContextMenu.OnRemoveAllZombies
ZomboidForge.Patcher.DebugContextMenu.OnRemoveAllZombiesClient = DebugContextMenu.OnRemoveAllZombiesClient

ZomboidForge.Patcher.AdminContextMenu.OnRemoveAllZombiesClient = AdminContextMenu.OnRemoveAllZombiesClient


-- Remove all emitters of every zombies getting deleted.
ZomboidForge.Patcher.RemoveAllEmitters = function()
    local zombies = getCell():getObjectList()
    for i=zombies:size()-1,0,-1 do
        local zombie = zombies:get(i)
        if instanceof(zombie, "IsoZombie") then
        zombie:getEmitter():stopAll()
        if isClient() then
            sendClientCommand('ZombieHandler','RemoveEmitters',{zombie = zombie:getOnlineID()})
        end

        -- delete zombie data
        local trueID = ZomboidForge.pID(zombie)
        ZomboidForge.DeleteZombieData(trueID)
        end
    end
end

-- replace vanilla methods to remove all emitters before
-- DebugContextMenu.lua
function DebugContextMenu.OnRemoveAllZombies(zombie)
    ZomboidForge.Patcher.RemoveAllEmitters()

    ZomboidForge.Patcher.DebugContextMenu.OnRemoveAllZombies(zombie)
end
function DebugContextMenu.OnRemoveAllZombiesClient(zombie)
    ZomboidForge.Patcher.RemoveAllEmitters()

    ZomboidForge.Patcher.DebugContextMenu.OnRemoveAllZombiesClient(zombie)
end
-- AdminContextMenu.lua
function AdminContextMenu.OnRemoveAllZombiesClient(zombie)
    ZomboidForge.Patcher.RemoveAllEmitters()

    ZomboidForge.Patcher.AdminContextMenu.OnRemoveAllZombiesClient(zombie)
end


-- keep stored vanilla methods for removal of emitters
ZomboidForge.Patcher.ISSpawnHordeUI = {}

ZomboidForge.Patcher.ISSpawnHordeUI.onRemoveZombies = ISSpawnHordeUI.onRemoveZombies

-- Remove emitters of zombies in radius getting deleted.
-- ISSpawnHordeUI.lua
function ISSpawnHordeUI:onRemoveZombies()
	local radius = self:getRadius() + 1;
	for x=self.selectX-radius, self.selectX + radius do
		for y=self.selectY-radius, self.selectY + radius do
			local sq = getCell():getGridSquare(x,y,self.selectZ);
			if sq then
				for i=sq:getMovingObjects():size()-1,0,-1 do
					local testZed = sq:getMovingObjects():get(i);
					if instanceof(testZed, "IsoZombie") then
                        ---@cast testZed IsoZombie
                        -- remove all emitters
                        testZed:getEmitter():stopAll()

                        -- delete zombie data
                        local trueID = ZomboidForge.pID(testZed)
                        ZomboidForge.DeleteZombieData(trueID)
					end
				end
			end
		end
	end

    ZomboidForge.Patcher.ISSpawnHordeUI.onRemoveZombies(self)
end