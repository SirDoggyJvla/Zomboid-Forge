--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

This file defines the Mod Options for the mod Zomboid Forge

]]--
--[[ ================================================ ]]--

local name = getText("IGUI_ZomboidForge_Zombie")
local ZFModOptions = {
	options_data = {
		-- allows client to chose to activate nametags or not
		NameTag = {
			-- properties
			name = "IGUI_ZomboidForge_NameTag",
			tooltip = "IGUI_ZomboidForge_NameTag_Tooltip",
			default = true,
		},

		-- allows client to chose nametag placement
		VerticalPlacement = {
			-- choices
			getText("IGUI_ZomboidForge_VerticalPlacement1"),
			getText("IGUI_ZomboidForge_VerticalPlacement2"),
			getText("IGUI_ZomboidForge_VerticalPlacement3"),
			getText("IGUI_ZomboidForge_VerticalPlacement4"),
			getText("IGUI_ZomboidForge_VerticalPlacement5"),
			getText("IGUI_ZomboidForge_VerticalPlacement6"),
			getText("IGUI_ZomboidForge_VerticalPlacement7"),

			-- properties
			name = "IGUI_ZomboidForge_VerticalPlacement",
			tooltip = "IGUI_ZomboidForge_VerticalPlacement_Tooltip",
			default = 4,
		},

		-- allows client to have nametags always on. If on server, sandbox option
		-- allowing it needs to be active
		AlwaysOn = {
			-- properties
			name = getText("IGUI_ZomboidForge_AlwaysOn"),
			tooltip = getText("IGUI_ZomboidForge_AlwaysOn_Tooltip"),
			default = false,
		},

		-- by default, the player needs to aim, but this option allows to just put the cursor
		-- on the zombie to show the nametag
		NoAimingNeeded = {
			-- properties
			name = getText("IGUI_ZomboidForge_NoAimingNeeded"),
			tooltip = getText("IGUI_ZomboidForge_NoAimingNeeded_Tooltip"),
			default = false,
		},

		-- adds a black background behind the nametag
		Background = {
			-- properties
			name = getText("IGUI_ZomboidForge_Background"),
			tooltip = getText("IGUI_ZomboidForge_Background_Tooltip"),
			default = false,
		},

		-- show nametag when zombie has a target
		WhenZombieIsTargeting = {
			-- properties
			name = getText("IGUI_ZomboidForge_WhenZombieIsTargeting"),
			tooltip = getText("IGUI_ZomboidForge_WhenZombieIsTargeting_Tooltip"),
			default = false,
		},

		-- show nametag when zombie is attacking
		WhenZombieIsAttacking = {
			-- properties
			name = getText("IGUI_ZomboidForge_WhenZombieIsAttacking"),
			tooltip = getText("IGUI_ZomboidForge_WhenZombieIsAttacking_Tooltip"),
			default = true,
		},

		-- ticks before nametag disappears
		Ticks = {
			-- choices
			getText("IGUI_ZomboidForge_Ticks1"),
			getText("IGUI_ZomboidForge_Ticks2"),
			getText("IGUI_ZomboidForge_Ticks3"),
			getText("IGUI_ZomboidForge_Ticks4"),
			getText("IGUI_ZomboidForge_Ticks5"),
			getText("IGUI_ZomboidForge_Ticks6"),
			getText("IGUI_ZomboidForge_Ticks7"),
			getText("IGUI_ZomboidForge_Ticks8"),
			getText("IGUI_ZomboidForge_Ticks9"),
			getText("IGUI_ZomboidForge_Ticks10"),
			getText("IGUI_ZomboidForge_Ticks11"),
			getText("IGUI_ZomboidForge_Ticks12"),
			getText("IGUI_ZomboidForge_Ticks13"),
			getText("IGUI_ZomboidForge_Ticks14"),
			getText("IGUI_ZomboidForge_Ticks15"),
			getText("IGUI_ZomboidForge_Ticks16"),
			getText("IGUI_ZomboidForge_Ticks17"),
			getText("IGUI_ZomboidForge_Ticks18"),
			getText("IGUI_ZomboidForge_Ticks19"),
			getText("IGUI_ZomboidForge_Ticks20"),

			-- properties
			name = getText("IGUI_ZomboidForge_Ticks"),
			tooltip = getText("IGUI_ZomboidForge_Ticks_Tooltip"),
			default = 2,
		},

		-- radius around cursor to show nametag
		Radius = {
			-- choices
			getText("IGUI_ZomboidForge_Radius1"),
			getText("IGUI_ZomboidForge_Radius2"),
			getText("IGUI_ZomboidForge_Radius3"),
			getText("IGUI_ZomboidForge_Radius4"),
			getText("IGUI_ZomboidForge_Radius5"),
			getText("IGUI_ZomboidForge_Radius6"),
			getText("IGUI_ZomboidForge_Radius7"),
			getText("IGUI_ZomboidForge_Radius8"),

			-- properties
			name = getText("IGUI_ZomboidForge_Radius"),
			tooltip = getText("IGUI_ZomboidForge_Radius_Tooltip"),
			default = 2,
		},

		-- lets client chose the nametag font
		Fonts = {
			-- choices
			"Handwritten",
			"AutoNormLarge",
			"AutoNormMedium",
			"AutoNormSmall",
			"Code",
			"Cred1",
			"Cred2",
			"DebugConsole",
			"Dialogue",
			"Intro",
			"Large",
			"MainMenu1",
			"MainMenu2",
			"Massive",
			"Medium",
			"MediumNew",
			"NewLarge",
			"NewMedium",
			"NewSmall",
			"Small",
			"Title",

			-- properties
			name = getText("IGUI_ZomboidForge_Fonts"),
			tooltip = getText("IGUI_ZomboidForge_Fonts_Tooltip"),
			default = 1,
		},
	},

	-- option informations
	mod_id = 'ZomboidForge',
	mod_shortname = name,
	mod_fullname = name,
}

-- adds the options
if ModOptions and ModOptions.getInstance then
    ModOptions:getInstance(ZFModOptions)
end

return ZFModOptions