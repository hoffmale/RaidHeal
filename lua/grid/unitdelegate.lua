local UnitDelegateMT = {}
UnitDelegateMT.__index = UnitDelegateMT

function createDelegate(unitID, config)
  local delegate = setmetatable({}, UnitDelegateMT)
  delegate:SetConfig(config)
  delegate:SetUnit(unitID)
  return delegate
end
