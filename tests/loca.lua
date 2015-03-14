local mainFunc, ts, fEnv = ...

local Loca

local locaTest = "test %s"
local locaTestID = "LOCA_TEST_ID" .. tostring(math.random())

ts:CreateTest("prereq test", function()
    ts:Assert(fEnv.loca == nil)
    ts:Assert(fEnv.locaFormat == nil)

    ts:Assert(Loca == nil)

    Loca = ts:AssertNoThrow(mainFunc)
end)

ts:CreateTest("Loca", function()
    ts:Assert(Loca)
    ts:Assert(Loca.AddMessage)
    ts:Assert(Loca.GetMessage)
    ts:Assert(Loca.RemoveMessage)
    ts:Assert(Loca.LoadFile)
    ts:Assert(Loca.Clear)
end)

ts:CreateTest("Loca:AddMessage", function()
    ts:Assert(Loca:GetMessage(locaTestID) == locaTestID)
    ts:AssertNoThrow(Loca.AddMessage, Loca, locaTestID, locaTest)

    ts:Assert(Loca:GetMessage(locaTestID) == locaTest)

    local errorMsg = ts:AssertThrown(Loca.AddMessage, Loca, locaTestID, locaTest)
    ts:Assert(string.match(errorMsg, "entry already exists"))
    ts:AssertNoThrow(Loca.AddMessage, Loca, locaTestID, locaTest, true)

    errorMsg = ts:AssertThrown(Loca.AddMessage, Loca, {}, locaTest)
    ts:Assert(string.match(errorMsg, "invalid argument"))
    errorMsg = ts:AssertThrown(Loca.AddMessage, Loca, locaTestID, {})
    ts:Assert(string.match(errorMsg, "invalid argument"))
end)

ts:CreateTest("Loca:GetMessage", function()
    local res = ts:AssertNoThrow(Loca.GetMessage, Loca, locaTestID)
    ts:Assert(res == locaTest)

    local locaTestID2 = locaTestID .. "A"
    res = ts:AssertNoThrow(Loca.GetMessage, Loca, locaTestID2)
    ts:Assert(res == locaTestID2)

    local errorMsg = ts:AssertThrown(Loca.GetMessage, Loca, {})
    ts:Assert(string.match(errorMsg, "invalid argument"))
end)

ts:CreateTest("Loca:RemoveMessage", function()
    ts:Assert(Loca:GetMessage(locaTestID) == locaTest)
    ts:AssertNoThrow(Loca.RemoveMessage, Loca, locaTestID)
    ts:Assert(Loca:GetMessage(locaTestID) == locaTestID)

    ts:AssertNoThrow(Loca.RemoveMessage, Loca, locaTestID)

    local errorMsg = ts:AssertThrown(Loca.RemoveMessage, Loca)
    ts:Assert(string.match(errorMsg, "invalid argument"))
end)

ts:CreateTest("Loca:Clear", function()
    Loca:AddMessage(locaTestID, locaTest)

    ts:Assert(Loca:GetMessage(locaTestID) == locaTest)
    ts:AssertNoThrow(Loca.Clear, Loca)
    ts:Assert(Loca:GetMessage(locaTestID) == locaTestID)
end)

ts:CreateTest("Loca:LoadFile", function()
    local loadMessages = ts:Assert(loadfile(LOCA_PATH .. "en.lua"))

    ts:AssertNoThrow(Loca.LoadFile, Loca, "en")
    for locaID, locaString in pairs(loadMessages()) do
        ts:Assert(Loca:GetMessage(locaID) == locaString)
    end
end)

ts:CreateTest("loca", function()
    ts:Assert(fEnv.loca)
    ts:Assert(Loca)
    ts:Assert(Loca.AddMessage)
    ts:Assert(Loca.RemoveMessage)

    local res = ts:AssertNoThrow(loca, locaTestID)
    ts:Assert(res == locaTestID)

    ts:AssertNoThrow(Loca.AddMessage, Loca, locaTestID, locaTest)

    res = ts:AssertNoThrow(loca, locaTestID)
    ts:Assert(res == locaTest)

    res = ts:AssertNoThrow(loca, locaTestID, locaTestID)
    ts:Assert(res == locaTest)

    ts:AssertNoThrow(Loca.RemoveMessage, Loca, locaTestID)
end)

ts:CreateTest("locaFormat", function()
    ts:Assert(fEnv.locaFormat)
    ts:Assert(Loca)
    ts:Assert(Loca.AddMessage)
    ts:Assert(Loca.RemoveMessage)

    local formatted = string.format(locaTest, locaTestID)

    local res = ts:AssertNoThrow(locaFormat, locaTestID)
    ts:Assert(res == locaTestID)

    local errorMsg = ts:AssertThrown(locaFormat, locaTestID, locaTestID) -- string.format

    Loca:AddMessage(locaTestID, locaTest)
    ts:Assert(Loca:GetMessage(locaTestID) == locaTest)
    ts:Assert(string.format(Loca:GetMessage(locaTestID), locaTestID) == formatted)
    ts:Assert(locaFormat(locaTestID, locaTestID) == formatted)
end)

ts:RunTests()
return Loca