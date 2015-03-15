if not LibStub then error("LibStub required!") end

local LIB_NAME = "hfGUIBuilder"
local LIB_VERSION = 1.0

local ERRMSG_TEMPLATE_UNKNOWN = string.format("[%s] Template unknown: '%%s'", LIB_NAME)
local ERRMSG_TEMPLATE_LOADED = string.format("[%s] Template already loaded: '%%s'", LIB_NAME)
local ERRMSG_TEMPLATE_INVALID = string.format("[%s] Template invalid: '%%s'", LIB_NAME)
local ERRMSG_TEMPLATE_NOT_FOUND = string.format("[%s] Template not found", LIB_NAME)

local ERRMSG_PARENT_INVALID = string.format("[%s] Invalid parent", LIB_NAME)
local ERRMSG_PARENT_NOT_FOUND = string.format("[%s] Parent not found: '%%s'", LIB_NAME)

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
    errorLvl = (errorLvl or 1) + 1
    if not self._templates[template] then
        error(ERRMSG_TEMPLATE_UNKNOWN:format(tostring(template)), errorLvl)
    end
    
    if type(parent) == "string" then
        if not _G[parent] then
            error(ERRMSG_PARENT_NOT_FOUND:format(parent), errorLvl)
        end
        parent = _G[parent]
    elseif type(parent) == "table" then
        if parent.GetFrame then
            parent = parent:GetFrame()
        elseif not parent.GetName then
            error(ERRMSG_PARENT_INVALID, errorLvl)
        end
    else
        error(ERRMSG_PARENT_INVALID, errorLvl)
    end

    local frame = self._templates[template]:Create(name, parent, errorLvl + 1)
    return frame
end

function GUIBuilder:Arrange(guiObject, errorLvl)
    errorLvl = (errorLvl or 1) + 1
    
    local template = nil
    if guiObject.GetTemplate then
        template = guiObject:GetTemplate()
    elseif guiObject.GetName and guiObject._template then
        template = guiObject._template
    end
    
    if not template then
        error(ERRMSG_TEMPLATE_NOT_FOUND, errorLvl)
    end
    
    return template:Arrange(guiObject, errorLvl + 1)
end

function GUIBuilder:AddTemplatePath(path)
    if self._templatePaths[path] ~= "SUCCESS" then
        local errMsg
        self._templatePaths[path], errMsg = loadTemplates(path)

        return errMsg
    end
end

return GUIBuilder
