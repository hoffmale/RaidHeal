local mainFunc, ts, fEnv = ...

local results
ts:CreateTest("prereq test", function()
    ts:Assert(fEnv.addCommand == nil)
    ts:Assert(fEnv.removeCommand == nil)
    ts:Assert(fEnv.runCommand == nil)

    results = { ts:AssertNoThrow(mainFunc) }
end)

local testVar = false
local testError = "testVar already set"
local testCommand = function() if not testVar then testVar = true else error(testError) end end
local testName = "test"

ts:CreateTest("addCommand", function()
    ts:Assert(fEnv.addCommand)

    -- dont throw for normal addition and dont call the function
    ts:AssertNoThrow(addCommand, testName, testCommand)
    ts:Assert(testVar == false)

    -- throw if any of the 2 arguments are not of the required type
    local errorMsg = ts:AssertThrown(addCommand, testVar, testCommand)
    ts:Assert(string.match(errorMsg, "invalid argument"))

    errorMsg = ts:AssertThrown(addCommand, testName, testVar)
    ts:Assert(string.match(errorMsg, "invalid argument"))

    -- throw if trying to add the same command name twice
    errorMsg = ts:AssertThrown(addCommand, testName, testCommand)
    ts:Assert(string.match(errorMsg, "command already exists"))
end)

ts:CreateTest("runCommand", function()
    ts:Assert(fEnv.runCommand)

    -- dont throw for valid calls, also call the command handler!
    testVar = false
    ts:AssertNoThrow(runCommand, testName)
    ts:Assert(testVar == true)

    -- throw if type(arg1) isn't string
    local errorMsg = ts:AssertThrown(runCommand, testVar)
    ts:Assert(string.match(errorMsg, "invalid argument"))

    -- throw if command is unknown
    errorMsg = ts:AssertThrown(runCommand, testName.."A")
    ts:Assert(string.match(errorMsg, "not found"))

    -- throw if command throws!
    testVar = true
    errorMsg = ts:AssertThrown(runCommand, testName)
    ts:Assert(string.match(errorMsg, testError))
    ts:Assert(string.match(errorMsg, "error processing command"))
end)

ts:CreateTest("removeCommand", function()
    ts:Assert(fEnv.removeCommand)

    -- check if command runs properly
    testVar = false
    ts:AssertNoThrow(runCommand, testName)
    ts:Assert(testVar == true)

    -- remove command
    ts:AssertNoThrow(removeCommand, testName)

    -- check removal
    testVar = false
    local errorMsg = ts:AssertThrown(runCommand, testName)
    ts:Assert(string.match(errorMsg, "not found"))
    ts:Assert(testVar == false)

    -- throw if type(arg1) isn't string
    errorMsg = ts:AssertThrown(removeCommand, testVar)
    ts:Assert(string.match(errorMsg, "invalid argument"))

    -- don't throw if command is unknown
    ts:AssertNoThrow(removeCommand, testName)
end)

ts:CreateTest("check slash commands", function()
    local slashFunc = ts:Assert(RoMAPI.SlashCmdList["RaidHeal"])
    ts:Assert(slashFunc)

    testVar = false
    ts:AssertNoThrow(addCommand, testName, testCommand)

    ts:AssertNoThrow(slashFunc, nil, testName)
    ts:Assert(testVar == true)

    ts:AssertNoThrow(removeCommand, testName)
end)

ts:RunTests()

return unpack(results)