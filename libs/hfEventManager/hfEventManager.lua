if not LibStub then
    error("LibStub required!")
end

local LIB_NAME = "hfEventManager"
local LIB_VERSION = 1.0

local EventManager, oldVersion = LibStub:NewLibrary(LIB_NAME, LIB_VERSION)

if not EventManager then
    return LibStub:GetLibrary(LIB_NAME)
end

if oldVersion and oldVersion < LIB_VERSION then
    -- check references!
end

EventManager._handlers = EventManager._handlers or {}
EventManager._events = EventManager._events or {}
EventManager._eventFreeList = {}

local function safeUnregisterEvent(self, event)
    self._eventFreeList[#self._eventFreeList + 1] = event

    self:AddHandler("OnUpdate", function()
        for _, event in pairs(self._eventFreeList) do
            if not self._handlers[event] then self._eventFrame:UnregisterEvent(event) end
        end
        self._eventFreeList = {}
    end, { CallOnce = true, HandlerName = "_eventManager_unregisterEvents" })
end

function EventManager:AddHandler(event, handler, _params)
    if not self._handlers[event] then
        self._handlers[event] = {}
        if type(event) == "string" then
            self._eventFrame:RegisterEvent(event)
        end
    end

    local handlerInfo = _params or {}
    handlerInfo.Handler = handler

    local handlerIndex = handlerInfo.HandlerName or #self._handlers[event] + 1
    if self._handlers[event][handlerIndex] then
        return -- TODO: throw?
    end

    self._handlers[event][handlerIndex] = handlerInfo

    return handlerIndex
end

function EventManager:RemoveHandler(event, handler)
    if not self._handlers[event] then
        return 0
    end

    local cpHandlers = {}
    local countRemoved = 0

    for index, handlerInfo in pairs(self._handlers[event]) do
        if index == handler or handlerInfo.Handler == handler then
            countRemoved = countRemoved + 1
        else
            cpHandlers[index] = handlerInfo
        end
    end

    if next(cpHandlers) == nil then
        cpHandlers = nil
        if type(event) == "string" then
            --self._eventFrame:UnregisterEvent(event) -- BUG, see handleEvents below for details
            safeUnregisterEvent(self, event)
        end
    end
    self._handlers[event] = cpHandlers

    return countRemoved
end

local isHandling = false
local function handleEvents(self)
    if isHandling then return end
    isHandling = true

    while #self._events > 0 do
        local eventData = table.remove(self._events, 1)

        if eventData and self._handlers[eventData.Event] then
            local cpHandlers = {}

            for index, handlerInfo in pairs(self._handlers[eventData.Event]) do
                local success, errorMsg = pcall(handlerInfo.Handler, eventData.Event, unpack(eventData.Args))

                if not success then
                    SendSystemChat(string.format("[%s] Error during event '%s': %s", LIB_NAME, tostring(eventData.Event), errorMsg))
                elseif not handlerInfo.CallOnce then
                    cpHandlers[index] = handlerInfo
                end
            end

            if next(cpHandlers) == nil then
                cpHandlers = nil
                if type(eventData.Event) == "string" then
                    --self._eventFrame:UnregisterEvent(eventData.Event) -- BUG: can't unregister the event currently being handled! Use workaround (unregister event on next "OnUpdate" tick)
                    safeUnregisterEvent(self, eventData.Event)
                end
            end
            self._handlers[eventData.Event] = cpHandlers
        elseif not eventData then
            break
        end
    end

    isHandling = false
end

function EventManager:PassEvent(event, ...)
    local eventData = {
        Event = event,
        Args = {...}
    }

    table.insert(self._events, 1, eventData)
    handleEvents(self)
end

function EventManager:QueueEvent(event, ...)
    local eventData = {
        Event = event,
        Args = {...}
    }

    self._events[#self._events + 1] = eventData
    -- will get executed latest after the next "OnUpdate" tick, so no call to handleEvents
end

function EventManager:HandlePendingEvents()
    handleEvents(self)
end

local function init()
    local eventFrame = CreateUIComponent("Frame", "", "UIParent")
    eventFrame._eventManager = EventManager

    eventFrame:SetScripts("OnEvent", "this._eventManager:PassEvent(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)")
    eventFrame:SetScripts("OnUpdate", "this._eventManager:PassEvent(\"OnUpdate\", elapsedTime)")

    EventManager._eventFrame = eventFrame
end
init()

return EventManager