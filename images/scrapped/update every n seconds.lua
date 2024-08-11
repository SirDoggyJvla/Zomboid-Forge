
local zeroTick = 0
local time_before_update = 10 -- seconds

--- SHOULD RUN EVERY TICKS

    local tick_fraction = math.floor((time_before_update*60/zombieList_size)+0.5)

local OnTick = function(tick)
    -- initialize zombieList
    if not zombieList then
        zombieList = client_player:getCell():getZombieList()
    end

    local zombieList_size = zombieList:size()

    -- Update zombie stats
    local zombieIndex = (tick - zeroTick)/tick_fraction
    local zombie
    if zombieIndex >= 0 and zombieIndex%1 == 0 then
        if zombieList_size > zombieIndex then
            zombie = zombieList:get(zombieIndex)
            if ZomboidForge.IsZombieValid(zombie) then
                ZomboidForge.SetZombieData(zombie)
            end
        else
            zeroTick = tick + 1
        end
    end
end