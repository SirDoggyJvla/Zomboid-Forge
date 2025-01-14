--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

Lua object to delay actions for ZomboidForge

]]--
--[[ ================================================ ]]--

-- requirements
local ZomboidForge = require "ZomboidForge_module"

ZomboidForge.DelayedActions = {ActionList = {},}
local DelayedActions = ZomboidForge.DelayedActions



DelayedActions.AddNewAction = function(newAction)
    table.insert(DelayedActions.ActionList,newAction)
end

DelayedActions.UpdateDelayedActions = function()
    local ActionList = DelayedActions.ActionList
    for i = #ActionList,1,-1 do
        local action = ActionList[i]

        --- VERIFY IF SHOULD RUN ACTION ---
        local pass

        repeat -- used to be able to skip other checks if one passes
            -- check tick delay passes
            local ticks = action._ticksDelay
            if ticks then
                action._ticksDelay = ticks - 1
                if action._ticksDelay <= 0 then
                    pass = true
                    break
                end
            end

            -- cache check function
            local _shouldRun = action._shouldRun
            if _shouldRun then
                local fct = _shouldRun.fct
                if fct and fct(action) then
                    -- reduce validation function ticks if present
                    local ticks = _shouldRun.ticks
                    if ticks then
                        _shouldRun.ticks = ticks - 1
                    end

                    -- if uses delay per validation, verify it passes
                    if not ticks or _shouldRun.ticks <= 0 then
                        pass = true
                    end
                end
            end
        until true

        -- check if action is valid to be ran
        if pass then
            action.fct(unpack(action.args)) -- unpack variables to be read by function
            table.remove(ActionList,i) -- remove action from the list
        end
    end
end






--- _shouldRun FUNCTIONS ---

---Function used to verify if the zombie had its model loaded in to set visuals.
---@param action table
---@return boolean
ZomboidForge.IsValidForInitialization = function(action)
    -- action.args[1] needs to be IsoZombie
    return action.args[1]:hasActiveModel()
end

