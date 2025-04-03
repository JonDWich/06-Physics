-- @BRIEF: Functions for getting/setting animations and related behavior.
-- ChangePlayerAnim(): Change the player's current animation to the provided cue.
-- GetPlayerAnim(): Returns the current animation cue.
-- Get/SetCurrentAnimationTime(): Check the current frame of the player's animation, or jump to a provided frame.

-- TODO: Some of these functions are redundant, simplify before release.

local mach_speed_to_hex_enum = { -- May not be accurate
  RunFast = "0x0",
  DushFast = "0x1",
  FallFast = "0x2",
  JumpFast = "0x3",
  JumpupFast = "0x4",
  FastStart = "0x5",
  DamageFast = "0x6",
  DramaticJumpSFast = "0x7",
  DramaticJumpLFast = "0x8",
  DramaticJumpEFast = "0x9",
  DramaticLandingFast = "0xA",
  HomingFast = "0xB",
  LightdashFast = "0xC",
  ChainjumpSFast = "0xD",
  ChainjumpLFast = "0xE",
  ChainjumpLandindFast = "0xF", -- sic
  SpringFast = "0x10",
  GoalFast = "0x11",
  GoalLFast = "0x12",
  DefaultFast = "0x13"
}

local board_to_hex = {
  run = "0x0",
  turn_l = "0x1",
  turn_r = "0x2",
  prejump = "0x3",
  fall = "0x4",
  jump = "0x5",
  hi_fall = "0x6",
  hi_jump = "0x7",
  grind_l = "0x8",
  grindturn_l = "0x9",
  damage1 = "0xA",
  damage1_alt = "0xB", -- Death
  against = "0xC",
  landing = "0xD"
  
}

local anim_to_hex = {
  test_anim = "0x6F",
  wait = "0x0",
  wait2 = "0x1",
  wait3 = "0x2",
  wait4 = "0x3",
  walk = "0x4",
  run = "0x5",
  dush = "0x6",
  down = "0x7",
  down_l = "0x8",
  down_fall = "0x9",
  stop = "0xA",
  water_slide = "0x1F",
  quickturn = "0xB",
  fall = "0xC",
  jumpup = "0xD",
  jump = "0xE",
  damage1 = "0xF",
  damage2 = "0x10",
  damage3 = "0x11",
  damage_light_s = "0x12",
  damage_light_l = "0x13",
  damage_light_e = "0x14",
  standup = "0x15",
  grind_l = "0x17",
  grindturn_l = "0x18",
  jumpup_alt = "0x19",
  sliding = "0x4F",
  sliding_stand = "0x50",
  jump_alt = "0x51",
  spindash = "0x52", -- Reuses the "jump" cue
  bounce = "0x53", --Reuses the "jump" cue
  homing = "0x46",
  homing_t1 = "0x47",
  homing_after = "0x48",
  homing_after1 = "0x49",
  homing_after2 = "0x4A",
  spring = "0x4B",
  wide_spring = "0x4C", -- Reuses the "spring" cue
  landing = "0x55",
  goal = "0x4D",
  goal_l = "0x4E",
  edge_hang = "0x1A",
  edge_jump = "0x1B",
  ottotto = "0x56",
  attack = "0x45",
  updownreel = "0x57",
  tarzan_l = "0x58",
  tarzan_f_l = "0x59",
  tarzan_f2b_l = "0x5A",
  tarzan_b_l = "0x5B",
  tarzan_b2f_l = "0x5C",
  bungee_d_l = "0x5D",
  bungee_d2u = "0x5E",
  bungee_u = "0x5F",
  bungee_fly = "0x60",
  poll_s = "0x61",
  poll_l = "0x62",
  poll_e = "0x63",
  wind = "0x54",
  lightdash = "0x64",
  chainjump_s = "0x65",
  chainjump_l = "0x66",
  chainjump_landing = "0x67",
  overdrive = "0x95",
  overdrive_l = "0x96",
  chaos_spear_s = "0x97",
  chaos_spear_l = "0x98",
  chaos_spear_wait_s = "0x99",
  chaos_spear_wait_l = "0x9A",
  chaos_blast_s = "0x9B",
  chaos_blast_wait_l = "0x9C",
  chaos_blast_attack_s = "0x9D",
  chaos_blast_attack_l = "0x9E",
  chaos_wait = "0x9F",
  chaos_snap_0 = "0xA0",
  chaos_snap_0_alt = "0xA1",
  chaos_snap_1 = "0xA2",
  chaos_snap_2 = "0xA3",
  chaos_snap_3 = "0xA4",
  chaos_snap_4 = "0xA5",
  esp_w_up = "0x25",
  esp_w = "0x26",
  esp_w_to_charge = "0x27",
  esp_w_charge = "0x28",
  esp_w_attack = "0x29",
  esp_hold_s = "0x2A",
  esp_hold_l = "0x2B",
  esp_one_l_charge = "0x2C",
  esp_one_l = "0x2D",
  esp_one_r_charge = "0x2F",
  esp_one_r = "0x2E",
  esp_one_a = "0x30",
  esp_one_j_l_charge = "0x31",
  esp_one_j_l = "0x32",
  esp_one_j_r_charge = "0x33",
  esp_one_j_r = "0x34",
  esp_one_j_a = "0x35",
  esp_r_atk1 = "0x3E",
  esp_r_atk2 = "0x3F",
  esp_r_atk2a = "0x40",
  esp_r_atk3_1 = "0x41",
  esp_r_atk3_1a = "0x42",
  esp_r_atk3_2 = "0x43",
  esp_r_atk3_2a = "0x44",
  quake_s = "0x36",
  quake_s_t1 = "0x37",
  quake_s_t2 = "0x38",
  quake_s_t3 = "0x36",
  quake_s_t4 = "0x39",
  quake_s_j = "0x3A",
  quake_l = "0x3B",
  quake_e = "0x3C",
  quake_roll = "0x3D",
  teleport_dash_s = "0x20",
  teleport_dash_l = "0x21",
  teleport_dash_e = "0x22",
  homing_t2 = "0x70", -- vehicle entry
  jeep_ride = "0x71",
  jeep_ride_r = "0x72",
  jeep_ride_l = "0x73",
  jeep_damage = "0x75",
  jeep_damage_light = "0x74",
  jeep_back_s = "0x76",
  jeep_back_l = "0x77",
  bike_ride = "0x78",
  bike_ride_r = "0x79",
  bike_ride_l = "0x7A",
  bike_damage = "0x7C",
  bike_damage_light = "0x7B",
  bike_jump_up = "0x7D",
  bike_jump_down = "0x7E",
  bike_dash = "0x7F",
  bike_back_s = "0x80",
  bike_back_l = "0x81",
  bike_wily = "0x82",
  bike_brake = "0x83",
  hover_ride = "0x84",
  hover_ride_r = "0x85",
  hover_ride_l = "0x86",
  hover_damage = "0x88",
  hover_damage_light = "0x87",
  hover_back_s = "0x89",
  hover_back_l = "0x8A",
  hover_brake = "0x8B",
  hover_jump = "0x8C",
  glider_ride = "0x8D",
  glider_ride_r = "0x8E",
  glider_ride_l = "0x8F",
  glider_ride_u = "0x90",
  glider_ride_d = "0x91",
  glider_damage = "0x93",
  glider_damage_light = "0x92",
  glider_boost = "0x94",
  float_wait = "0x23",
  float_walk = "0x24",
  rainbow_ring_s = "0x1C",
  rainbow_ring_l = "0x1D",
  rainbow_ring_e = "0x1E",
  fly = "0xA9",
  fly_tired = "0xAA",
  bomb_throw = "0xAB",
  bomb_search_s = "0xAC",
  bomb_search_l = "0xAD",
  bomb_search_e = "0xAE",
  pray = "0xAF",
  stealth_end = "0xB0",
  jump_double_0 = "0xB1",
  jump_double_1 = "0xB2",
  accel_tornado = "0xB3",
  spinning_claw_l = "0xB4",
  spinning_claw_e = "0xB5",
  glide_s = "0xB6",
  glide_l = "0xB7",
  glide_e = "0xB8",
  heat_knuckle_0 = "0xB9",
  heat_knuckle_1 = "0xBA",
  heat_knuckle_2 = "0xBB",
  screw_charge_s = "0xBE",
  screw_charge_l = "0xBF",
  screw_l = "0xC0",
  screw_e = "0xC1",
  screw_after = "0xC2",
  screw_l_alt = "0xBC",
  screw_e_alt = "0xBD",
  jumpbomb = "0xC3",
  jumpbomb_spread_l = "0xC4",
  jumpbomb_spread_e = "0xC5",
  heart_mine = "0xC6",
  climb_wait = "0xC7",
  climb_walk = "0xC8",
  spinattack_s = "0xA6",
  spinattack_l = "0xA7",
  spinattack_e = "0xA8",
  rodeo = "0xC9",
  amigo_s = "0x68",
  amigo_l = "0x69",
  select_s = "0x6A",
  select_l = "0x6B",
  fall_t1 = "0xCA", -- Omega's hover
  tornado_s = "0xCB",
  tornado_ground = "0xCC",
  tornado_air = "0xCD",
  super = "0xCE",
  piyori_l = "0x6C",
  piyori_e = "0x6D",
  hold = "0x6E",
  hold_alt = "0x6F",
  wait_alt = "0xCF",
  super_fly_up = "0xD0",
  super_fly_down = "0xD1",
  super_fly_left = "0xD2",
  super_fly_right = "0xD3",
  lightattack_l = "0xD4",
  lightattack_l_alt = "0xD5",
  store = "0xD6",
  store_l = "0xD7",
  chaos_attack = "0xD8",
  chaos_attack_alt = "0xD9",
  chaos_attack_l = "0xDA",
  psycho_field = "0xDB",
  psycho_field_l = "0xDC",
  smash3 = "0xDD",
  smash3_l = "0xDE",
  launcher_r = "0xDF",
  launcher_l = "0xE0",
  lock_on_l = "0xE1",
  lock_on_air_l = "0xE2"
}

function ChangePlayerAnim(anim_str, player_id) -- Puts the player in the provided animation
  local hex_val = anim_to_hex[anim_str]
  if not hex_val then
    DebugPrint("ChangePlayerAnim: Invalid anim_str: " .. anim_str)
	return
  end
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    DebugPrint("ChangePlayerAnim: Invalid ptr, returning...")
    return
  end
  local anim_state_ptr = GetPlayerMemoryValue("add", HEX("0x70"), player_id)
  local anim_ID_ptr = GetPlayerMemoryValue("add", HEX("0x40"), player_id)
  SetPlayerMemoryValue("dword", anim_state_ptr, -2, player_id)
  SetPlayerMemoryValue("dword", anim_ID_ptr, HEX(hex_val), player_id)
end

function GetPlayerAnim(by_name, player_id) -- Returns the hex ID (converted to decimal) of the current animation
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    DebugPrint("GetPlayerAnim: Invalid ptr, returning...")
    return
  end
  by_name = by_name or false
  local anim_ID_ptr = GetPlayerMemoryValue("add", HEX("0x40"), player_id)
  local anim = tostring((memory.GetDWORD(anim_ID_ptr)))
  local anim_hex_id = ""
  anim = tonumber(anim)
  for tbl_anim, hex in pairs(anim_to_hex) do
	if anim == HEX(hex) then
	  if by_name then
	    anim = tbl_anim
	  end
	  anim_hex_id = hex
	  break
	end
  end
  return anim, anim_hex_id
end

function GetAnimValue(anim_str) -- Returns the hex ID (converted to decimal) of a given animation
  if not anim_to_hex[anim_str] then
    DebugPrint("GetAnimID: Invalid anim_str: " .. anim_str)
	return
  end
  local decimal_anim_value = HEX(anim_to_hex[anim_str])
  return decimal_anim_value
end

function GetCurrentAnimation(anim_str, by_hex, player_id) -- Compares the player's current animation against a provided one, returns True/False
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    DebugPrint("GetCurrentAnimation: Invalid ptr, returning...")
    return
  end
  by_hex = by_hex or false
  local anim_ID_ptr = GetPlayerMemoryValue("add", HEX("0x40"), player_id)
  local anim = tonumber(tostring((memory.GetDWORD(anim_ID_ptr)))) --Get the (decimal) value of the current animation
  local check_id = by_hex and HEX(anim_str) or GetAnimValue(anim_str)
  return anim == check_id
end

function GetCurrentAnimationTime(player_id)
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    DebugPrint("GetCurrentAnimationTime: Invalid ptr, returning...")
    return
  end
  local hierarchy = GetAnimationHierarchy(player_id)
  local anim_time = hierarchy:Move("0x18"):GetFLOAT()
  return anim_time
end

function SetCurrentAnimationTime(frame, player_id)
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    DebugPrint("SetCurrentAnimationTime: Invalid ptr, returning...")
    return
  end
  local hierarchy = GetAnimationHierarchy(player_id)
  hierarchy:Move("0x18"):SetFLOAT(frame)
end