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
Adds the template(s) given by the return value of the file at the given path to the known templates list

path:      string of the template file to be loaded

[Returns]: nothing if successful, error message otherwise


template definition
===================

a template is defined to be a table with the following methods:

template:Create(name, parent[, errorLvl])
-----------------------------------------
name:      the name of the frame to be created
parent:    the parent frame
errorLvl:  The error level on which errors should be raised
[Returns]: a valid GUIObject

template:Arrange(guiObject)
---------------------------
guiObject: the GUIObject to be arranged (must be created from the same template)
[Returns]: the arranged guiObject

GUIObject definition
====================
a GUIObject is either a frame with some required fields or a table with some required methods

frame fields
------------
_template      the template used to create this frame

object methods
--------------
:GetTemplate() returns the template
:GetFrame()    Returns a frame or nil
