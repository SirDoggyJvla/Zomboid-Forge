ZomboidForge.TraitCombinations = {
    {traits = {"EagleEyed", "NightVision"}, a = -0.334577447813991, b = 0.197545720796016},
    {traits = {"EagleEyed"}, a = -0.635844881798067, b = 0.45},
    {traits = {"NightVision"}, a = -0.30342419828057, b = 0.204948474885133},
}

-- Reproduction of the Java method `LightingJNI.calculateVisionCone`.
--
-- This determines the FOV Dot threshold used to check the FOV Dot.
-- https://freakoutstudios.com/dot-product-fov.html
-- https://en.wikipedia.org/wiki/Dot_product
---@param gameCharacter IsoPlayer
---@return number
ZomboidForge.CalculateVisionCone = function(gameCharacter)
    local dayLightStrength = ClimateManager:getInstance():getDayLightStrength()
    print("dayLightStrength = "..tostring(dayLightStrength))
    if gameCharacter:getVehicle() == nil then
        FOV = -0.2
        FOV = FOV - gameCharacter:getStats().fatigue - 0.6
        if FOV > -0.2 then
            FOV = -0.2
        end

        if gameCharacter:getStats().fatigue >= 1.0 then
            FOV = FOV - 0.2
        end

        if gameCharacter:getMoodles():getMoodleLevel(MoodleType.Panic) == 4 then
            FOV = FOV - 0.2
        end

        if gameCharacter:isInARoom() then
            FOV = FOV - 0.2 * (1.0 - dayLightStrength)
        else
            FOV = FOV - 0.7 * (1.0 - dayLightStrength)
        end

        if FOV < -0.9 then
            FOV = -0.9
        end

        for _, combo in ipairs(ZomboidForge.TraitCombinations) do
            if ZomboidForge.hasAllTraits(gameCharacter, combo.traits) then
                FOV = FOV + combo.a * dayLightStrength + combo.b
                break
            end
        end

        -- if gameCharacter:HasTrait("EagleEyed") then
        --     --FOV = FOV + 0.2 * ClimateManager:getInstance():getDayLightStrength()
        --     FOV = FOV - 0.635844881798067*dayLightStrength + 0.45
        -- end

        -- if gameCharacter:HasTrait("NightVision") then
        --     --FOV = FOV + 0.2 * (1.0 - dayLightStrength)
        --     FOV = FOV - 0.297327436881164*dayLightStrength + 0.18
        -- end

        if FOV > 0.0 then
            FOV = 0.0
        end
    else
        if gameCharacter:getVehicle():getHeadlightsOn() and gameCharacter:getVehicle():getHeadlightCanEmmitLight() then
            FOV = 0.8 - 3.0 * (1.0 - dayLightStrength)
            if FOV < -0.8 then
                FOV = -0.8
            end
        else
            FOV = 0.8 - 3.0 * (1.0 - dayLightStrength)
            if FOV < -0.95 then
                FOV = -0.95
            end
        end

        if gameCharacter:HasTrait("NightVision") then
            FOV = FOV + 0.2 * (1.0 - dayLightStrength)
        end

        if FOV > 1.0 then
            FOV = 1.0
        end
    end

    return FOV
end

-- Adapted to output the FOV of `IsoZombie` too. FOV of zombies will depend on their sight value.
---comment
---@param gameCharacter IsoGameCharacter
---@return any
ZomboidForge.GetDotFOV = function(gameCharacter)
    local FOV

    if instanceof(gameCharacter,"IsoPlayer") then
        ---@cast gameCharacter IsoPlayer

        FOV = ZomboidForge.CalculateVisionCone(gameCharacter)

    elseif instanceof(gameCharacter,"IsoZombie") then
        ---@cast gameCharacter IsoZombie

        -- get zombie data
        local trueID = ZomboidForge.pID(gameCharacter)
        local ZType = ZomboidForge.GetZType(trueID)
        local ZombieTable = ZomboidForge.ZTypes[ZType]
        local gender = ZomboidForge.GetGender(gameCharacter)

        -- 1- Eagle
        -- 2- Normal 
        -- 3- Poor
        local sight = gameCharacter.sight
        local FOV_table = ZombieTable.FOV
        if FOV_table and type(FOV_table) == "table" then
            FOV_table = FOV_table[gender] or FOV_table

            FOV = FOV_table[sight] or ZomboidForge.defaultFOV[sight]
        end
    end

    return FOV
end

-- Gives the FOV of `gameCharacter`. It can be `IsoPlayer` or `IsoZombie`.
---comment
---@param gameCharacter IsoGameCharacter
---@return any
ZomboidForge.GetFOV = function(gameCharacter)
    print(math.min(-ZomboidForge.GetDotFOV(gameCharacter)+0.2,0.99))
    return math.deg(math.acos(math.min(-ZomboidForge.GetDotFOV(gameCharacter)+0.2,0.99))*2)*2
end