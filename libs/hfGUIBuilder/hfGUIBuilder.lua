if not LibStub then error("LibStub required!") end

local LIB_NAME = "hfGUIBuilder"
local LIB_VERSION = 1.0

local ERRMSG_TEMPLATE_UNKNOWN = string.format("[%s] Template unknown: '%%s'", LIB_NAME)
local ERRMSG_TEMPLATE_LOADED = string.format("[%s] Template already loaded: '%%s'", LIB_NAME)
local ERRMSG_TEMPLATE_INVALID = string.format("[%s] Template invalid: '%%s'", LIB_NAME)

local GUIBuilder, oldVersion = LibStub:NewLibrary(LIB_NAME, LIB_VERSION)

if not GUIBuilder then
    return LibStub:GetLibrary(LIB_NAME)
end

if oldVersion and oldVersion < LIB_VERSION then
    -- update references
end

GUIBuilder._templatePaths = {}
GUIBuilder._templates = {}

local function loadTemplates(path)
    local loadFunc, errorMsg = loadfile(path)

    if errorMsg then
        return "FAILURE", errorMsg
    end

    local loadedTemplates = {}
    local function isValidTemplate(template)
        return template and type(template.Create)=="function" and type(template.Arrange)=="function"
    end

    local function undoLoading()
        for name in pairs(loadedTemplates) do
            GUIBuilder._templates[name] = nil
        end
    end

    templates = loadFunc()
    for templateName, templateData in pairs(templates) do
        if not GUIBuilder._templates[templateName] then
            if isValidTemplate(templateData) then
                GUIBuilder._templates[templateName] = templateData
                loadedTemplates[templateName] = true
            else
                undoLoading()
                error(ERRMSG_TEMPLATE_INVALID:format(tostring(templateName)), 3)
            end
        else
            undoLoading()
            error(ERRMSG_TEMPLATE_LOADED:format(tostring(templateName)), 3)
        end
    end
    return "SUCCESS"
end

function GUIBuilder:Create(template, name, parent, errorLvl)
    if not self._templates[template] then
        error(ERRMSG_TEMPLATE_UNKNOWN:format(tostring(template)), 2)
    end

    local frame = self._templates[template]:Create(name, parent, (errorLvl or 0) + 1)
    if frame then
        frame._template = template
    end
    return frame
end

function GUIBuilder:Arrange(frame, errorLvl)
    errorLvl = (errorLvl or 1) + 1
    if not frame or not frame._template or not self._templates[frame._template] then
        error(ERRMSG_TEMPLATE_UNKNOWN:format(tostring(frame._template)), errorLvl)
    end

    return self._templates[frame._template]:Arrange(frame, errorLvl)
end

function GUIBuilder:AddTemplatePath(path)
    if self._templatePaths[path] ~= "SUCCESS" then
        local errMsg
        self._templatePaths[path], errMsg = loadTemplates(path)

        return errMsg
    end
end

return GUIBuilder