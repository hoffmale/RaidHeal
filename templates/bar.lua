local BarMT = {}
local BarTemplate = {}

function BarMT:GetTemplate()
    return BarTemplate
end

function BarMT:GetFrame()
    return self._barFrame
end

function BarMT:Update()
    
end

function BarMT:SetMinValue(minValue)
    self._minValue = minValue
    self:Update()
end

local function createBar(name, parent)
    local bar = setmetatable({}, BarMT)
    bar._barFrame = CreateUIComponent("Frame", name, parent:GetName())
    local frameName = bar._barFrame:GetName()
    bar._bgTexture = CreateUIComponent("Texture", frameName .. "_bgTexture", frameName)
    bar._barTexture = CreateUIComponent("Texture", frameName .. "_barTexture", frameName)
    
    bar._minValue = 0
    bar._maxValue = 100
    bar._curValue = 50
    
    return bar
end

local function arrangeBar(bar, errorLvl)
    bar._bgTexture:ClearAllAnchors()
    bar._BgTexture:SetAnchor("TOPLEFT", "TOPLEFT", bar._barFrame)
    bar._bgTexture:SetAnchor("BOTTOMRIGHT", "BOTTOMRIGHT", bar._barFrame)
    
    bar._barTexture:ClearAllAnchors()
    bar._barTexture:SetAnchor("TOPLEFT", "TOPLEFT", bar._barFrame)
    bar._barTexture:SetAnchor("BOTTOMLEFT", "BOTTOMLEFT", bar._barFrame)
    bar._barTexture:SetWidth(((bar._curValue - bar._minValue) / (bar._maxValue - bar._minValue)) * bar._barFrame:GetWidth())

    return bar
end

function BarTemplate:Create(name, parent, errorLvl)
    return createBar(name, parent, errorLvl + 1)
end

function BarTemplate:Arrange(bar, errorLvl)
    return arrangeBar(bar, errorLvl + 1)
end

return { RH_Bar = BarTemplate }
