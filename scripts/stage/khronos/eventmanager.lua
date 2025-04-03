----------------------------------------------------------------
-----------------$Helper Functions$-----------------------------
-- @Brief: Easier scripting and drags stuff out of the Game Lib.
----------------------------------------------------------------
--		 @StartObj(actor_name): Alias for Game.StartEntityByName
--		 @SignalObj(actor_name): Alias for Game.Signal
--		 @WaitFor(1.2): Alias for Game.Sleep. Pauses the event for the given number of seconds. 
--		 @SendMsg(actor_name, msg, ...): Alias for Game.ProcessMessage.
--		 @PlaySound(sbk, cue): Alias for the PlaySE message.
--		 @StartPsi(actor_name): Signals a pathobj and gives it the PSI glow.
--		 @ToggleOpen(actor_name, is_open): Sends the GateOpen/Close message based on is_open.
----------------------------------------------------------------
StartObj = Game.StartEntityByName

SignalObj = Game.Signal

WaitFor = Game.Sleep

function SendMsg(actor_name, msg, ...)
  Game.ProcessMessage(actor_name, msg, arg[1])
end

function PlaySound(sbk, cue)
  Game.ProcessMessage("LEVEL", "PlaySE", {bank = sbk, id = cue})
end

function StartPsi(actor_name)
  Game.Signal(actor_name)
  Game.ProcessMessage(actor_name, "PsiEffect", {effect = true})
end

function ToggleOpen(actor_name, is_open)
  if is_open then
    Game.ProcessMessage(actor_name, "GateOpen")
  else
    Game.ProcessMessage(actor_name, "GateClose")
  end
end
----------------------------------------------------------------
---------------$New Event Functions$----------------------------
-- @Brief: Functions used to run the new scripting system.
----------------------------------------------------------------
--		 @StartEvent(ev_name): Plays a created or registered event.
--		  NOTE: Once an event is registered or created, it will 
--		  automatically play if a Group or Eventbox sends an event
-- 		  that matches its ev_name. StartEvent just allows you to 
--		  trigger an event directly through the Area script.	
--		 @RegisterEvent(ev_name, ev_function): Adds a new event from 
--		  an existing function.
--		 @CreateEvent(ev_name, arguments): Creates a new event with
--		  behavior defined at time of creation. Place each action in 
--		  a table.
--[[EXAMPLE: 
CreateEvent("test_event",
	{SpawnObj, "box1"},
	{PlaySound, {"obj_common", "ring"}},
	{WaitFor, 1.2},
	{SignalObj, "box1"}
	)
]]	 
----------------------------------------------------------------

function RegisterEvent(event_name, event_function)
  local eventer = g_level.states["event"]
  if eventer == nil then
    Game.Log("EVENTER IS NIL")
    return
  elseif event_function == nil then
    Game.Log("EVENT FUNCTION IS NIL")
	return
  end
  --table.insert(eventer._registered, event_name) Not using this atm
  eventer[event_name] = function()
	eventer._forceEvent = event_function
	eventer._stage:ChangeThread("Playing")
  end
end

function CreateEvent(event_name, ...)
  local eventer = g_level.states["event"]
  local func = function()
	for _, action_table in ipairs(arg) do
	  local action, param = action_table[1], action_table[2]
	  if type(param) == "table" then
		action(unpack(param))
	  else
		action(param)
	  end
	end
  end
  --table.insert(eventer._registered, event_name)
  RegisterEvent(event_name, func)
end

function StartEvent(event_name)
  local eventer = g_level.states["event"]
  return eventer[event_name]()
end

----------------------------------------------------------------
---------------$Overwrite Functions$----------------------------
-- @Brief: Default state behavior isn't the best. While you can 
--		   run "ChangeState" to force an update, the State thread 
--         doesn't really look for events on its own. If you add 
--		   CallEvent or Switch to a State table, it can execute 
--		   on that, but doing so means no event can pass to 
--		   ActionStage (and thus an Area script). It's also 
--		   much simpler to just hijack the ActionStage states 
--		   rather than trying to set up another State instance. 
--		   I had that working, but it seemed to cause a stack 
--		   overflow after ~2 minutes of gameplay, possibly related to
--         it calling dead coroutines?
--         Thus, this block changes some behavior to make the EventManager JustWork(TM).
----------------------------------------------------------------

-- Previously looked for msg (checked CallEvent/Switch). Now seeks the string ID of the specific event.
-- Removing the return allows ActionStage to still process and pass the event to the Area script.

function Object.ProcessEvent(action_stage, msg, ...)
  Custom.ProcessEvent(action_stage, msg, arg)
  if action_stage._s ~= nil and action_stage._s[arg[1].eventID] ~= nil then
    action_stage._s[arg[1].eventID](action_stage._s, action_stage, unpack(arg))
	--return true
  end
  if action_stage[msg] ~= nil then
    action_stage[msg](action_stage, unpack(arg))
	return true
  end
  return false
end

-- Changes the coroutine to execute from an index other than Main, allowing Game.Sleep to be used.
-- Updates "threads" to allow toggling between substates.
-- action_stage isn't technically the best param name, but it's the only table that'll use this.
function Object.ChangeThread(action_stage, new_coroutine_index)
  if action_stage.states[action_stage.state][new_coroutine_index] == nil then
    Game.Log("FAILED TO UPDATE COROUTINE. INDEX NOT PRESENT IN STATE")
	return
  end
  --action_stage._lastThread = action_stage._thread Currently obsolete, may re-implement later.
  --action_stage._thread = new_coroutine_index
  action_stage._co = coroutine.create(action_stage.states[action_stage.state]:new()[new_coroutine_index])
  action_stage:Wake()
  --Game.Log("UPDATED COROUTINE TO: " .. new_coroutine_index)
end
----------------------------------------------------------------
-----------------$Add Eventer Functions$------------------------
-- @Brief: Declare the necessary functions for the Eventer table.
--		   c_ is used as a prefix for "class." Tad nicer to read.
----------------------------------------------------------------
function ActionStage.Eventer.Main(class, action_stage)
  Game.Log("Eventer:Main")
  while true do
    Game.Sleep(10)
  end
end

function ActionStage.Eventer.Playing(class, action_stage)
  if action_stage.states["event"]._forceEvent then
    action_stage.states["event"]._forceEvent()
	action_stage.states["event"]._forceEvent = function() return end
  end
  action_stage:ChangeThread("Main")
end
-- This is just a leftover from creation. Keeping it as a reference, though. 
-- If an eventbox passes "enemy_set091", those are the arguments that this function would receive.
--[[
function ActionStage.Eventer.enemy_set091(state_table, action_stage, msg_table)
  Game.Log("THREAD BEGIN")
  PlaySound("obj_common", "rainbow")
  WaitFor(1.23)
  PlaySound("obj_common", "key_get")
  Game.Log("Done")
end
]]