local curMouseOverDelegate

local function eventHandler_OnUnitDelegateEnter(self)
    curMouseOverDelegate = self
end

local function eventHandler_OnUnitDelegateLeave(self)
    curMouseOverDelegate = nil
end

local function executeAction(unitDelegate, action)
    -- TODO
end

local function lookupAction(unitDelegate, key, modifier)
    -- TODO
end

local function checkForOverrideAction(unitDelegate, action)
    -- TODO
end

function setupDelegateHandlers(unitDelegate)
    unitDelegate.onEnter = eventHandler_OnUnitDelegateEnter
    unitDelegate.onLeave = eventHandler_OnUnitDelegateLeave
    return unitDelegate
end

function handleInput(key, modifiers)
    if not curMouseOverDelegate then return end

    local action = lookupAction(curMouseOverDelegate, key, modifiers)
    action = checkForOverrideAction(curMouseOverDelegate, action)

    return executeAction(curMouseOverDelegate, action)
end