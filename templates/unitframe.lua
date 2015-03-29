local UnitFrameMT = {}
local UnitFrameTemplate = {}
UnitFrameMT.__index = UnitFrameMT

function UnitFrameTemplate:Arrange(guiObject)
  return unitFrame:Update()
end

function UnitFrameTemplate:Create(name, parent, errorLvl)
  local unitFrame = setmetatable({}, UnitFrameMT)
  unitFrame.Frame = CreateUIComponent("Frame", name or parent .. "_UnitFrame", parent)
  
  return unitFrame
end

return { RH_UnitFrame = UnitFrameTemplate }
