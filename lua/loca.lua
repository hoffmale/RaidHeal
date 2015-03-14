local Loca = {}
--RaidHeal.Loca = Loca

Loca._messages = {}

function Loca:AddMessage(id, msg, _force)
    if type(id) ~= "string" or type(msg) ~= "string" then
        error("invalid argument #" .. (type(id) ~= "string" and "1" or "2"), 2)
    end
    if not self._messages[id] or _force then
        self._messages[id] = msg
    else
        error("entry already exists: " .. id)
    end
end

function Loca:GetMessage(id)
    if type(id) ~= "string" then
        error("invalid argument", 2)
    end
    if self._messages[id] then
        return self._messages[id]
    end
    return id
end

function Loca:RemoveMessage(id)
    if type(id) ~= "string" then
        error("invalid argument", 2)
    end
    if self._messages[id] then
        self._messages[id] = nil
    end
end

function Loca:LoadFile(locale)
    local localeLoader = assert(loadfile(LOCA_PATH .. locale .. ".lua"))
    self:Clear()
    -- load base
    if locale ~= "en" then
        self._messages = dofile(LOCA_PATH .. "en.lua")
    end
    -- load locale (_force = true) if locale ~= baseLocale
    local messages = localeLoader()
    for locaID, locaString in pairs(messages) do
        self:AddMessage(locaID, locaString, true)
    end
end

function Loca:Clear()
    self._messages = {}
end

function loca(id)
    return Loca:GetMessage(id)
end

function locaFormat(id, ...)
    -- TODO: implement possible arg reordering
    return string.format(Loca:GetMessage(id), ...)
end

--load default
Loca:LoadFile("en")

return Loca
