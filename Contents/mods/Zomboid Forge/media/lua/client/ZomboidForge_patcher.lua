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
local tostring = tostring --tostring function

--- import module from ZomboidForge
local ZomboidForge = require "ZomboidForge_module"

--- Import original methods and keep them stored
ZomboidForge.Patcher = {}
ZomboidForge.Patcher.DebugContextMenu = {}
ZomboidForge.Patcher.AdminContextMenu = {}

--#region Patcher to remove functions to make sure emitters are removed too

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

--#endregion

--#region Patcher to ATRO

if getActivatedMods():contains("Advanced_Trajectorys_Realistic_Overhaul") then

require "Advanced_trajectory_core"

print("Replacing Advanced_trajectory.checkontick()")

-----------------------------------
-----BODY PART LOGIC FUNC SECT-----
-----------------------------------
function Advanced_trajectory.checkontick()
    Advanced_trajectory.boomontick()
    Advanced_trajectory.OnPlayerUpdate()

    local timemultiplier = getGameTime():getMultiplier()

    for la,lb in pairs(Advanced_trajectory.damagedisplayer) do

        lb[1] = lb[1] - timemultiplier
        if lb[1] < 0 then
            lb = nil
        else

            lb[3] = lb[3] + timemultiplier
            lb[4] = lb[4] - timemultiplier
            lb[2]:AddBatchedDraw(lb[3], lb[4], true)

            -- print(Advanced_trajectory.damagedisplayer[3] - Advanced_trajectory.damagedisplayer[5]) 
        end
    end

    local tablenow = Advanced_trajectory.table
    -- print(#tablenow)
    -- print(getGameTime():getMultiplier())

    for kt, vt in pairs(tablenow) do

        Advanced_trajectory.itemremove(vt[1])

        local tablenowz12_ = vt[12] * 0.35

        -- RADON NOTES: PERHAPS THIS DETERMINES IF BULLET SHOULD DISAPPEAR/BREAK IF COLLIDE WITH SOMETHING
        if Advanced_trajectory.aimlevels then
            vt[2] = getWorld():getCell():getOrCreateGridSquare(vt[4][1], vt[4][2], Advanced_trajectory.aimlevels)
        else
            vt[2] = getWorld():getCell():getOrCreateGridSquare(vt[4][1], vt[4][2], vt[4][3])
        end

        vt[22]["pos"] = {Advanced_trajectory.mathfloor(vt[4][1]), Advanced_trajectory.mathfloor(vt[4][2])}


       if vt[2] then
            -- bullet square, dirc, offset, offset, nonsfx
            if Advanced_trajectory.checkiswallordoor(vt[2],vt[5],vt[4],vt[20],vt["nonsfx"]) and not vt[15] then
                --print("***********Bullet collided with wall.************")
                --print("Wallcarmouse: ", vt["wallcarmouse"])
                --print("Wallcarzombie: ", vt["wallcarzombie"])
                --print("Cell: ", vt[4][1],", ",vt[4][2],", ",vt[4][3])
                if  vt[9] =="Grenade" or vt["wallcarmouse"] or vt["wallcarzombie"]then

                    if vt[22][2] > 0 then
                        Advanced_trajectory.boomsfx(vt[2],vt["boomsfx"][1],vt["boomsfx"][2],vt["boomsfx"][3])
                    end
                    if not vt["nonsfx"]  then
                        -- print("Boom")
                        Advanced_trajectory.Boom(vt[2],vt[22])
                    end
                end

                Advanced_trajectory.itemremove(vt[1]) 
                tablenow[kt]=nil

                break
            end

            -- reassign so visual offset of bullet doesn't go whack
            if getWorld():getCell():getOrCreateGridSquare(vt[4][1], vt[4][2], vt[4][3]) then
                vt[2] = getWorld():getCell():getOrCreateGridSquare(vt[4][1], vt[4][2], vt[4][3])
            end

            local mathfloor = Advanced_trajectory.mathfloor


            vt[1] = Advanced_trajectory.additemsfx(vt[2], vt[14] .. tostring(vt[8]), mathfloor(vt[4][1]), mathfloor(vt[4][2]), mathfloor(vt[4][3]))
            local spnumber = (vt[3][1]^2 + vt[3][2]^2) ^ 0.5* tablenowz12_
            vt[7] = vt[7] - spnumber
            vt[17] = vt[17] + spnumber

            -- NOT SURE WHAT WEAPON THIS CHECKS SINCE THERE ARE NO FLAMETHROWERS IN VANILLA
            if vt[9] == "flamethrower" then

                -- print(vt[17])
                if vt[17] >3 then
                    vt[17] = 0
                    vt[21]=vt[21]+1
                    vt[4] = Advanced_trajectory.twotable(vt[20])
                end
                -- print(vt[21])
                if vt[21] >4 then
                    Advanced_trajectory.itemremove(vt[1]) 
                    tablenow[kt]=nil
                    --print("Broke bullet FLAMETHROWER")
                    break
                end

            -- WHERE BULLET BBEAKS WHEN OUT OF RANGE. CHECKS IF REMAINING DISTANCE IS LESS THAN 0 AND WEAPON IS NOT GRENADE.
            elseif vt[7]<0 and vt[9] ~= "Grenade"  then

                if vt["wallcarmouse"] or vt["wallcarzombie"]then

                    if vt[22][2] > 0 then
                        Advanced_trajectory.boomsfx(vt[2],vt["boomsfx"][1],vt["boomsfx"][2],vt["boomsfx"][3])
                    end
                    if not vt["nonsfx"]  then
                        Advanced_trajectory.Boom(vt[2],vt[22])
                    end
                end



                Advanced_trajectory.itemremove(vt[1])
                tablenow[kt]=nil

                determineArrowSpawn(vt[2], false)

                --print("Broke bullet GRENADE")
                break
            end


            vt[5] = vt[5] + vt[10]
            if vt[1] then
                vt[1]:setWorldZRotation(vt[5])
            end

            vt[4][1] = vt[4][1]+tablenowz12_ * vt[3][1]
            vt[4][2] = vt[4][2]+tablenowz12_ * vt[3][2]

            -- BREAKS GRENADE/THROWABLES 
            if  vt["isparabola"]  then

                vt[4][3] = 0.5-vt["isparabola"]*vt[17]*(vt[17]-vt[18])

                if vt[4][3]<=0.3  then
                    if not vt["nonsfx"]  then
                        Advanced_trajectory.Boom(vt[2],vt[22])
                    end

                    if vt[22][2] > 0 then
                        Advanced_trajectory.boomsfx(vt[2],vt["boomsfx"][1],vt["boomsfx"][2],vt["boomsfx"][3])
                    end
                    Advanced_trajectory.itemremove(vt[1])
                    tablenow[kt]=nil
                    --print("Broke bullet PARABOLA")
                    break
                end

            end

            -- NOTES IMPORTANT, WORK HERE: Headshot, Bodypart, Footpart
            if  (vt[9] ~= "Grenade" or (vt[22][8]or 0) > 0 or vt["wallcarzombie"]) and  not vt["wallcarmouse"] then

                -- direction of bullet
                local angleammo = vt[5]

                -- offset of bullet
                local angleammooff = 0

                if angleammo >= 135 and angleammo <= 180 then
                    angleammooff = angleammo - 135
                elseif angleammo >= -180 and angleammo <= -135 then
                    angleammooff = angleammo+180 +45
                elseif angleammo >= -135 and angleammo <= -45 then
                    angleammooff = -angleammo - 45 
                end

                angleammooff = angleammooff / 30
                --print('angleammo: ', angleammo)
                --print('angleammooff: ', angleammooff)

                local admindel = vt["animlevels"] - math.floor(vt[4][3])
                local shootlevel =  vt[4][3] + admindel

                if  vt["isparabola"] then
                    shootlevel  = vt[4][3]
                end

                --print('admindel (for x and y): ', admindel)
                --print('shootlevel (z): ', shootlevel)

                local saywhat = ""

                -- returns object zombie and player that was shot
                local Zombie,Playershot =  Advanced_trajectory.getShootzombie({vt[4][1] + admindel * 3, vt[4][2]  + admindel * 3, shootlevel, angleammo}, 1 + angleammooff, {vt[20][1], vt[20][2], vt[20][3]}, vt["missedShot"])

                -- headshot on zombie
                local damagezb = 0

                -- headshot damage multiplier on player (will be multiplied by vt6 in player's if statement)
                local damagepr = 0

                -- steady aim wins the game, else bodyshot damage 
                if Advanced_trajectory.aimnumBeforeShot <= 5 then
                    damagezb = Advanced_trajectory.HeadShotDmgZomMultiplier            -- zombie headshot aka strong headshot
                    damagepr = Advanced_trajectory.HeadShotDmgPlayerMultiplier         -- player headshot aka strong headshot
                    saywhat = "IGUI_Headshot (STRONG): " .. Advanced_trajectory.aimnumBeforeShot
                else
                    damagezb = Advanced_trajectory.BodyShotDmgZomMultiplier            -- zombie bodyshot aka weak headshot
                    damagepr = Advanced_trajectory.BodyShotDmgPlayerMultiplier         -- player bodyshot aka weak headshot
                    saywhat = "IGUI_Headshot (WEAK): " .. Advanced_trajectory.aimnumBeforeShot
                end
                -- vt[4] is offset xyz
                if not Zombie and not Playershot  then
                    Zombie,Playershot = Advanced_trajectory.getShootzombie({vt[4][1] - 0.9 + angleammooff*0.45 + admindel*3, vt[4][2] - 0.9 + angleammooff*0.45 + admindel*3, shootlevel, angleammo}, 2, {vt[20][1], vt[20][2], vt[20][3]}, vt["missedShot"])
                    damagezb = Advanced_trajectory.BodyShotDmgZomMultiplier            -- zombie bodyshot
                    damagepr = Advanced_trajectory.BodyShotDmgPlayerMultiplier         -- player bodyshot
                    saywhat = "IGUI_Bodyshot"
                end

                if not getSandboxOptions():getOptionByName("Advanced_trajectory.DebugRemoveFootHitbox"):getValue() then
                    if not Zombie and not Playershot then
                        Zombie,Playershot = Advanced_trajectory.getShootzombie({vt[4][1] - 1.8 + angleammooff*0.9 + admindel*3, vt[4][2] - 1.8 + angleammooff*0.9 + admindel*3, shootlevel, angleammo}, 3, {vt[20][1], vt[20][2], vt[20][3]}, vt["missedShot"])
                        damagezb = Advanced_trajectory.FootShotDmgZomMultiplier            -- zombie footshot
                        damagepr = Advanced_trajectory.FootShotDmgPlayerMultiplier         -- player footshot
                        saywhat = "IGUI_Footshot"
                    end
                end

                -------------------------------------
                ---DEAL WITH ALIVE PLAYER WHEN HIT---
                -------------------------------------
                -- NOTES: if it's a non friendly player is shot at, determine damage done and which body part is affected
                -- vt[19] is the player itself (you)
                -- the player shot can not be the client player (you can't shoot you)
                if not vt["nonsfx"] and Playershot and vt[19] and Playershot ~= vt[19] and (Faction.getPlayerFaction(Playershot)~=Faction.getPlayerFaction(vt[19]) or not Faction.getPlayerFaction(Playershot))     then

                    --Playershot:setX(Playershot:getX()+0.15*vt[3][1])
                    --Playershot:setY(Playershot:getY()+0.15*vt[3][2])
                    Playershot:addBlood(100)

                    -- isClient() returns true if the code is being run in MP
                    if isClient() then
                        sendClientCommand("ATY_shotplayer", "true", {vt[19]:getOnlineID(), Playershot:getOnlineID(), damagepr, vt[6], Advanced_trajectory.HeadShotDmgPlayerMultiplier, Advanced_trajectory.BodyShotDmgPlayerMultiplier, Advanced_trajectory.FootShotDmgPlayerMultiplier})
                    else
                        damagePlayershot(Playershot, damagepr, vt[6], Advanced_trajectory.HeadShotDmgPlayerMultiplier, Advanced_trajectory.BodyShotDmgPlayerMultiplier, Advanced_trajectory.FootShotDmgPlayerMultiplier)
                    end

                    Advanced_trajectory.itemremove(vt[1])
                    tablenow[kt]=nil
                    break
                end

                -------------------------------------
                ---DEAL WITH ALIVE ZOMBIE WHEN HIT--
                -------------------------------------
                if Zombie and Zombie:isAlive() then

                    -- If zombies are alive, announce the body part it hits if the advanced trajectory option is enabled
                    if vt[19] and getSandboxOptions():getOptionByName("Advanced_trajectory.callshot"):getValue() then
                        vt[19]:Say(getText(saywhat))
                    end

                    if getSandboxOptions():getOptionByName("Advanced_trajectory.DebugEnableVoodoo"):getValue() then
                        if isClient() then
                            sendClientCommand("ATY_shotplayer", "true", {vt[19]:getOnlineID(), vt[19]:getOnlineID(), damagezb, vt[6]*0.1, Advanced_trajectory.HeadShotDmgZomMultiplier, Advanced_trajectory.BodyShotDmgZomMultiplier, Advanced_trajectory.FootShotDmgZomMultiplier})
                        else
                            damagePlayershot(vt[19], damagezb, vt[6]*0.1, Advanced_trajectory.HeadShotDmgZomMultiplier, Advanced_trajectory.BodyShotDmgZomMultiplier, Advanced_trajectory.FootShotDmgZomMultiplier)
                        end
                    end


                    if vt["wallcarzombie"] or vt[9] == "Grenade"then

                        vt[22]["zombie"] = Zombie
                        if vt[22][2] > 0 then
                            Advanced_trajectory.boomsfx(vt[2])
                        end
                        if not vt["nonsfx"] then
                            Advanced_trajectory.Boom(vt[2], vt[22])
                        end

                        Advanced_trajectory.itemremove(vt[1])
                        tablenow[kt] = nil
                        break

                    elseif not vt["nonsfx"]  then
                        if vt[9] == "flamethrower" then
                            Zombie:setOnFire(true)

                            -- Uncomment this section if you want to handle GrenadeLauncher differently
                            -- elseif vt[9] == "GrenadeLauncher" then
                            --     tanksuperboom(vt[2])
                            -- end
                        end

                        if isClient() then
                            sendClientCommand("ATY_cshotzombie","true",{Zombie:getOnlineID(),vt[19]:getOnlineID()})
                        end

                        damagezb = damagezb * vt[6] * 0.1

                        if not Advanced_trajectory.hasFlameWeapon then
                            -- give xp upon hit
                            local hitXP = getSandboxOptions():getOptionByName("Advanced_trajectory.XPHitModifier"):getValue()
                            triggerEvent("OnWeaponHitCharacter", vt[19], Zombie, vt[19]:getPrimaryHandItem(), damagezb) -- OnWeaponHitXp From "KillCount",used(wielder,victim,weapon,damage)
                            if isServer() == false then
                                Events.OnWeaponHitXp.Add(vt[19]:getXp():AddXP(Perks.Aiming, hitXP));
                            end
                        end

                        -- subtract health from zombie 
                        --Zombie:setHealth(Zombie:getHealth()-damagezb)
                        Zombie:setHitReaction("Shot")
                        Zombie:addBlood(getSandboxOptions():getOptionByName("AT_Blood"):getValue())

                        -- if zombie's health is very low, just kill it (recall full health is over 140) and give xp like usual
                        if Zombie:getHealth() <= 0.1 then
                            -- if zombie's health is very low, just kill it (recall full health is over 140) and give xp like usual                         
                            if vt[19] then
                                vt[19]:setZombieKills(vt[19]:getZombieKills()+1)

                                if not Advanced_trajectory.hasFlameWeapon then
                                    local killXP = getSandboxOptions():getOptionByName("Advanced_trajectory.XPKillModifier"):getValue()
                                    -- multiplier to 0.67
                                    triggerEvent("OnWeaponHitXp",vt[19], vt[19]:getPrimaryHandItem(), Zombie, damagezb) -- OnWeaponHitXp From "KillCount",used(wielder,weapon,victim,damage)

                                    if isServer() == false then
                                        Events.OnWeaponHitXp.Add(vt[19]:getXp():AddXP(Perks.Aiming, killXP));
                                    end
                                end
                            end
                        end

                        if getSandboxOptions():getOptionByName("Advanced_trajectory.DebugEnableBow"):getValue() then
                            checkBowAndCrossbow(vt[19], Zombie)
                        end
                    end

                    Advanced_trajectory.itemremove(vt[1])

                    -- set penetration to 1 if null, subtract after zombie is hit
                    if not vt["ThroNumber"] then vt["ThroNumber"] = 1 end
                    vt["ThroNumber"] = vt["ThroNumber"]-1

                    -- reduce damage after penetration
                    local penDmgReduction = getSandboxOptions():getOptionByName("Advanced_trajectory.penDamageReductionMultiplier"):getValue()
                    vt[6] = penDmgReduction * vt[6]

                    -- break if iscantthrough and penetration is 0
                    if not vt[11] and (vt["ThroNumber"] <= 0  )then
                        tablenow[kt]=nil
                        --print("Broke bullet PENETRATION")
                        break
                    end
                end
            end
        end
    end
end

Events.OnTick.Remove(Advanced_trajectory.checkontick)
Events.OnTick.Add(Advanced_trajectory.checkontick)

-- end patch
end



--#endregion