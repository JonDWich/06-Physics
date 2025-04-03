-- @BRIEF: Primary physics behavior. Handles air deceleration, rotation dampening, slope physics, and more.

is_grinding = false -- Used by the physics manager for calling the rail update. Really need to just check the class instead.
is_rolling = false
local SLOPE_last_height = 0 -- Previous Y position
local SLOPE_current_height = 0 -- Current Y position
local SLOPE_total_speed = 0 -- Tracks gimmick speed (unused)
local SLOPE_additional_speed = 0 -- Additional bonus from grav. accel.
local SLOPE_update_timer = 0 
local SLOPE_timer_threshold = 1/60 --0.016 -- How often to run the calculations
SLOPE_height_speed = 0 -- (current_height/last_height)/timer_threshold. Calculates speed on a 90 degree incline
local SLOPE_angle_threshold = 5 -- Degrees. How steep the incline must be before physics take effect
SLOPE_is_downward = false -- Checks if you're traveling up or down
local SLOPE_current_gimmick_speed = 0 -- Tracks gimmick speed, aka speed added from slope physics
local SLOPE_MAX_ANGLE = 90 -- Angle needed for the maximum speed boost
local SLOPE_FORCE_FALL_ANGLE = 60 -- Angle threshold for instantly dropping to 0 speed upon neutral sticking
local SLOPE_is_force_kickoff = 0 -- Tracker for how many update periods you've neutral sticked (in a case where it can kick you off a slope/reset spd)
local SLOPE_FORCE_OFF_THRESHOLD = 7 -- # of update periods before kicking you off, used with SLOPE_is_force_kickoff.
local SLOPE_lerped_accel = 0 -- Deceleration gets lerped

local MIN_DELTA_Y = (0.08333 * SLOPE_timer_threshold) -- Minimum change in Y value to trigger 
local ignore_frame_count = false -- Once physics kick in, update every frame until accel goes back to 0
local FRAME_THRESH = 35
local frame_count = 0

g_last_ground_speed = 0 -- Acceleration from slopes, updated while grounded, used when you enter a state like water sliding.
g_my_curve = "straight"
g_lock_rotation = false
local is_dashpanel_cooldown = false -- Force standard decel when affected by a dash panel.

local jump_run_current = 0
local player_max_run = 1700 -- Updated in slope_step for now, used in a lot of calculations as the default max run speed (pulled from player_reference)

local accumulated_vert = 0 -- Slope launch
local was_grounded = true
local last_total_speed = 0

g_ground_magnitude = 0
g_ground_supplement = 0
g_ground_sine = 0
g_ground_cosine = 0

local mission_ptr = GetMissionPointer() --Just placed this here for convenience, totally unused.

function SetAngleThreshold(val)
  SLOPE_angle_threshold = val
end

--AccelText = DebugLabel("", 0, 550)
--PosText = DebugLabel("", 0, 625)
--HeightText = DebugLabel("", 0, 600)
slope_angle = DebugLabel("", 475, 600)
--frame_ignore = DebugLabel("", 0, 650)

-- These are getting used in functions that run per frame, so may as well optimize a bit.

function lerp(start_val, end_val, time)
  return start_val * (1 - time) + (end_val * time)
end

function HandleOverByAnimation() -- Checks if you're in a valid "OverRun" state. If not, notify deceleration reversion to kick in.
  is_grinding = player_reference.current_class == "Grind" 
  is_rolling = GetLuaClass() == "Roll" --GetCurrentAnimation("0x52", true)
  local is_lightdash = GetCurrentAnimation("0x64", true)
  --local anim_decimal, anim_hex = GetPlayerAnim()
  if is_grinding then -- Rail grinding
    
	return true
  elseif is_rolling then -- Spin Dash
    
	return true
  elseif is_lightdash then -- Light Dash
    
	return true
  end
  return false
end

function ResetAdditionalHandlers()
  SLOPE_is_force_kickoff = 0
end

function CalculateAngleBySpeed(speed, max_speed, existing_bonus)
  if existing_bonus < 0 then -- Flips the negative speed from going uphill for this calculation.
    speed = speed - existing_bonus
  end
  local normalized_speed = speed/max_speed
  local angle = mAbs(normalized_speed * 90)
  return angle
end

function CalculateAcceleration(angle)
  local PLAYER_MASS = player_reference.slope_params.MASS
  local GRAVITY = player_reference.slope_params.GRAVITY
  local radians = mRad(angle)
  local parallelGravity = PLAYER_MASS * GRAVITY * mSin(radians)
  local acceleration = parallelGravity / PLAYER_MASS
  acceleration = mFloor(acceleration * 100)
  return acceleration/100
end

function slerp(q1, q2, t)
    -- Ensure quaternions are normalized
    local function normalize(quat)
        local length = math.sqrt(quat[1]^2 + quat[2]^2 + quat[3]^2 + quat[4]^2)
        return {quat[1] / length, quat[2] / length, quat[3] / length, quat[4] / length}
    end
    
    q1 = normalize(q1)
    q2 = normalize(q2)
    
    -- Calculate dot product
    local dot = q1[1] * q2[1] + q1[2] * q2[2] + q1[3] * q2[3] + q1[4] * q2[4]
    
    -- Ensure shortest path by reversing one quaternion if necessary
    if dot < 0 then
        for i = 1, 4 do
            q2[i] = -q2[i]
        end
        dot = -dot
    end
    
    -- Clamp dot product to ensure interpolation doesn't exceed 180 degrees
    dot = math.max(-1, math.min(dot, 1))
    
    -- Calculate angle between quaternions
    local theta_0 = math.acos(dot)
    
    -- Interpolate quaternions
    local q_intermediate = {}
    for i = 1, 4 do
        q_intermediate[i] = (q1[i] * math.sin((1 - t) * theta_0) + q2[i] * math.sin(t * theta_0)) / math.sin(theta_0)
    end
    
    return q_intermediate
end

function CalculateAngleBySurface()
  local my_quat = {0, 0, 0, 0}
  local expected_quat = {0.707106, 0, 0.707106, 0} -- Expected quaternion for a 90-degree incline, generated from quat.yrot(90) 
  my_quat[1], my_quat[2], my_quat[3] = SurfaceGetPlayerRotation()
  local interpolated_quat = slerp(my_quat, expected_quat, 0.05)
  local angle = interpolated_quat[3]
  angle = mAbs(mFloor(angle * 100)/100)
  --angle = mMin(angle, 90)
  return angle, interpolated_quat[1], interpolated_quat[2], interpolated_quat[3]
end

TestLab = DebugLabel("", 500, 300)
function CalculateDataByNormal(is_snowboard) -- Calculates the realistic gravitational accel based on the normal of the ground
  local normal = not is_snowboard and GetGroundNormal() or GetGroundNormalSnowboard()
  if not (normal[2] > 2) and not (normal[2] < 2) then -- Trying to fix a weird despawn bug
    normal[1] = 0 
    normal[2] = 0
	normal[3] = 0
  end
  local gravity = {0, -9.81, 0}
  local perpendicular = normal[2] * gravity[2] -- The perpendicular force of gravity. Usually multiply all parts of the vectors.
  local perpendicular_vector = {} -- Perpendicular gravity vector
  local parallel_vector = {} -- Parallel gravity vector
  local mag_vec = {} -- Convert the parallel vector to a float representing the force applied.
  for i = 1, 3 do
    perpendicular_vector[i] = perpendicular * normal[i]
    parallel_vector[i] = gravity[i] - perpendicular_vector[i]
    mag_vec[i] = parallel_vector[i]^2 -- Euclidean norm
  end
  local magnitude = mSqrt(mag_vec[1] + mag_vec[2] + mag_vec[3]) -- Euclidean norm
  magnitude = mFloor(magnitude * 100)
  local ang = mAcos(normal[2])
  ang = mDeg(ang)
  local supplement = mFloor((180 - ang)*100)/100
  local sup_sine = mAbs(mSin(mRad(supplement)))
  local sup_cos = mAbs(mCos(mRad(supplement)))
  --TestLab:SetText(string.format("X: %.2f\nY: %.2f\nZ: %.2f\nAng: %.2f\nReal: %.2f", normal[1], normal[2], normal[3], ang, supplement))
  if not (supplement > 2) and not (supplement < 2) then supplement = 0 end -- Check to hopefully prevent the random black screen when applying this to the player.
  if not (magnitude > 2) and not (magnitude < 2) then magnitude = 0 end
  if not (sup_sine > 2) and not (sup_sine < 2) then sup_sine = 0 end
  if not (sup_cos > 2) and not (sup_cos < 2) then sup_cos = 0 end
  return magnitude, supplement, sup_sine, sup_cos
end

function ApplySpeedByNormal(current_speed, is_down) -- Also unused right now. Adds speed when walking, for some reason?
  if GetPlayerSpeed("forward", false) < 10 then 
    return
  end
  local max_speed = g_ground_magnitude
  local accel_time = 2 -- Time to reach max speed from a standstill, per the player lua
  local fps = 60
  local speed_per_second = max_speed/accel_time
  local speed_per_frame = speed_per_second/fps
  speed_per_frame = not is_down and (speed_per_frame * -1) or (speed_per_frame + GetPlayerLuaValue("c_brake_dashpanel")/60)
  if current_speed < 980 and current_speed > -980 then
    SetPlayerSpeed("forward", current_speed + speed_per_frame, true)
  end
end

local BASE_ROTATION_SPEED = 800

function UpdateRotationForce()
  local gimmick_x = GetPlayerSpeed("x", true)
  if not IsGrounded() then
    gimmick_x = GetPlayerSpeed("x", false)
  end
  local add_rot = math.max(250, BASE_ROTATION_SPEED - gimmick_x/3)
  local add_border = (gimmick_x/1.5)
  SetRotationSpeed(add_rot)
  --SetRotationSpeedBorder(add_border)
  if GetInput("y") then
    print("ROT: " .. add_rot .. " BORDER: " .. add_border)
  end
end

function UpdateRollRotation()
  local spd = GetPlayerSpeed("total")
  if spd >= player_reference.slope_params.ROLL_RESTRICTED_HIGH_SPD then
    --[[if spd < 0 then spd = spd * -1 end
    local standard_resistance_cap = 500
	local ratio = mFloor(player_reference.slope_params.ROLL_RESTRICTED_TURNING_SPD/spd)
	local new_rot = ratio * standard_resistance_cap
	SetRotationSpeed(new_rot)
	if GetInput("y") then print("ROT: " .. new_rot .. " RATIO: " .. ratio .. " SPD: " .. spd) end]]
	SetRotationSpeed(200)
  elseif spd >= player_reference.slope_params.ROLL_RESTRICTED_MID_SPD then
    SetRotationSpeed(300)
  else
    SetRotationSpeed(800)
  end
end

function UpdateRotationInTurn(delta)
  local is_roll = false
  if GetLuaClass() == "Roll" then
    UpdateRollRotation()
	is_roll = true
  elseif GetLuaClass() == "Gear" then
    return
  elseif not g_lock_rotation then
    UpdateRotationForce()
  end
  g_my_curve = SetRailDirection(delta)
  if g_my_curve ~= "straight" then
    -- Depending on camera, it's possible to hold "forward" but have it read as 0. bit.AND(groundflag, 2^15) should tell if I'm holding away from cam tho
	local stick_Y = mAbs(GetStickInput("L", "Y", true))--math.max(0, GetStickInput("L", "Y", true) * -1)
	local gimmick = GetPlayerSpeed("x", true, false)
	local lockout = GetInputLockout(false)
	if lockout == 0 and gimmick > 0 and stick_Y <= 0.80 then
	  if is_roll then
	    local modifier = 1.2 - stick_Y
		local dec = lerp(gimmick, gimmick/2, modifier/120)
	    SetPlayerSpeed("forward", dec, true)
	  else
	    local modifier = 1.2 - (stick_Y) -- $ Adjust to 1.2 if this feels bad.
	    local rotation_decrease = lerp(gimmick, 0, modifier/60)
	    SetPlayerSpeed("forward", rotation_decrease, true)  
	    --if mAbs(stick_Y) <= 0.95 then -- Constant brake
		  --SetPlayerSpeed("forward", gimmick - (160/60), true)
	    --end
	  end
	end
  end
end

-- This function is used in other scripts, but it's not in player_utilities because it relies on UpdateRotationInTurn to update it
function IsPlayerTurning()
  return g_my_curve ~= "straight"
end

function ManageDownforce(slope_downward, delta_y)
  if player_reference.downforce_override then
    return
  elseif delta_y < MIN_DELTA_Y then
    SetDownforce(60)
	return
  end
  local force_applied = 60 --slope_downward and 16 or 8 -- For now, let's just try keeping it at 60.
  SetDownforce(force_applied)  
end

local blacklist_air_states = {
  [17] = true, -- Spring
  [18] = true, -- Wide spring/rope
  [19] = true, -- Spring
  [21] = true, -- Jump panel
  [31] = true, -- Chain Jump
  [32] = true, -- Rainbow Ring
  [39] = true, -- Spring
  [66] = true, -- Homing attack
  [72] = true, -- Light Dash
}
local blacklist_on = false
function CheckAirBlacklist(state_check)
  if blacklist_air_states[state_check] or blacklist_on then
    blacklist_on = true
    return true
  else
    return false
  end
end

function ManageAirDeceleration(state_check)
  --SetRotationSpeed(BASE_ROTATION_SPEED)
  --SetRotationSpeedBorder(0)

  -- A "pushback" can be replicated (at least when walking) by removing the < 0 check and taking the abs of GetPlayerSpeed("total")
  local max_jump = player_reference.base_jump_speed
  --if blacklist_air_states[state_check] or blacklist_on then
  if (state_check == 17 or state_check == 18) and GetInputLockout() == 0 and GetPlayerSpeed("x", true) == 0 then
    SetPlayerLuaValue("c_jump_run", 900)
	SetPlayerLuaValue("c_jump_walk", 150)
	SetPlayerLuaValue("c_jump_speed", player_reference.base_jump_speed)
  elseif CheckAirBlacklist(state_check) then
    SetPlayerLuaValue("c_jump_run", 900) -- Max horizontal air speed from a non-stationary jump
	SetPlayerLuaValue("c_jump_walk", 150) -- Max horizontal air speed from a stationary jump
	SetPlayerLuaValue("c_jump_speed", player_reference.base_jump_speed) -- Vertical boost
    return
  end
  local total = GetPlayerSpeed("total")
  jump_run_current = total
  if GetPlayerSpeed("x", true) < 0 then
    SetPlayerSpeed("x", 0, true)
  end
  local stick_Y = GetStickInput("L", "Y", true)
  local stick_X = GetStickInput("L", "X", true)
  if (stick_Y < 0.1 and stick_Y > -0.1) and (stick_X < 0.1 and stick_X > -0.1) then -- Quickly drop to 0 if you release the left stick
    jump_run_current = lerp(jump_run_current, 0, 2.5/60) -- 1.5
  elseif jump_run_current > player_reference.slope_params.base_jump_run then -- If above regular jump speed, decelerate to it.
	jump_run_current = lerp(jump_run_current, player_reference.slope_params.base_jump_run, 1.1/60)
  elseif jump_run_current < player_reference.slope_params.base_jump_run then -- If below regular jump speed, accelerate to it.
	jump_run_current = lerp(jump_run_current, player_reference.slope_params.base_jump_run, 1.5/60) -- 2
  end
  local jump_vert = GetPlayerLuaValue("c_jump_speed") --math.max(max_jump, GetPlayerLuaValue("c_jump_speed")) -- Not currently used
  if jump_vert > max_jump then
	jump_vert = lerp(jump_vert, max_jump, 0.75/60)
  end
  local shrink_on = GetPlayerName() == "sonic" and GetContextFlag("IsShrink") or nil
  if shrink_on then
    local gem_spd = total - (total * PlayerList.sonic.sonic_gem_params.purple.air_drag_rate)/60
	if state_check == StateID.GEM_PURPLE then
      SetPlayerSpeed("x", gem_spd, false)
	  SetPlayerLuaValue("c_jump_run", jump_run_current)
      SetPlayerLuaValue("c_jump_walk", jump_run_current)
	else
	  if jump_run_current > gem_spd - 0.1 then gem_spd = jump_run_current end -- This prevents decelerating towards 0 when airborne and shrunk
	  SetPlayerLuaValue("c_jump_run", gem_spd - 0.1)
      SetPlayerLuaValue("c_jump_walk", gem_spd - 0.1)
	end
  else
    if state_check == StateID.GEM_PURPLE and GetPlayerName() == "sonic" then
      SetPlayerSpeed("x", jump_run_current, false)
	end
	SetPlayerLuaValue("c_jump_run", jump_run_current)
    SetPlayerLuaValue("c_jump_walk", jump_run_current)
  end
  --SetPlayerLuaValue("c_jump_run", jump_run_current)
  --SetPlayerLuaValue("c_jump_walk", jump_run_current)
  SetPlayerLuaValue("c_jump_speed", jump_vert)
  --SetPlayerLuaValue("c_flight_speed_max", mMax(1700, jump_run_current))
  if state_check == 4 and GetInput("a", "hold") then
    SetPlayerSpeed("y", jump_vert, false) -- This causes water bounce, maybe remove?
  end
  
  SetPlayerLuaValue("c_run_speed_max", math.max(jump_run_current, player_max_run)) -- Carries air speed into the ground when landing
end

local guide_countdown = 30
function OLDManageAerialLaunch(surface_angle, speed_angle, state_check) -- Approximates carrying vertical speed when transitioning to the fall state.
  if IsOnGuide() and GetInputLockout() > 0.1 then
    guide_countdown = 30 -- Temporarily disable an aerial launch when you hit a guide spline. Some loops break otherwise
  end
  if guide_countdown > 0 or CheckAirBlacklist(state_check) then
    guide_countdown = guide_countdown - 1
	if guide_countdown <= 0 then guide_countdown = 0 end
    return
  end
  if surface_angle >= 0.1 then
	local total_spd = mAbs(GetPlayerSpeed("total"))
	local base_x = mMin(player_max_run, GetPlayerSpeed("x", false))
	total_spd = total_spd - base_x
	local launch_spd = total_spd/1.5 * (surface_angle/1)
	launch_spd = SLOPE_is_downward and (launch_spd * -1) or launch_spd
	--SetPlayerSpeed("y", launch_spd, true) -- Y Speed won't proc until you leave the ground, and if you jump, it gets reset anyway.
	accumulated_vert = launch_spd
  else
	--SetPlayerSpeed("y", 0, true)
	accumulated_vert = 0
	-- Logically, this looks sketchy to remove, but functionally it hasn't caused issues *yet*. Having this call breaks the Wave Ocean orca chase. Dunno why.
  end
end

function ManageAerialLaunch(state_check)
  -- Store the calculated value but don't actually apply it until the player enters the fall state? Maybe?
  if IsOnGuide() and GetInputLockout() > 0.1 then
    guide_countdown = 30 -- Temporarily disable an aerial launch when you hit a guide spline. Some loops break otherwise
  end
  if guide_countdown > 0 or CheckAirBlacklist(state_check) then
    guide_countdown = guide_countdown - 1
	if guide_countdown <= 0 then guide_countdown = 0 end
    return
  end
  if g_ground_supplement >= 10 then
    local height_diff = SLOPE_is_downward and (SLOPE_last_height - SLOPE_current_height) or (SLOPE_current_height - SLOPE_last_height)
    local total_spd = GetPlayerSpeed("total")--mAbs(GetPlayerSpeed("forward", false)) + mAbs(GetPlayerSpeed("forward", true))
	local base_spd = mMin(player_max_run, GetPlayerSpeed("x", false))
	local gimmick_spd = GetPlayerSpeed("forward", true)
	if true or gimmick_spd >= 0 then
	  --total_spd = total_spd - 0 --base_spd -- Screw it, realistic launches for now
	  local valid_base_spd = mMin(base_spd, mAbs(gimmick_spd))
	  if valid_base_spd < 500 then
	    valid_base_spd = 500
	  end
	  total_spd = gimmick_spd >= 0 and (gimmick_spd + valid_base_spd) or valid_base_spd
	end
	local launch_Y = total_spd/1.0 * g_ground_sine--total_spd/1.25 * g_ground_sine
	launch_Y = mFloor(launch_Y * 100)/100
	launch_Y = mMin(2500, launch_Y)
	launch_Y = SLOPE_is_downward and (launch_Y * -1) or mAbs(launch_Y) -- Try to prevent getting spiked down at the end of a ramp.
	if not (launch_Y > 2) and not (launch_Y < 2) then
	  launch_Y = 0 -- Sometimes an invalid number gets calculated, causing Sonic to despawn constantly.
	end
	--SetPlayerSpeed("y", launch_Y, true)
	accumulated_vert = launch_Y
  else
    accumulated_vert = 0
  end
end

local has_set_speed = false
function ConserveSpeedByState(state)
  if state == StateID.WATER_SLIDE then -- Waterslider
    if g_last_ground_speed > player_reference.slope_params.TOP_AIR_SPEED then
	  g_last_ground_speed = lerp(g_last_ground_speed, player_reference.slope_params.TOP_AIR_SPEED, 0.5/60)
	end
	slope_angle:SetText(string.format("AIR LERP: %.2f", g_last_ground_speed))
	--SetPlayerSpeed("forward", 2300, false)
	SetPlayerSpeed("forward", g_last_ground_speed, true)
	--SetPlayerSpeed("forward", 2300, false)
	--SetPlayerSpeed("forward", 0, true)
  elseif state == StateID.LIGHT_DASH then
    SetPlayerLuaValue("c_run_speed_max", math.max(5000, player_max_run))
  elseif state == StateID.GRIND and not has_set_speed then
    has_set_speed = true
	SetPlayerSpeed("x", last_total_speed/2, true)
  end
end

local algo_adv = true
function SetAlgo(is_on)
  algo_adv = is_on or false
end

local reset_vert_states = {
  [4] = true, -- jump
  [5] = true, -- water jump
  [9] = true, -- damage
  [12] = true, -- grind
  [17] = true, -- spring
  [23] = true,
  [31] = true, -- chain jump
  [72] = true, -- light dash
}

is_slipback = false
USE_SLOPE_SLIPBACK = false
WAS_ROLL = false
function ForceSlipback()
  if not USE_SLOPE_SLIPBACK or not IsOnGuide() or (IsOnGuide() and GetInputLockout() > 0 and GetPlayerState() ~= 6) then -- Mach Speed enters Dramatic Jump if he hits a Chain Jump.
    return
  end
  local total = GetPlayerSpeed("total")
  if not is_slipback and total <= 100 and total >= 0 then
    SetPlayerSpeed("x", 0, false)
	SetPlayerSpeed("x", -250, true)
	SetInputLockout(0.25)
	if GetLuaClass() == "Roll" then
	  WAS_ROLL = true
	end
	SetPlayerState(6)
	if WAS_ROLL then ChangePlayerAnim("jump_alt") end
	is_slipback = true
  elseif is_slipback then
    SetPlayerState(6)
	if WAS_ROLL then ChangePlayerAnim("jump_alt") end
	--SetInputLockout(0.1)
	local slip = GetPlayerSpeed("x", true)
	slip = lerp(slip, slip - 500, 1.5/60)
	SetPlayerSpeed("x", slip, true)
  end
end


TEST_TIMER = 0
has_reset_force = false
time_slow = false
my_last_pos = {}
wait_timer = 0

char_idx = 0
char_list = {"0x8D", "0x242",}
-- entire effect, Blue smoke trail behind (unused?), activation blue orb?, charge blue orb, charge blue orb (no lines)
anim_timer = 1/60

G_BRAKE_RATE = 1000
function SlopeStep(delta)
  if GetInput("dpad_right") then
    local pos = GetPlayerPos()
    char_idx = mMin(char_idx + 1, table.getn(char_list))
	--Game.NewActor("particle",{bank="player_shadow", name = char_list[char_idx], cycle = 0, cyclewidth = 0, sebank = "", sename = ""},{Position = Vector(pos.X,pos.Y + 25,pos.Z) , Rotation = Vector(1,0,0,0)})
	--PlayerSwap(char_list[char_idx])
	anim_timer = anim_timer + 1/60
	--dofile("game:\\Hud_TEST.lua")
	--player.print(anim_timer * 60)
	--player.print(char_list[char_idx])
	--TestIndividualByte(char_idx)
  elseif GetInput("dpad_left") then
    char_idx = mMax(char_idx - 1, 1)
	local pos = GetPlayerPos()
	--Game.NewActor("particle",{bank="player_shadow", name = char_list[char_idx], cycle = 0, cyclewidth = 0, sebank = "", sename = ""},{Position = Vector(pos.X,pos.Y + 25,pos.Z) , Rotation = Vector(1,0,0,0)})
	--PlayerSwap(char_list[char_idx])
	anim_timer = anim_timer - 1/60
	--player.print(anim_timer * 60)
	--player.print(char_list[char_idx])
	--TestIndividualByte(char_idx)
  end
  --if GetInput("y") then TestCharBytes() end
  if false and time_slow then
    SetCurrentAnimationTime(anim_timer)
  end
  if GetInput("rt", "hold") and GetInput("a", "hold") then
    --local _, err = pcall(dofile, "game:\\HUD_Test.lua")
    if GetInput("y") then
      --SetPlayerPos(21558, -981, -28723, true)
	  PlayerSwap("amy")
	elseif GetInput("x") then
	  --SetPlayerPos(12990, 1691, -32476, true)
	end
  end
  local my_state = GetPlayerState()
  if GetLuaClass() ~= "Grind" then
    has_set_speed = false
  end
  if my_state == 4 and not has_reset_force then
    SetDownforce(0)
	TEST_TIMER = 12
	has_reset_force = true
  end
  if TEST_TIMER > 0 then
    TEST_TIMER = TEST_TIMER - 1
	if TEST_TIMER <= 0 then
	  TEST_TIMER = 0
	  SetDownforce(60)
	end
  end
  ConserveSpeedByState(my_state)
  last_total_speed = GetPlayerSpeed("total")
  --local val_handle = GetPlayerMemoryValue("add", 234)
  --SetPlayerMemoryValue("byte", val_handle, 1)
  
  --Player(0):GetMachine2():OnStateConnect("OnStartP", 2, function(State)
    --player.print("Running")
  --end)
  local debug_pos = GetPlayerPos("ALL")
  if my_state == 66 and (debug_pos.X < 100 and debug_pos.X > -100) and (debug_pos.Z < 100 and debug_pos.Z > -100) and (debug_pos.Y < 100 and debug_pos.Y > -100) then -- Chaos Snap shenanigans
    --SetPlayerPos(my_last_pos.X, my_last_pos.Y, my_last_pos.Z, true)
	wait_timer = 1
  end
  if wait_timer == 0 then
    my_last_pos = GetPlayerPos()
  else
    wait_timer = wait_timer + 1
	if wait_timer > 2 then
	  SetPlayerPos(my_last_pos.X, my_last_pos.Y, my_last_pos.Z, true)
	  wait_timer = 0
	end
  end
  -- 0x10B Goal Camera mode?
  -- 0x10D Kill on 0 rings
  if GetInput("y") then
    --SetPlayerTimeScale(2)
	--SetPlayerTimeScale(not time_slow and -1 or 1)
	--SetPlayerLuaValue("c_brake_dashpanel", not time_slow and 0 or 450)
	time_slow = not time_slow
	local _, err = pcall(dofile, "game:\\HUD_Test.lua")
	--local test_v = GetTestValues(time_slow)
	--PrintOutput(test_v)
	--SetPlayerPos(8825, 20001, -147837, true)
    --DefineProcess("Test", TestSleep)
	--PlayProcess("Test")
	--print("X: " .. debug_pos.X .. " Y: " .. debug_pos.Y .. " Z: " .. debug_pos.Z)
	--GetPlayerPosture()
	--DefineGrab({38707, 9193, 27315}, {40047, 9193, 27539}, 10)
  end
  local y_height = GetPlayerPos("Y") 
  SLOPE_last_height = SLOPE_current_height
  SLOPE_current_height = y_height --GetPlayerPos("Y")
  if IsGrounded() or my_state == 53 then
    if has_reset_force then has_reset_force = false end
  
    g_ground_magnitude, g_ground_supplement, g_ground_sine, g_ground_cosine = CalculateDataByNormal()
	if is_slipback and g_ground_supplement < player_reference.slope_params.SLIPBACK_RETURN then
	  is_slipback = false
	  WAS_ROLL = false
    elseif g_ground_supplement > player_reference.slope_params.SLIPBACK_ANGLE or is_slipback then
	  ForceSlipback() -- $$$$ SLIPBACK
	  if is_slipback then return end
    end
	
    was_grounded = true
    local run_spd = GetPlayerLuaValue("c_run_speed_max")
	player_max_run = player_reference.max_run_spd
	if run_spd > player_max_run then
	  run_spd = lerp(run_spd, player_max_run, 1.5/60)
	  if run_spd < player_max_run + 50 then
	    run_spd = player_max_run
	  end
	  SetPlayerLuaValue("c_run_speed_max", run_spd) -- Gradually decrease your top run speed rather than snapping it back down.
	elseif run_spd < player_max_run then
	  SetPlayerLuaValue("c_run_speed_max", player_max_run)
	end
	
	if my_state == StateID.DASH_PANEL then
	  is_dashpanel_cooldown = true
	end
	if is_dashpanel_cooldown and GetInputLockout() <= 0.01 then
	  is_dashpanel_cooldown = false
	end
  
    --blacklist_on = false -- Restore air physics. They get disabled after hitting a spring or the like
    local jump_bias_multiplier = SLOPE_is_downward and -0.25 or 1
    SetPlayerLuaValue("c_jump_run", player_reference.base_jump_speed + GetPlayerSpeed("x", true)) -- Allows maintaining speed in a jump
	--SetPlayerLuaValue("c_jump_speed", 900 + (CalculateAngleBySurface() * jump_bias_multiplier))
	if GetPlayerSpeed("total") ~= 0 then -- Slope jumps btw
	  SetPlayerLuaValue("c_jump_speed", player_reference.base_jump_speed + mFloor(g_ground_magnitude * jump_bias_multiplier))
	else
	  SetPlayerLuaValue("c_jump_speed", player_reference.base_jump_speed)
	end
	
	
    if is_grinding and not player_reference.rail_params.use_physics == true then
	  return
	end
	
	------Rotation Deceleration Block------
	if GetLuaClass() ~= "Grind" then -- GetLuaClass() ~= "Roll" and 
	  UpdateRotationInTurn(delta)
	end
	------Rotation Deceleration Block------
	
	SLOPE_total_speed = GetPlayerSpeed("x", false)
    SLOPE_update_timer = SLOPE_update_timer + delta
	if SLOPE_update_timer >= SLOPE_timer_threshold then	  
	  SLOPE_current_gimmick_speed = GetPlayerSpeed("x", true, false)	  
	  SLOPE_additional_speed = 0
	  SLOPE_height_speed = 0
	  SLOPE_update_timer = 0
	  if GetCurrentAnimation("0x45", true) or GetCurrentAnimation("0x70", true) or GetCurrentAnimation("0xA", true) then -- Spin Kick, Antigrav
	    if GetCurrentAnimation("0xA", true) then -- Skid
		  local lerp_to_0 = lerp(SLOPE_current_gimmick_speed, 0, 1.5/60)
		  if lerp_to_0 <= 50 and lerp_to_0 >= -50 then lerp_to_0 = 0 end
		  SetPlayerSpeed("forward", lerp_to_0, true)
		end
	    return
	  end
	  local height_diff = 0
      if SLOPE_last_height > SLOPE_current_height then -- Player moving downwards
	    height_diff = SLOPE_last_height - SLOPE_current_height
		height_diff = math.floor(height_diff * 100)/100
		--if height_diff ~= 0 then HeightText:SetText("Height diff: " .. height_diff) end
	    SLOPE_height_speed = (SLOPE_last_height - SLOPE_current_height)/SLOPE_timer_threshold -- Vertical units covered in the update threshold, approximately equal to the player's downward speed.
		SLOPE_is_downward = true
		
	  elseif SLOPE_last_height < SLOPE_current_height then -- Player moving upwards
	    height_diff = SLOPE_current_height - SLOPE_last_height
		height_diff = math.floor(height_diff * 100)/100
		--if height_diff ~= 0 then HeightText:SetText("Height diff: " .. height_diff) end
		SLOPE_height_speed = (SLOPE_current_height - SLOPE_last_height)/SLOPE_timer_threshold -- Returns speed at a 90 degree angle
		SLOPE_is_downward = false
		
	  end
	  if GetLuaClass() == "Roll" then
	    return
	  end
	  --frame_ignore:SetText("IGNORE: " .. tostring(ignore_frame_count))
	  
	  local current_slope = mMin(CalculateAngleBySpeed(SLOPE_height_speed, player_max_run, SLOPE_current_gimmick_speed), SLOPE_MAX_ANGLE)
	  local stick_total = mAbs(GetStickInput("L", "X", true)) + mAbs(GetStickInput("L", "Y", true))
	  --if GetInputLockout() == 0 and stick_total == 0 and g_ground_supplement < 35 and GetLuaClass() ~= "Grind" then 
	  if IsOnGuide() then -- Testing as a replacement for the ground_supp check
	    SetPlayerLuaValue("c_brake_dashpanel", G_BRAKE_RATE)
	  elseif GetInputLockout() == 0 and stick_total == 0 and GetLuaClass() ~= "Grind" then
	    SetPlayerLuaValue("c_brake_dashpanel", 2000)
		if GetPlayerSpeed("x", true) < 0 then
		  SetPlayerSpeed("x", 0, true)
		end
		return 
	  else
	    SetPlayerLuaValue("c_brake_dashpanel", 1000)
	  end
	  --local surface_angle, mX, mY, mZ = CalculateAngleBySurface()
	  --local angle_180 = CalculateAngleBySurface(temp)
	  ManageAerialLaunch(my_state)
	  blacklist_on = false
	  
	  if not ignore_frame_count then -- Be on a sufficiently steep slope for X frames
	    if height_diff > MIN_DELTA_Y then
	      frame_count = frame_count + 1
		  if frame_count < FRAME_THRESH then
		    return
		  else
		    ignore_frame_count = true
		    frame_count = 0
		  end
	    else
	      frame_count = 0
	    end
	  end
	  
	  
	  
	  local bX_, bY_, bZ_ = SurfaceGetPlayerRotation()
	  
	  -- Adjust the lerp based on your speed and surface incline (actual slope). Higher lerp at lower speeds/slopes to allow accel to kick in
	  --local lerp_time = math.max(1 + surface_angle, (4 - surface_angle) - (SLOPE_current_gimmick_speed/750)) Saving as a backup, this is good
	  --local lerp_time = math.max(1 + surface_angle, (4 - surface_angle) - (SLOPE_current_gimmick_speed/750)) SURFACE_ANGLE VERSION
	  
	  --math.max(1 + current_slope/100, (4 - current_slope/100) - (SLOPE_current_gimmick_speed/750)) Original
	  --SLOPE_current_gimmick_speed < 500 and 5 or SLOPE_current_gimmick_speed < 1000 and 2.5 or 1.25
	  --math.max(1 + current_slope/100, (5.1 - current_slope/100) - (SLOPE_current_gimmick_speed/750)) --Good for SSH, bad elsewhere?
	  --current_slope < 15 and 4.5 or 2.35
	  local lerp_time = math.max(1 + current_slope/100, (4 - current_slope/100) - (SLOPE_current_gimmick_speed/750))
	  
	  local stick_input = mAbs(GetStickInput("L", "Y", true))

	  --local speed_cap = mMin(5000, 5000 * surface_angle/90) Not working but I want to try adjusting the speed cap based on slope?
	  slope_angle:SetText(string.format("SLOPE: %.2f\nLERP_V/SPD: %.2f | %.2f\nANGLE: %.2f\nSTICK: %.2f", current_slope, lerp_time, SLOPE_lerped_accel - SLOPE_current_gimmick_speed, g_ground_supplement, stick_input))
	  
	  local is_handle_overrun = HandleOverByAnimation()
	  
	  if current_slope >= SLOPE_angle_threshold then -- Steep slope, apply physics
	    if ignore_frame_count then
		  frame_count = 0
		end
	    SLOPE_additional_speed = mMin(CalculateAcceleration(current_slope), player_reference.slope_params.GRAVITY) -- Cap speed bonus by gravity
		--SLOPE_additional_speed = mMin(g_ground_magnitude, player_reference.slope_params.GRAVITY)
		SLOPE_additional_speed = SLOPE_is_downward and SLOPE_additional_speed * player_reference.slope_params.DOWNWARDS_BIAS or (SLOPE_additional_speed * -1) * player_reference.slope_params.UPWARDS_BIAS
		local extra_speed = SLOPE_current_gimmick_speed + SLOPE_additional_speed
		if GetInputLockout() <= 0.01 then
		  extra_speed = mMin(player_reference.slope_params.speed_cap, extra_speed) 
		end
		if GetInput("dpad_left") then print ("ADD: " .. SLOPE_additional_speed .. " EX: " .. extra_speed) end
		--SLOPE_lerped_accel = SLOPE_is_downward and lerp(SLOPE_current_gimmick_speed, extra_speed, lerp_time/60) or lerp(SLOPE_current_gimmick_speed, SLOPE_additional_speed, 1/60) TESTING HERE
		
		SetAlgo(SLOPE_is_downward)
		if not algo_adv then
		  SLOPE_lerped_accel = lerp(SLOPE_current_gimmick_speed, SLOPE_additional_speed, 0.5/60) -- 1/60
		else
		  SLOPE_lerped_accel = lerp(SLOPE_current_gimmick_speed, extra_speed, lerp_time/60) + 500/60 -- NEW
		end
		-- Check stick, slow down to 0 if neutral
		if GetInputLockout() == 0 and stick_total == 0 and GetLuaClass() ~= "Roll" and GetLuaClass() ~= "Grind" then
		  --SLOPE_lerped_accel = lerp(SLOPE_lerped_accel, 0, 2/60)
		  if SLOPE_lerped_accel <= 50 then SLOPE_lerped_accel = 0 end
		end
		--
		SLOPE_lerped_accel = mFloor(SLOPE_lerped_accel * 100)/100 -- Round it off
		g_last_ground_speed = SLOPE_lerped_accel/2
		if SLOPE_is_downward then
		  SetPlayerSpeed("forward", SLOPE_lerped_accel, true)	  
		else -- Gotta have this so that you decelerate lol. Can remove the entire conditional later, just not sure if I'll need upwards for now.
		  if SLOPE_current_gimmick_speed > 0 then --and stick_total ~= 0 
		  -- This part of the code counteracts the natural brake when going uphill while gimmick_speed > 0. 
		  -- 1000/60 strictly counteracts it and feels pretty natural, while the other formula allows stuff like naturally clearing the WVO loop,
		  -- but it lets you maintain too much speed when manually turning from downhill > uphill.
		    --SLOPE_lerped_accel = SLOPE_lerped_accel + GetPlayerLuaValue("c_brake_dashpanel")/60
			
			-- Additional speed decay while rolling uphill
		    --SLOPE_lerped_accel = SLOPE_lerped_accel + ((1450 + (surface_angle * 100 * -1))/60)
			--local counter_force = (1000 + (g_ground_magnitude * -1))/60
			SLOPE_lerped_accel = SLOPE_lerped_accel + GetPlayerLuaValue("c_brake_dashpanel")/60
		  end
		  if GetInputLockout() <= 0.01 then -- If input is not locked
		    SetPlayerSpeed("forward", SLOPE_lerped_accel, true)
		  end
		end
	  elseif current_slope >= 0 and current_slope < SLOPE_angle_threshold then -- Light/no slope
	    if ignore_frame_count then
		  frame_count = frame_count + 1
		  if frame_count >= FRAME_THRESH then
		    frame_count = 0
			ignore_frame_count = false
		  end
		end
		if GetInputLockout() <= 0.01 and not is_dashpanel_cooldown then
		  --SetPlayerLuaValue("c_brake_dashpanel", 650) --750
		else
		  --SetPlayerLuaValue("c_brake_dashpanel", 1000)
		end
		
		--ApplySpeedByNormal(SLOPE_current_gimmick_speed, SLOPE_is_downward) --$$$$$$$$
		
		--SetRotationSpeed(player_reference.slope_params.BASE_ROTATION_SPEED) -- Reset. When absent, resistance is applied on Blue Gem
		--SetRotationSpeedBorder(0)
	  end
	  ManageDownforce(SLOPE_is_downward, height_diff)
	  if SLOPE_current_gimmick_speed < 0 and not is_grinding then
	    local stick_angle = mAbs(GetStickInput("L", "Y", true)) + mAbs(GetStickInput("L", "X", true))
	    if SLOPE_total_speed > player_max_run and is_handle_overrun then -- Player has an outside force, like rails or Light Dash. Do not force decel
		  --Blank for now, might apply light deceleration later
		elseif current_slope >= SLOPE_FORCE_FALL_ANGLE and stick_angle == 0 then
		  --print("Stick was 0")
		  if SLOPE_is_force_kickoff >= SLOPE_FORCE_OFF_THRESHOLD then
		    SLOPE_additional_speed = 0
		    SetPlayerSpeed("forward", SLOPE_additional_speed, true) 
		    SetPlayerSpeed("forward", 0, false) --Drop native speed to 0
			SLOPE_is_force_kickoff = 0
		  else
		    SLOPE_is_force_kickoff = SLOPE_is_force_kickoff + 1
		    if SLOPE_is_force_kickoff > SLOPE_FORCE_OFF_THRESHOLD then
		      SLOPE_is_force_kickoff = SLOPE_FORCE_OFF_THRESHOLD
		    end
		  end
		elseif current_slope < SLOPE_angle_threshold then -- Fixes a bug where negative speed won't get reset when the ground flattens out.
		  --SLOPE_additional_speed = SLOPE_additional_speed + 1 -- Quickly increment negative speed towards 0
		  --if SLOPE_additional_speed >= 0.1 then
		    --SLOPE_additional_speed = 0
		  --end
		  local lerp_to_0 = lerp(SLOPE_additional_speed, 0, 1.5/60)
		  if lerp_to_0 > -10 then
		    lerp_to_0 = 0
		  end
		  SetPlayerSpeed("forward", lerp_to_0, true)
		elseif stick_angle == 0 then
		  --print("Angle was 0")
		  if SLOPE_is_force_kickoff >= SLOPE_FORCE_OFF_THRESHOLD then
		    SLOPE_additional_speed = 0
		    SetPlayerSpeed("forward", SLOPE_additional_speed, true) 
		    SetPlayerSpeed("forward", 0, false) --Drop native speed to 0
			SLOPE_is_force_kickoff = 0
		  else
		    SLOPE_is_force_kickoff = SLOPE_is_force_kickoff + 1
		    if SLOPE_is_force_kickoff > SLOPE_FORCE_OFF_THRESHOLD then
		      SLOPE_is_force_kickoff = SLOPE_FORCE_OFF_THRESHOLD
		    end
		  end
		end
	  else
	    ResetAdditionalHandlers()
	  end
	end  
  else
    if was_grounded then
	  if reset_vert_states[my_state] then
	    accumulated_vert = 0
	  end
	  if GetPlayerState() == StateID.FALL then
	    was_grounded = false
		if mFloor(accumulated_vert) ~= 0 then
		  SetPlayerSpeed("y", accumulated_vert, true)
		  PlayProcess("LD", accumulated_vert)
		  --SetPlayerSpeed("y", accumulated_vert, true) -- Mach Speed crashes here.
		end
		print("VERT WAS: " .. accumulated_vert)
		accumulated_vert = 0
	  else
		--print("STATE WAS: " .. GetPlayerState())
	  end
	end
	--[[local my_air_spd = GetPlayerSpeed("x", true, false) -- Sonic Team, in their infinite wisdom, forces your Z speed to 0 during jumps/falling.
	if g_last_ground_speed > player_reference.slope_params.TOP_AIR_SPEED then
	  g_last_ground_speed = lerp(g_last_ground_speed, player_reference.slope_params.TOP_AIR_SPEED, 1/60)
	end
	slope_angle:SetText(string.format("AIR LERP: %.2f", g_last_ground_speed))
	SetPlayerSpeed("forward", g_last_ground_speed, true)]]
	ManageAirDeceleration(my_state)
	
    SLOPE_additional_speed = 0
	ignore_frame_count = false
	frame_count = 0
	ResetAdditionalHandlers()
  end
  --lerped_spd:SetText(string.format("LERPED_VALUE: %.2f \nFrom: %.2f \nTo %.2f", SLOPE_lerped_accel, SLOPE_current_gimmick_speed, SLOPE_additional_speed))
end