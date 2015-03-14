local main, ts, fEnv = ...

local retValue

ts:CreateTest("checkAPICreation", function()
    ts:Assert(RAIDHEAL_AUTHOR == nil)
    ts:Assert(RAIDHEAL_AUTHOR == nil)
    ts:Assert(RaidHeal == nil)
    ts:Assert(not RoMAPI.RaidHeal or RoMAPI.RaidHeal ~= RaidHeal)

    retValue = ts:AssertNoThrow(main)

    ts:Assert(RAIDHEAL_AUTHOR)
    ts:Assert(RAIDHEAL_VERSION)
    ts:Assert(RaidHeal)
    ts:Assert(RoMAPI.RaidHeal == RaidHeal)

    ts:Assert(RaidHeal.Events)
end)

ts:RunTests()
return retValue