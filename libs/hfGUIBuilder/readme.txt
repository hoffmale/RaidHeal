hfGUIBuilder v1.0 API Overview
==============================

GUIBuilder:Create(template, name, parent[, errorLvl])
-----------------------------------------------------
Creates a GUI object as implemented by a specified template.

template: The name (aka ID) of the template which specifies the construction details

name:     The name that the create frame should have.

parent:   The parent frame for the created one. Might be one of the following:
           - a string specifying a frame by name
           - a frame table
           - a GUI object

errorLvl: If an exception were to be thrown, it will be throw at (errorLvl+1) if set or 2 else

[Return]: nil or a GUI object


GUIBuilder:Arrange(guiObject)
-----------------------------
(Re-)Arranges a GUI object. Same as the GUI object method :Arrange()

guiObject: The GUI object to be arranged

[Return]:  nil if successful, an error message otherwise


GUIBuilder:AddTemplatePath(path)
--------------------------------
Adds a 