-- @BRIEF: Main manager script, handles the execution order of other functions.

AIR_DENSITY = 1.225
DRAG_COEFF = 0.47
BALL_AREA = 0.785
G_DELTA_TIME = 1/60
FORCE_SUPER = false
function ComputeDrag(spd) 
  local drag = 0.5 * (AIR_DENSITY) * (DRAG_COEFF) * (BALL_AREA) * ((spd/100)^2)
  return drag
end
Game.ExecScript("scripts/stage/khronos/wip/ledges.lua")
Game.ExecScript("scripts/stage/khronos/wip/player_states.lua")
Game.ExecScript("scripts/stage/khronos/wip/slope_manager.lua")
Game.ExecScript("scripts/stage/khronos/wip/rail_manager.lua")
Game.ExecScript("scripts/stage/khronos/wip/powerup_manager.lua")
Game.ExecScript("scripts/stage/khronos/wip/variant_manager.lua")
local has_set_player = false
sonic_variant = -1 -- 1 is Mach Speed, 2 is Snow Board, 3 is Princess
local prep_ready = false
IS_PHYSICS_OFF = false


function Custom.Physics.Step(self, delta)
  G_DELTA_TIME = delta
  
  if not Player(0):IsValidPTR() then
    has_set_player = false
	prep_ready = false
    return
  end
  if not has_set_player then
    local cCtx = GetCharacterContext(0):GetPointer()
	if cCtx == Memory("8200A728") then -- Mach Speed
	  sonic_variant = 4
	  prep_ready = true
	  local character = GetManagedFlag(g_flags.is_super) and "super_mach" or "sonic_mach"
	  if FORCE_SUPER then character = "super_mach" end
	  local icon = character == "sonic_mach" and 0 or 10
	  PlayerSwap(character)
	  CallUIIndex("life", "character_icon", icon)
	  SetInputLockout(10/60)
	elseif cCtx == Memory("8200ADD8") then -- Snow Board
	  sonic_variant = 2
	elseif cCtx == Memory("8200ABB8") then -- Princess
	  sonic_variant = 3
	else
	  sonic_variant = 0
	end
	has_set_player = true
  end
  SleepStep(delta)
  UpdateText()
  if IS_PHYSICS_OFF then
    if GetInput("y") then
	  dofile("game://HUD_Test.lua")
	end
	return
  end
  
  if sonic_variant == 1 then
    MachStep(delta)
    return
  elseif sonic_variant == 2 then
    if GetInput("y") then dofile("game:\\HUD_Test.lua") end
    BoardStep(delta)
    return
  elseif sonic_variant == 4 then
    if GetPlayerName() == "sonic" then
	  local character = GetManagedFlag(g_flags.is_super) and "super_mach" or "sonic_mach"
	  if FORCE_SUPER then character = "super_mach" end
	  local icon = character == "sonic_mach" and 0 or 10
	  PlayerSwap(character)
	  local icon = character == "sonic_mach" and 0 or 10
	  CallUIIndex("life", "character_icon", icon)
	  SetInputLockout(10/60)
	  return
	elseif GetPlayerName() == "sonic_mach" and prep_ready then
	  prep_ready = false
	  StateSystem = OpenStateEx()
	  
	  StateSystem:Connect(0,2,LEOS_StateOnUpdateNo,function(state_ptr,context,stateid,statewhen,delta)
	    Memory("0x8220CBC0"):CallFunc(state_ptr) -- Call standard start/end behavior so that the player can still take damage.
	    Memory("0x8220CC28"):CallFunc(state_ptr)
        return false -- No External Block
	  end)
	
	  StateSystem:Connect(0,69,LEOS_StateOnStartNo,function(state_ptr,context,stateid,statewhen,delta)
	    return false -- Disable Spin Kick state
	  end)
	end
	
	if GetInput("y") then dofile("game:\\HUD_Test.lua") end -- Debug file
	
	StateStep(delta)
	CustomMachStep(delta)
	PowerupStep(delta)
	if GetManagedFlag(g_flags.stage_restart) then
      SetManagedFlag(g_flags.stage_restart, false)
    end
	return
  end
  StateStep(delta)
  PowerupStep(delta)
  SlopeStep(delta)
  if player_reference.current_class == "Grind" then
	is_grinding = true
	local _, err = pcall(RailDebug, delta)
	if not _ then
	  print("GRIND ERROR: " .. tostring(err))
	end
  else
    is_grinding = false
  end
  
  if GetManagedFlag(g_flags.stage_restart) then
    SetManagedFlag(g_flags.stage_restart, false)
  end
end