--[[local BASE_PATH = "interface/addons/"

local addonList = {}

local function createEnv(addonName)
    local _env = {
        RoMAPI = _G,
        string = string,
        table = table,
        tostring = tostring,
        pairs = pairs,
        ipairs = ipairs,
        type = type,
        ADDON_NAME = addonName,
        BASE_PATH = BASE_PATH .. addonName .. "/",
    }
    _env.__index = _env
    _env.__newindex = _env
end

function loadAddon(addonName, addonFile)
    local addon = {}
    addon.modules = {}
    addon.env = createEnv(addonName)

    addon.env.require = function(path)
        local fullPath = addon.env.BASE_PATH .. path

        for name, moduleInfo in pairs(addon.modules) do
            if moduleInfo.path == fullPath then return end
        end

        local moduleName = string.sub(path, 1, -5)
        moduleName = moduleName:gsub("/", "_"):gsub("%.", "_")

        local moduleInfo = {
            path = fullPath,
            name = moduleName,
            env = setmetatable({
                FILENAME = path,
                MODULENAME = moduleName
            }, addon.env)
        }

        local moduleFunc = assert(loadfile(fullPath))
        setfenv(moduleFunc, moduleInfo.env)

        moduleInfo.func = moduleFunc
        addon.modules[moduleName] = moduleInfo

        return moduleFunc()
    end

    addonList[addonName] = addon

    return addon.env.require(addonFile)
end

loadAddon("RaidHeal", "main.lua")--]]

local TestSuite = LibStub("hfTestSuite")
local loadConfig = {
    MainFile = "main.lua",
    TestPath = "interface/addons/raidheal/tests/",
    LibPath = "interface/addons/raidheal/libs/"
}

if TestSuite then
    TestSuite:LoadAddon("RaidHeal", "interface/addons/raidheal/lua/", loadConfig)
else
    SendSystemChat("Error: hfTestSuite could not be loaded (required to run RaidHeal)!")
end