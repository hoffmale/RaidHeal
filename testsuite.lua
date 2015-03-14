local testSuite = {
    SHOW_ERRORS = true,
    SHOW_WARNINGS = true,
    SHOW_INFOS = false,

    testFiles = {}
}

local unpack = unpack

testSuite._callStack = {}

local funcWrapperMap = {}
local function createFuncWrapper(name, func)
    if type(name) ~= "string" or type(func) ~= "function" then
        error("wrong type, name must be string and func must be function", 2)
    end
    if name == "error" or name == "assert" then return func end
    if funcWrapperMap[func] then return funcWrapperMap[func] end

    local _fenv = getfenv(func)
    local wrapper = function(...)
        testSuite.addCall(name, func, ...)
        local result = {func(...) }
        testSuite.removeCall(name)
        return unpack(result)
    end
    setfenv(wrapper, _fenv)
    funcWrapperMap[func] = wrapper
    funcWrapperMap[wrapper] = wrapper
    return wrapper
end

local function createTableWrapper(name, tbl)
    local wrapper = {}
    setmetatable(wrapper, {
        __index = function(_table, _key)
            if type(tbl[_key]) == "function" then
                return createFuncWrapper(name .. "." .. _key, tbl[_key])
            elseif type(tbl[_key]) == "table" then
                return createTableWrapper(name .. "." .. _key, tbl[_key])
            end
            return tbl[_key]
        end,
        __newindex = function(_table, _key, _value)
            tbl[_key] = _value
        end
    })
    return wrapper
end

local function lookup(globalName)
    local lastFuncCall = testSuite._callStack[#testSuite._callStack]
    local _env
    if lastFuncCall == nil then
        _env = _G
    else
        _env = getfenv(lastFuncCall.func)
    end
    return _env[globalName]
end

local function restoreCallStack(level)
    while testSuite._callStack[level + 1] do
        table.remove(testSuite._callStack, level + 1)
    end
end

testSuite.printWarning = function(warningMsg)
    if type(warningMsg) == "nil" then error("warningMsg is nil", 2) end
    if not testSuite.SHOW_WARNINGS then return end
    SendSystemChat("WARNING: " .. tostring(warningMsg))
end

testSuite.printError = function(errorMsg)
    if type(errorMsg) == "nil" then error("errorMsg is nil", 2) end
    if not testSuite.SHOW_ERRORS then return end
    SendSystemChat("|cffff0000ERROR: " .. tostring(errorMsg))
end

testSuite.printInfo = function(infoMsg)
    if type(infoMsg) == "nil" then error("infoMsg is nil", 2) end
    if not testSuite.SHOW_INFOS then return end
    SendSystemChat("|cffffff00INFO: " .. tostring(infoMsg))
end

testSuite.printCallStack = function()
    for i = 1, #testSuite._callStack do
        local stackData = testSuite._callStack[i]
        local argsAsStrings = {}
        for i=1,#stackData.args do argsAsStrings[i] = tostring(stackData.args[i]) end
        SendSystemChat(string.format("[%d] = %s(%s) [%s]", i, stackData.name, table.concat(argsAsStrings, " ,"), tostring(stackData.func)))
    end
end

testSuite.addCall = function(funcName, func, ...)
    local stackData = {
        name = funcName,
        func = func,
        args = {...}
    }
    testSuite._callStack[#testSuite._callStack + 1] = stackData
end

testSuite.removeCall = function(name)
    local stackData = testSuite._callStack[#testSuite._callStack]
    if stackData.name ~= name then
        testSuite.printCallStack()
        error("Corrupted call stack! name ~= " .. name)
    end
    testSuite._callStack[#testSuite._callStack] = nil
end

testSuite.assertNoThrow = function(func, ...)
    if type(func) == "function" then
        local callStackLevel = #testSuite._callStack
        local success, errorMsg = pcall(func, ...)
        restoreCallStack(callStackLevel)
        if not success then error(errorMsg or "(error)", 2) end
    elseif type(func) == "thread" then
        -- TODO: implement
    else
        error("invalid argument: func must be a function or coroutine")
    end
end

testSuite.assertThrown = function(func, ...)
    local args = {...}
    local expectedErrorMsg = table.remove(args, #args)

    if type(func) == "function" then
        local callStackLevel = #testSuite._callStack
        local success, errorMsg = pcall(func, unpack(args))
        restoreCallStack(callStackLevel)
        if success then error("fail: expected " .. expectedErrorMsg, 2) end

        if not success and not errorMsg:find(expectedErrorMsg) then
            testSuite.printWarning("errorMsg '" .. errorMsg .. "' doesn't match '" .. expectedErrorMsg .. "' (expected)")
        end
    elseif type(func) == "thread" then
        -- TODO: implement
    else
        error("invalid argument: func must be a function or coroutine")
    end
end

testSuite.assertTrue = function(condition, failMsg)
    if not condition then
        error("assertion fail" .. (failMsg and ": " .. failMsg or ""), 2)
    end
end

testSuite.assertFalse = function(condition, failMsg)
    if condition then
        error("assertion fail" .. (failMsg and ": " .. failMsg or ""), 2)
    end
end

testSuite.runTest = function(test)
    local testName = ""
    if type(test) == "string" then
        testName = test
        test = lookup(test)
        if type(test) ~= "function" then
            testSuite.printError("invalid test '" .. testName .. "'")
            return false
        end
    elseif test ~= "string" and test ~= "function" then
        testSuite.printError("invalid test '" .. tostring(test) .. "'")
        return false
    end

    local testFile = getfenv(test).FILENAME
    local testResult = { name = testName }
    if not testSuite.testFiles[testFile] then
        testSuite.testFiles[testFile] = {}
    end

    local callStackLevel = #testSuite._callStack
    local success, errorMsg = pcall(test)
    if not success then
        testResult.result = "FAIL"
        testResult.details = errorMsg
        --SendSystemChat("|cffff0000" .. (testName or "") .. " FAIL: " .. errorMsg)
        restoreCallStack(callStackLevel)
        --return false
    elseif success and not errorMsg then
        testResult.result = "FAIL"
        testResult.details = "test returned false"
        --return false
    elseif testName then
        testResult.result = "PASS"
        --SendSystemChat("|cff00ff00" .. testName .. " PASS")
    end

    table.insert(testSuite.testFiles[testFile], testResult)

    return testResult.result == "PASS"
end

testSuite.runTests = function(...)
    local allPassed = true
    for _, test in ipairs({...}) do
        if type(test) == "table" then
            allPassed = allPassed and testSuite.runTests(test)
        else
            allPassed = allPassed and testSuite.runTest(test)
        end
        if not allPassed then break end
    end
    return allPassed
end

testSuite.setupEnvironment = function(_env)
    _env.__index = function(_table, _key)
        testSuite.logGlobalAccess(_key)
        if type(_env[_key]) == "function" then
            return createFuncWrapper(_key, _env[_key])
        elseif type(_env[_key]) == "table" then
            return createTableWrapper(_key, _env[_key])
        end
        return _env[_key]
    end
    _env.__newindex = function(_table, _key, _value)
        testSuite.logGlobalCreation(_key)
        if type(_value) == "function" then
            -- wrap function to get a working "call stack"
            _env[_key] = createFuncWrapper(_key, _value)
        else
            _env[_key] = _value
        end
    end

    return _env
end

testSuite.logGlobalAccess = function(globalName)
    testSuite.printInfo("Global '" .. globalName .. "' got accessed")
end

testSuite.logGlobalCreation = function(globalName)
    testSuite.printInfo("Global '" .. globalName .. "' got created")
end

testSuite.printResults = function()
    local countPass, countFails = 0, 0
    for fileName, fileTests in pairs(testSuite.testFiles) do
        SendSystemChat("Results for file '" .. fileName .. "':")

        for _, testResult in pairs(fileTests) do
            if testResult.result == "PASS" then
                countPass = countPass + 1
                SendSystemChat("|cff00ff00PASS " .. testResult.name)
            else
                countFails = countFails + 1
                SendSystemChat("|cffff0000FAIL " .. testResult.name .. (testResult.details and ": " .. testResult.details or ""))
            end
        end
    end
end

return testSuite
