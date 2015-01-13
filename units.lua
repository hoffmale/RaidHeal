-- import as local for speedup
local UnitName = UnitName
local UnitExists = UnitExists
local UnitHealth = UnitHealth
local UnitMaxHealth = UnitMaxHealth
local UnitMana = UnitMana
local UnitMaxMana = UnitMaxMana
local UnitSkill = UnitSkill
local UnitMaxSkill = UnitMaxSkill
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff
local UnitLevel = UnitLevel

local _preventRecursive = false
local _buffDB, _debuffDB = {}, {}
local _maxHPDB = {}

local function updateMaxHP(unit, maxHP)
    if not UnitExists(unit) then return end
    local key = UnitName(unit) .. "_" .. UnitLevel(unit) .. GetInstanceLevel()
    if not UnitIsPlayer(unit) and maxHP ~= 100 and not _maxHPDB[key] then
        _maxHPDB[key] = maxHP
    end
end

--_G.GetMaxHealthTable = function() return _maxHPDB end

local function eventHandler_OnUnitTargetChanged(unit)
    if not UnitExists(unit) then return end
    local target = unit.."target"
    updateMaxHP(unit, math.abs(UnitChangeHealth(unit)))
    updateMaxHP(target, math.abs(UnitChangeHealth(target)))
end

local function getBuffMaxTime(id, curTime)
    if _buffDB[id] and curTime > _buffDB[id] or not _buffDB[id] then
        _buffDB[id] = curTime
    end
    return _buffDB[id]
end

local function getDebuffMaxTime(id, curTime)
    if _debuffDB[id] and curTime > _debuffDB[id] or not _debuffDB[id] then
        _debuffDB[id] = curTime
    end
    return _debuffDB[id]
end

local function unitFunc_clear(self)
    for k, v in pairs(self) do
        if type(v) ~= "function" and k ~= "UnitID" then
            self[k] = v
        end
    end
end

local function unitFunc_exists(self)
    return UnitExists(self.UnitID)
end

local function unitFunc_getBuffs(self)
    local oldVal = _preventRecursive
    _preventRecursive = true

    if not self.Buffs then
        local buffs = {}

        local index = 1
        local _name, _texture, _stacks, _id, _param = UnitBuff(self.UnitID, index)

        while _name do
            local _timeLeft = UnitBuffLeftTime(self.UnitID) or -1
            local _timeMax = getBuffMaxTime(_id, _timeLeft)

            local buffData = {
                Name = _name,
                ID = _id,
                Stacks = _stacks,
                Param = _param,
                TimeLeft = _timeLeft,
                TimeMax = _timeMax,
                Texture = _texture
            }
            buffs[_name] = buffData
            buffs[_id] = buffData
            buffs[index] = buffData -- TODO: check ids 0-100 if they contain a buff

            index = index + 1
            _name, _texture, _stacks, _id, _param = UnitBuff(self.UnitID, index)
        end

        self.Buffs = buffs
    end

    _preventRecursive = oldVal
    return self.Buffs
end

local function unitFunc_getDebuffs(self)
    local oldVal = _preventRecursive
    _preventRecursive = true

    if not self.Debuffs then
        local debuffs = {}

        local index = 1
        local _name, _texture, _stacks, _id, _param = UnitDebuff(self.UnitID, index)

        while _name do
            local _timeLeft = UnitDebuffLeftTime(self.UnitID) or -1
            local _timeMax = getDebuffMaxTime(_id, _timeLeft)

            local debuffData = {
                Name = _name,
                ID = _id,
                Stacks = _stacks,
                Param = _param,
                TimeLeft = _timeLeft,
                TimeMax = _timeMax,
                Texture = _texture
            }
            debuffs[_name] = debuffData
            debuffs[_id] = debuffData
            debuffs[index] = debuffData -- TODO: check ids 0-100 if they contain a debuff

            index = index + 1
            _name, _texture, _stacks, _id, _param = UnitDebuff(self.UnitID, index)
        end

        self.Debuffs = debuffs
    end

    _preventRecursive = oldVal
    return self.Debuffs
end

local function unitFunc_getMaxAbsHP(self)
    if not UnitIsPlayer(self.UnitID) and self.HPMax == 100 then
        local key = self.Name .. "_" .. (UnitLevel(self.UnitID)) .. GetInstanceLevel()
        return _maxHPDB[key] or 100
    end
    return self.HPMax
end

local function unitFunc_getCurAbsHP(self)
    if not UnitIsPlayer(self.UnitID) and self.HPMax == 100 then
        local key = self.Name .. "_" .. (UnitLevel(self.UnitID)) .. GetInstanceLevel()
        return _maxHPDB[key] and _maxHPDB[key] * self.HP / self.HPMax or self.HP
    end
    return self.HP
end

local unitFuncTable = {
    clear = unitFunc_clear,
    exists = unitFunc_exists,
    getBuffs = unitFunc_getBuffs,
    getDebuffs = unitFunc_getDebuffs,
    getMaxAbsHP = unitFunc_getMaxAbsHP,
    getCurAbsHP = unitFunc_getCurAbsHP
}

local function createUnitFunc(varName, origFunc)
    unitFuncTable["get"..varName] = function(self)
        local oldVal = _preventRecursive
        _preventRecursive = true
        if not self[varName] then self[varName] = origFunc(self.UnitID) end
        _preventRecursive = oldVal
        return self[varName]
    end
end

createUnitFunc("Name", UnitName)
createUnitFunc("HP", UnitHealth)
createUnitFunc("HPMax", UnitMaxHealth)
createUnitFunc("MP", UnitMana)
createUnitFunc("MPMax", UnitMaxMana)
createUnitFunc("SP", UnitSkill)
createUnitFunc("SPMax", UnitMaxSkill)


local unitMT = {
    __index = function(unit, index)
        local result = nil
        if not _preventRecursive then
            _preventRecursive = true

            if unitFuncTable[index] then
                result = { unitFuncTable[index] }
            elseif unitFuncTable["get" .. index] then
                result = { unitFuncTable["get" .. index](unit) }
            end

            _preventRecursive = false
        end
        if result then return unpack(result) end
        return nil
    end
}

local function createUnit(unitID)
    local unit = {}

    for k, v in pairs(unitFuncTable) do
        unit[k] = v
    end
    setmetatable(unit, unitMT)

    unit.UnitID = unitID
    unit:clear()

    return unit
end

---------------------------------------

Units = {
    getUnit = function(self, unitID, _noCheck)
        local unit = nil
        if _noCheck or not self[unitID] then
            unit = createUnit(unitID)
            if unit:exists() then self[unitID] = unit end
        else
            unit = self[unitID]
        end
        return unit
    end,
    clear = function(self)
        for k, unit in pairs(self) do
            if type(unit) == "table" and unit.clear then
                unit:clear()
                if not unit:exists() then
                    self[k] = nil
                end
            end
        end
    end,
}

local _prevRec = false
local Units_MT = {
    __index = function(self, key)
        local result = nil
        if not _prevRec then
            _prevRec = true
            if type(key) == "string" then
                result = self:getUnit(key)
            end
            _prevRec = false
        end
        return result
    end,
}

setmetatable(Units, Units_MT)

--[[if RaidHeal and RaidHeal.Events and RaidHeal.Events.Register then -- TODO: replace with lib internal event manager
    RaidHeal.Events.Register("UNIT_TARGET_CHANGED", eventHandler_OnUnitTargetChanged)
end--]]