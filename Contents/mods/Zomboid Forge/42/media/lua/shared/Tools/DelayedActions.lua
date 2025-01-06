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



DelayedActions.AddNewAction = function(fct,ticks,args)
    -- function
    local newAction = {
        fct = fct,
        ticks = ticks,
        args = args,
    }

    table.insert(DelayedActions.ActionList,newAction)
end

DelayedActions.UpdateDelayedActions = function()
    local ActionList = DelayedActions.ActionList
    for i = #ActionList,1,-1 do
        local action = ActionList[i]
        action.ticks = action.ticks - 1

        if action.ticks <= 0 then
            action.fct(unpack(action.args))
            table.remove(ActionList,i)
        end
    end
end