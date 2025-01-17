
local ZomboidForge = require "ZomboidForge_module"

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.NewLarge)
local UI_BORDER_SPACING = 10
local BUTTON_HGT = FONT_HGT_SMALL + 6

local ISSpawnHordeUI_createChildren = ISSpawnHordeUI.createChildren

function ISSpawnHordeUI:createChildren()
    ISSpawnHordeUI_createChildren(self)

    print(self.x)

    local x = UI_BORDER_SPACING+1
	local btnWid = 100
	local y = self:titleBarHeight() + UI_BORDER_SPACING

    x = self.boolOptions.width - UI_BORDER_SPACING*4
    y = y + (BUTTON_HGT + UI_BORDER_SPACING)*4

    self.ZTypeLbl = ISLabel:new(x, y, BUTTON_HGT, "ZType" ,1,1,1,1,UIFont.Small, true)
    self:addChild(self.ZTypeLbl);

    self.ZType = ISComboBox:new(self.ZTypeLbl:getRight() + UI_BORDER_SPACING, y, 100, BUTTON_HGT)
    self.ZType:initialise()
	self:addChild(self.ZType)

    for ztype,data in pairs(ZomboidForge.ZTypes) do
        self.ZType:addOptionWithData(data.name,ztype)
    end
end

function ISSpawnHordeUI:getZType()
	return self.ZType.options[self.ZType.selected].data;
end

function ISSpawnHordeUI:onSpawn()
	local count = self:getZombiesNumber()
	local radius = self:getRadius();
	local outfit = self:getOutfit();
    local ZType = self:getZType()
	-- force female or male chance if you've selected a outfit that's only for male or female
	local femaleChance = nil;
	local knockedDown = false;
	local crawler = false;
	local isFallOnFront = false;
	local isFakeDead = false;
	local isInvulnerable = false;
	local isSitting = false;
	if self.maleOutfits:contains(outfit) and not self.femaleOutfits:contains(outfit) then
		femaleChance = 0;
	end
	if self.femaleOutfits:contains(outfit) and not self.maleOutfits:contains(outfit) then
		femaleChance = 100;
	end
	if self.boolOptions.selected[1] then
		knockedDown = true;
	end
	if self.boolOptions.selected[2] then
		crawler = true;
	end
	if self.boolOptions.selected[3] then
		isFakeDead = true;
	end
	if self.boolOptions.selected[4] then
		isFallOnFront = true;
	end
	if self.boolOptions.selected[5] then
		isInvulnerable = true;
	end
	if self.boolOptions.selected[6] then
		isSitting = true;
	end
	local health = self.healthSlider:getCurrentValue()
	if isClient() then
		SendCommandToServer(string.format("/createhorde2 -x %d -y %d -z %d -count %d -radius %d -crawler %s -isFallOnFront %s -isFakeDead %s -knockedDown %s -isInvulnerable %s -health %s -outfit %s ", self.selectX, self.selectY, self.selectZ, count, radius, tostring(crawler), tostring(isFallOnFront), tostring(isFakeDead), tostring(knockedDown), tostring(isInvulnerable), tostring(health), outfit or ""))
		return
	end
	for i=1,count do
		local x = ZombRand(self.selectX-radius, self.selectX+radius+1);
		local y = ZombRand(self.selectY-radius, self.selectY+radius+1);
		local zombie = addZombiesInOutfit(x, y, self.selectZ, 1, outfit, femaleChance, crawler, isFallOnFront, isFakeDead, knockedDown, isInvulnerable, isSitting, health);
        zombie = zombie:get(0)

        local nonPersistentZData = ZomboidForge.GetNonPersistentZData(zombie)
        nonPersistentZData.ZType = ZType
    end
end