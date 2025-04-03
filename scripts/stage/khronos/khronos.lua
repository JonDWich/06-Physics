--@BRIEF: Loader/manager for new Lua scripts

-- has_events causes stage events to be passed to that table's entry as well. While EventManager does technically do this,
-- it's using a unique implementation with the game's (scripting) State system.
-- "scripts" is indexed with strings so that it's easier to disable specific managers in a given stage.
-- name is used for indexing. The "scripts" table should be an array so that load order can be handled
-- has_init is handled internally.
-- For some reason, if a script tries to run RegisterEvent as part of its constructor, g_level won't be registered yet, so the game will crash
-- has_init is a workaround for that, causing a script to run the first time StartPlaying is called by the game.
-- has_step means this script has an Update function (i.e., a function that should be called each frame).

Game.ExecScript("scripts/stage/khronos/khr_utilities.lua")
Custom = {
  scripts = {
    -- Enables a variety of helpful utilities, like running functions that can use Game.Sleep to pause their execution for X time.
	[1] = {filepath = "scripts/stage/khronos/eventmanager.lua", name = "EventManager", has_events = false, enabled = true, use_init = false,
		   has_step = false},
	
	-- Hijacks EventManager atm. Restores the Super Sonic transformation
	[2] = {filepath = "scripts/stage/khronos/wip/super_manager.lua", name = "SuperSonic", has_events = false, enabled = true, use_init = true,
		   has_step = true},
	
	-- S l o p e s
	[3] = {filepath = "scripts/stage/khronos/wip/physics_manager.lua", name = "Physics", has_events = false, enabled = true,
		   use_init = false, has_step = true}
  },
  EventManager = {},
  SuperSonic = {},
  Physics = {},
  Test = {},
  has_manager_events = {},
  has_step_behavior = {},
  has_custom_init = {has_run_init = false},
  object_references = {}
}
USE_DEBUGGER = false -- Allows toggling debug mode when pressing Y.

-- We may be running *a lot* of functions through this. I don't know how well 06 will handle that, so
-- I'm trying to limit overhead by minimizing function calls during it.
local STEP_TABLE_LENGTH = 0
old_actionstage_constructor = ActionStage.constructor
old_actionstage_step = ActionStage.Step
old_actionstage_setup = ActionStage.Setup
-- Runs the old ActionStage constructor then adds an entrypoint for the new scripts
-- Adds a reference to ActionStage in case we ever need it later
function ActionStage.constructor(self)
  old_actionstage_constructor(self)
  Custom.object_references["ACT_STAGE"] = self
  --Custom:constructor()
  local _, err = pcall(Custom.constructor, Custom)
  print("ERROR: " .. tostring(err))
end

function ActionStage.Setup(self)
  old_actionstage_setup(self)
  InitText()
  Custom:StartPlaying() -- Yes, this happens during load. The actual StartPlaying wouldn't run on first load
end

function ActionStage.Step(self, deltaTime)
  old_actionstage_step(self, deltaTime)
  if USE_DEBUGGER then
    if GetInput("y") then
	  Player(0):Move("0x100"):SetDWORD(2)
	end
	return
  end
  Custom:Step(deltaTime)
end

-- Constructor must run first in case we modify an existing table (like ActionStage)
-- enabled_entries allows processing custom events on a manager.
function Custom.constructor(self)
  STEP_TABLE_LENGTH = 0
  self.has_manager_events = {}
  for idx, properties in ipairs(self.scripts) do
    if properties.enabled then
	  local name = properties.name
	  Game.Log("ENABLED MANAGER: " .. name)
	  if properties.use_init then
	    table.insert(self.has_custom_init, name)
	  end
	  if properties.has_step then
	    table.insert(self.has_step_behavior, name)
		STEP_TABLE_LENGTH = STEP_TABLE_LENGTH + 1
	  end
	  self[name].constructor(self.object_references)
	  if properties.has_events then
	    table.insert(self.has_manager_events, name)
	  end
	  Game.ExecScript(properties.filepath)
	end
  end
end

function Custom.Step(self, delta)
  for i = 1, STEP_TABLE_LENGTH do
    local entry = self.has_step_behavior[i]
	--self[entry]:Step(delta)
	local _, err = pcall(self[entry].Step, self[entry], delta)
	if not _ then
	  print("ER: " .. tostring(err))
	end
  end
end

function Custom.ProcessEvent(action_stage, call_or_switch, event_table)
  local eventID = event_table[1].eventID
  for _, manager_name in ipairs(Custom.has_manager_events) do
    local manager = Custom[manager_name]
	if manager[eventID] then
	  if call_or_switch == "CallEvent" then
	    manager[eventID](manager, event_table[1].otherID, event_table[1].actorID)
	  elseif call_or_switch == "Switch" then
	    manager[eventID](manager, event_table[1].on, event_table[1].otherID, event_table[1].actorID)
	  end
	end
  end
end

function Custom.StartPlaying(self)
  if not self.has_custom_init.has_run_init then
    self.has_custom_init.has_run_init = true
    for _, script_name in ipairs(self.has_custom_init) do
      Custom[script_name]:StartPlaying()
    end
  end
end

-- For safety, declare constructors inside this script.

-- Eventer's reference to ActionStage (_stage) is used for changing threads.
function Custom.EventManager.constructor(obj_ref)
  ActionStage.Eventer = inherits_from(State)
  local action_stage = obj_ref.ACT_STAGE
  action_stage.states["event"] = ActionStage.Eventer
  action_stage.state = "event"
  local eventer = action_stage.states[action_stage.state]
  eventer._stage = action_stage
  eventer._forceEvent = function() return end
end

function Custom.SuperSonic.constructor(obj_ref)
  DebugPrint("Constructing Custom.SuperSonic")
end

function Custom.SuperSonic.StartPlaying(self)
  DebugPrint("SuperSonic.StartPlaying")
  RegisterEvent("SwapToSuper", SwapToSuper)
  RegisterEvent("ManageSuper", ManageSuper)
end

function Custom.Physics.constructor(obj_ref)
  DebugPrint("Constructing Custom.Physics")
end