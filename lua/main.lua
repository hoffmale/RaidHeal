-- create global accessible interface
RaidHeal = {}
RoMAPI.RaidHeal = RaidHeal

RAIDHEAL_VERSION = "0.9.9 inDev"
RAIDHEAL_AUTHOR = "hoffmale"
LOCA_PATH = "interface/addons/raidheal/locales/"

RaidHeal.Loca = require("loca.lua")

local function registerAddonManager()
    local addon = {
        name = "RaidHeal",
        version = RAIDHEAL_VERSION,
        author = RAIDHEAL_AUTHOR,
        description = loca("ADDONMANAGER_DESC"), -- TODO: implement sth like IO.Format("ADDON_DESC"),
        icon = "Interface/widgeticons/classicon_druid", -- TODO: get better icon
        category = "Interface",
        configFrame = nil, -- TODO: create a config frame
        slashCommand = "/rh /RH /raidheal /RaidHeal", -- TODO: implement slash commands
        disableScript = function() --[[runCommand("disable")]] end,
        enableScript = function() --[[runCommand("enable")]] end,
        mini_icon = "Interface/widgeticons/classicon_druid",
        mini_icon_pushed = "Interface/widgeticons/classicon_druid",
        mini_onClickScript = function() --[[ TODO: implement ]] end
    }
    if RoMAPI.AddonManager then
        if RoMAPI.AddonManager.RegisterAddonTable then
            RoMAPI.AddonManager:RegisterAddonTable(addon)
            return true
        elseif RoMAPI.AddonManager.RegisterAddon then
            RoMAPI.AddonManager.RegisterAddon(addon.name, addon.description, addon.icon, addon.category, addon.configFrame, addon.slashCommand, nil, addon.mini_onClickScript, addon.version, addon.author, addon.disableScript, addon.enableScript)
            return true
        end
    end
    return false
end

local function onLoad()
    require("commands.lua")

    addCommand("version", function()
        RoMAPI.SendSystemChat(locaFormat("CMD_VERSION_TEXT", RAIDHEAL_VERSION, RAIDHEAL_AUTHOR))
    end)
    if not registerAddonManager() then
        runCommand("version")
    end
end

do
    RaidHeal.Events = requireLib("hfEventManager")
    RaidHeal.Events:AddHandler("LOADING_END", onLoad, { CallOnce = true })
end
--[==[
local function eventHandler_onLoadingEnd()
    if not RaidHeal.ProfileManager:init() then
        -- no settings found
        addCommand("install", function()
            require("procedures.lua")
            startProcedure("firstUse", { onFinished = function(success) removeCommand("install") end })
        end)

        runCommand("install")
    end

end

local function init()
    require("commands.lua")
    require("eventmanager.lua")
    require("profilemanager.lua")

    RaidHeal.Events = createEventManager("WorldFrame")
    RaidHeal.ProfileManager = createProfileManager("RH_LocalSettings", "RH_GlobalSettings")

    addCommand("version", function() RoMAPI.SendSystemChat("|cffffffffRaidHeal v" .. RAIDHEAL_VERSION) end)
    RaidHeal.Events:registerEventHandler("LOADING_END", eventHandler_onLoadingEnd)
end
init()
--]==]