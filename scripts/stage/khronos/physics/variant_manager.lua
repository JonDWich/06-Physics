--@BRIEF: Mach Speed and Snow Board tend to crash with the regular physics, so they're running stripped down code.

local ground_magnitude, ground_supplement, ground_sine, ground_cosine = 0, 0, 0, 0
local last_pos_y = 0
local slope_upward = false
local was_grounded = false
local base_fast_walk = 5500
local base_fast_run = 0
MASS_N = -20 * (9.81 * 1.75)
MY_GRAVITY_RATE = 980 * 1.75
X_MULTI = 1.1
local function SetMachY(val) -- standard SetPlayerSpeed doesn't work for Y on this, for some reason
  local context = GetCharacterContext(0)
  context:Move("0x38"):SetFLOAT(val)
end

function MachStep(delta) -- Retail Mach Speed compatible code. Unused for now.
  local new_pos_y = GetPlayerPos("y")
  slope_upward = new_pos_y > last_pos_y
  last_pos_y = new_pos_y
  
  local spd = GetPlayerSpeed("x", false)
  local h_air_spd = mAbs(spd * ground_cosine)
  local v_air_spd = slope_upward and mAbs(spd * ground_sine) or mAbs(spd * ground_sine) * -1
  if GetPlayerState() == 11 then
    SetFastLuaValue("c_run_speed_max", 12000)
  end
  if IsGrounded() then
    was_grounded = true
	ground_magnitude, ground_supplement, ground_sine, ground_cosine = CalculateDataByNormal() -- from slope_manager
	local my_run = GetFastLuaValue("c_run_speed_max")
	if my_run ~= base_fast_run then
	  local lerp_rate = 2.5/60
	  my_run = lerp(my_run, base_fast_run, lerp_rate)
	  if mAbs(base_fast_run - my_run) <= 50 then
	    my_run = base_fast_run
	  end
	  SetFastLuaValue("c_run_speed_max", my_run)
	  SetFastLuaValue("c_jump_run", my_run)
	  SetFastLuaValue("c_jump_walk", my_run)
	end
	SetFastLuaValue("c_jump_speed", 900)
  else
    if was_grounded then
	  was_grounded = false
	  
	  SetGravityForce(980 * player_reference.mach_params.MACH_GRAVITY_MULTIPLIER)
	  SetPlayerSpeed("x", h_air_spd, false)
	  --SetPlayerSpeed("y", v_air_spd, false)
	  if not GetInput("a") and not GetInput("a", "hold") then
	    SetMachY(v_air_spd)
	  end
	else
	  if GetPlayerState() == 2 then
	    local mass_n = player_reference.slope_params.MASS * (GetGravityForce()/100) * -1 -- So that it forces you downward
	    local y_spd = GetPlayerSpeed("y", false)
	    local drag_spd_x = ComputeDrag(spd) -- from standard_states
	    local drag_spd_y = ComputeDrag(y_spd)
	    local v_force = ((mass_n - drag_spd_y)/20) -- 20 is the player weight, in kilograms
	    local x_force = drag_spd_x * X_MULTI
	    v_force = v_force * 1/60
	    x_force = (x_force * 1/60) * -1
	    local final_spd = y_spd + v_force -- v_force is already negative)
		local final_x = spd + x_force
	    --SetPlayerSpeed("y", final_spd, false)
	    SetMachY(final_spd)
	    SetPlayerSpeed("x", final_x, false)
		SetFastLuaValue("c_run_speed_max", final_x)
		SetFastLuaValue("c_jump_run", final_x)
		SetFastLuaValue("c_jump_walk", final_x)
		SetFastLuaValue("c_jump_speed", y_spd)
	  else
	    SetGravityForce(980)
	  end
	end
  end
end

local aura_on = false -- Just avoids making the Context call as often. Not necessary otherwise
function CustomMachStep(delta) -- Mach Speed rewrite behavior.
  local new_pos_y = GetPlayerPos("y")
  slope_upward = new_pos_y > last_pos_y
  last_pos_y = new_pos_y
  local is_super = GetManagedFlag(g_flags.is_super)
  local spd = GetPlayerSpeed("x", false)
  local total = GetPlayerSpeed("total")
  local gauge_max_spd = not is_super and player_reference.mach_params.RUN_MAX_SPEED or player_reference.mach_params.RUN_MAX_SPEED_SUPER
  SetCurrentGaugeValue(mMin(1, total/gauge_max_spd))
  
  if total >= player_reference.mach_params.MACH_AURA_ENABLE_SPD then
	if not aura_on then
      SetContextFlag("MachAura", true)
	  SetContextFlag("SlideHitbox", true)
	end
	aura_on = true
  else
    if aura_on and total < player_reference.mach_params.MACH_AURA_DISABLE_SPD then
      SetContextFlag("MachAura", false)
	  SetContextFlag("SlideHitbox", false)
	  aura_on = false
	end
  end
  if is_super then
    SetContextFlag("SlideHitbox", true)
  end
  local h_air_spd = mAbs(spd * ground_cosine)
  local v_air_spd = slope_upward and mAbs(spd * ground_sine) or mAbs(spd * ground_sine) * -1
  if GetPlayerState() == 11 then
    --SetFastLuaValue("c_run_speed_max", 12000)
  end
  local my_lua_state = player_reference.current_state
  if IsGrounded() then
    was_grounded = true
	ground_magnitude, ground_supplement, ground_sine, ground_cosine = CalculateDataByNormal() -- from slope_manager
	local my_run = GetPlayerSpeed("x", false)
	if base_fast_run == 0 then
	  base_fast_run = not is_super and player_reference.mach_params.RUN_MAX_SPEED or player_reference.mach_params.RUN_MAX_SPEED_SUPER
	end
	if my_run ~= base_fast_run then
	  local lerp_rate = 2.25/60
	  my_run = lerp(my_run, base_fast_run, lerp_rate)
	  if mAbs(base_fast_run - my_run) <= 50 then
	    my_run = base_fast_run
	  end
	  --SetFastLuaValue("c_run_speed_max", my_run)
	  --SetFastLuaValue("c_jump_run", my_run)
	  --SetFastLuaValue("c_jump_walk", my_run)
	  if my_run >= base_fast_run then
	    if is_super then
		  player_reference.mach_params.RUN_MAX_SPEED_SUPER = my_run
		else
	      player_reference.mach_params.RUN_MAX_SPEED = my_run
		end
	  end
	end
	--SetFastLuaValue("c_jump_speed", 900)
  else
    if was_grounded then
	  was_grounded = false
	  if my_lua_state == "Falling" then
	    SetGravityForce(980 * player_reference.mach_params.MACH_GRAVITY_MULTIPLIER)
		local has_capped = false
		local ratio = mMax(1, mAbs(v_air_spd/h_air_spd))
		local vertical_positive_cap = player_reference.mach_params.MAX_LAUNCH_UP
		local vertical_negative_cap = player_reference.mach_params.MAX_LAUNCH_DOWN
		if v_air_spd >= 0 then
		  has_capped = v_air_spd > vertical_positive_cap
		  v_air_spd = mMin(vertical_positive_cap, v_air_spd)
		else
		  has_capped = v_air_spd < -vertical_negative_cap
		  v_air_spd = mMax(-vertical_negative_cap, v_air_spd)
		end
		if has_capped then
		  local new_spd = mAbs((h_air_spd * ratio))
		  h_air_spd = new_spd
		end
	    SetPlayerSpeed("x", h_air_spd, false)
	    SetPlayerSpeed("y", v_air_spd, false)
	  end
	else
	  if my_lua_state == "Falling" then
	    local mass_n = player_reference.slope_params.MASS * (GetGravityForce()/100) * -1 -- So that it forces you downward
	    local y_spd = GetPlayerSpeed("y", false)
	    local drag_spd_x = ComputeDrag(spd) -- from standard_states
	    local drag_spd_y = ComputeDrag(y_spd)
	    local v_force = ((mass_n - drag_spd_y)/20) -- 20 is the player weight, in kilograms
	    local x_force = drag_spd_x * X_MULTI
	    v_force = v_force * 1/60
	    x_force = (x_force * 1/60) * -1
	    local final_spd = y_spd + v_force -- v_force is already negative)
		local final_x = spd + x_force
	    SetPlayerSpeed("y", final_spd, false)
	    SetPlayerSpeed("x", final_x, false)
		
		--SetFastLuaValue("c_run_speed_max", final_x)
		--SetFastLuaValue("c_jump_run", final_x)
		--SetFastLuaValue("c_jump_walk", final_x)
		--SetFastLuaValue("c_jump_speed", y_spd)
	  else
	    SetGravityForce(980)
	  end
	end
  end
end


local base_accel = 100
local base_rotation_rate = 80
local top_spd = 2500
local min_spd = -1000
function BoardStep(delta)
  local new_pos_y = GetPlayerPos("y")
  slope_upward = new_pos_y > last_pos_y
  last_pos_y = new_pos_y
  ground_magnitude, ground_supplement, ground_sine, ground_cosine = CalculateDataByNormal(true)
  ground_magnitude = slope_upward and ground_magnitude * -1 or ground_magnitude
  local my_accel = base_accel + (ground_magnitude)
  --SetSnowboardLuaValue("c_acceleration", my_accel)
  local my_spd = GetPlayerSpeed("x", false)
  local add_spd = my_spd + (my_accel * G_DELTA_TIME)
  if add_spd > GetSnowboardLuaValue("c_max_speed") then
    add_spd = GetSnowboardLuaValue("c_max_speed")
  elseif add_spd < GetSnowboardLuaValue("c_min_speed") then
    add_spd = GetSnowboardLuaValue("c_min_speed")
  end
  player.print(my_accel)
  if IsGrounded() then
    SetPlayerSpeed("x", add_spd, false)
    if GetPlayerState() == 2 then
	  SetPostureLuaValue("c_rotation_speed", 160, true)
	else
      SetPostureLuaValue("c_rotation_speed", base_rotation_rate, true)
	end
	if GetPlayerState() == 1 then
	  SetContextFlag("BoardRotationLocked", false)
	end
  else
    SetPostureLuaValue("c_rotation_speed", 20, true)
	SetContextFlag("BoardRotationLocked", false)
  end
end