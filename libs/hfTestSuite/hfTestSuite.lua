if not LibStub then error("LibStub required! (hfTestSuite)") end

local TESTSUITE_VERSION = 1.0
local TESTSUITE_LIBNAME = "hfTestSuite"

local TestSuite, oldVersion = LibStub:NewLibrary(TESTSUITE_LIBNAME, TESTSUITE_VERSION)

if not TestSuite then
    return LibStub:GetLibrary(TESTSUITE_LIBNAME)
end

if oldVersion and oldVersion < TESTSUITE_VERSION then
    -- old version detected, remember to update old references!
end

TestSuite._addonList = TestSuite._addonList or {}
TestSuite._libList = TestSuite._libList or {}

local function createTestAPI()
    local api = {}

    function api:Assert(condition, message)
        if not condition then
            error(message or "assertion failed", 2)
        end
        return condition
    end

    function api:AssertNoThrow(func, ...)
        local results = { pcall(func, ...) }
        local success = table.remove(results, 1)

        if success then
            return unpack(results)
        else
            error(results[1] or "unexpected exception!", 2)
        end
    end

    function api:AssertThrown(func, ...)
        local results = { pcall(func, ...) }
        local success = table.remove(results, 1)

        if success then -- no error! <.<
            error(results[1] or "missing exception", 2)
        else
            return results[1]
        end
    end

    return api
end

local libTestAPI = createTestAPI()
local addonTestAPI = createTestAPI()

do
    local function createTest(db, testName, testFunc)
        if not db.Tests then db.Tests = {} end

        local testInfo = {
            Name = testName,
            Test = testFunc,
            Result = "UNKNOWN"
        }
        db.Tests[#db.Tests + 1] = testInfo
    end

    local function runTests(db)
        if db.Tests then
            for _, testInfo in ipairs(db.Tests) do
                local success, errorMsg = pcall(testInfo.Test)

                if success then
                    testInfo.Result = "SUCCESS"

                    SendSystemChat("SUCCESS: [" .. db.Name .. "] " .. testInfo.Name)
                else
                    testInfo.Result = "FAILURE"
                    testInfo.Error = errorMsg

                    SendSystemChat("FAILURE: [" .. db.Name .. "] " .. testInfo.Name .. " (" .. errorMsg .. ")")
                    error("test '" .. testInfo.Name .. "' failed!", 3)
                end
            end
        end
    end

    do -- setup missing libTestAPI functionality
        local function checkSetup(libName)
            if not libName or not TestSuite._libList[libName] then
                error("unknown library '" .. tostring(libName) .. "'", 3)
            end

            return TestSuite._libList[libName]
        end

        function libTestAPI:CreateTest(libName, testName, testFunc)
            local libInfo = checkSetup(libName)
            createTest(libInfo, testName, testFunc)
        end

        function libTestAPI:RunTests(libName)
            local libInfo = checkSetup(libName)
            runTests(libInfo)
        end
    end

    do -- setup missing addonTestAPI functionality
        local function checkSetup()
            local fEnv = getfenv(3)
            local moduleName = fEnv["MODULE_NAME"]
            local addonName = fEnv["ADDON_NAME"]

            if not addonName or not TestSuite._addonList[addonName] then
                error("unknown addon '" .. tostring(addonName) .. "'", 3)
            end

            if not moduleName or not TestSuite._addonList[addonName].Modules[moduleName] then
                error("unknown module '" .. tostring(moduleName) .. "' for addon '" .. tostring(addonName) .. "'", 3)
            end

            return TestSuite._addonList[addonName].Modules[moduleName]
        end

        function addonTestAPI:CreateTest(testName, testFunc)
            local moduleInfo = checkSetup()
            createTest(moduleInfo, testName, testFunc)
        end

        function addonTestAPI:RunTests()
            local moduleInfo = checkSetup()
            runTests(moduleInfo)
        end
    end
end

local function createAddonEnvironment(addon)
    local _env = {
        -- general
        RoMAPI = _G,
        string = string,
        table = table,
        tostring = tostring,
        tonumber = tonumber,
        coroutine = coroutine,
        pairs = pairs,
        ipairs = ipairs,
        type = type,
        error = error,
        assert = assert,
        pcall = pcall,
        xpcall = xpcall,
        setmetatable = setmetatable,
        getmetatable = getmetatable,
        getfenv = getfenv,
        setfenv = setfenv,
        unpack = unpack,
        math = math,
        loadfile = loadfile,
        dofile = dofile,
        load = load,
        loadstring = loadstring,

        -- addon specifics
        ADDON_NAME = addon.Name,
        BASE_PATH = addon.BasePath
    }

    function _env.require(path)
        local fullPath = addon.BasePath .. path
        local testPath = addon.TestPath and addon.TestPath .. path or nil

        for _, moduleInfo in pairs(addon.Modules) do
            if moduleInfo.Path == fullPath then return end
        end

        local moduleName = string.match(fullPath, "(%w+)%.lua$")
        moduleName = moduleName:gsub("/", "_"):gsub("%.", "_")

        local moduleInfo = {
            Path = fullPath,
            Name = moduleName,
            Env = setmetatable({
                FILE_NAME = path,
                MODULE_NAME = moduleName
            }, addon.Env)
        }

        local moduleFunc = assert(loadfile(fullPath))
        setfenv(moduleFunc, moduleInfo.Env)


        local testFunc = testPath and assert(loadfile(testPath))
        if testFunc then setfenv(testFunc, moduleInfo.Env) end

        moduleInfo.Func = moduleFunc
        moduleInfo.TestFunc = testFunc
        addon.Modules[moduleName] = moduleInfo

        if testFunc then
            return testFunc(moduleFunc, addonTestAPI, moduleInfo.Env)
        else
            return moduleFunc()
        end
    end

    function _env.requireLib(libName)
        return TestSuite:LoadLibrary(addon.LibPath, libName)
    end

    _env._G = _env
    _env.__index = _env
    _env.__newindex = _env
    return _env
end

function TestSuite:LoadAddon(addonName, addonPath, addonConfig)
    if TestSuite._addonList[addonName] then
        error("Addon with name '" .. addonName .. "' is already registered!", 2)
    end

    local addon = {
        Name = addonName,
        BasePath = addonPath,
        MainFile = addonConfig.MainFile or addonName .. ".lua",
        LibPath = addonConfig.LibPath or addonPath .. "libs/",
        TestPath = addonConfig.TestPath,
        Modules = {},
    }
    addon.Env = createAddonEnvironment(addon)
    TestSuite._addonList[addonName] = addon

    return addon.Env.require(addon.MainFile)
end

function TestSuite:LoadLibrary(libPath, libName)
    if TestSuite._libList[libName] then return LibStub(libName) end

    local libInfo = {
        Path = libPath .. libName .. "/",
        File = libName .. ".lua",
        Name = libName
    }

    libInfo.Func = assert(loadfile(libInfo.Path .. libInfo.File))
    libInfo.TestFunc = loadfile(libInfo.Path .. "tests.lua")

    TestSuite._libList[libName] = libInfo

    if libInfo.TestFunc then
        return libInfo.TestFunc(libInfo.Func, libTestAPI, libName, libInfo)
    else
        return libInfo.Func()
    end
end

_G["SLASH_TestSuite1"] = "/testsuite"
_G["SLASH_TestSuite2"] = "/ts"

SlashCmdList["TestSuite"] = function(arg1, msg)
    local cmd = string.match(msg, "^([^%s]+)")

    if not cmd then
        --printAvailableCommands()
        return
    end

    cmd = cmd:lower()
    if cmd == "list" then
        SendSystemChat("Addons loaded:")

        for name in pairs(TestSuite._addonList) do
            SendSystemChat(name)
        end

        SendSystemChat("Libraries loaded:")

        for name in pairs(TestSuite._libList) do
            SendSystemChat(name)
        end
    end
end
