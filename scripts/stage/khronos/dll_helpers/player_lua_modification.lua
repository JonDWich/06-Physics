-- @BRIEF: Functions for getting/setting lua-defined player parameters.
-- TODO: Try to consolidate all getters/setters so it's more intuitive to use.

lua_params = {
  test = "0x148",
  gravity = "0x14C",
  c_brake_acc = "0x150",
  c_brake_dashpanel = "0x154",
  c_walk_border = "0x158",
  c_run_border = "0x15C",
  c_walk_speed_max = "0x160",
  c_run_acc = "0x164",
  c_run_speed_max = "0x168",
  c_speedup_acc = "0x16C",
  c_speedup_speed_max = "0x170",
  c_jump_time_min = "0x174",
  c_jump_brake = "0x178", -- How quickly you decelerate after releasing the A button
  c_jump_speed_acc = "0x17C",
  c_jump_speed_brake = "0x180",
  c_jump_speed = "0x184",
  c_jump_walk = "0x188",
  c_jump_run = "0x18C",
  c_brake_quick_acc = "0x190",
  c_wait_no_input_time = "0x194",
  c_damage_time = "0x198",
  c_damage_jump = "0x19C",
  c_damage_speed = "0x1A0",
  c_run_against_time = "0x1A4",
  c_grind_speed_org = "0x1A8",
  c_grind_acc = "0x1AC",
  c_grind_speed_max = "0x1B0",
  c_grind_time = "0x1B4",
  c_grind_penalty_time = "0x1B8",
  c_grind_brake_acc = "0x1BC",
  c_invincible_time = "0x1C0",
  c_invincible_time_ring1 = "0x1C4",
  c_invincible_item = "0x1C8",
  c_speedup_time = "0x1CC",
  c_wind_init = "0x1D0",
  c_wind_spd = "0x1D4",
  c_wind_dist = "0x1D8",
  c_border_gravity = "0x1DC",
  c_landing_time = "0x1E0",
  c_ottoto_time = "0x1E4",
  c_dead_animation_time = "0x1E8",
  c_dead_animation_time_coll = "0x1EC",
  c_wallwait_time = "0x1F0",
  c_lclick_time = "0x1F4",
  c_flight_acc = "0x1F8",
  c_flight_speed_acc = "0x1FC",
  c_flight_speed_min = "0x200",
  c_flight_speed_max = "0x204",
  c_hovering_acc = "0x208",
  c_climb_speed = "0x20C",
  c_stun = "0x210",
  c_brake_acc_sand = "0x214",
  c_run_acc_sand = "0x218",
  c_jump_speed_sand = "0x21C",
  c_psi_throw_speed = "0x220"
}

-- 822004F0 will put you in the general spot. To access rotation_method and whatnot, take the offset in pseudocode as the start of your move (e.g. 0x2D0)
local posture_values = {
  c_rotation_method = "0x2F4", -- DWORD
  c_rotation_speed = "0x2F8",
  c_weight = "0x31C",
  c_slope_rad = "0x320",
  c_slope_rad_b = "0x324",
  c_downforce = "0x328",
  c_interp_gravity = "0x32C",
  c_posture_continue_num = "0x330", -- DWORD
  c_posture_continue_len = "0x334",
  c_rotation_speed_border = "0x338",
  c_posture_inertia_move = "0x33C"
}

local snowboard_posture_values = {
  c_rotation_method = "0x254", -- DWORD
  c_rotation_speed = "0x258",
  c_weight = "0x298",
  c_slope_rad = "0x29C",
  c_slope_rad_b = "0x2A0",
  c_downforce = "0x2A4",
  c_turn_drift = "0x2AC", -- Disabled by default (-1), though any other value will "enable" it. Modifier on c_brake_drift?
  c_turn_curving = "0x2B0", -- Affects strength of c_brake_curving
  c_interp_drift = "0x2B4",
  c_interp_curving = "0x2B8",
  c_interp_gravity = "0x2BC",
  c_posture_continue_num = "0x2C0", -- DWORD
  c_posture_continue_len = "0x2C4",
}

local plugin_values = {
  waterslider = {
    c_distance_binormal = "0x6C", -- How far you can move from the center of the spline
	c_waterslider_lr = "0x70", -- Rate at which you move l/r
  },
  zock = {
    dwords = {
	  c_sliding_damage = "0xB8",
	  c_sliding_power = "0xBC"
	}
  },
  sonic_weapons = {
    c_custom_action_slow_bias = "0xAC",
	c_custom_action_scale = "0xB0",
  },
  venice_weapons = {
    -- 0x2C initial
    c_psychosmash_power = "0x84",
	c_radius = "0x88",
	-- weapons + 0x48 -> GetPointer
	--c_dunk_radius_start = "0x58",
	--c_dunk_radius_end = "0x5C",
	--c_dunk_time = "0x60",
	--c_dunk_time_remain = "0x64",
	
	-- weapons + 0x60 -> GetPointer
	-- c_radius = "0x98",
	-- c_catch_one_begin = "0x9C",
	-- c_catch_one_end = ""0xA0",
	-- c_catch_one_speed = "0xA4"
  },
  homing = {
	c_homing_power = "0xE4",
	c_homing_time = "0xE8",
	dwords = {
	  c_homing_damage = "0xE0",
	}
  }
}

local unique_params = { -- Values exclusive to the particular character
  sonic = {
    c_homing_spd = "0x254",
    c_homing_brake = "0x258",
	c_sliding_time = "0x25c",
	c_spindash_spd = "0x260",
	c_spindash_time = "0x264",
	c_bound_jump_spd_0 = "0x268",
	c_bound_jump_spd_1 = "0x26c",
	c_boundjump_jmp = "0x274",
	c_boundjump_block = "0x279",
	c_attack_brake = "0x27c",
	c_sliding_speed_min = "0x280",
	c_sliding_speed_max = "0x284",
	c_homing_smash_charge = "0x288",
	c_custom_action_slow_time = "0x28c",
    c_custom_action_machspeed_acc = "0x290",
	c_custom_action_machspeed_time = "0x294",
	c_scale_run_speed_max = "0x298",
	c_scale_run_acc = "0x29c",
	c_scale_walk_speed_max = "0x2a0",
	c_scale_jump_speed = "0x2a4",
	c_scale_jump_block = "0x2a8",
  },
  shadow = {
    c_homing_jmp = "0x23C", -- Upward force applied if Homing Attack ends prematurely
    c_homing_spd = "0x240",
	c_homing_time = "0x244",
	c_chaos_spear_accumulate_wait = "0x248", -- Time taken to fully charge the Spear (launching multiple spears with a lockon)
	c_chaos_spear_stiffening_time = "0x24C", -- Time Shadow remains frozen in the air after a Spear
	c_chaos_smash_accumulate_wait = "0x250", -- Charge time
	c_chaos_smash_preliminary = "0x254", -- Acceptance time for Chaos Attack
	c_lightdash_speed = "0x258",
  },
  silver = {
    -- 20 initial offset, need to add
    c_tele_dash_speed = "0x234",
	c_tele_dash_time = "0x238",
	c_tele_dash_brake = "0x23C",
	c_tele_dash_post = "0x240",
	c_float_walk_border = "0x244",
	c_float_walk_speed = "0x248",
	c_tele_dash_input = "0x24C",
	c_float_input = "0x250",
	c_psychosmash_charge_time = "0x254",
	c_dunk_charge_time = "0x258" -- Windup for the AoE ground pound
  },
  tails = {
    c_flight_timer = "0x23c",
	c_flight_timer_b = "0x240",
	c_ignore_spread_time = "0x248", -- Time between air bomb throws
  },
  blaze = {
    c_spinning_claw_min = "0x238",
	c_spinning_claw_max = "0x23c",
  },
  amy = {
    c_stealth_pray = "0x244",
	c_stealth_limit = "0x248",
	c_stealth_countdown = "0x24c",
	c_jump_double_speed = "0x250",
	dwords = {
	  c_jump_double_count = "0x240"
	}
  },
  omega = {
    c_hovering_acc = "0x208"
  },
  rouge = {
    c_blast_timer = "0x23C"
  }
}

local fast_values = { -- offsets used for Mach Speed
  c_run_acc = "0xE8",
  c_walk_speed_max = "0xEC", -- or 0x30
  c_run_speed_max = "0xF0",
  c_brake_acc = "0xF4",
  c_brake_dashpanel = "0xF8",
  c_brake_quick_acc = "0xFC",
  c_jump_walk = "0x100",
  c_jump_run = "0x104",
  c_jump_brake = "0x108",
  c_jump_speed = "0x10C",
  c_homing_speed = "0x11C",
  c_lightdash_speed = "0x120",
}

local snowboard_values = {
  c_min_speed = "0xD4",
  c_max_speed = "0xD8",
  c_acceleration = "0xDC",
  c_brake = "0xE0",
  c_base_jump = "0xE4",
  c_high_jump = "0xE8",
  c_jump_time = "0xEC",
  c_brake_drift = "0xF4",
  c_brake_curving = "0xF8", -- Deceleration when turning the stick left or right
  c_jump_walk = "0xFC",
  c_walk_border = "0x100",
  c_jump_run = "0x104",
  c_grind_speed_org = "0x108",
  c_grind_acc = "0x10C",
  c_grind_speed_max = "0x110",
  c_grind_time = "0x114",
  c_grind_penalty_time = "0x118",
  c_grind_brake_acc = "0x11C",
  c_brake_quick_acc = "0x120",
  c_jump_brake = "0x124",
}

function GetFastLuaValue(param_name, player_id)
  if not fast_values[param_name] then
    DebugPrint("GetFastLuaValue: Invalid param " .. tostring(param_name))
	return
  end
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  local character_context = GetCharacterContext(player_id)
  local hex_val = fast_values[param_name]
  local lua_value = character_context:GetFLOAT(hex_val)
  return lua_value
end

function SetFastLuaValue(param_name, value, player_id)
  if not fast_values[param_name] then
    DebugPrint("SetFastLuaValue: Invalid param " .. tostring(param_name))
	return
  end
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  local character_context = GetCharacterContext(player_id)
  local hex_val = fast_values[param_name]
  character_context:Move(hex_val):SetFLOAT(value)
end

function GetSnowboardLuaValue(param_name, player_id)
  if not snowboard_values[param_name] then
    DebugPrint("GetSnowboardLuaValue: Invalid param " .. tostring(param_name))
	return
  end
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  local character_context = GetCharacterContext(player_id)
  local hex_val = snowboard_values[param_name]
  local lua_value = character_context:GetFLOAT(hex_val)
  return lua_value
end

function SetSnowboardLuaValue(param_name, value, player_id)
  if not snowboard_values[param_name] then
    DebugPrint("SetSnowboardLuaValue: Invalid param " .. tostring(param_name))
	return
  end
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  local character_context = GetCharacterContext(player_id)
  local hex_val = snowboard_values[param_name]
  character_context:Move(hex_val):SetFLOAT(value)
end

function GetPlayerLuaValue(param_name, player_id)
  if not lua_params[param_name] then
    DebugPrint("GetPlayerLuaValue: Invalid param " .. tostring(param_name))
	return
  end
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  local character_context = GetCharacterContext(player_id)
  local hex_val = lua_params[param_name]
  local lua_value = character_context:GetFLOAT(hex_val)
  return lua_value
end

function SetPlayerLuaValue(param_name, value, is_absolute, player_id)
  if not lua_params[param_name] then
    DebugPrint("SetPlayerLuaValue: Invalid param " .. tostring(param_name))
	return
  end
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  is_absolute = is_absolute == nil and true or is_absolute
  local character_context = GetCharacterContext(player_id)
  local hex_val = lua_params[param_name]
  if is_absolute then
    character_context:SetFLOAT(hex_val, value)
  else
    local current_value = GetPlayerLuaValue(param_name, player_id)
	value = value + current_value
	character_context:SetFLOAT(hex_val, value)
  end
end

function GetUniqueLuaValue(param_name, player_id)
  local is_dword = false
  local hex_val = ""
  local player_name = GetPlayerName()
  if not unique_params[player_name] then
    DebugPrint("INVALID CHARACTER NAME FOR PARAMETER! " .. tostring(player_name))
	return
  end
  if not unique_params[player_name][param_name] then
    local dwords = unique_params[player_name].dwords
    if dwords then
	  if dwords[param_name] then
	    is_dword = true
		hex_val = dwords[param_name]
	  end
	end
	if not is_dword then
	  DebugPrint("GetUniqueLuaValue: Invalid param: " .. tostring(param_name) .. " on character: " .. player_name)
	  return
	end
  end
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  local character_context = GetCharacterContext(player_id)
  if hex_val == "" then
    hex_val = unique_params[player_name][param_name]
  end
  local lua_val = 0
  if is_dword then
    lua_val = character_context:GetDWORD(hex_val)
  else
    lua_val = character_context:GetFLOAT(hex_val)
  end
  return lua_val
end

function SetUniqueLuaValue(param_name, value, player_id)
  local is_dword = false
  local hex_val = ""
  local player_name = GetPlayerName()
  if not unique_params[player_name] then
    DebugPrint("INVALID CHARACTER NAME FOR PARAMETER! " .. tostring(player_name))
	return
  end
  if not unique_params[player_name][param_name] then
    local dwords = unique_params[player_name].dwords
    if dwords then
	  if dwords[param_name] then
	    is_dword = true
		hex_val = dwords[param_name]
	  end
	end
	if not is_dword then
	  DebugPrint("GetUniqueLuaValue: Invalid param: " .. tostring(param_name) .. " on character: " .. player_name)
	  return
	end
  end
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  local character_context = GetCharacterContext(player_id)
  if hex_val == "" then
    hex_val = unique_params[player_name][param_name]
  end
  if is_dword then
    character_context:SetDWORD(hex_val, value)
  else
    character_context:SetFLOAT(hex_val, value)
  end
end

function GetPluginValue(plugin, param, player_id)
  player_id = player_id or 0
  if not Player(0):GetIPluginByName(plugin):IsValidPTR() then
    DebugPrint("GetPlayerLuaValue: Invalid plugin " .. tostring(plugin))
	return
  end
  local is_dword = false
  local offset = ""
  if not Player(player_id):IsValidPTR() then
    return
  end
  if not plugin_values[plugin] then
    DebugPrint("GetPluginValue: Invalid plug " .. tostring(plugin))
	return
  elseif not plugin_values[plugin][param] then
    local dwords = plugin_values[plugin].dwords
	if dwords then
	  if dwords[param] then
	    is_dword = true
		offset = dwords[param]
	  end
	end
	if not is_dword then
      DebugPrint("GetPluginValue: Invalid param " .. tostring(param) .. " on plugin " .. plugin)
	  return
	end
  end
  local obj_player = Player(player_id)
  offset = offset == "" and plugin_values[plugin][param] or offset
  local lua_val = 0
  if is_dword then
    lua_val = obj_player:GetIPluginByName(plugin):Move(offset):GetDWORD()
  else
    lua_val = obj_player:GetIPluginByName(plugin):Move(offset):GetFLOAT()
  end
  return lua_val
end

function SetPluginValue(plugin, param, value, player_id)
  player_id = player_id or 0
  if not Player(0):GetIPluginByName(plugin):IsValidPTR() then
    DebugPrint("SetPlayerLuaValue: Invalid plugin " .. tostring(plugin))
	return
  end
  local is_dword = false
  local offset = ""
  if not Player(player_id):IsValidPTR() then
    return
  end
  if not plugin_values[plugin] then
    DebugPrint("SetPluginValue: Invalid plug " .. tostring(plugin))
	return
  elseif not plugin_values[plugin][param] then
    local dwords = plugin_values[plugin].dwords
	if dwords then
	  if dwords[param] then
	    is_dword = true
		offset = dwords[param]
	  end
	end
	if not is_dword then
      DebugPrint("SetPluginValue: Invalid param " .. tostring(param) .. " on plugin " .. plugin)
	  return
	end
  end
  local obj_player = Player(player_id)
  offset = offset == "" and plugin_values[plugin][param] or offset
  if obj_player:GetIPluginByName("sonic_weapons"):IsValidPTR() then
    if param == "c_sliding_damage" then
      obj_player:GetIPluginByName("sonic_weapons"):Move("0x58"):GetPointer():Move("0xE4"):SetDWORD(value)
	elseif param == "c_sliding_power" then
	  obj_player:GetIPluginByName("sonic_weapons"):Move("0x58"):GetPointer():Move("0xE8"):SetFLOAT(value)
    end
  end
  if is_dword then
	obj_player:GetIPluginByName(plugin):Move(offset):SetDWORD(value)
  else
    obj_player:GetIPluginByName(plugin):Move(offset):SetFLOAT(value)
  end
end

function GetRotationSpeed(player_id) -- Checks the c_rotation_speed param.
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  local c_rotation_speed = Player(player_id):GetPointer("0xDC"):GetFLOAT("0x2F8")
  return c_rotation_speed
end

function SetRotationSpeed(value, player_id) -- Sets the c_rotation_speed param. Lower values cause a bigger turning arc at high speed.
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  Player(player_id):GetPointer("0xDC"):SetFLOAT("0x2F8", value)
end


function GetPostureLuaValue(param, is_snowboard, player_id)
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  local posture_start = Player(player_id):GetPointer("0xDC") -- Not sure what this technically is
  local offset = not is_snowboard and posture_values[param] or snowboard_posture_values[param]
  if offset ~= nil then
    local value = 0
	if param == "c_posture_continue_num" or param == "c_rotation_method" then
	  value = posture_start:Move(offset):GetDWORD()
	else
	  value = posture_start:Move(offset):GetFLOAT()
	end
    return value
  else
    DebugPrint("GetPostureLuaValue: Invalid param " .. tostring(param))
	return
  end
end

function SetPostureLuaValue(param, value, is_snowboard, player_id)
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  local posture_start = Player(player_id):GetPointer("0xDC") -- Not sure what this technically is
  local offset = not is_snowboard and posture_values[param] or snowboard_posture_values[param]
  if offset ~= nil then
	if param == "c_posture_continue_num" or param == "c_rotation_method" then
	  posture_start:Move(offset):SetDWORD(value)
	else
	  posture_start:Move(offset):SetFLOAT(value)
	end
  else
    DebugPrint("SetPostureLuaValue: Invalid param " .. tostring(param))
	return
  end
end

function GetRotationSpeedBorder(player_id) -- Checks the (unused) c_rotation_speed_border param.
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  local spd_border = Player(player_id):GetPointer("0xDC"):GetFLOAT("0x338")
  return spd_border
end

function SetRotationSpeedBorder(value, player_id) -- Sets c_rotation_speed_border. Higher values allow easier turning at high speed.
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  Player(player_id):GetPointer("0xDC"):SetFLOAT("0x338", value)
end

function GetDownforce(player_id)
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  local c_downforce = Player(player_id):GetPointer("0xDC"):GetFLOAT("0x328")
  return c_downforce
end

function SetDownforce(value, is_absolute, player_id)
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  is_absolute = is_absolute == nil and true or is_absolute
  local downforce = GetDownforce(player_id)
  value = is_absolute and value or (value + downforce)
  Player(player_id):GetPointer("0xDC"):SetFLOAT("0x328", value)
end