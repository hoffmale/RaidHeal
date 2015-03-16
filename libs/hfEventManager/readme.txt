hfEventManager v1.0 API Overview
================================

EventManager:AddHandler(event, handler, _params)
------------------------------------------------

event:    event identifier, can be string but doesn't have to. Use the same event identifier to trigger
          the handlers registered for it
          NOTE: if the event identifier equals to a RoM-API Event, if will get triggered with the same!

handler:  The handler function that handles the event trigger. Will get called with the event identifier
          as first event and all additional arguments afterwards (so "arg9" will be the tenth parameter)
          NOTE: coroutine support is planned, but not included yet (__call metatables should work fine)

_params:  Additional parameters for the handler. Currently supported are:
           - "CallOnce": if set, handler will be removed after first execution
           - "HandlerName": specifies a unique "name" for the handler. No two handlers for the same event
                            may have the same "name" (the second one gets ignored)

[Return]: "name" of the event handler if added successfully, nothing otherwise


EventManager:RemoveHandler(event, handler)
------------------------------------------

event:    event identifier, only handlers for this event might be affected

handler:  the index ("name") or the handler itself to be removed

[Return]: Number of removed handlers


EventManager:PassEvent(event, ...)
----------------------------------
Will execute the event as soon as possible (compared to :QueueEvent)
WARNING: Might execute event immediately! Consider using :QueueEvent for performance critical situations

event:    the event identifier that gets triggered.

(args):   possible additional information to be passed to all event handlers

[Return]: Nothing


EventManager:QueueEvent(event, ...)
-----------------------------------
Will delay event execution (either after all currently queued events get executed or next frame)

event:    the event identifier that gets triggered

(args):   possible additional information to be passed to all event handlers

[Return]: Nothing


EventManager:HandlePendingEvents()
----------------------------------
Handles any delayed events if there is no event being handled at the moment (might take a while depending
on queue length)

[Return]: Nothing


Currently Known Bugs
====================

 - (None)
