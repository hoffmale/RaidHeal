local profileManagerMT = {}
profileManagerMT.__index = profileManagerMT

function profileManagerMT:init()
    -- TODO
    return false
end

function createProfileManager(localSettings, globalSettings)
    if not RoMAPI[localSettings] then
        RoMAPI[localSettings] = {}
    end

    if not RoMAPI[globalSettings] then
        RoMAPI[globalSettings] = {}
    end

    RoMAPI.SaveVariables(globalSettings)
    RoMAPI.SaveVariablesPerCharacter(localSettings)

    local profileManager = {}
    profileManager.localSettings = localSettings
    profileManager.globalSettings = globalSettings
    setmetatable(profileManager, profileManagerMT)

    return profileManager
end