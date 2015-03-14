local libFunc, ts, libName = ...

ts:Assert(libName == "hfEventManager", "Wrong library")

local lib
ts:CreateTest(libName, "runTest", function()
    lib = ts:AssertNoThrow(libFunc)

    ts:Assert(lib)
    ts:Assert(lib.AddHandler)
    ts:Assert(lib.RemoveHandler)
    ts:Assert(lib.PassEvent)
    ts:Assert(lib.QueueEvent)
    ts:Assert(lib.HandlePendingEvents)
end)

local eventA, eventB = {}, {}
local testA, testB = 0, false
local eventHandlerA = function() testA = testA + 1 end
local nameA = "testA"

local setupA, setupB
local cleanupA, cleanupB

ts:CreateTest(libName, "addEventNoParams", function()
    ts:Assert(lib, "prereq error")
    ts:Assert(lib.AddHandler, "prereq error")
    ts:Assert(lib.PassEvent, "prereq error")

    testA = 0
    ts:AssertNoThrow(lib.PassEvent, lib, eventA)
    local countA = testA

    setupA = function()
        local index = ts:AssertNoThrow(lib.AddHandler, lib, eventA, eventHandlerA)
        ts:Assert(index, "addition not successful")
    end
    ts:AssertNoThrow(setupA)

    testA = 0
    ts:AssertNoThrow(lib.PassEvent, lib, eventA)
    ts:Assert(testA == countA + 1)
end)

ts:CreateTest(libName, "addEventHandlerByName", function()
    ts:Assert(lib, "prereq error")
    ts:Assert(lib.AddHandler, "prereq error")
    ts:Assert(lib.PassEvent, "prereq error")

    local params = { HandlerName = nameA }

    testA = 0
    ts:AssertNoThrow(lib.PassEvent, lib, eventA)
    local countA = testA

    local name = ts:AssertNoThrow(lib.AddHandler, lib, eventA, eventHandlerA, params)
    ts:Assert(name == nameA)

    testA = 0
    ts:AssertNoThrow(lib.PassEvent, lib, eventA)
    ts:Assert(testA == countA + 1)

    name = ts:AssertNoThrow(lib.AddHandler, lib, eventA, eventHandlerA, params)
    ts:Assert(name == nil)

    testA = 0
    ts:AssertNoThrow(lib.PassEvent, lib, eventA)
    ts:Assert(testA == countA + 1)
end)

ts:CreateTest(libName, "removeEventHandlerByName", function()
    ts:Assert(lib, "prereq error")
    ts:Assert(lib.RemoveHandler, "prereq error")
    ts:Assert(lib.PassEvent, "prereq error")

    testA = 0
    ts:AssertNoThrow(lib.PassEvent, lib, eventA)
    local countA = testA

    local countRemoved = ts:AssertNoThrow(lib.RemoveHandler, lib, eventA, nameA)
    ts:Assert(countRemoved == 1)

    testA = 0
    ts:AssertNoThrow(lib.PassEvent, lib, eventA)
    ts:Assert(testA == countA - 1)


end)

ts:CreateTest(libName, "removeEvent", function()
    ts:Assert(lib, "prereq error")
    ts:Assert(lib.RemoveHandler, "prereq error")
    ts:Assert(lib.PassEvent, "prereq error")

    -- test for registered handler
    testA = 0
    ts:AssertNoThrow(lib.PassEvent, lib, eventA)
    ts:Assert(testA > 0)

    -- remove once
    cleanupA = function()
        local count = ts:AssertNoThrow(lib.RemoveHandler, lib, eventA, eventHandlerA)
        ts:Assert(count == 1)
    end
    ts:AssertNoThrow(cleanupA)

    -- nothing left to remove!
    local count = ts:AssertNoThrow(lib.RemoveHandler, lib, eventA, eventHandlerA)
    ts:Assert(count == 0)

    -- test for actual removal!
    testA = 0
    ts:AssertNoThrow(lib.PassEvent, lib, eventA)
    ts:Assert(testA == 0)
end)

ts:CreateTest(libName, "addEventCallOnce", function()
    ts:Assert(lib, "prereq error")
    ts:Assert(lib.AddHandler, "prereq error")
    ts:Assert(lib.PassEvent, "prereq error")

    local params = { CallOnce = true }
    local index = ts:AssertNoThrow(lib.AddHandler, lib, eventA, eventHandlerA, params)
    ts:Assert(index)

    testA = 0
    ts:AssertNoThrow(lib.PassEvent, lib, eventA)
    ts:Assert(testA == 1)

    testA = 0
    ts:AssertNoThrow(lib.PassEvent, lib, eventA)
    ts:Assert(testA == 0)

    local count = ts:AssertNoThrow(lib.RemoveHandler, lib, eventA, index)
    ts:Assert(count == 0)
end)

ts:CreateTest(libName, "passEvent", function()
    ts:Assert(lib, "prereq error")
    ts:Assert(lib.PassEvent, "prereq error")

    setupA()

    testA = 0
    ts:AssertNoThrow(lib.PassEvent, lib, eventA)
    ts:Assert(testA == 1)

    cleanupA()
end)

ts:CreateTest(libName, "queueEvent", function()
    ts:Assert(lib, "prereq error")
    ts:Assert(lib.QueueEvent, "prereq error")
    ts:Assert(lib.HandlePendingEvents, "prereq error")

    setupA()

    testA = 0
    ts:AssertNoThrow(lib.QueueEvent, lib, eventA)
    ts:Assert(testA == 0)
    ts:AssertNoThrow(lib.HandlePendingEvents, lib)
    ts:Assert(testA == 1)

    cleanupA()
end)

ts:RunTests(libName)
return lib