-- @BRIEF: Custom player state implementation.
-- TODO: 
-- At this point, each character should probably have their own scripts for this.
-- Make a generic function for handling speed, similar to ExitOnAutomationCollision?

RegisterState(PlayerList.sonic, "Rolling", "Roll")
RegisterState(PlayerList.sonic, "Smashing", "Smash")
RegisterState(PlayerList.sonic, "SpinDash", "Roll")
RegisterState(PlayerList.sonic, "Flying", "Flight")
RegisterState(PlayerList.sonic, "Attacking", "Attack")
RegisterState(PlayerList.sonic, "Bounding", "Bound")
RegisterState(PlayerList.sonic, "Tornadoing", "Tornado")
RegisterState(PlayerList.sonic, "Dashing", "Dash")

RegisterState(PlayerList.sonic_mach, "Starting", "Start")
RegisterState(PlayerList.sonic_mach, "Jumping", "Jump")
RegisterState(PlayerList.sonic_mach, "Damaging", "Damage")
RegisterState(PlayerList.sonic_mach, "Bonking", "Bonk")
RegisterState(PlayerList.sonic_mach, "Falling", "Fall")
RegisterState(PlayerList.sonic_mach, "ChainJumping", "ChainJump")

RegisterState(PlayerList.tails, "Rolling", "Roll")
RegisterState(PlayerList.tails, "Flying", "Fly")
RegisterState(PlayerList.tails, "Attacking", "Attack")

RegisterState(PlayerList.knuckles, "Rolling", "Roll")
RegisterState(PlayerList.knuckles, "Attacking", "Attack")
RegisterState(PlayerList.knuckles, "Gliding", "Glide")
RegisterState(PlayerList.knuckles, "Diving", "Dive")

RegisterState(PlayerList.shadow, "Attacking", "Attack")
RegisterState(PlayerList.shadow, "Rolling", "Roll")
RegisterState(PlayerList.shadow, "SpinDash", "Roll")
RegisterState(PlayerList.shadow, "SpearingPost", "SpearPost")

RegisterState(PlayerList.rouge, "Rolling", "Roll")
RegisterState(PlayerList.rouge, "Gliding", "Glide")
RegisterState(PlayerList.rouge, "Blasting", "Blast") -- Blast Jump
RegisterState(PlayerList.rouge, "Throwing", "Throw")
RegisterState(PlayerList.rouge, "Diving", "Dive")

RegisterState(PlayerList.blaze, "Rolling", "Roll")
RegisterState(PlayerList.blaze, "Attacking", "Attack")

RegisterState(PlayerList.amy, "Rolling", "Roll")
RegisterState(PlayerList.amy, "DoubleJumping", "DoubleJump")
RegisterState(PlayerList.amy, "Attacking", "Attack") -- Grounded Hammer Attack
RegisterState(PlayerList.amy, "Vaulting", "Vault") -- Hammer Jump
RegisterState(PlayerList.amy, "Spinning", "Spin") -- Hammer Spin
RegisterState(PlayerList.amy, "Dizzying", "Dizzy") -- Post-Spin-Dizzy
RegisterState(PlayerList.amy, "AirSwinging", "AirSwing") -- Aerial attack
RegisterState(PlayerList.amy, "Stealthing", "Stealth") -- Invisibility

RegisterState(PlayerList.omega, "Hovering", "Hover")
RegisterState(PlayerList.omega, "Attacking", "Attack")


local smash_charge_val = 0
function PlayerList.sonic.states.Smashing:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  ChangePlayerAnim("screw_charge_l")
  PlaySound("player_sonic", "homing_charge")
  smash_charge_val = 0
  SetPluginValue("homing", "c_homing_damage", GetMaturityLevel())
  return self:StateEnter()
end

function PlayerList.sonic.states.Smashing:StateMain()
  if GetInput("rt", "hold") then
    smash_charge_val = mMin(self.player.sonic_gem_params.white.smash_max_charge, smash_charge_val + self.player.sonic_gem_params.white.smash_charge_rate)
	SetUniqueLuaValue("c_homing_spd", 4000 + smash_charge_val)
  elseif GetInput("rt", "released") and GetPlayerState() == 65 then
    ChangePlayerAnim("homing_after")
	if smash_charge_val >= 250 then
	  PlaySound("player_sonic", "homing_shoot")
	end
  end
end

function PlayerList.sonic.states.Smashing:StateExit()
  smash_charge_val = 0
  SetUniqueLuaValue("c_homing_spd", 4000)
  SetPluginValue("homing", "c_homing_damage", 1)
end

local dash_timer = 0
function PlayerList.sonic.states.Dashing:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  SetPlayerSpeed("x", player_reference.dash_spd, false)
  SetPlayerSpeed("x", 0, true)
  SetPlayerSpeed("y", player_reference.dash_up_initial, false)
  SetPlayerSpeed("y", 0, true)
  SetAccumulatedGravity(0)
  dash_timer = 0
  g_lock_rotation = true
  SetRotationSpeed(350)
  local gauge = GetGaugeParameter("c_gauge_value")
  if gauge < player_reference.dash_cost then
    return self:SwitchState("RESET")
  end
  ChangePlayerAnim("homing_t1")
  PlaySound("player_princess", "kickback")
  gauge = mMax(0, gauge - player_reference.dash_cost)
  SetGaugeParameter("c_gauge_value", gauge)
  SetGravityForce(player_reference.dash_gravity_force)
  self.player.dash_available = false
  return self:StateEnter()
end

function PlayerList.sonic.states.Dashing:StateMain()
  local flag = GetGroundAirFlags()
  local is_sand_water = bit.AND(flag, 2^10) ~= 0
  local spd = GetPlayerSpeed("x", false)
  spd = mMax(0, spd - (player_reference.dash_brake * G_DELTA_TIME))
  SetPlayerSpeed("x", spd, false)
  SetAnimationRotationLock(false)
  if GetManagedFlag(g_flags.bounce_ready) then
    SetAccumulatedGravity(0)
	dash_timer = 0
	SetPlayerSpeed("y", player_reference.dash_up, false)
	SetManagedFlag(g_flags.bounce_ready, false)
	self.player.dash_available = true
  end
  dash_timer = dash_timer + G_DELTA_TIME
  if dash_timer >= player_reference.dash_time or IsGrounded() or is_sand_water then
    SetPlayerState(0)
	dash_timer = 0
	SetPlayerSpeed("y", 0, false)
	return self:SwitchState("RESET")
  elseif GetInput("a") then
    SetPlayerState(4)
	dash_timer = 0
  end
end


function PlayerList.sonic.states.Dashing:StateExit()
  g_lock_rotation = false
  SetRotationSpeed(800)
  SetGravityForce(980)
end
local m_ptr = GetMissionPointer()
local prev_state_gimmick_speed = 0
local prev_state_base_speed = 0

local bounce_on = false
local bounce_timer = 0
local timer_limit = 1
local jump_brake = 2500/60
local FORCE_OFF = false
function badnik_bounce(delta)
  if GetManagedFlag(g_flags.bounce_ready) then
    SetManagedFlag(g_flags.bounce_ready, false)
	if not GetInput("b", "hold") then
	  return
	end
	local my_state = GetPlayerState()
    if my_state ~= StateID.JUMP and my_state ~= StateID.FALL and my_state ~= StateID.GLIDE_END then -- Validate in Init instead?
	  return
	end
	bounce_on = true
	SetAccumulatedGravity(0)
	SetPlayerSpeed("y", 900, false) -- 0
	bounce_timer = 0
	FORCE_OFF = false
  end

  if FORCE_OFF or (bounce_on and not GetInput("b", "hold")) then 
    FORCE_OFF = true
	if bounce_timer < timer_limit then
	  bounce_timer = bounce_timer + delta
	  local cur_spd = GetPlayerSpeed("y", false)
	  cur_spd = mMax(150, cur_spd - jump_brake)
	  if GetPlayerState() == 4 then
	    SetPlayerSpeed("y", cur_spd, false)
	  end
	end
	if bounce_timer >= timer_limit then
	  FORCE_OFF = false
	  bounce_timer = 0
	  bounce_on = false
	end
	return
  end
  if bounce_on then
    bounce_timer = bounce_timer + delta
	if bounce_timer > timer_limit or GetInput("a") then
	  FORCE_OFF = false
	  bounce_timer = 0
	  bounce_on = false
	  return
	end
	if GetInput("b", "hold") then
	  --SetPlayerSpeed("y", 900, false)
	  SetPlayerState(4)
	  ChangePlayerAnim(player_reference.custom_anims.Plugins.badnik_bounce)
	end
  end
end

function ExitOnAutomationCollision(self)
  if GetPlayerSpeed("y", true, true) ~= 0 then
    SetPlayerState(0)
    return self:SwitchState("RESET")
  elseif GetPlayerSpeed("x", true, true) ~= 0 then
    local last_lockout = GetInputLockout(true)
	SetInputLockout(last_lockout)
	SetPlayerState(0)
	SetPlayerSpeed("x", GetPlayerSpeed("x", true, true), true)
	return self:SwitchState("RESET")
  end
end
--RegisterStatePlugin("sonic", "badnik", badnik_bounce)
AttachPluginState("sonic", "Init", badnik_bounce)
AttachPluginState("tails", "Init", badnik_bounce)
AttachPluginState("knuckles", "Init", badnik_bounce)

--RegisterStatePlugin("shadow", "badnik", badnik_bounce)
AttachPluginState("shadow", "Init", badnik_bounce)
AttachPluginState("rouge", "Init", badnik_bounce)

--RegisterStatePlugin("blaze", "badnik", badnik_bounce)
AttachPluginState("blaze", "Init", badnik_bounce)
AttachPluginState("amy", "Init", badnik_bounce)
function PlayerList.shadow.states.Attacking:Startup()
  --self.player.base_jump_speed = 650
  --SetPlayerLuaValue("c_jump_speed", 650)
  self.player.downforce_override = true
  --SetDownforce(16)
  self.player.current_state = self.name
  self.player.current_class = self.class
  return self:StateEnter()
end
function PlayerList.shadow.states.Attacking:StateMain()
  if GetInput("a") and IsGrounded() then
    PlayProcess("MS")
  end
  --SetDownforce(16)
end
function PlayerList.shadow.states.Attacking:StateExit()
  --self.player.base_jump_speed = 900
  --SetPlayerLuaValue("c_jump_speed", 900)
  self.player.downforce_override = false
  --SetDownforce(60)
end


function PlayerList.sonic.states.Attacking:Startup()
  --self.player.base_jump_speed = 650
  --SetPlayerLuaValue("c_jump_speed", 650)
  self.player.downforce_override = true
  --SetDownforce(16)
  self.player.current_state = self.name
  self.player.current_class = self.class
  return self:StateEnter()
end
function PlayerList.sonic.states.Attacking:StateMain()
  if GetInput("a") and IsGrounded() then
    PlayProcess("MS")
  end
  --SetDownforce(16)
end
function PlayerList.sonic.states.Attacking:StateExit()
  --self.player.base_jump_speed = 900
  --SetPlayerLuaValue("c_jump_speed", self.player.base_jump_speed)
  self.player.downforce_override = false
  --SetDownforce(60)
end

local forced_time, forced_time_base = 0, 30
local function RollStartup(self)
  ToggleHitboxKick(true)
  SetLuaMaxSpeed(6000)
  SetPreviousSpeed("y", 0) -- The main loop checks for a change in this value to detect automation
  SetPreviousSpeed("x", 0) -- Likewise, this detects dash panels
  SetGravityForce(980 * player_reference.slope_params.ROLL_GRAVITY_MULTIPLIER)
  if not GetInput("x", "hold") and not GetInput("x", "down") then
    local base, gimm = GetPlayerSpeed("x", false), GetPlayerSpeed("x", true)
    local total = base + gimm
    SetPlayerSpeed("forward", total, true) -- Apply all speed as gimmick speed
    SetPlayerSpeed("forward", 0, false) -- ^
    if total >= 0 and total <= 450 then
      SetPlayerSpeed("forward", 750, true) -- If the player is stationary or walking, apply a light impulse
    end
    forced_time = forced_time_base -- Minimum time in the Roll state
	return false
  end
  return true
end

local spnd_base_mult = 0.7 --.35
local spnd_charge_mult = 0.7 -- Starting speed multiplier for Spin Dash
local spnd_roll_mult = 0.35 -- Starting multiplier if Spin Dash is triggered through a Roll
local spnd_charge_inc = 1.0/60
local spnd_charge_max = 1.35
local spnd_base_spd = 3000
function PlayerList.sonic.states.Rolling:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  self.player.downforce_override = true
  if GetManagedFlag(g_flags.is_super) then
    ChangePlayerAnim("lightattack_l")
  else
    ChangePlayerAnim("fly")
  end
  local is_x_pressed = RollStartup(self)
  if is_x_pressed then
    g_delay_override = true
	ChangePlayerAnim("jump_alt")
    return self:SwitchState("SpinDash")
  else
   spnd_charge_mult = spnd_roll_mult
   print("Set to lower mult: " .. spnd_charge_mult)
   return self:StateEnter()
  end
end

--g_ground_magnitude, -- Grav accel
--g_ground_supplement,  -- Ground angle
--g_ground_sine -- Used for calculating launches
local WasGrounded = false
local roll_multiplier = 1

local bounce_decay = 0 -- Water bouncing
local badnik_multiplier_base = 1.75
local badnik_multiplier_current = 1.75
local badnik_multiplier_decay = 0.25
function AirAttackBounce()
  if GetManagedFlag(g_flags.bounce_ready) then
	SetManagedFlag(g_flags.bounce_ready, false)
	local final_spd = GetAccumulatedGravity() * badnik_multiplier_current
	badnik_multiplier_current = badnik_multiplier_current - badnik_multiplier_decay
	return final_spd
  end
end
local function RollMain(self)
  SetAnimationRotationLock(0)
  local spd = GetPlayerSpeed("forward", true)
  if not SLOPE_is_downward then
    roll_multiplier = 1.25
  else
    roll_multiplier = 1.15
  end
  local pos = GetPlayerPos()
  local l_ground_magnitude = SLOPE_is_downward and mAbs(g_ground_magnitude) or g_ground_magnitude * -1
  local new_spd = mMin(GetLuaMaxSpeed(), spd + ((l_ground_magnitude * (roll_multiplier) * 1/60) - player_reference.slope_params.ROLL_CONSTANT_BRAKE) * 2) --50/60
  local h_air_spd = mAbs(spd * g_ground_cosine)
  local y_air_spd = SLOPE_is_downward and mAbs(spd * g_ground_sine) * -1 or mAbs(spd * g_ground_sine)
  if IsGrounded() then
    WasGrounded = true
    SetPlayerSpeed("forward", new_spd, true)
	g_last_ground_speed = new_spd/2--mMax(new_spd - player_reference.slope_params.MAX_SPEED, 0)/2--mMin(mMax(new_spd-player_reference.slope_params.MAX_SPEED, 0), 2300)
	SetPlayerSpeed("y", 0, true)
	bounce_decay = 0
	local last_gimmick_spd = GetPlayerSpeed("x", true, true)
	if last_gimmick_spd ~= 0 then -- Player hit a dash panel
	  local last_lockout = GetInputLockout(true)
	  SetInputLockout(last_lockout)
	  if last_gimmick_spd > new_spd then
	    SetPlayerSpeed("forward", last_gimmick_spd, true)
	  end
	  SetPreviousSpeed("x", 0)
	end
  else
    if WasGrounded then
      WasGrounded = false
      SetPlayerSpeed("forward", h_air_spd, true)
	  SetPlayerSpeed("y", y_air_spd, true)
	else
	  local mass_n = player_reference.slope_params.MASS * (GetGravityForce()/100) * -1 -- So that it forces you downward
	  local y_spd = GetPlayerSpeed("y", true)
	  local drag_spd_x = ComputeDrag(spd)
	  local drag_spd_y = ComputeDrag(y_spd)
	  local v_force = ((mass_n - drag_spd_y)/20) -- 20 is the player weight, in kilograms. Mass set in physics_manager
	  local x_force = drag_spd_x
	  v_force = v_force * 1/60
	  x_force = (x_force * 1/60) * -1
	  local final_spd = y_spd + v_force -- v_force is already negative)
	  --print("FINAL/SPD: " .. final_spd .. " | " .. spd + x_force) 
	  final_spd = AirAttackBounce() or final_spd -- Launch up if you roll into an enemy
	  SetPlayerSpeed("y", final_spd, true)
	  SetPlayerSpeed("x", spd + x_force, true)
	  local flag = GetGroundAirFlags()
	  if bit.AND(flag, 2048) ~= 0 then
	    SetPlayerSpeed("y", y_spd/(1.2 + bounce_decay), true)
		bounce_decay = bounce_decay + 0.1
		if y_spd > 700 then
		  Game.NewActor("particle",{bank="map_common", name = "c_splash6m", cycle = 0, cyclewidth = 0, sebank = "", sename = ""},{Position = Vector(pos.X,pos.Y + 25,pos.Z) , Rotation = Vector(1,0,0,0)})
		elseif y_spd < 250 and y_spd > 0 then
		  SetPlayerSpeed("y", 0, true)
		end
		
		Game.NewActor("particle",{bank="player_" .. GetPlayerName(), name = "deep_water", cycle = 0, cyclewidth = 0, sebank = "", sename = ""},{Position = Vector(pos.X,pos.Y + 50,pos.Z) , Rotation = Vector(1,0,0,0)})
	  end
	end
  end
  
  if forced_time <= forced_time_base and forced_time > 0 then
    forced_time = forced_time - 1
	if forced_time <= 0 then
	  forced_time = forced_time_base + 1
	end
	return
  end
  local total_spd = GetPlayerSpeed("total")
  if total_spd <= 450 then 
	SetPlayerState(2)
	spnd_charge_mult = spnd_base_mult
	return self:SwitchState("RESET")
  end
end

function PlayerList.sonic.states.Rolling:StateMain()
  if GetPlayerSpeed("y", true, true) ~= 0 then
    SetPlayerState(0)
    return self:SwitchState("RESET")
  end
  if GetInput("b") then
    SetPlayerState(2)
	spnd_charge_mult = spnd_base_mult
    return self:SwitchState("RESET")
  elseif GetInput("a") and GetInputLockout() == 0 then
    spnd_charge_mult = spnd_base_mult
    if IsGrounded() then
      PlayProcess("SDJ")
	  return
	else
	  SetPlayerState(4)
	  return
	end
  elseif GetInput("x") then
    SetPlayerState(70)
	self:SwitchState("SpinDash")
  elseif ValidateFlightTransition(true) then
    return self:SwitchState("Flying")
  elseif not ValidateRollTransition(GetPlayerState(0)) and GetInputLockout() == 0 then
    spnd_charge_mult = spnd_base_mult
    SetPlayerState(0)
    return self:SwitchState("RESET")
  end
  RollMain(self)
end

local function RollExit(self)
  self.player.downforce_override = false
  ToggleHitboxKick(false)
  SetDownforce(60)
  --SetAngleThreshold(10)
  SetLuaMaxSpeed(3300)
  SetGravityForce(980)
  badnik_multiplier_current = badnik_multiplier_base
end

function PlayerList.sonic.states.Rolling:StateExit()
  RollExit(self)
end

function PlayerList.sonic.states.Bounding:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  SetPlayerSpeed("x", g_my_total_spd, false)
  return self:StateEnter()
end

function PlayerList.sonic.states.Bounding:StateMain()
  ManageAdditionalHomingAttack(71)
  ManageBadnikEnable(71)
  local my_spd = GetPlayerSpeed("x", false)
  local min_spd = self.player.bound_spd_min
  if not IsStickNeutral() then
	if my_spd < min_spd then
      my_spd = my_spd + (self.player.bound_accel_rate * G_DELTA_TIME)
	else
	  my_spd = my_spd - (self.player.bound_decel_rate * G_DELTA_TIME)
	  my_spd = mMax(min_spd, my_spd)
    end
  else
    my_spd = my_spd - (self.player.bound_decel_rate_idle * G_DELTA_TIME)
	min_spd = 0
	my_spd = mMax(min_spd, my_spd)
  end
  SetPlayerSpeed("x", my_spd, false)
  SetPlayerSpeed("x", 0, true)
  if ValidateFlightTransition() then
    SetPlayerState(23)
	return self:SwitchState("Flying")
  end
end

function PlayerList.sonic.states.Tornadoing:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  SetPlayerSpeed("x", mMin(self.player.sonic_gem_params.green.max_move_spd, g_my_total_spd), false)
  return self:StateEnter()
end

function PlayerList.sonic.states.Tornadoing:StateMain()
  if GetInput("a") then
    PlayProcess("SDJ")
	return
  end
  local my_spd = GetPlayerSpeed("x", false)
  if not IsStickNeutral() then
    my_spd = mMin(self.player.sonic_gem_params.green.max_move_spd, my_spd + self.player.sonic_gem_params.green.move_acc_rate)
  else
    my_spd = mMax(0, my_spd - self.player.sonic_gem_params.green.move_dec_rate)
  end
  SetPlayerSpeed("x", my_spd, false)
  SetPlayerSpeed("x", 0, true)
end

local ring_sfx_timer = 0
function PlayerList.sonic.states.Flying:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  SetContextFlag("DisableGravity", true)
  SetAccumulatedGravity(0)
  SetDownforce(16)
  SetPlayerPos(0, 25, 0)
  g_lock_rotation = true
  SetRotationSpeed(50)
  local total = GetPlayerSpeed("total")
  SetPlayerSpeed("x", total, false)
  SetPreviousSpeed("x", 0)
  SetPreviousSpeed("y", 0)
  SetPlayerSpeed("y", 0, true)
  SetPlayerSpeed("x", 0, true)
  ring_sfx_timer = 0
  PlaySound("obj_common", "ring_sparkle")
  local my_gauge = GetGaugeParameter("c_gauge_value")
  local decrease = self.player.sonic_gem_params.super.flight_values_by_level[GetMaturityLevel()].initial
  my_gauge = mMax(0, my_gauge - decrease)
  SetGaugeParameter("c_gauge_value", my_gauge)
  return self:StateEnter()
end

function PlayerList.sonic.states.Flying:StateMain()
  SetAnimationRotationLock(false)
  if ring_sfx_timer >= 2 then
    ring_sfx_timer = 0
    PlaySound("obj_common", "ring_sparkle")
  end
  if GetInput("rt", "released") then
    SetInputLockout(0)
	SetPlayerState(3)
	--player.print("LEFT")
	return self:SwitchState("RESET")
  elseif IsGrounded() and ring_sfx_timer > 0 then
    SetInputLockout(0)
	SetPlayerState(0)
	return self:SwitchState("RESET")
  end
  ring_sfx_timer = ring_sfx_timer + G_DELTA_TIME
  local my_gauge = GetGaugeParameter("c_gauge_value")
  local flight_values = self.player.sonic_gem_params.super.flight_values_by_level[GetMaturityLevel()]
  my_gauge = my_gauge - (flight_values.cost * G_DELTA_TIME)
  if my_gauge < 0 then
    --player.print("LEFT ON GAUGE")
    SetGaugeParameter("c_gauge_value", 0)
	SetPlayerState(3)
	return self:SwitchState("RESET")
  end
  SetGaugeParameter("c_gauge_value", my_gauge)
  local my_spd = GetPlayerSpeed("x", false)
  local top_h_spd = flight_values.top_speed
  if IsStickNeutral() then
    my_spd = mMax(0, my_spd - ( (top_h_spd * 2) * G_DELTA_TIME))
  else
    if my_spd > top_h_spd then
	  my_spd = my_spd - (flight_values.over_run_decel * G_DELTA_TIME)
	else
      my_spd = mMin(top_h_spd, my_spd + ( (top_h_spd * 0.4) * G_DELTA_TIME))
	end
  end
  SetPlayerSpeed("x", my_spd, false)
  local stick_Y = GetStickInput("L", "Y", true)
  local stick_X = GetStickInput("L", "X", true)
  if mAbs(stick_Y) >= 0.1 then
    ChangePlayerAnim("lightdash")
  elseif stick_X >= 0.1 then
    ChangePlayerAnim("super_fly_right")
  elseif stick_X <= -0.1 then
    ChangePlayerAnim("super_fly_left")
  elseif GetInput("a", "hold") then
    ChangePlayerAnim("super_fly_up")
	--SetPlayerSpeed("y", 750, false)
  elseif GetInput("x", "hold") then
    ChangePlayerAnim("super_fly_down")
	--SetPlayerSpeed("y", -750, false)
  else
    ChangePlayerAnim("wait")
  end
  if GetInput("a", "hold") then
    SetPlayerSpeed("y", flight_values.up_rate, false)
  elseif GetInput("x", "hold") then
    SetPlayerSpeed("y", flight_values.down_rate, false)
  end
  if not GetInput("x", "hold") and not GetInput("a", "hold") then
    SetPlayerSpeed("y", 0, false)
  end
  ExitOnAutomationCollision(self)
end

function PlayerList.sonic.states.Flying:StateExit()
  SetContextFlag("DisableGravity", false)
  g_lock_rotation = false
  SetRotationSpeed(800)
  SetPlayerSpeed("y", 0, false)
end

mach_variables = { invuln_damage_time = 0, bonk_time = 0, knee_time = 0, base_jump = 900, min_jump = 150, jump_brake = 1800, jump_timer = 0 }
function PlayerList.sonic_mach.states.Starting:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  mach_variables.knee_time = 0
  ChangePlayerAnim("wait4")
  return self:StateEnter()
end

function PlayerList.sonic_mach.states.Starting:StateMain() 
  SetPlayerSpeed("x", 0, false)
  SetPlayerSpeed("y", 0, false)
  SetAnimationRotationLock(true)
  local knee_time = mach_variables.knee_time
  knee_time = knee_time + G_DELTA_TIME
  if knee_time >= player_reference.mach_params.starting_time then
    return self:SwitchState("RESET")
  elseif knee_time >= 0.65 then
    if not GetManagedFlag(g_flags.is_super) then
      ChangePlayerAnim("tornado_s")
	end
  end
  mach_variables.knee_time = knee_time
end

function PlayerList.sonic_mach.states.Starting:StateExit()
  local launch_force = not GetManagedFlag(g_flags.is_super) and player_reference.mach_params.STARTING_LAUNCH or player_reference.mach_params.STARTING_LAUNCH_SUPER
  SetPlayerSpeed("x", launch_force, false)
end

function PlayerList.sonic_mach.states.Damaging:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  mach_variables.invuln_damage_time = 0
  SetPreviousSpeed("x", 0)
  SetPreviousSpeed("y", 0)
  local spd = GetPlayerSpeed("x", false)
  if spd >= player_reference.mach_params.stumble_threshold then
    if GetContextFlag("MachAura") or GetManagedFlag(g_flags.is_super) then
	  return self:StateEnter()
	end
    if GetRingCount() == 0 then
	  SetPlayerState(8)
	  return self:SwitchState("RESET")
	end
	ToggleHitboxKick(true)
    SetContextFlag("BlinkMode", true)
	SetRingCount(0)
	ChangePlayerAnim("sliding_stand")
	SetPlayerSpeed("x", spd * 0.85, false)
    return self:StateEnter()
  else
    g_delay_override = true
    return self:SwitchState("Bonking")
  end
end

function PlayerList.sonic_mach.states.Damaging:StateMain() 
  local damage_time = mach_variables.invuln_damage_time
  if damage_time >= 7/60 and bit.AND(GetGroundAirFlags(), 16) ~= 0 then
    return self:SwitchState("Bonking")
  end
  SetAnimationRotationLock(false)
  damage_time = damage_time + G_DELTA_TIME
  if damage_time >= player_reference.mach_params.damage_invuln_time then
	SetContextFlag("BlinkMode", false)
	return self:SwitchState("RESET")
  end
  mach_variables.invuln_damage_time = damage_time
  ExitOnAutomationCollision(self)
  if GetContextFlag("MachAura") or GetManagedFlag(g_flags.is_super) then
    if GetInput("a") and IsGrounded() then
	  return self:SwitchState("Jumping")
	elseif GetInput("x") then
	  SetPlayerState(0)
	  return
	end
	if IsGrounded() then
	  UpdateRunAnimation()
	else
	  ChangePlayerAnim("fall")
	end
  else
    local spd = GetPlayerSpeed("x", false)
	local new_spd = mMax(player_reference.mach_params.MIN_GROUND_SPEED, spd - (player_reference.mach_params.DAMAGE_DECEL_RATE * G_DELTA_TIME))
	SetPlayerSpeed("x", new_spd, false)
  end
end

function PlayerList.sonic_mach.states.Damaging:StateExit()
  ToggleHitboxKick(false)
end

function PlayerList.sonic_mach.states.Bonking:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  if IsGrounded() then
    ChangePlayerAnim("stop")
  else
    ChangePlayerAnim("wind")
	SetPlayerTimeScale(1.5)
	SetPlayerSpeed("y", 250, false)
	SetAccumulatedGravity(0)
  end
  SetPlayerSpeed("x", player_reference.mach_params.bonk_spd, false)
  mach_variables.bonk_time = 0
  PlaySound("player_sonic", "boundattack")
  return self:StateEnter()
end

function PlayerList.sonic_mach.states.Bonking:StateMain() 
  if GetCurrentAnimationTime() < 2/60 then
    SetCurrentAnimationTime(8/60)
  end
  SetAnimationRotationLock(true)
  local bonk_time = mach_variables.bonk_time
  bonk_time = bonk_time + G_DELTA_TIME
  local anim = GetPlayerAnim(true)
  local grounded = IsGrounded()
  if bonk_time >= player_reference.mach_params.bonk_time then
	return self:SwitchState("RESET")
  elseif anim == "wind" and grounded then
	return self:SwitchState("RESET")
  elseif anim == "stop" and not grounded then
    ChangePlayerAnim("wind")
	bonk_time = 0
  end
  mach_variables.bonk_time = bonk_time
  ExitOnAutomationCollision(self)
end

function PlayerList.sonic_mach.states.Bonking:StateExit()
  SetPlayerSpeed("x", 0, false)
  SetPlayerTimeScale(1)
  SetContextFlag("BlinkMode", false)
  SetRotationSpeed(0)
end

function PlayerList.sonic_mach.states.Jumping:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  local is_super = GetManagedFlag(g_flags.is_super)
  mach_variables.base_jump = not is_super and player_reference.mach_params.BASE_JUMP_SPEED or player_reference.mach_params.BASE_JUMP_SPEED_SUPER
  mach_variables.min_jump = not is_super and player_reference.mach_params.BASE_MIN_JUMP or player_reference.mach_params.BASE_MIN_JUMP_SUPER
  mach_variables.jump_brake = player_reference.mach_params.JUMP_BRAKE * G_DELTA_TIME
  mach_variables.jump_timer = 0
  SetAccumulatedGravity(0)
  SetPostureLuaValue("c_downforce", 16)
  SetPlayerPos(0, 17, 0)
  SetPlayerSpeed("y", mach_variables.base_jump, false)
  ChangePlayerAnim("jumpup")
  SetPreviousSpeed("x", 0)
  SetPreviousSpeed("y", 0)
  return self:StateEnter()
end

function PlayerList.sonic_mach.states.Jumping:StateMain()
  SetAnimationRotationLock(false)
  local flags = GetGroundAirFlags()
  local spd = GetPlayerSpeed("x", false)
  if bit.AND(flags, 512) ~= 0 then
    ChangePlayerAnim("fall")
  else
    ChangePlayerAnim("jump")
  end
  if bit.AND(flags, 16) ~= 0 and spd >= player_reference.mach_params.AIR_BONK_THRESHOLD then
    self:SwitchState("Damaging")
	return
  end
  local y_spd = GetPlayerSpeed("y", false)
  local jump_time = mach_variables.jump_timer
  if jump_time >= 0.1 and IsGrounded() then
    return self:SwitchState("RESET")
  elseif jump_time < 0.1 then
    ChangePlayerAnim("jumpup")
  end
  jump_time = mMin(1, jump_time + G_DELTA_TIME)
  mach_variables.jump_timer = jump_time
  local is_super = GetManagedFlag(g_flags.is_super)
  local MAX_AIR_SPEED = not is_super and player_reference.mach_params.MAX_AIR_SPEED or player_reference.mach_params.MAX_AIR_SPEED_SUPER
  local MIN_AIR_SPEED = not is_super and player_reference.mach_params.MIN_AIR_SPEED or player_reference.mach_params.MIN_AIR_SPEED_SUPER
  local top_spd = not IsStickNeutral() and MAX_AIR_SPEED or MIN_AIR_SPEED
  if spd ~= top_spd then
    local rate = spd < top_spd and player_reference.mach_params.AIR_ACCELERATION_RATE or (player_reference.mach_params.AIR_DECELERATION_RATE * -1)
    local new_spd = spd + (rate * G_DELTA_TIME)
	if mAbs(top_spd - new_spd) <= 50 then new_spd = top_spd end
	SetPlayerSpeed("x", new_spd, false)
  end
  if GetInput("x") then
    SetPlayerState(0)
  end
  if jump_time >= 1 then
    return
  else
    if not GetInput("a", "hold") then
	  y_spd = mMax(mach_variables.min_jump, y_spd - mach_variables.jump_brake)
	end
	SetPlayerSpeed("y", y_spd, false)
  end
  ExitOnAutomationCollision(self)
end

function PlayerList.sonic_mach.states.Jumping:StateExit()
  SetPostureLuaValue("c_downforce", 60)
end

function PlayerList.sonic_mach.states.Falling:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  ChangePlayerAnim("fall")
  SetPreviousSpeed("x", 0)
  SetPreviousSpeed("y", 0)
  return self:StateEnter()
end

function PlayerList.sonic_mach.states.Falling:StateMain()
  SetAnimationRotationLock(false)
  local flags = GetGroundAirFlags()
  if bit.AND(flags, 16) ~= 0 then
    return self:SwitchState("Damaging")
  end
  if IsGrounded() then
    return self:SwitchState("RESET")
  end
  ExitOnAutomationCollision(self)
end

function PlayerList.sonic_mach.states.Falling:StateExit()
end

local has_finished = false
function PlayerList.sonic_mach.states.ChainJumping:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  my_time = 0
  SetPlayerLuaValue("c_landing_time", 1)
  has_finished = false
  return self:StateEnter()
end

function PlayerList.sonic_mach.states.ChainJumping:StateMain()
  if GetPlayerState() ~= 31 and IsGrounded() then
    SetPlayerState(25)
	SetAnimationRotationLock(false)
	SetPlayerSpeed("x", 1, false)
	SetPlayerSpeed("y", 0, true)
	SetRotationSpeed(0.025)
    my_time = my_time + G_DELTA_TIME
	if my_time >= 1.0 then
	  my_time = 0
	  has_finished = true
	  SetPlayerState(2)
	  ChangePlayerAnim("dush")
	  SetPlayerSpeed("x", 3500, false)
	  SetPreviousSpeed("x", 3500)
	  return self:SwitchState("RESET")
	end
  end
end

function PlayerList.sonic_mach.states.ChainJumping:StateExit()
  SetRotationSpeed(100)
  if not has_finished then
    SetPlayerState(2)
    return self:StateEnter()
  end
  SetPlayerLuaValue("c_landing_time", 0)
end

function PlayerList.tails.states.Rolling:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  self.player.downforce_override = true
  ChangePlayerAnim("jump_alt")
  RollStartup(self)
  return self:StateEnter()
end

function PlayerList.tails.states.Rolling:StateMain()
  if GetPlayerSpeed("y", true, true) ~= 0 then
    SetPlayerState(0)
    return self:SwitchState("RESET")
  end
  SetAnimationRotationLock(0)
  if GetInput("b") then
    SetPlayerState(2)
    return self:SwitchState("RESET")
  elseif GetInput("a") and GetInputLockout() == 0 then
    if IsGrounded() then
      PlayProcess("SDJ")
	  return
	else
	  SetPlayerState(3)
	  return
	end
  elseif GetInput("y") and GetInputLockout() == 0 and IsGrounded() then
    SetPlayerState(23)
    return self:SwitchState("Attacking")
  elseif not ValidateRollTransition(GetPlayerState()) and GetInputLockout() == 0 then
    SetPlayerState(0)
    return self:SwitchState("RESET")
  end
  
  RollMain(self)
end

function PlayerList.tails.states.Rolling:StateExit()
  RollExit(self)
end

FLIGHT_BRAKE = 1500/60
local function FlightStartup()
  local total_x = GetPlayerSpeed("total")
  SetPlayerLuaValue("c_flight_speed_max", mMax(total_x, 1700))
  SetPlayerSpeed("x", total_x, false)
  SetPlayerSpeed("x", 0, true)
end

local function FlightMain()
  local current_flight = GetPlayerLuaValue("c_flight_speed_max")
  local new_flight = mMax(1700, current_flight - FLIGHT_BRAKE)
  SetPlayerLuaValue("c_flight_speed_max", new_flight)
end

local function FlightExit()
  SetPlayerLuaValue("c_flight_speed_max", 1700)
end

function PlayerList.tails.states.Flying:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  player_reference.custom_gauge_params.action_gauge_regen_valid = false
  FlightStartup()
  SetGravityEnabled(false)
  SetAccumulatedGravity(0)
  local my_params = player_reference.flight_params.brake_by_level[GetMaturityLevel()]
  player_reference.flight_params.gauge_brake = my_params.gauge_brake
  player_reference.flight_params.gauge_brake_idle = my_params.gauge_brake_idle
  return self:StateEnter()
end

local flight_y = 0
function PlayerList.tails.states.Flying:StateMain()
  FlightMain()
  flight_y = GetPlayerSpeed("y", false)
  if not GetInput("a", "hold") then
	flight_y = flight_y - player_reference.flight_params.flight_decel
  end
  SetPlayerSpeed("y", mMin(flight_y, 600), false)
  if GetInput("b") then
    SetPlayerState(3) -- Awkward "flight cap" transition thingy
  end
end

function PlayerList.tails.states.Flying:StateExit()
  if not IsGrounded() then
    SetPlayerSpeed("y", mFloor(flight_y), false)
  end
  if GetPlayerState() == 3 then
    ChangePlayerAnim("fly_tired")
  else
    player_reference.custom_gauge_params.action_gauge_regen_valid = true
  end
  SetGravityEnabled(true)
  FlightExit()
end

attack_loop_count = 1
do_vfx_thing = false
function PlayerList.tails.states.Attacking:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  ToggleHitboxKick(true)
  ChangePlayerAnim("attack")
  attack_loop_count = 1
  do_vfx_thing = false
  SetCurrentAnimationTime(0/60)
  SetPreviousSpeed("x", 0)
  SetPreviousSpeed("y", 0)
  return self:StateEnter()
end

local spin_brake = 500/60
function PlayerList.tails.states.Attacking:StateMain()
  SetAnimationRotationLock(false)
  local held, released = GetInput("y", "hold")
  if GetInput("a") then
    PlayProcess("SDJ")
    return self:SwitchState("RESET")
  end
  if do_vfx_thing then
    do_vfx_thing = false
	ChangePlayerAnim("attack")
  end
  local base_spd = GetPlayerSpeed("x", false)
  local gimm_spd = GetPlayerSpeed("x", true)
  local stick_total = mAbs(GetStickInput("L", "X", true)) + mAbs(GetStickInput("L", "Y", true))
  if gimm_spd > 0 then
    gimm_spd = mMax(0, gimm_spd - (GetPlayerLuaValue("c_brake_dashpanel")/60))
	SetPlayerSpeed("x", gimm_spd, true)
  end
  if stick_total ~= 0 then
    local max_spd = GetPlayerLuaValue("c_run_speed_max") + 500
	if base_spd < max_spd then
	  base_spd = mMin(max_spd, base_spd + spin_brake)
	else
      base_spd = mMax(max_spd, base_spd - spin_brake)
	end
  else
    base_spd = mMax(0, base_spd - spin_brake * 2)
  end
  SetPlayerSpeed("x", base_spd, false)
  local anim_time = GetCurrentAnimationTime()
  if anim_time >= 19/60 then
    attack_loop_count = attack_loop_count - 1
	if attack_loop_count <= 0 then
	  SetPlayerState(0)
	  return
	else
	  do_vfx_thing = true
	  ChangePlayerAnim("wait")
	  SetCurrentAnimationTime(0/60)
	end
  elseif anim_time >= 1/60 and held then
    attack_loop_count = 2
  end
  if (not IsGrounded()) then
    SetPlayerState(0)
	return self:SwitchState("RESET")
  end
  ExitOnAutomationCollision(self)
end

function PlayerList.tails.states.Attacking:StateExit()
  ToggleHitboxKick(false)
  attack_loop_count = 1
end

function PlayerList.knuckles.states.Rolling:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  self.player.downforce_override = true
  ChangePlayerAnim("jump_alt")
  RollStartup(self)
  return self:StateEnter()
end

function PlayerList.knuckles.states.Rolling:StateMain()
  if GetPlayerSpeed("y", true, true) ~= 0 then
    SetPlayerState(0)
    return self:SwitchState("RESET")
  end
  SetAnimationRotationLock(0)
  if GetInput("b") then
    SetPlayerState(2)
    return self:SwitchState("RESET")
  elseif GetInputLockout() == 0 then
    if GetInput("a") then
	  if IsGrounded() then
	    PlayProcess("SDJ")
		return
	  else
	    SetPlayerState(4)
		return
	  end
	elseif GetInput("x") then
	  if IsGrounded() then
	    SetPlayerState(0)
	    return self:SwitchState("Attacking")
	  else
	    SetPlayerState(103)
		return self:SwitchState("RESET")
	  end
	end
	if not ValidateRollTransition(GetPlayerState()) then
	  SetPlayerState(0)
	  return self:SwitchState("RESET")
	end
  end
  RollMain(self)
end

function PlayerList.knuckles.states.Rolling:StateExit()
  RollExit(self)
end

PUNCH_BRAKE = 700/60
PUNCH_GIMMICK_BRAKE = 1500/60
local punch_anim = ""
local base_punch_spd = 900

function PlayerList.knuckles.states.Attacking:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  ToggleHitboxKick(true)
  punch_anim = GetPlayerAnim(true)
  prev_state_gimmick_speed = mFloor(GetPlayerSpeed("x", true))
  local base_spd = mFloor(GetPlayerSpeed("x", false))
  base_punch_spd = base_spd <= 900 and 900 or base_spd
  return self:StateEnter()
end

function PlayerList.knuckles.states.Attacking:StateMain()
  if GetInput("a") then
    PlayProcess("SDJ")
	return
  end
  local stick_total = mAbs(GetStickInput("L", "X", true)) + mAbs(GetStickInput("L", "Y", true))
  local gimmick = GetPlayerSpeed("x", true)
  if prev_state_gimmick_speed ~= 0 then
    prev_state_gimmick_speed = mMax(0, prev_state_gimmick_speed - PUNCH_GIMMICK_BRAKE)
	SetPlayerSpeed("x", prev_state_gimmick_speed, true)
  end
  base_punch_spd = base_punch_spd - PUNCH_BRAKE
  if stick_total == 0 then
    base_punch_spd = base_punch_spd - (PUNCH_BRAKE * 2)-- Decelerate twice as fast if the stick goes neutral
  end
  if punch_anim ~= GetPlayerAnim(true) then
    punch_anim = GetPlayerAnim(true)
	base_punch_spd = 900
  elseif base_punch_spd < 0 then
    base_punch_spd = 0
  end
  SetPlayerSpeed("x", base_punch_spd, false)
end

function PlayerList.knuckles.states.Attacking:StateExit()
  ToggleHitboxKick(false)
end

function PlayerList.knuckles.states.Gliding:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  ToggleHitboxKick(true)
  SetPlayerInvuln(true)
  FlightStartup()
  return self:StateEnter()
end

function PlayerList.knuckles.states.Gliding:StateMain()
  FlightMain()
  if GetManagedFlag(g_flags.bounce_ready) then
    SetManagedFlag(g_flags.bounce_ready, false)
	local grav = GetAccumulatedGravity()
	SetPlayerSpeed("y", grav + 150, false)
  end
end

function PlayerList.knuckles.states.Gliding:StateExit()
  ToggleHitboxKick(false)
  SetPlayerInvuln(false)
  FlightExit()
end

function PlayerList.knuckles.states.Diving:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  ToggleHitboxKick(true)
  SetPlayerInvuln(true)
  SetPlayerSpeed("y", -1500, true)
end

function PlayerList.knuckles.states.Diving:StateMain()
  SetPlayerSpeed("x", 0, false)
  if GetManagedFlag(g_flags.bounce_ready) then
    SetManagedFlag(g_flags.bounce_ready, false)
	ToggleHitboxKick(false)
  end
  if GetInput("a") then
    SetPlayerState(4)
	SetPlayerSpeed("x", 1700, false)
	return self:SwitchState("Gliding")
  end
end

function PlayerList.knuckles.states.Diving:StateExit()
  ToggleHitboxKick(false)
  SetPlayerInvuln(false)
end

function PlayerList.shadow.states.Rolling:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  self.player.downforce_override = true
  ChangePlayerAnim("jump_alt")
  RollStartup(self)
  return self:StateEnter()
end

function PlayerList.shadow.states.Rolling:StateMain()
  if GetPlayerSpeed("y", true, true) ~= 0 then
    SetPlayerState(0)
    return self:SwitchState("RESET")
  end
  SetAnimationRotationLock(0)
  if GetInput("b") then
    SetPlayerState(2)
    return self:SwitchState("RESET")
  elseif GetInput("a") and GetInputLockout() == 0 then
    if IsGrounded() then
      PlayProcess("SDJ")
	  return
	else
	  SetPlayerState(4)
	  return
	end
  elseif GetInput("x") and GetInputLockout() == 0 then
    return self:SwitchState("SpinDash")
  elseif not ValidateRollTransition(GetPlayerState()) and GetInputLockout() == 0 then
    SetPlayerState(0)
    return self:SwitchState("RESET")
  end
  
  RollMain(self)
end

function PlayerList.shadow.states.Rolling:StateExit()
  RollExit(self)
end

function PlayerList.rouge.states.Rolling:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  self.player.downforce_override = true
  ChangePlayerAnim("jump_alt")
  RollStartup(self)
  return self:StateEnter()
end

function PlayerList.rouge.states.Rolling:StateMain()
  if GetPlayerSpeed("y", true, true) ~= 0 then
    SetPlayerState(0)
    return self:SwitchState("RESET")
  end
  SetAnimationRotationLock(0)
  if GetInput("b") then
    SetPlayerState(2)
    return self:SwitchState("RESET")
  elseif GetInput("a") and GetInputLockout() == 0 then
    if IsGrounded() then
      PlayProcess("SDJ")
	  return
	else
	  SetPlayerState(4)
	  return
	end
  elseif GetInput("y") and not IsGrounded() then
    return self:SwitchState("Diving")
  elseif not ValidateRollTransition(GetPlayerState()) and GetInputLockout() == 0 then
    SetPlayerState(0)
    return self:SwitchState("RESET")
  end
  
  RollMain(self)
end

function PlayerList.rouge.states.Rolling:StateExit()
  RollExit(self)
end

function PlayerList.rouge.states.Blasting:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  SetInputLockout(0)
  prev_state_gimmick_speed = mFloor(GetPlayerLuaValue("c_jump_run")) -- This tracks your total speed. Gimmick speed gets reset frame 1 in this state.
  return self:StateEnter()
end

function PlayerList.rouge.states.Blasting:StateMain()
  if GetPlayerSpeed("y", true, true) ~= 0 then
    SetPlayerSpeed("y", 2100, true)
	SetPlayerSpeed("x", prev_state_gimmick_speed - GetPlayerSpeed("x", false), true)
	SetPreviousSpeed("y", 0)
  end
  if GetInput("a") then
	return self:SwitchState("Gliding")
  elseif GetInput("y") then
    SetPlayerState(StateID.GOAL_LOOP)
	return self:SwitchState("Diving")
  end
end

function PlayerList.rouge.states.Blasting:StateExit()
  if IsGrounded() then
    if GetInput("b") then
	  ChangePlayerAnim("bounce")
	end
    DisableBadnikProperties()
  end
end

function PlayerList.rouge.states.Throwing:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  prev_state_gimmick_speed = mFloor(GetPlayerLuaValue("c_jump_run"))
  return self:StateEnter()
end

function PlayerList.rouge.states.Throwing:StateMain()
  local stick_total = mAbs(GetStickInput("L", "X", true)) + mAbs(GetStickInput("L", "Y", true))
  if prev_state_gimmick_speed ~= 0 then
    prev_state_gimmick_speed = mMax(1, prev_state_gimmick_speed - (FLIGHT_BRAKE * 0.85)) -- 0.75
	if stick_total == 0 then
	  prev_state_gimmick_speed = mMax(1, prev_state_gimmick_speed - (FLIGHT_BRAKE * 2))
	end
    SetPlayerSpeed("x", prev_state_gimmick_speed, false)
  end
end

function PlayerList.rouge.states.Throwing:StateExit()
end

function PlayerList.rouge.states.Diving:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  ToggleHitboxKick(true)
  SetPlayerSpeed("y", -500, false)
  ChangePlayerAnim("bungee_fly")
  SetPreviousSpeed("x", 0)
  SetPreviousSpeed("y", 0)
  return self:StateEnter()
end

function PlayerList.rouge.states.Diving:StateMain()
  SetAnimationRotationLock(false)
  SetPlayerSpeed("y", -500, false)
  if IsGrounded() then
    SetPlayerState(0)
	SetPlayerSpeed("y", 0, false)
    return self:SwitchState("RESET") -- This is excluded to prevent a softlock upon landing
  elseif GetInput("a") then
    SetPlayerState(4)
	return self:SwitchState("Gliding")
  end
  ExitOnAutomationCollision(self)
end

function PlayerList.rouge.states.Diving:StateExit()
  ToggleHitboxKick(false)
  SetPlayerInvuln(false)
end

function PlayerList.rouge.states.Gliding:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  ToggleHitboxKick(true)
  SetPlayerInvuln(true)
  FlightStartup()
  return self:StateEnter()
end

function PlayerList.rouge.states.Gliding:StateMain()
  FlightMain()
  if GetInput("y") then
    SetPlayerState(StateID.GOAL_LOOP)
	return self:SwitchState("Diving")
  end
  if GetManagedFlag(g_flags.bounce_ready) then
    SetManagedFlag(g_flags.bounce_ready, false)
	local grav = GetAccumulatedGravity()
	SetPlayerSpeed("y", grav + 100, false)
  end
end

function PlayerList.rouge.states.Gliding:StateExit()
  ToggleHitboxKick(false)
  SetPlayerInvuln(false)
  FlightExit()
end

function PlayerList.omega.states.Hovering:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  player_reference.custom_gauge_params.action_gauge_regen_valid = false
  if self.player.custom_gauge_params.current_action_gauge == 0 then
    SetAccumulatedGravity(g_last_grav)
  else
    local gauge = self.player.custom_gauge_params.current_action_gauge
    local decrease = self.player.hover_params.gauge_initial
    gauge = mMax(0, gauge - decrease)
    self.player.custom_gauge_params.current_action_gauge = gauge
  end
  return self:StateEnter()
end

function PlayerList.omega.states.Hovering:StateMain()
  local my_spd = GetPlayerSpeed("total")
  if self.player.custom_gauge_params.current_action_gauge == 0 then
    ChangePlayerAnim("fall")
  elseif my_spd >= 850 then
    ChangePlayerAnim("super_fly_up")
  else
    ChangePlayerAnim("fall_t1")
  end
  if GetInput("a", "released") then
    SetPlayerState(0)
	return self:SwitchState("RESET")
  end
end

function PlayerList.omega.states.Hovering:StateExit()
  local my_state = GetPlayerState()
  if (my_state ~= 79 and my_state ~= 80) and player_reference.custom_gauge_params.current_action_gauge ~= 0 and not GetInput("a", "released") then
    player_reference.custom_gauge_params.action_gauge_regen_valid = true
  end
end

function PlayerList.omega.states.Attacking:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  player_reference.custom_gauge_params.action_gauge_regen_valid = false
  if self.player.custom_gauge_params.current_action_gauge == 0 then
    SetGravityEnabled(true)
    --SetAccumulatedGravity(g_last_grav)
  end
  g_lock_rotation = true
  SetRotationSpeed(50)
  player.print(GetContextFlag("ResetGravity"))
  SetPlayerSpeed("x", g_my_total_spd, false)
  return self:StateEnter()
end

function PlayerList.omega.states.Attacking:StateMain()
  SetAnimationRotationLock(false)
  player.print(GetContextFlag("ResetGravity"))
  local my_spd = GetPlayerSpeed("x", false)
  local atk_prms = self.player.attack_params
  local top_spd = atk_prms.TOP_SPEED
  local brake = atk_prms.DECELERATION_RATE
  if my_spd > top_spd then
    brake = atk_prms.OVER_RUN_DECEL
	local new_spd = mMax(top_spd, my_spd - (brake * G_DELTA_TIME))
	SetPlayerSpeed("x", new_spd, false)
  elseif IsStickNeutral() then
    local new_spd = mMax(0, my_spd - (brake * G_DELTA_TIME))
	SetPlayerSpeed("x", new_spd, false)
  elseif my_spd < top_spd then
    local accel = atk_prms.ACCELERATION_RATE
	local new_spd = mMin(top_spd, my_spd + (accel * G_DELTA_TIME))
	SetPlayerSpeed("x", new_spd, false)
  end
end

function PlayerList.omega.states.Attacking:StateExit()
  local my_state = GetPlayerState()
  if player_reference.custom_gauge_params.current_action_gauge ~= 0 and not GetInput("a", "hold") then
    player_reference.custom_gauge_params.action_gauge_regen_valid = true
  end
  g_lock_rotation = false
  SetRotationSpeed(800)
end

function PlayerList.blaze.states.Rolling:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  self.player.downforce_override = true
  ChangePlayerAnim("jump_alt")
  RollStartup(self)
  return self:StateEnter()
end

function PlayerList.blaze.states.Rolling:StateMain()
  if GetPlayerSpeed("y", true, true) ~= 0 then
    SetPlayerState(0)
    return self:SwitchState("RESET")
  end
  SetAnimationRotationLock(0)
  if GetInput("b") then
    SetPlayerState(2)
    return self:SwitchState("RESET")
  elseif GetInput("a") and GetInputLockout() == 0 then
    if IsGrounded() then
      PlayProcess("SDJ")
	  return
	else
	  SetPlayerState(4)
	  return
	end
  elseif not ValidateRollTransition(GetPlayerState()) and GetInputLockout() == 0 then
    SetPlayerState(0)
    return self:SwitchState("RESET")
  end
  
  RollMain(self)
end

function PlayerList.blaze.states.Rolling:StateExit()
  RollExit(self)
end

function PlayerList.blaze.states.Attacking:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  ToggleHitboxKick(true)
  ChangePlayerAnim("attack")
  SetPreviousSpeed("x", 0)
  SetPreviousSpeed("y", 0)
  SetCurrentAnimationTime(0)
  return self:StateEnter()
end

function PlayerList.blaze.states.Attacking:StateMain()
  --SetAnimationRotationLock(false)
  if GetInput("a") and GetInputLockout() == 0 then
    PlayProcess("SDJ") 
	return
  elseif not IsGrounded then
    SetPlayerState(0)
	return self:SwitchState("RESET")
  end
  local stick_total = mAbs(GetStickInput("L", "X", true)) + mAbs(GetStickInput("L", "Y", true))
  local exit_time = stick_total == 0 and 59/60 or 40/60
  if GetCurrentAnimationTime() >= exit_time or (not IsGrounded() and self.player.current_class ~= "Attack") then
    SetPlayerState(0)
    return self:SwitchState("RESET")
  end
  ExitOnAutomationCollision(self)
end

function PlayerList.blaze.states.Attacking:StateExit()
  ToggleHitboxKick(false)
end

function PlayerList.amy.states.Rolling:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  self.player.downforce_override = true
  ChangePlayerAnim("jump_alt")
  RollStartup(self)
  return self:StateEnter()
end

function PlayerList.amy.states.Rolling:StateMain()
  if GetPlayerSpeed("y", true, true) ~= 0 then
    SetPlayerState(0)
    return self:SwitchState("RESET")
  end
  SetAnimationRotationLock(0)
  if GetInput("b") then
    SetPlayerState(2)
    return self:SwitchState("RESET")
  elseif GetInput("a") and GetInputLockout() == 0 then
    if IsGrounded() then
      PlayProcess("SDJ")
	  return
	elseif GetRemainingJumps() > 0 then
	  SetPlayerState(94)
	  return self:SwitchState("DoubleJumping")
	end
  elseif GetInput("x") and GetInputLockout() == 0 then
    if IsGrounded() then
      SetPlayerState(96)
	  return self:SwitchState("Attacking")
	else
	  return self:SwitchState("AirSwinging")
	end
  elseif not ValidateRollTransition(GetPlayerState()) and GetInputLockout() == 0 then
    SetPlayerState(0)
    return self:SwitchState("RESET")
  end
  
  RollMain(self)
end

function PlayerList.amy.states.Rolling:StateExit()
  RollExit(self)
end

local was_vault_exit = false
function PlayerList.amy.states.DoubleJumping:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  prev_state_base_speed = mFloor(GetPlayerSpeed("total"))
  SetPlayerSpeed("x", 0, true)
  if prev_state_base_speed == 0 then
    prev_state_base_speed = GetPlayerLuaValue("c_jump_run")
  end
  SetPlayerSpeed("x", prev_state_base_speed, false)
  g_lock_rotation = true
  SetRotationSpeed(150)
  return self:StateEnter()
end

function PlayerList.amy.states.DoubleJumping:StateMain()
  SetAnimationRotationLock(false)
  if GetPlayerSpeed("x", false) == 0 then
    SetPlayerSpeed("x", prev_state_base_speed, false)
  end
  if GetPlayerState() == 94 then--and was_vault_exit then
    ChangePlayerAnim("jump_double_1")
  end
  if not IsGrounded() and GetPlayerState() == 95 then
    if GetInput("x") then
      SetPlayerState(23)
	  return self:SwitchState("AirSwinging")
	elseif GetInput("b") then
	  SetPlayerState(0)
	  return self:SwitchState("RESET")
    end
  elseif IsGrounded() then
    SetPlayerState(0)
    return self:SwitchState("RESET")
  end
end

function PlayerList.amy.states.DoubleJumping:StateExit()
  was_vault_exit = false
  g_lock_rotation = false
  SetRotationSpeed(800)
end

local prev_accel = 0
function PlayerList.amy.states.Stealthing:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  player_reference.custom_gauge_params.action_gauge_regen_valid = false
  SetUniqueLuaValue("c_jump_double_count", self.player.hammer_params.stealth_double_jump_count)
  prev_accel = GetPlayerLuaValue("c_run_acc")
  SetPlayerLuaValue("c_run_acc", self.player.hammer_params.stealth_accel)
  return self:StateEnter()
end

function PlayerList.amy.states.Stealthing:StateMain()
  if GetCurrentGaugeValue() == 0 then
	return self:SwitchState("RESET")
  end
  SetPlayerLuaValue("c_run_speed_max", self.player.hammer_params.stealth_max_velocity)
  local my_state = GetPlayerState()
  if GetInputLockout() == 0 then
    if IsGrounded() then
	  if GetInput("x") then
	    SetPlayerState(96)
		return self:SwitchState("Attacking")
	  elseif GetInput("y") then
	    SetPlayerState(23)
		return self:SwitchState("Spinning")
	  elseif GetInput("b") and ValidateRollTransition(my_state) and my_state ~= 23 then
	    SetPlayerState(StateID.GOAL_LOOP)
        return self:SwitchState("Rolling")
	  end
	else
	  if my_state == 94 then
	    if GetPlayerSpeed("x", false) == 0 then
		  SetPlayerSpeed("x", prev_state_base_speed, false)
		end
	  else
	    prev_state_base_speed = GetPlayerSpeed("x", false)
	  end
	  if GetInput("x") then
	    SetPlayerState(23)
		return self:SwitchState("AirSwinging")
	  elseif GetInput("a") and GetRemainingJumps() > 0 and my_state == 3 then
	    SetPlayerState(94)
	    --return self:SwitchState("DoubleJumping")
	  end
	end
  end
end

function PlayerList.amy.states.Stealthing:StateExit()
  player_reference.custom_gauge_params.action_gauge_regen_valid = true
  SetRemainingStealthTime(0)
  SetUniqueLuaValue("c_jump_double_count", self.player.hammer_params.base_double_jump_count)
  SetPlayerLuaValue("c_run_acc", prev_accel)
  prev_state_base_speed = 0
end

function PlayerList.amy.states.Attacking:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  SetCurrentAnimationTime(0)
  prev_state_base_speed = GetPlayerSpeed("x", false)
  prev_state_gimmick_speed = GetPlayerSpeed("x", true)
  EnableAmyHammer(true)
  return self:StateEnter()
end

function PlayerList.amy.states.Attacking:StateMain()
  SetAnimationRotationLock(false)
  local brake_multiplier = IsStickNeutral() and 2 or 1
  prev_state_base_speed = mMax(0, prev_state_base_speed - self.player.hammer_params.attack_brake_base * brake_multiplier)
  prev_state_gimmick_speed = mMax(0, prev_state_gimmick_speed - self.player.hammer_params.attack_brake_gimmick * brake_multiplier)
  SetPlayerSpeed("x", prev_state_base_speed, false)
  SetPlayerSpeed("x", prev_state_gimmick_speed, true)
  local anim_time = GetCurrentAnimationTime() -- Lasts 18 frames
  if anim_time >= 20/60 and GetInput("x", "hold") then -- 22
	SetCurrentAnimationTime(0)
	SetPlayerState(23)
	return self:SwitchState("Vaulting")
  end
end

function PlayerList.amy.states.Attacking:StateExit()
  prev_state_base_speed = 0
  prev_state_gimmick_speed = 0
  was_vault_exit = false
end


local has_been_air = false
function PlayerList.amy.states.Vaulting:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  EnableAmyHammer(true)
  has_been_air = false
  SetPlayerOffGround(true)
  local spd_total = GetPlayerSpeed("total")
  SetPlayerSpeed("x", spd_total, false)
  SetPlayerSpeed("x", 0, true)
  SetGravityForce(980 * 3)
  SetPlayerSpeed("y", 1500, false)
  SetPlayerSpeed("y", 0, true)
  SetPreviousSpeed("x", 0)
  SetPreviousSpeed("y", 0)
  g_lock_rotation = true
  SetRotationSpeed(150)
  ChangePlayerAnim("homing")
  Game.ProcessMessage("LEVEL", "PlaySE", {bank = "player_amy", id = "double_jump"})
  return self:StateEnter()
end

function PlayerList.amy.states.Vaulting:StateMain()
  SetAnimationRotationLock(false)
  EnableAmyHammer(true)
  local my_h_spd = GetPlayerSpeed("total")
  my_h_spd = mMax(self.player.hammer_params.vault_min_spd, my_h_spd - self.player.hammer_params.vault_horizontal_brake)
  SetPlayerSpeed("x", my_h_spd, false)
  SetPlayerSpeed("x", 0, true)
  local my_y_spd = AirAttackBounce() or 0
  if my_y_spd > 0 then
    --SetPlayerSpeed("y", my_y_spd, false)
	local my_grav = GetAccumulatedGravity()
	--SetAccumulatedGravity(mMax(0, my_grav - GetPlayerSpeed("y", false)))
	SetAccumulatedGravity(0)
  end
  if IsGrounded() then
    if has_been_air then
      SetPlayerOffGround(false)
	  SetPlayerState(0)
	  SetPlayerSpeed("y", 0, false)
	  return self:SwitchState("RESET")
	end
  else
    has_been_air = true
  end
  if GetInput("b") then
    SetPlayerState(0)
	SetPlayerSpeed("y", 900, false)
	return self:SwitchState("RESET")
  elseif GetInput("a") and GetRemainingJumps() > 0 then
    SetPlayerState(94)
	return self:SwitchState("DoubleJumping")
  elseif GetInput("x", "down") and not GetInput("x", "released") and not IsGrounded() then
    return self:SwitchState("AirSwinging")
  end
  ExitOnAutomationCollision(self)
end

function PlayerList.amy.states.Vaulting:StateExit()
  EnableAmyHammer(false)
  SetGravityForce(980)
  SetPlayerOffGround(false)
  has_delayed_state = false
  if IsGrounded() then
    SetPlayerSpeed("y", 0, false)
  end
  was_vault_exit = true
  SetAnimationRotationLock(false)
  g_lock_rotation = false
  SetRotationSpeed(800)
  badnik_multiplier_current = badnik_multiplier_base
end

function PlayerList.amy.states.AirSwinging:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  EnableAmyHammer(true)
  SetPreviousSpeed("x", 0)
  SetPreviousSpeed("y", 0)
  ChangePlayerAnim("fly")
  g_lock_rotation = true
  SetRotationSpeed(150)
  Game.ProcessMessage("LEVEL", "PlaySE", {bank = "player_amy", id = "hammer_attack"})
  return self:StateEnter()
end

function PlayerList.amy.states.AirSwinging:StateMain()
  SetAnimationRotationLock(false)
  local my_h_spd = GetPlayerSpeed("x", false)
  if my_h_spd > 0 then
    my_h_spd = mMax(0, my_h_spd - self.player.hammer_params.air_swing_brake)
    SetPlayerSpeed("x", my_h_spd, false)
  end
  local anim_time = GetCurrentAnimationTime()
  local my_y_spd = AirAttackBounce() or 0
  if my_y_spd > 0 then
    --SetPlayerSpeed("y", my_y_spd, false)
	local my_grav = GetAccumulatedGravity()
	--SetAccumulatedGravity(mMax(0, my_grav - GetPlayerSpeed("y", false)))
	SetAccumulatedGravity(0)
  end
  if IsGrounded() then
	if (anim_time >= 10/60 and anim_time < 17/60) then
	  local spd = GetPlayerSpeed("x", false)
	  SetPlayerSpeed("x", spd + self.player.hammer_params.air_swing_vault_add, false)
	  Game.ProcessMessage("LEVEL", "PlaySE", {bank = "player_amy", id = "hammer_cock"})
	  Game.ProcessMessage("LEVEL", "PlaySE", {bank = "player_amy", id = "double_jump"})
	  return self:SwitchState("Vaulting")
	else
      SetPlayerState(0)
	  return self:SwitchState("RESET")
	end
  elseif anim_time >= 35/60 then
    SetPlayerState(0)
	return self:SwitchState("RESET")
  elseif GetInput("a") and GetRemainingJumps() > 0 then
    SetPlayerState(94)
	return self:SwitchState("DoubleJumping")
  end
  ExitOnAutomationCollision(self)
end

function PlayerList.amy.states.AirSwinging:StateExit()
  EnableAmyHammer(false)
  was_vault_exit = false
  badnik_multiplier_current = badnik_multiplier_base
  if IsGrounded() then
    SetPlayerSpeed("y", 0, false)
  end
  g_lock_rotation = false
  SetRotationSpeed(800)
end

local my_hammer_time = 0
function PlayerList.amy.states.Spinning:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  EnableAmyHammer(true)
  ChangePlayerAnim("sliding")
  my_hammer_time = 0
  SetPreviousSpeed("x", 0)
  SetPreviousSpeed("y", 0)
  local total = GetPlayerSpeed("total")
  prev_state_base_speed = total
  SetPlayerSpeed("x", 0, true)
  SetPlayerSpeed("x", total, false)
  player_reference.custom_gauge_params.action_gauge_regen_valid = false
  Game.ProcessMessage("LEVEL", "PlaySE", {bank = "player_amy", id = "hammer_attack"})
  return self:StateEnter()
end

function PlayerList.amy.states.Spinning:StateMain()
  local held, released = GetInput("y", "hold")
  if math.mod(my_hammer_time, 18) == 0 then -- 18 is synced with the animation, but player input can affect the speed
	Game.ProcessMessage("LEVEL", "PlaySE", {bank = "player_amy", id = "hammer_attack"})
  end
  if not IsStickNeutral() then
    local stick_Y = mAbs(GetStickInput("L", "Y", true))
    local max_spd = stick_Y <= 0.9 and self.player.hammer_params.spin_min_spd or self.player.hammer_params.spin_max_spd
	if prev_state_base_speed > max_spd then
	  local turn_brake = stick_Y <= 0.9 and self.player.hammer_params.spin_rotation_brake or 0
      prev_state_base_speed = mMax(max_spd, prev_state_base_speed - (self.player.hammer_params.spin_brake + turn_brake))
	elseif prev_state_base_speed < max_spd then
	  prev_state_base_speed = mMin(max_spd, prev_state_base_speed + self.player.hammer_params.spin_accel)
	end
  else
    prev_state_base_speed = mMax(0, prev_state_base_speed - self.player.hammer_params.spin_brake * 2)
  end
  SetPlayerSpeed("x", prev_state_base_speed, false)
  SetPlayerLuaValue("c_run_speed_max", prev_state_base_speed)
  if not IsGrounded() then
    SetPlayerState(0)
	return self:SwitchState("RESET")
  elseif released and my_hammer_time >= 5 then
    SetPlayerState(0)
	return -- It's important to do a standard return and not call RESET. Otherwise you get stuck spinning.
  elseif GetCurrentGaugeValue() == 0 then
    SetPlayerState(0)
	SetInputLockout(10)
    return self:SwitchState("Dizzying")
  end
  my_hammer_time = my_hammer_time + 1
  SetAnimationRotationLock(false)
  ExitOnAutomationCollision(self)
end

function PlayerList.amy.states.Spinning:StateExit()
  EnableAmyHammer(false)
  SetAnimationRotationLock(false)
  was_vault_exit = false
  my_hammer_time = 0
  player_reference.custom_gauge_params.action_gauge_regen_valid = true
end

function PlayerList.amy.states.Dizzying:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  EnableAmyHammer(false)
  SetAnimationRotationLock(true)
  ChangePlayerAnim("piyori_l")
  SetPlayerSpeed("x", 0, false)
  SetPlayerSpeed("x", 0, true)
  Game.ProcessMessage("LEVEL", "PlaySE", {bank = "player_amy", id = "v_invisible_end"})
  my_hammer_time = 0
  return self:StateEnter()
end

function PlayerList.amy.states.Dizzying:StateMain()
  if math.mod(my_hammer_time, 30) == 0 then
    Game.ProcessMessage("LEVEL", "PlaySE", {bank = "player_amy", id = "invisible_end"})
  end
  ChangePlayerAnim("piyori_l")
  if not IsGrounded() then
    SetPlayerState(0)
	return self:SwitchState("RESET")
  elseif GetCurrentGaugeValue() >= 0.95 then
    SetPlayerState(0)
	return self:SwitchState("RESET")
  end
  my_hammer_time = my_hammer_time + 1
end

function PlayerList.amy.states.Dizzying:StateExit()
  SetAnimationRotationLock(false)
  SetInputLockout(0)
  if GetPlayerAnim(true) == "piyori_l" then
    ChangePlayerAnim("wait")
  end
  was_vault_exit = false
  my_hammer_time = 0
end

local impulse_ready = false
function PlayerList.sonic.states.SpinDash:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  SetLuaMaxSpeed(4500)
  return self:StateEnter()
end

local spnd_brake = 2000/60 --2500
local prev_spd = 0
function PlayerList.sonic.states.SpinDash:StateMain()
  if GetPlayerState() == 23 then SetPlayerState(70) end
  if impulse_ready then
	impulse_ready = false
	--SetPlayerSpeed("x", prev_spd, true)
	local final_spd = mMax(prev_spd + 500, (spnd_base_spd + prev_spd) * spnd_charge_mult)
	SetPlayerSpeed("x", final_spd, false)
	print("Mult: " .. spnd_charge_mult .. " prev: " .. prev_spd .. " final: " .. final_spd)
  end
  if GetInput("x", "hold") then 
    SetPlayerInvuln(true)
    local spd = GetPlayerSpeed("x", true)
    local l_ground_magnitude = SLOPE_is_downward and mAbs(g_ground_magnitude) or g_ground_magnitude * -1
    local new_spd = mMin(GetLuaMaxSpeed(), spd + ((l_ground_magnitude * (roll_multiplier) * 1/60)) * 2)
	new_spd = mMax(0, new_spd - spnd_brake)
    SetPlayerSpeed("forward", new_spd, true)
	spnd_charge_mult = mMin(spnd_charge_max, spnd_charge_mult + spnd_charge_inc)
	prev_spd = new_spd
    return 
  elseif GetInput("x", "released") then
    SetPlayerInvuln(false)
    impulse_ready = true
  end
  if GetInput("b") then
    SetPlayerState(2)
    return self:SwitchState("RESET")
  elseif GetInput("a") and GetInputLockout() == 0 then
    PlayProcess("SDJ")
	return
  end
  if GetPlayerSpeed("x", false) <= 10 then return end -- Hacky quick fix to stop spin kick
  local spd = GetPlayerSpeed("forward", false) 
  if not SLOPE_is_downward then
    roll_multiplier = 1
  end
  local l_ground_magnitude = SLOPE_is_downward and mAbs(g_ground_magnitude) or g_ground_magnitude * -1
  local new_spd = mMin(GetLuaMaxSpeed(), spd + ((l_ground_magnitude * (roll_multiplier) * 1/60) - 50/60) * 2)
  SetPlayerSpeed("forward", new_spd, false)
  local gimmick = GetPlayerSpeed("forward", true)
  local total_spd = GetPlayerSpeed("total")
  SetPlayerLuaValue("c_run_speed_max", mMax(player_reference.max_run_spd, total_spd))
  if forced_time <= forced_time_base and forced_time > 0 then
    forced_time = forced_time - 1
	if forced_time <= 0 then
	  forced_time = forced_time_base + 1
	end
	return
  end
  if total_spd <= 450 and not GetInput("x", "hold") then 
	SetPlayerState(2)
  end
end

function PlayerList.sonic.states.SpinDash:StateExit()
  self.player.downforce_override = false
  SetLuaMaxSpeed(3300)
  SetDownforce(60)
  SetAngleThreshold(10)
  spnd_charge_mult = spnd_base_mult
  prev_spd = 0
  SetPlayerInvuln(false)
end


local spindash_duration = 0
local sfx_timer = 0
function PlayerList.shadow.states.SpinDash:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  SetLuaMaxSpeed(4500)
  spindash_duration = 0
  sfx_timer = 0
  ToggleHitboxKick(true)
  spnd_charge_mult = spnd_roll_mult
  ChangePlayerAnim("jump_alt")
  local bank, sfx = self.player.custom_sounds.SpinDash.charge[1], self.player.custom_sounds.SpinDash.charge[2]
  PlaySound(bank, sfx)
  return self:StateEnter()
end

function PlayerList.shadow.states.SpinDash:StateMain()
  SetAnimationRotationLock(false)
  if not IsGrounded() and (not GetInput("a") and not GetInput("a", "hold")) then
    SetPlayerState(0)
	return self:SwitchState("RESET")
  end
  if spindash_duration > 0 then
    spindash_duration = spindash_duration + 1
  end
  if spindash_duration >= self.player.spindash_duration then
    SetPlayerState(0)
	return self:SwitchState("RESET")
  end
  if impulse_ready then
	impulse_ready = false
	SetPlayerInvuln(true)
	spindash_duration = 1
	local bank1, bank2 = self.player.custom_sounds.SpinDash.release_1[1], self.player.custom_sounds.SpinDash.release_2[1]
	local sfx1, sfx2 = self.player.custom_sounds.SpinDash.release_1[2], self.player.custom_sounds.SpinDash.release_2[2]
	PlaySound(bank1, sfx1)
    PlaySound(bank2, sfx2)
	--SetPlayerSpeed("x", prev_spd, true)
	local final_spd = mMax(prev_spd + 500, (spnd_base_spd + prev_spd) * spnd_charge_mult)
	SetPlayerSpeed("x", final_spd, false)
	print("Mult: " .. spnd_charge_mult .. " prev: " .. prev_spd .. " final: " .. final_spd)
  end
  if GetInput("x", "hold") and spindash_duration == 0 then 
    local spd = GetPlayerSpeed("x", true)
    local l_ground_magnitude = SLOPE_is_downward and mAbs(g_ground_magnitude) or g_ground_magnitude * -1
    local new_spd = mMin(GetLuaMaxSpeed(), spd + ((l_ground_magnitude * (roll_multiplier) * 1/60)) * 2)
	new_spd = mMax(0, new_spd - spnd_brake)
    SetPlayerSpeed("forward", new_spd, true)
	spnd_charge_mult = mMin(spnd_charge_max, spnd_charge_mult + spnd_charge_inc)
	prev_spd = new_spd
	local bank, sfx = self.player.custom_sounds.SpinDash.charge[1], self.player.custom_sounds.SpinDash.charge[2]
	sfx_timer = sfx_timer + G_DELTA_TIME
	if sfx_timer >= 13/60 then
	  sfx_timer = 0
	  PlaySound(bank, sfx)
	end
    return 
  elseif GetInput("x", "released") and spindash_duration == 0 then
    impulse_ready = true
	ChangePlayerAnim("spindash")
  end
  if GetInput("b") then
    SetPlayerState(2)
    return self:SwitchState("RESET")
  elseif GetInput("a") and GetInputLockout() == 0 then
    PlayProcess("SDJ")
	return
  end
  if GetPlayerSpeed("x", false) <= 10 then return end -- Hacky quick fix to stop spin kick
  local spd = GetPlayerSpeed("forward", false) 
  if not SLOPE_is_downward then
    roll_multiplier = 1
  end
  local l_ground_magnitude = SLOPE_is_downward and mAbs(g_ground_magnitude) or g_ground_magnitude * -1
  local new_spd = mMin(GetLuaMaxSpeed(), spd + ((l_ground_magnitude * (roll_multiplier) * 1/60) - 50/60) * 2)
  SetPlayerSpeed("forward", new_spd, false)
  SetPlayerSpeed("forward", 0, true)
  local gimmick = GetPlayerSpeed("forward", true)
  local total_spd = GetPlayerSpeed("total")
  SetPlayerLuaValue("c_run_speed_max", mMax(player_reference.max_run_spd, total_spd))
  if forced_time <= forced_time_base and forced_time > 0 then
    forced_time = forced_time - 1
	if forced_time <= 0 then
	  forced_time = forced_time_base + 1
	end
	return
  end
  if total_spd <= 450 and not GetInput("x", "hold") then 
	SetPlayerState(2)
  end
  ExitOnAutomationCollision(self)
end

function PlayerList.shadow.states.SpinDash:StateExit()
  self.player.downforce_override = false
  SetLuaMaxSpeed(3300)
  SetDownforce(60)
  SetAngleThreshold(10)
  spnd_charge_mult = spnd_base_mult
  prev_spd = 0
  SetPlayerInvuln(false)
  ToggleHitboxKick(false)
end

local spearing_time = 0
function PlayerList.shadow.states.SpearingPost:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  SetAnimationRotationLock(false)
  if self.player.spear_count >= 0 then
    local height = self.player.spear_heights[self.player.spear_count] or 150
	self.player.spear_count = self.player.spear_count - 1
	SetPlayerSpeed("y", height, false)
  end
  spearing_time = 0
  return self:StateEnter()
end

function PlayerList.shadow.states.SpearingPost:StateMain()
  spearing_time = spearing_time + G_DELTA_TIME
  local height = self.player.spear_heights[self.player.spear_count + 1] or 150
  if GetInput("x", "hold") then
    SetPlayerSpeed("y", height, false)
  end
  --SetPlayerSpeed("y", height, false)
  if spearing_time >= self.player.spear_cancel_time then
    if GetInput("a") then
	  SetPlayerState(4)
	  spearing_time = 0
	end
  end
end

function PlayerList.shadow.states.SpearingPost:StateExit()
  spearing_time = 0
end