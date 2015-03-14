local delegateList = {}

local delegateMT = {}

--[[
  delegate config scheme:
  {
    template             = nil | frameTemplate(type = "Frame")
    healthBar            = boolean | nil | frameTemplate(type = "Bar"),
    manaBar              = boolean | nil | frameTemplate(type = "Bar"),
    skillBar             = boolean | nil | frameTemplate(type = "Bar"),
    nameLabel            = boolean | nil | frameTemplate(type = "FontString")
    buffIcons            = number >= 0,
    buffIconAnchors      = list of valid anchors (# = buffIcons, relTo = unitDelegate by default),
    buffIconTemplate     = nil | frameTemplate(type = "BuffIcon")
    debuffIcons          = number >= 0,
    debuffIconAnchors    = list of valid anchors (# = debuffIcons, relTo = unitDelegate by default),
    debuffIconTemplate   = nil | frameTemplate(type = "BuffIcon")
    showDCMsg            = boolean,
    showDeathMsg         = boolean,
    colorizers           = nil | list of colorizers (hp, mp, sp, name, ...; ex: { healthBar = createColorizer("RoM_defaultClasses") } )
    intervals            = nil | list of update intervals (seconds; ex: { healthBar = 0.1, manaBar = 10 } )
  }
--]]
local defaultDelegateConfig = {
    template = {
        type = "Frame",
        size = { width = 300, height = 200 },
    },
    healthBar = {
        type = "Bar",
        anchors = {
            { point = "TOPLEFT" },
            { point = "TOPRIGHT" },
        },
        relSize = {
            fWidth = 1.0,
            fHeight = 0.33,
            dHeight = -1,
        },
        orientation = "LEFT",
    },
    manaBar = {
        type = "Bar",
        anchors = {
            { point = "TOPLEFT", relPoint = "BOTTOMLEFT", relTo = "healthBar", offsetY = 1 },
            { point = "BOTTOMRIGHT", relPoint = "TOPRIGHT", relTo = "skillBar", offsetY = -1 },
        },
        relSize = {
            fWidth = 1.0,
            fHeight = 0.33,
            dHeight = -1,
        },
        orientation = "LEFT",
    },
    skillBar = {
        type = "Bar",
        anchors = {
            { point = "BOTTOMLEFT" },
            { point = "BOTTOMRIGHT" },
        },
        relSize = {
            fWidth = 1.0,
            fHeight = 0.33,
            dHeight = -1,
        },
        orientation = "LEFT",
    },
    nameLabel = {
        type = "FontString",
        anchors = {
            { point = "TOPLEFT", offsetY = 10 },
            { point = "TOPRIGHT", offsetY = 10 },
        },
        relSize = {
            fWidth = 1.0,
            fHeight = 0.0,
            dHeight = 25,
            dWidth = 0,
        },
        layer = 3
    },
    buffIconCount = 0,
    debuffIconCount = 0,
    showDCMsg = false,
    showDeathMsg = false,
}

do -- ini delegateMT
delegateMT.__index = delegateMT

delegateMT.setUnitID = function(self, unitID)
    self.unitID = unitID
    self:updateAll()
end

delegateMT.updateAll = function(self)
    local unitData = Units:getUnit(self.unitID)

    SendSystemChat(string.format("%d/%d", unitData.HP, unitData.HPMax))
end
end

local function loadConfigBar(delegateTemplate, config, bar)
    if config.healthBar then
        if type(config[bar]) == "table" then
            delegateTemplate.frames[bar] = config[bar]
        else
            delegateTemplate.frames[bar] = defaultDelegateConfig[bar]
        end
    else
        delegateTemplate.frames[bar] = nil
    end
end

local function createUnitDelegate(config, parent)
    local delegate = {}
    setmetatable(delegate, delegateMT)

    local newIndex = #delegateList + 1
    delegateList[newIndex] = delegate

    delegate.config = config

    local delegateTemplate = defaultDelegateConfig.template

    if config.template and type(config.template) == "table" then
        delegateTemplate = config.template
    end

    if not delegateTemplate.frames then delegateTemplate.frames = {} end

    loadConfigBar(delegateTemplate, config, "healthBar")
    loadConfigBar(delegateTemplate, config, "manaBar")
    loadConfigBar(delegateTemplate, config, "skillBar")

    loadConfigBar(delegateTemplate, config, "nameLabel")
    -- DEBUG BEGIN
    --[[local frameTemplate = {
      type = "Frame",
      size = { width = 400, height = 300 },
      anchors = {
        { point = "CENTER", relTo = "UIParent" }
      },
      frames = {
        bgTexture = {
          type = "Texture",
          texture = "interface/tooltips/tooltip-background.tga",
          layer = 3,
          anchors = {
            { point = "TOPLEFT" },
            { point = "BOTTOMRIGHT" },
          }
        }
      }
    }--]]

    if type(parent) == "table" then parent = parent:GetName() end
    delegate.frame = FrameBuilder.create(delegateTemplate, parent or "UIParent", (parent and parent .. "_" or "") .. "delegate_" .. newIndex)
    -- DEBUG BEGIN
    delegate.frame:ClearAllAnchors()
    delegate.frame:SetAnchor("CENTER", "CENTER", parent or "UIParent")
    delegate.frame:Show()
    -- DEBUG END

    return delegate
end

-- DEBUG
_G.createUnitDelegate = createUnitDelegate
