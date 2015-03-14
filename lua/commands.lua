local commands = {}

function addCommand(cmd, handler)
    if type(cmd) ~= "string" then error("invalid argument #1", 2) end
    if type(handler) ~= "function" then error("invalid argument #2", 2) end
    if commands[cmd] then error("command already exists", 2) end

    commands[cmd] = handler
end

function runCommand(cmd, ...)
    if type(cmd) ~= "string" then error("invalid argument", 2) end
    if not commands[cmd] then
        error("command not found", 2)
    end

    local cmdFunc = commands[cmd]
    local success, errorMsg = pcall(cmdFunc, ...)

    if not success then
        error("error processing command '" .. cmd .. "': " .. errorMsg, 2)
    end
end

function removeCommand(cmd)
    if type(cmd) ~= "string" then error("invalid argument", 2) end
    commands[cmd] = nil
end

addCommand("list", function()
    for cmd, _ in pairs(commands) do
        RoMAPI.SendSystemChat(cmd)
    end
end)

do
    RoMAPI.SLASH_RaidHeal1 = "/rh"
    RoMAPI.SLASH_RaidHeal2 = "/RH"
    RoMAPI.SLASH_RaidHeal3 = "/raidheal"
    RoMAPI.SLASH_RaidHeal4 = "/RaidHeal"

    local function split(original, delimiter) -- TODO: general utility function, might be better if placed elsewhere
        local result, searchPos = {}, 0
        if #original == 1 then return { original } end

        while true do
            local pos = string.find(original, delimiter, searchPos, true)
            if pos ~= nil then
                result[#result + 1] = string.sub(original, searchPos, pos - 1)
                searchPos = pos + 1
            else
                result[#result + 1] = string.sub(original, searchPos + 1)
                break
            end
        end

        return result
    end

    RoMAPI.SlashCmdList["RaidHeal"] = function(editbox, msg)
        if msg ~= "" then
            local cmds = split(msg, " ")
            local cmd = table.remove(cmds, 1)
            runCommand(cmd, unpack(cmds))
        else
            runCommand("list")
        end
    end
end
