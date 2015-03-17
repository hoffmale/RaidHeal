local BarMT = {}
local BarTemplate = {}

function BarMT:GetTemplate()
    return BarTemplate
end

function BarMT:GetFrame()
    return self._barFrame
end

function BarMT:Update()
    if self._noUpdate then return end
    
    self._bgTexture:ClearAllAnchors()
    self._bgTexture:SetAnchor("TOPLEFT", "TOPLEFT", self._barFrame, self._padding.Left, self._padding.Top)
    self._bgTexture:SetAnchor("BOTTOMRIGHT", "BOTTOMRIGHT", self._barFrame, -self._padding.Right, -self._padding.Bottom)
    self._bgTexture:SetColor(unpack(self._bgColor))
    
    local maxWidth, maxHeight = self._bgTexture:GetSize()
    maxWidth = maxWidth - self._insets.Left - self._insets.Right
    maxHeight = maxHeight - self._insets.Top - self._insets.Bottom
    
    local percValue = math.min(1, math.max(0, (self._curValue - self._minValue) / (self._maxValue - self._minValue)))
    
    self._barTexture:ClearAllAnchors()
    if self._fillDirection == "LEFT" or self._fillDirection == "RIGHT" then
        maxWidth = maxWidth * percValue
        if maxWidth < 1.0 and percValue > 0.0 then maxWidth = 1 end
        self._barTexture:SetSize(maxWidth, maxHeight)
        
        local topAnchor, botAnchor = "TOP" .. self._fillDirection, "BOTTOM" .. self._fillDirection
        local offsetX = (self._fillDirection == "LEFT") and self._insets.Left or -self._insets.Right
        self._barTexture:SetAnchor(topAnchor, topAnchor, self._bgTexture, offsetX, self._insets.Top)
        self._barTexture:SetAnchor(botAnchor, botAnchor, self._bgTexture, offsetX, -self._insets.Bottom)
    else
        maxHeight = maxHeight * percValue
        if maxHeight < 1.0 and percValue > 0.0 then maxHeight = 1 end
        self._barTexture:SetSize(maxWidth, maxHeight)
        
        local leftAnchor, rightAnchor = self._fillDirection .. "LEFT", self._fillDirection .. "RIGHT"
        local offsetY = (self._fillDirection == "TOP") and self._insets.Top or -self._insets.Bottom
        self._barTexture:SetAnchor(leftAnchor, leftAnchor, self._bgTexture, self._insets.Left, offsetY)
        self._barTexture:SetAnchor(rightAnchor, rightAnchor, self._bgTexture, -self._insets.Right, offsetY)
    end
    self._barTexture:SetColor(unpack(self._barColor))
end

function BarMT:SetMinValue(minValue)
    if self._minValue ~= minValue and type(minValue) == "number" then
        self._minValue = minValue
        self:Update()
    end
end

function BarMT:GetMinValue()
    return self._minValue or 0
end

function BarMT:SetMaxValue(maxValue)
    if self._maxValue ~= maxValue and type(maxValue) == "number" then
        self._maxValue = maxValue
        self:Update()
    end
end

function BarMT:GetMaxValue()
    return self._maxValue or 1
end

function BarMT:SetValue(newValue)
    if self._curValue ~= newValue and type(newValue) == "number" then
        self._curValue = newValue
        self:Update()
    end
end

function BarMT:GetValue()
    return self._curValue or 0.5
end

function BarMT:SetPadding(top, bottom, left, right)
    if type(top) == "table" and top.Left and top.Right and top.Top and top.Bottom then
        self._padding = top
    elseif type(top) == "number" then
        self._padding = {
            Top = top,
            Bottom = bottom or top,
            Left = left or top,
            Right = right or top
        }
    end
    self:Update()
end

function self:GetPadding()
    return self._padding or { Top = 0, Bottom = 0, Left = 0, Right = 0 }
end

function BarMT:SetInsets(top, bottom, left, right)
    if type(top) == "table" and top.Top and top.Bottom and top.Left and top.Right then
        self._insets = top
    elseif type(top) == "number" then
        self._insets = {
            Top = top,
            Bottom = bottom or top,
            Left = left or top,
            Right = right or top
        }
    end
    self:Update()
end

function BarMT:GetInsets()
    return self._insets or { Top = 0, Bottom = 0, Left = 0, Right = 0 }
end

function BarMT:SetBarColor(red, green, blue)
    if type(red) == "table" then
        if red.r and red.g and red.b then
            self._barColor = { red.r, red.g, red.b }
        elseif red[1] and red[2] and red[3] then
            self._barColor = red
        end
    elseif type(red) == "number" and type(green) == "number" and type(blue) == "number" then
        self._barColor = { red, green, blue }
    end
    self:Update()
end

function BarMT:GetBarColor()
    return self._barColor or { 1, 1, 1 }
end

function BarMT:SetBGColor(red, green, blue)
    if type(red) == "table" then
        if red.r and red.g and red.b then
            self._bgColor = { red.r, red.g, red.b }
        elseif red[1] and red[2] and red[3] then
            self._bgColor = red
        end
    elseif type(red) == "number" and type(green) == "number" and type(blue) == "number" then
        self._bgColor = { red, green, blue }
    end
    self:Update()
end

function BarMT:GetBGColor()
    return self._bgColor or { 0, 0, 0 }
end

function BarMT:SetConfig(config)
    self._noUpdate = true
    
    self:SetMinValue(config.MinValue or self:GetMinValue())
    self:SetMaxValue(config.MaxValue or self:GetMaxValue())
    self:SetValue(config.Value or self:GetValue())
    
    self:SetPadding(config.Padding or self:GetPadding())
    self:SetInsets(config.Insets or self:GetInsets())
    
    self:SetBGColor(config.BGColor or self:GetBGColor())
    self:SetBarColor(config.BarColor or self:GetBarColor())
        
    if config.BGTexture then
        self._bgTexture:SetTexture(config.BGTexture)
        self._bgTexture._path = config.BGTexture
    end
    if config.BarTexture then
        self._barTexture:SetTexture(config.BarTexture)
        self._barTexture._path = config.BarTexture
    end
    
    self._noUpdate = false
    self:Update()
end

function BarMT:GetConfig()
    local config = {}
    
    config.MinValue = self:GetMinValue()
    config.MaxValue = self:GetMaxValue()
    config.Value = self:GetValue()
    
    config.Padding = self:GetPadding()
    config.Insets = self:GetInsets()
    
    config.BGColor = self:GetBGColor()
    config.BarColor = self:GetBarColor()
    
    config.BGTexture = self._bgTexture._path
    config.BarTexture = self._barTexture._path
    
    return config
end

function BarMT:Show()
    if not self._isShown then
        self._barFrame:Show()
        self._isShown = true
    end
end

function BarMT:Hide()
    if self._isShown then
        self._barFrame:Hide()
        self._isShown = false
    end
end

local function createBar(name, parent)
    local bar = setmetatable({}, BarMT)
    bar._barFrame = CreateUIComponent("Frame", name, parent:GetName())
    local frameName = bar._barFrame:GetName()
    bar._bgTexture = CreateUIComponent("Texture", frameName .. "_bgTexture", frameName)
    bar._barTexture = CreateUIComponent("Texture", frameName .. "_barTexture", frameName)
    
    bar:SetConfig({})
    return bar
end

local function arrangeBar(bar, errorLvl)
    bar:Update()
    return bar
end

function BarTemplate:Create(name, parent, errorLvl)
    return createBar(name, parent, errorLvl + 1)
end

function BarTemplate:Arrange(bar, errorLvl)
    return arrangeBar(bar, errorLvl + 1)
end

return { RH_Bar = BarTemplate }
