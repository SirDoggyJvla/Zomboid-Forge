--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

Core of ZomboidForge

]]--
--[[ ================================================ ]]--

-- requirements
local ZomboidForge = require "ZomboidForge_module"
local Configs = ZomboidForge.Configs

local options = PZAPI.ModOptions:create("ZomboidForge", "Zomboid Forge")

--- NAMETAGS ---
options:addSeparator()
options:addTitle("Nametag")
options:addDescription("Customize your zombie nametag option")

-- ON/OFF
options:addTickBox(
    "ShowNametag",
    getText("IGUI_ZomboidForge_NameTag"),
    true,
    getText("IGUI_ZomboidForge_NameTag_Tooltip")
)

-- AlwaysOn
options:addTickBox(
    "AlwaysOn",
    getText("IGUI_ZomboidForge_AlwaysOn"),
    false,
    getText("IGUI_ZomboidForge_AlwaysOn_Tooltip")
)

-- NoAimingNeeded
options:addTickBox(
    "NoAimingNeeded",
    getText("IGUI_ZomboidForge_NoAimingNeeded"),
    false,
    getText("IGUI_ZomboidForge_NoAimingNeeded_Tooltip")
)

-- WhenZombieIsTargeting
options:addTickBox(
    "WhenZombieIsTargeting",
    getText("IGUI_ZomboidForge_WhenZombieIsTargeting"),
    false,
    getText("IGUI_ZomboidForge_WhenZombieIsTargeting_Tooltip")
)

-- WhenZombieIsAttacking
options:addTickBox(
    "WhenZombieIsAttacking",
    getText("IGUI_ZomboidForge_WhenZombieIsAttacking"),
    true,
    getText("IGUI_ZomboidForge_WhenZombieIsAttacking_Tooltip")
)

-- Background
options:addTickBox(
    "Background",
    getText("IGUI_ZomboidForge_Background"),
    false,
    getText("IGUI_ZomboidForge_Background_Tooltip")
)

-- Nametag duration
options:addSlider(
    "NametagDuration",
    "Nametag duration [seconds]",
    1.5,10,0.5,2,
    "How long the nametag lasts."
)

-- Vertical offset
options:addSlider(
    "VerticalOffset",
    getText("IGUI_ZomboidForge_VerticalOffset"),
    -20,20,1,0,
    getText("IGUI_ZomboidForge_VerticalOffset_Tooltip")
)

-- Radius
options:addSlider(
    "Radius",
    getText("IGUI_ZomboidForge_Radius"),
    1,7,1,2,
    getText("IGUI_ZomboidForge_Radius_Tooltip")
)

-- Fonts
local FONT_LIST = Configs.FONT_LIST
local comboBox = options:addComboBox("Font",getText("IGUI_ZomboidForge_Fonts"),getText("IGUI_ZomboidForge_Fonts_Tooltip"))
comboBox:addItem(FONT_LIST[1],true) -- add first in the list as default
for i = 2,#FONT_LIST do
    comboBox:addItem(FONT_LIST[i]) -- add the other options
end

-- options:addSeparator()




-- This is a helper function that will automatically populate the "config" table.
--- Retrieve each option as: config."ID"
options.apply = function(self)
    for k,v in pairs(self.dict) do
        if v.type == "multipletickbox" then
            for i=1, #v.values do
                Configs[(k.."_"..tostring(i))] = v:getValue(i)
            end
        elseif v.type ~= "button" then
            Configs[k] = v:getValue()
        end
    end
end

Events.OnMainMenuEnter.Add(function()
    options:apply()
end)