-- @BRIEF: Sets variables used for the new rail grinding mechanics.

local rail_direction = "straight" -- Direction of the curve. "straight" means there's no significant curve
local straight_timer = 0 -- Time you've been heading straight, resets when direction changes
local xr, zr = 0, 0 -- X_rotation, Z_rotation
local old_xr, old_zr = 0, 0 -- Previous X/R rotation
local straight_frame_counter = 0 -- Frames you've been heading straight
local straight_threshold = 6 -- Begin incrementing straight_timer after straight_frame_counter exceeds this value
local STR_TIMER_THRESH = 1.1/60 -- Time before setting direction to straight
RailDirection = DebugLabel("", 10, 600) --450

function GetRotationDirection(z_rot, x_rot, x_increasing, z_increasing)
  local final_direction = rail_direction
  if straight_timer >= STR_TIMER_THRESH then
	 final_direction = "straight"
  elseif z_rot <= 1 and z_rot >= 0 then
	if x_increasing then
	  final_direction = "left"
	else
	  final_direction = "right"
	end
  elseif z_rot >= -1 and z_rot < 0 then
	if x_increasing then
	  final_direction = "right"
	else
	  final_direction = "left"
	end
  
  elseif x_rot <= 1 and x_rot >= 0 then
	if z_increasing then
	  final_direction = "right"
	else
	  final_direction = "left"
	end
  elseif x_rot >= -1 and x_rot < 0 then
	if z_increasing then
	  final_direction = "left"
	else
	  final_direction = "right"
	end
  end
  return final_direction
end

function GetRotationDelta(x_rot, old_x_rot, z_rot, old_z_rot, x_increasing, z_increasing)
  local dX = x_increasing and x_rot - old_x_rot or old_x_rot - x_rot
  local dZ = z_increasing and z_rot - old_z_rot or old_z_rot - z_rot
  dX = mFloor(dX * 100)/100
  dZ = mFloor(dZ * 100)/100
  return dX, dZ
end

function SetRailDirection(delta_time)
  xr, zr = GetPlayerRotation(0)
  local x_increasing = old_xr < xr
  local z_increasing = old_zr < zr
  local delta_X, delta_Z = GetRotationDelta(xr, old_xr, zr, old_zr, x_increasing, z_increasing)
  if straight_frame_counter >= straight_threshold then
	straight_timer = straight_timer + delta_time
  end
  if delta_X <= 0.001 and delta_Z <= 0.001 then
	straight_frame_counter = straight_frame_counter + 1
  else
	straight_frame_counter = 0
	straight_timer = 0
  end
  rail_direction = GetRotationDirection(zr, xr, x_increasing, z_increasing)
  local curve_dir = rail_direction
  if old_xr ~= xr then
	old_xr = xr
  end
  if old_zr ~= zr then
	old_zr = zr
  end
  return curve_dir
  --RailDirection:SetText(string.format("TURNING: %s\nDX, DZ: %.2f  %.2f\nX_ROT: %s  %.2f\nZ_ROT: %s  %.2f", rail_direction, delta_X, delta_Z, tostring(x_increasing), xr, tostring(z_increasing), zr))
end

-- Called by the rail states
function SetRailBalance(player_lean)
  local crouched = player_reference.rail_params.is_crouched
  local correct_lean = rail_direction --rail_direction == "left" and "right" or rail_direction == "right" and "left" or "straight"
  local opposite_direction = rail_direction == "left" and "right" or rail_direction == "right" and "left" or "left"
  if player_lean == correct_lean then
    player_reference.rail_params.balance_state = "balanced"
  elseif (correct_lean == "left" or correct_lean == "right") then
    if player_lean == "straight" then
	  player_reference.rail_params.balance_state = "unbalanced"
	elseif player_lean == opposite_direction then -- == rail_direction
	  player_reference.rail_params.balance_state = "flailing"
	end
  else
    player_reference.rail_params.balance_state = "unbalanced"
  end
  local balance = player_reference.rail_params.balance_state
  RailDirection:SetText(string.format("Balance: %s\nrail: %s\nmy lean: %s", balance, rail_direction, player_lean))
  UpdateBalanceMultiplier(player_reference.rail_params[balance], crouched)
end

function UpdateBalanceMultiplier(params, crouched)
  local max = crouched and params.CROUCH_MAX_MULTIPLIER or params.MAX_SPEED_MULTIPLIER
  local min = crouched and params.CROUCH_MIN_MULTIPLIER or params.MIN_SPEED_MULTIPLIER
  local c_multiplier = player_reference.rail_params.balance_multiplier
  if c_multiplier < min then
    --c_multiplier = min
  end
  --else
    player_reference.rail_params.balance_multiplier = lerp(c_multiplier, max, 1.5/60)
	--player.print("LERPED: " .. player_reference.rail_params.balance_multiplier)
	local adjusted = mFloor(player_reference.rail_params.balance_multiplier * 100)/100
	adjusted = c_multiplier < max and (adjusted + 0.01) or adjusted
	if adjusted >= max then
	  --player_reference.rail_params.balance_multiplier = max
	end
  --end
  UpdatePlayerRailSpeed(player_reference.rail_params.balance_multiplier, max, crouched)
end

function UpdatePlayerRailSpeed(spd_multi, max_multi, is_crouched)
  local current_speed = GetPlayerSpeed("x", false, false)
  local target_spd = (current_speed * spd_multi)
  local top_spd = is_crouched and player_reference.rail_params.MAX_CROUCH_SPEED or player_reference.rail_params.MAX_RAIL_SPEED
  local min_spd = is_crouched and player_reference.rail_params.MIN_CROUCH_SPEED or player_reference.rail_params.MIN_RAIL_SPEED
  -- Clamp the calculated speed value between a min and max
  target_spd = math.max(min_spd, target_spd)
  target_spd = math.min(2300 * max_multi, target_spd)
  -- Lerp towards the target speed, accounting for framerate
  target_spd = lerp(current_speed, target_spd, 1.0/60)
  SetPlayerSpeed("forward", target_spd, false)
end

-- This function is currently called via physics_manager.lub
function RailDebug(delta)
  SetRailDirection(delta)
end