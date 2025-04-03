-- @BRIEF: Unique (i.e., Amy, Omega, Tails) or extended (Shadow, Sonic) character gauge behavior.

local is_regen_delayed = false
local regen_timer = 0

local function ResetOnRestart()
  if GetManagedFlag(g_flags.stage_restart) then
    local custom_gauge = player_reference.custom_gauge_params
    --SetManagedFlag(g_flags.stage_restart, false)
	custom_gauge.action_gauge_maturity_level = custom_gauge.action_gauge_maturity_level_initial
	custom_gauge.action_gauge_maturity_current = 0
	custom_gauge.current_action_gauge = 0
	SetMaturityLevel(custom_gauge.action_gauge_maturity_level)
    SetMaturity(0)
	is_regen_delayed = false
	regen_timer = 0
	return true
  end
  return false
end

local function AddMaturityOnDrive(is_shadow)
  local custom_gauge = player_reference.custom_gauge_params
  if custom_gauge.action_gauge_maturity_valid then
    local maturity = custom_gauge.action_gauge_maturity_current
    local maturity_add = custom_gauge.action_gauge_maturity_add
    maturity = mMin(1, maturity + maturity_add)
    if not is_shadow and (maturity >= 1.0 and GetMaturityLevel() ~= 3) then
	  maturity = 0
	  local maturity_level = custom_gauge.action_gauge_maturity_level
	  custom_gauge.action_gauge_maturity_level = maturity_level + 1
	  SetMaturityLevel(maturity_level + 1)
	  CallUIAnim("power_a", "DefaultAnim")
    end
    custom_gauge.action_gauge_maturity_current = maturity
    SetMaturity(maturity)
  end
end

function ManageActionGauge() -- Generic Action Gauge manager
  local custom_gauge = player_reference.custom_gauge_params
  if ResetOnRestart() then return end
  
  if GetMaturityLevel() ~= custom_gauge.action_gauge_maturity_level then
    SetMaturityLevel(custom_gauge.action_gauge_maturity_level)
  end
  local current_gauge = custom_gauge.current_action_gauge
  if HasGotDrive() then
    current_gauge = mMin(1, current_gauge + custom_gauge.action_gauge_core_add)
	AddMaturityOnDrive()
  end
  if custom_gauge.action_gauge_regen_valid then
    if is_regen_delayed then
	  regen_timer = regen_timer + G_DELTA_TIME
	  if regen_timer >= custom_gauge.action_gauge_regen_delay then
	    regen_timer = 0
		is_regen_delayed = false
	  end
	else
      current_gauge = mMin(1, current_gauge + custom_gauge.action_gauge_time_add)
	end
  else
    is_regen_delayed = custom_gauge.action_gauge_use_regen_delay
  end
  custom_gauge.current_action_gauge = current_gauge
  SetCurrentGaugeValue(current_gauge)
end


--- $ Character Gauges $ ---
function ManageTailsGauge()
  local my_state = GetPlayerState()
  if IsGrounded() or GetInputLockout() ~= 0 then
    player_reference.custom_gauge_params.action_gauge_regen_valid = true
  end
  ManageActionGauge()
  if my_state == StateID.GLIDE then
    local my_brake = 0
	local my_gauge = player_reference.custom_gauge_params.current_action_gauge
    if GetInput("a", "hold") then
	  my_brake = player_reference.flight_params.gauge_brake
	else
	  my_brake = player_reference.flight_params.gauge_brake_idle
	end
	my_gauge = mMax(0, my_gauge - my_brake)
	if my_gauge <= 0 then
	  my_gauge = 0
	  SetPlayerState(3)
	  SetRemainingFlightTime(0)
	end
	player_reference.custom_gauge_params.current_action_gauge = my_gauge
	SetCurrentGaugeValue(my_gauge)
  end
  if player_reference.custom_gauge_params.current_action_gauge ~= 0 then
    SetRemainingFlightTime(50)
  end
end
PlayerList.tails.action_gauge_function = ManageTailsGauge
PlayerList.tails.custom_gauge_params.action_gauge_maturity_level = PlayerList.tails.custom_gauge_params.action_gauge_maturity_level_initial

local function OmegaHover()
  local my_gauge = player_reference.custom_gauge_params.current_action_gauge
  local my_brake = player_reference.hover_params.brake_by_level[GetMaturityLevel()]
  my_gauge = mMax(0, my_gauge - my_brake)
  if my_gauge <= 0 then
    my_gauge = 0
    SetUniqueLuaValue("c_hovering_acc", 0)
  end
  player_reference.custom_gauge_params.current_action_gauge = my_gauge
  SetCurrentGaugeValue(my_gauge)
end
function ManageOmegaGauge()
  local my_state = GetPlayerState()
  if IsGrounded() or GetInputLockout() ~= 0 then
    player_reference.custom_gauge_params.action_gauge_regen_valid = true
  end
  ManageActionGauge()
  if my_state == StateID.HOVER then
    OmegaHover()
  elseif my_state == StateID.LAUNCHER or my_state == StateID.LOCKON then
    OmegaHover()
  end
  if player_reference.custom_gauge_params.current_action_gauge ~= 0 then
    SetUniqueLuaValue("c_hovering_acc", player_reference.hover_params.base_hover_speed)
  end
end
PlayerList.omega.action_gauge_function = ManageOmegaGauge
PlayerList.omega.custom_gauge_params.action_gauge_maturity_level = PlayerList.omega.custom_gauge_params.action_gauge_maturity_level_initial

function ManageAmyGauge()
  ManageActionGauge()
  local my_lua_state = player_reference.current_state
  if player_reference.custom_gauge_params.action_gauge_regen_valid == false then
    local gauge_brake = my_lua_state == "Spinning" and player_reference.hammer_params.spinning_gauge_brake or player_reference.hammer_params.stealth_gauge_brake
    local my_gauge = player_reference.custom_gauge_params.current_action_gauge
	my_gauge = mMax(0, my_gauge - gauge_brake)
	if my_gauge <= 0 then
	  my_gauge = 0
	end
	player_reference.custom_gauge_params.current_action_gauge = my_gauge
	SetCurrentGaugeValue(my_gauge)
  elseif IsGrounded() or GetInputLockout() ~= 0 then
    player_reference.custom_gauge_params.action_gauge_regen_valid = true
  end
end
PlayerList.amy.action_gauge_function = ManageAmyGauge
PlayerList.amy.custom_gauge_params.action_gauge_maturity_level = PlayerList.amy.custom_gauge_params.action_gauge_maturity_level_initial


local max_gem_attributes = {
  blue = { hitbox_on = false, active_time = 0 }, -- Active time is used internally. The duration is set in PlayerList
  red = {},
  green = {},
  purple = { shrink_on = false },
  sky = { hitbox_on = false },
  white = {},
  yellow = {},
  super = { c_jump_speed = 900, c_run_speed_max = 1700, c_jump_run = 900, c_run_acc = 650,
			plugins = { 
			  c_sliding_damage = {value = 1, plugin = "zock"}, 
			  c_homing_damage = {value = 1, plugin = "homing" } 
			} 
  }
}

local do_startup = true

function ResetGemStatus()
  do_startup = true
  for gem_name, gem_params in pairs(player_reference.sonic_gem_params) do
    gem_params.current_maturity_value = 0
    gem_params.current_maturity_level = 1
	ParseGemLevelFlag(gem_name, 1) -- in FlagManager
  end
  SetMaturityLevel(1)
  SetMaturity(0)
  SetCurrentGem(0)
end

local function OnGemUse(my_gem, my_level)
  if my_gem == "blue" then
    if my_level == 3 then
	  max_gem_attributes.blue.hitbox_on = true
	  max_gem_attributes.blue.active_time = 0
	  ToggleHitboxKick(true)
	  SetPlayerInvuln(true)
	end
  elseif my_gem == "red" then

  elseif my_gem == "green" then
  
  elseif my_gem == "purple" then
    max_gem_attributes.purple.shrink_on = true
	SetContextFlag("SmallCollision", true)
  elseif my_gem == "sky" then
    
  elseif my_gem == "white" then
  
  elseif my_gem == "yellow" then
  
  elseif my_gem == "super" then
    local attributes = max_gem_attributes.super
	player_reference.base_jump_speed = attributes.c_jump_speed
	player_reference.max_run_spd = attributes.c_run_speed_max
	player_reference.slope_params.base_jump_run = attributes.c_jump_run
	for param_name, param_value in pairs(attributes) do
	  if param_name ~= "plugins" then
	    SetPlayerLuaValue(param_name, param_value)
	  else
	    for plugin_entry, plugin_vals in pairs(param_value) do
		  SetPluginValue(plugin_vals.plugin, plugin_entry, plugin_vals.value)
		end
	  end
	end
  end
end

local function OnGemLevelUp(gem, ignore_sfx)
  local gem_name = "c_" .. gem
  local gem_gauge = player_reference.sonic_gem_params[gem]
  local my_level = gem_gauge.current_maturity_level
  if do_startup then
    my_level = ParseGemLevelFlag(gem)
	gem_gauge.current_maturity_level = my_level
  end
  if not ignore_sfx then
    Game.ProcessMessage("LEVEL", "PlaySE", {bank = "player_sonic", id = "levelup"})
  end
  if gem == "none" then
	local heal_delay = gem_gauge.gauge_heal_delay_by_level[my_level]
	local heal_rate = gem_gauge.gauge_heal_rate_by_level[my_level]
    SetGaugeParameter("c_gauge_heal_delay", heal_delay)
	SetGaugeParameter("c_gauge_heal", heal_rate)
  else
    local my_consumption_rate = gem_gauge.gauge_drain_by_level[my_level]
    SetGaugeParameter(gem_name, my_consumption_rate)
	for parameter, value in pairs(gem_gauge.lua_values_by_level[my_level]) do
	  SetUniqueLuaValue(parameter, value)
	end
  end
  if gem == "purple" then
    gem_gauge.air_drag_rate = gem_gauge.air_drag_by_level[my_level]
  elseif gem == "green" then
    gem_gauge.max_move_spd = gem_gauge.max_move_by_level[my_level]
  elseif gem == "super" then
    for _, value_set in pairs(gem_gauge.additional_values_by_level[my_level]) do
	  local param_name = value_set.param
	  local param_value = value_set.value
	  if value_set.is_plugin then
		max_gem_attributes.super.plugins[param_name].value = param_value
		local rates = gem_gauge.my_damage_rates
		if rates[param_name] then
		  rates[param_name] = param_value
		end
		--if GetManagedFlag(g_flags.is_super) then
	      --SetPluginValue(value_set.plugin_name, param_name, param_value)
		--end
	  else
		max_gem_attributes.super[param_name] = param_value
	  end
	end
	if GetManagedFlag(g_flags.is_super) then
	  --SetPluginValue(value_set.plugin_name, param_name, param_value)
	  OnGemUse("super", GetMaturityLevel())
	end
  end
end

local function ManageSonicCores() -- Since Sonic's base gauge is re-implemented through a patch, I need specific behavior for him
  if GetManagedFlag(g_flags.stage_restart) then
    --SetManagedFlag(g_flags.stage_restart, false)
	ResetGemStatus()
	return
  end
  if do_startup then
    for gem_name, _ in pairs(player_reference.sonic_gem_params) do
      OnGemLevelUp(gem_name, true)
    end
	do_startup = false
	return
  end
  local my_gem = GetHUDGem() -- String name of the currently selected gem
  local custom_gauge = player_reference.custom_gauge_params -- General custom gauge values, used for collecting Chaos Drives/Light Cores
  local gem_gauge = player_reference.sonic_gem_params[my_gem] -- Table for custom gem values
  if GetMaturityLevel() ~= gem_gauge.current_maturity_level then
    SetMaturityLevel(gem_gauge.current_maturity_level)
	OnGemLevelUp(my_gem, true)
  elseif GetMaturity() ~= gem_gauge.current_maturity_value then
    SetMaturity(gem_gauge.current_maturity_value)
  end
  local current_gauge = GetGaugeParameter("c_gauge_value")
  local last_gauge = player_reference.custom_gauge_params.current_action_gauge
  if current_gauge < last_gauge then
    OnGemUse(my_gem, gem_gauge.current_maturity_level)
  end
  if HasGotDrive() then
    current_gauge = mMin(100, current_gauge + custom_gauge.action_gauge_core_add)
	SetGaugeParameter("c_gauge_value", current_gauge)
	if true then
	  local maturity = gem_gauge.current_maturity_value
	  local maturity_add = custom_gauge.action_gauge_maturity_add
	  maturity = mMin(1, maturity + maturity_add)
	  local current_level = GetMaturityLevel()
	  if maturity >= 1.0 and GetMaturityLevel() ~= 3 then
		local maturity_level = gem_gauge.current_maturity_level + 1
		gem_gauge.current_maturity_level = maturity_level
		SetMaturityLevel(maturity_level)
		CallUIAnim("power_a", "DefaultAnim")
		maturity = maturity_level == 3 and 1 or 0
		OnGemLevelUp(my_gem)
		ParseGemLevelFlag(my_gem, maturity_level)
	  end
	  gem_gauge.current_maturity_value = maturity
	  SetMaturity(maturity)
	end
  end
  player_reference.custom_gauge_params.current_action_gauge = current_gauge
end
local function ManageGemEffects()
  if max_gem_attributes.purple.shrink_on and not GetContextFlag("IsShrink") then
    max_gem_attributes.purple.shrink_on = false
	SetContextFlag("SmallCollision", false)
  end
  if GetMaturityLevel() < 3 then -- Max level behavior below this point
    return
  end
  if max_gem_attributes.blue.hitbox_on then
    local blue = max_gem_attributes.blue
    blue.active_time = blue.active_time + 1
	SetContextFlag("MachAura", 1)
	if blue.active_time >= player_reference.sonic_gem_params.blue.hitbox_duration then
	  blue.active_time = 0
	  blue.hitbox_on = false
	  ToggleHitboxKick(false)
	  SetPlayerInvuln(false)
	  SetContextFlag("MachAura", 0)
	end
  elseif GetContextFlag("IsTimeSlow") then
	SetPlayerTimeScale(2 + player_reference.sonic_gem_params.red.max_level_speed_bonus)
  end
end

function ManageSonicGauge()
  if not Player(0):IsValidPTR() then
    return
  elseif sonic_variant == 3 then
    if HasGotDrive() then
	  local gauge = GetGaugeParameter("c_gauge_value")
	  local inc = player_reference.custom_gauge_params.action_gauge_core_add
	  gauge = gauge + inc
	  SetGaugeParameter("c_gauge_value", gauge)
	end
	return
  end
  ManageSonicCores()
  ManageGemEffects()
end
PlayerList.sonic.action_gauge_function = ManageSonicGauge
PlayerList.sonic.custom_gauge_params.action_gauge_maturity_level = PlayerList.sonic.custom_gauge_params.action_gauge_maturity_level_initial

function ManageShadowGauge()
  if not Player(0):IsValidPTR() then
    return
  end
  if ResetOnRestart() then return end
  local maturity_lvl = GetMaturityLevel()
  if maturity_lvl > 0 and HasGotDrive() then
    AddMaturityOnDrive(true)
  end
  local set_lvl = maturity_lvl <= 1 and 1 or maturity_lvl
  SetGaugeParameter("c_level_max", set_lvl)
  if maturity_lvl < 3 and maturity_lvl > 0 then
    local maturity_meter = GetMaturity()
	if maturity_meter >= 1 and GetInput("rt", "released") then
	  maturity_lvl = maturity_lvl + 1
	  player_reference.custom_gauge_params.action_gauge_maturity_level = maturity_lvl
	  SetMaturity(0)
	  player_reference.custom_gauge_params.action_gauge_maturity_current = 0
	  SetGaugeParameter("c_level", maturity_lvl)
	  CallUIAnim("power_a", "DefaultAnim")
	  CallCameraEvent(player_reference.custom_cameras.Boost)
	end
    SetGaugeParameter("c_level_max", maturity_lvl)
  end
end
PlayerList.shadow.action_gauge_function = ManageShadowGauge
PlayerList.shadow.custom_gauge_params.action_gauge_maturity_level = PlayerList.shadow.custom_gauge_params.action_gauge_maturity_level_initial