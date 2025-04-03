-- @BRIEF: A slew of helpful player related functions.
-- TODO: 
-- Group these under tables?
-- Split into different scripts?
-- It's a lot of information, and it's not well formatted. Some functions are now redundant, as well.
-- Fix the structure before release.


-- Specifically for converting X/Y/Z from lowercase to uppercase. Can't use argument_correction since
-- the functions that use that specifically need lowercase for X and Y
-- UPDATE: String library is now available, update this later.
local to_upper = {x = "X", y = "Y", z = "Z"}
function TestGetPos()
  return player.GetPlayerPosition(0)
end
function GetPlayerPos(coordinate, player_id)
  player_id = player_id or 0
  coordinate = coordinate or "ALL" -- If no coordinate is provided, return the entire position table.
  local playerPos = player.GetPlayerPosition(player_id)
  if type(coordinate) == "string" then
    coordinate = string.upper(coordinate) -- Convert to uppercase
	if coordinate == "ALL" then
	  return playerPos -- Returns all 3 coordinates.
	else
	  return playerPos[coordinate] -- Returns the specific coordinate.
	end
  elseif type(coordinate) == "table" then
    local return_coords = {}
	for _, coord in pairs(coordinate) do
	  coord = string.upper(coord) -- Indexed as X/Y/Z, so convert to uppercase if it's currently lowercase.
	  return_coords[coord] = playerPos[coord] -- Create X/Y/Z as an index, provide the corresponding coordinate.
	end
	return return_coords -- Return a new table, containing only the requested coordinate values.
  end
end

function SetPlayerPos(x, y, z, is_world, player_id)
  player_id = player_id or 0
  is_world = is_world or false
  if not is_world then
    local pos = GetPlayerPos("ALL", player_id)
	x, y, z = x + pos.X, y + pos.Y, z + pos.Z
  end
  if not (x > 2 or x < 2) or not (y > 2 or y < 2) or not (z > 2 or z < 2) then
    player.print("ABORT!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("X: " .. tostring(x) .. " Y: " .. tostring(y) .. " Z: " .. tostring(z))
	return
  end
  player.SetPlayerPosition(player_id, x, y, z)
end

-- This new approach works for Mach Speed as well
function IsGrounded(player_id)
  player_id = player_id or 0
  local GroundAirFlag = GetGravityModule(player_id):Move("0x24"):GetDWORD() --GetPlayerMemoryValue("dword", 196, player_id) --196
  local is_grounded = bit.AND(GroundAirFlag,1) ~= 0
  return is_grounded
end

function GetGroundAirFlags(player_id)
  player_id = player_id or 0
  return GetGravityModule(player_id):Move("0x24"):GetDWORD() --GetPlayerMemoryValue("dword", 196, player_id)
end

--local ground_normal = DebugLabel("", 500, 300)
function IsOnGuide(player_id)
  player_id = player_id or 0
  return Player(player_id):GetIPluginByName("path_gd"):Move("0x44"):GetPointer() ~= Memory(0)
  --local posture = GetPlayerPosture(player_id)
  --[[local context = GetCharacterContext(player_id)
  --player.print(Memory(context.ptr):Move("0xC4"):GetPointer().ptr)
  player.print(Memory(context.ptr):Move("0xC4"):GetPointer():AND("0x00400000").ptr)
  if Memory(context.ptr):Move("0xC4"):GetPointer():AND("0x00400000") == Memory("0x00400000") then
    DebugPrint("Yep")
    return true
  else
    DebugPrint("Nope")
    return false
  end]]
end

function GetGroundNormal(player_id)
  player_id = player_id or 0
  local posture = GetPlayerPosture(player_id)
  local x, y, z = Memory(posture):GetFLOAT("0x3B0"), Memory(posture):GetFLOAT("0x3B4"), Memory(posture):GetFLOAT("0x3B8")
  local normal_vector = {x, y, z}
  return normal_vector
end

function GetGroundNormalSnowboard(player_id)
  player_id = player_id or 0
  local posture = GetPlayerPosture(player_id)
  local x, y, z = Memory(posture):GetFLOAT("0x30C"), Memory(posture):GetFLOAT("0x304"), Memory(posture):GetFLOAT("0x308")
  local normal_vector = {x, y, z}
  return normal_vector
end

function PlayerSwap(character, player_id)
  player_id = player_id or 0
  local plr = GetPlayerData(player_id)
  if plr:IsValidPTR() then
    plr:Reload()
    plr:SWAP(character)
	plr:Reload()
  else
    DebugPrint("PlayerSwap: Invalid player pointer...")
	return
  end
end

function GetPlayerName(player_id)
  player_id = player_id or 0
  local plr = GetPlayerData(player_id)
  if plr then
    plr:Reload()
	local name = plr:GetName()
	--DebugPrint("Got name: " .. name)
	return name
  else
    DebugPrint("Failed to get player name")
  end
end

function GetPlayerState(player_id)
  player_id = player_id or 0
  local plr = GetPlayerData(player_id)
  return plr:GetStateID()
end

function SetPlayerState(state_id, player_id)
  player_id = player_id or 0
  local plr = GetPlayerData(player_id)
  return plr:SetStateID(state_id)
end


-- Returns floats between -1 and +1, based on the player's rotation relative to +X and +Z.
local has_label = false
function GetPlayerRotation(player_id)
  player_id = player_id or 0
  local root_frame = GetPlayerRootFrame(player_id)
  if not root_frame then
    DebugPrint("GetPlayerRotation: Invalid root frame...")
	return
  end
  local x_and_z = root_frame:Move("0x90")
  local x_rot = x_and_z:Move("0x0"):GetFLOAT()
  local z_rot = x_and_z:Move("0x8"):GetFLOAT()
  return x_rot, z_rot
end

-- Testing for SurfaceRotation
function SurfaceGetPlayerRotation()
  if not has_label then
    --Label = DebugLabel("", 25, 300)
	has_label = true
  end
  local root = GetPlayerRootFrame(0)
  local RotationArray = root:Move("0x80")
  local X, Y, Z = RotationArray:Move("0x0"):GetFLOAT(), RotationArray:Move("0x4"):GetFLOAT(), RotationArray:Move("0x8"):GetFLOAT()
  --print(string.format("X: %.2f  Y: %.2f  Z: %.2f", X, Y, Z))
  X = math.floor(X * 1000)/1000
  Y = math.floor(Y * 1000)/1000
  Z = math.floor(Z * 1000)/1000
  return X,Y,Z
  --Label:SetText(tostring(Vector(X,Y,Z,W)) .. "\n")
end

function GetModelRotation(player_id)
  player_id = player_id or 0
  return Player(player_id):Move("0xDC"):GetPointer():Move("0xC0"):GetVector()
end

function SetModelRotation(quat_rotation, is_absolute, player_id)
  player_id = player_id or 0
  if type(quat_rotation) == "number" then -- You'll *probably* want to rotate on Y, generally
    local y_rot = quat.yrot(quat_rotation)
	quat_rotation = y_rot
  end
  if not is_absolute then
    local current_dir = GetModelRotation(player_id)
	local relative_turn = QuatMultiply(quat_rotation, current_dir)
	quat_rotation = relative_turn
  end
  Player(player_id):Move("0xDC"):GetPointer():Move("0xC0"):SetVector(quat_rotation)
  --Player(0):Move("0xDC"):GetPointer():Move("0xC4"):SetVector(q_Y) -- Scales along the X and Y axis, can only shrink/compress
  --Player(0):Move("0xDC"):GetPointer():Move("0xC8"):SetVector({0.0, 0.99, 0.0, 0.0}) -- Weird scale/rotation along the -X axis?
end

function GetPlayerSpeed(direction, is_gimmick, is_prev_spd, player_id) -- Rewrite. Use separate functions for each speed type.
  player_id = player_id or 0
  if direction == "total" then
    local base = GetPlayerMemoryValue("float", 48, player_id)
	local gimmick = GetPlayerMemoryValue("float", 52, player_id)
	local total_x = base + gimmick
	base = GetPlayerMemoryValue("float", 56, player_id)
	gimmick = GetPlayerMemoryValue("float", 60, player_id)
	local total_y = base + gimmick
	return total_x, total_y
  end
  is_gimmick = is_gimmick or false
  is_prev_spd = is_gimmick and (is_prev_spd or false) or false -- Only allow checking previous speed if you're checking gimmick speed.
  local speed = 0
  if direction == "horizontal" or direction == "x" or direction == "forward" then 
    if not is_prev_spd then
      speed = is_gimmick and GetPlayerMemoryValue("float", 52, player_id) or GetPlayerMemoryValue("float", 48, player_id) -- FWC/FW
	else
	  speed = GetPlayerMemoryValue("float", 72, player_id)
	end
  elseif direction == "vertical" or direction == "y" or direction == "up" then 
    if not is_prev_spd then
      speed = is_gimmick and GetPlayerMemoryValue("float", 60, player_id) or GetPlayerMemoryValue("float", 56, player_id) -- UP/UPC
	else
	  speed = GetPlayerMemoryValue("float", 76, player_id)
	end
  end
  --DebugPrint(direction .. " speed: " .. speed)
  return speed
end

function SetPlayerOffGround(enable, player_id)
  player_id = player_id or 0
  local context = GetCharacterContext()
  enable = enable == nil and 1 or enable
  if type(enable) == "boolean" then
    enable = enable == true and 1 or 0
  end
  context:Move("0xE9"):SetBYTE(enable)
end

function SetPlayerSpeed(direction, value, is_gimmick, player_id) -- "up" and "z" work at the moment, not sure about the others.
  player_id = player_id or 0
  is_gimmick = is_gimmick or false
  direction = string.lower(direction)
  local ptr = 0
  if direction == "x" or direction == "forward" then
    ptr = is_gimmick and GetPlayerMemoryValue("add", 52, player_id) or GetPlayerMemoryValue("add", 48, player_id)
  elseif direction == "y" or direction == "up" then
    local yHandle = GetPlayerMemoryValue("add", 223, player_id)
	ptr = is_gimmick and GetPlayerMemoryValue("add", 60, player_id) or GetPlayerMemoryValue("add", 56, player_id)
	SetPlayerMemoryValue("byte", yHandle, 1, player_id) -- Honestly not sure what this does, but Rei used it.
  --elseif direction == "z" or direction == "forward" then
    --
  end
  SetPlayerMemoryValue("float", ptr, value, player_id)
end

function SetPreviousSpeed(direction, value, player_id)
  player_id = player_id or 0
  local ptr = 0
  if direction == "x" or direction == "forward" then
    ptr = GetPlayerMemoryValue("add", 72, player_id)
  elseif direction == "y" or direction == "up" then
    local yHandle = GetPlayerMemoryValue("add", 223, player_id)
    ptr = GetPlayerMemoryValue("add", 76, player_id)
	SetPlayerMemoryValue("byte", yHandle, 1, player_id)
  else
    return
  end
  SetPlayerMemoryValue("float", ptr, value, player_id)
end

function GetRingCount(player_id)
  player_id = player_id or 0
  local score_plugin = GetPlayerMemoryValue("pointer", HEX("0x128"), player_id)
  local ring_count_ptr = memory.ADD(score_plugin, HEX("0x28"))
  local ring_num = memory.GetDWORD(ring_count_ptr)
  return ring_num, ring_count_ptr
end

function SetRingCount(ring_num, is_absolute, player_id)
  player_id = player_id or 0
  is_absolute = is_absolute or false -- If true, forcibly sets to the number provided. Else, adds on top of the current value.
  local current_rings, ring_ptr = GetRingCount(player_id)
  if is_absolute then
    SetPlayerMemoryValue("dword", ring_ptr, -ring_num) -- Might need to be -current_rings? This does work atm, though
	current_rings = GetRingCount(player_id)
  end
  if current_rings + ring_num < 0 then
    DebugPrint("SetRingCount: INVALID RINGS. FINAL VALUE MUST BE POSITIVE!!!")
	return
  end
  SetPlayerMemoryValue("dword", ring_ptr, ring_num)
end

function GetPlayerScore()
  local game_imp = GetGameImpulse()
  local score_val = game_imp:Move("0xE50"):GetDWORD()
  return score_val
end

function SetPlayerScore(score_num, is_absolute)
  is_absolute = is_absolute or false
  local game_imp = GetGameImpulse()
  score_num = is_absolute and score_num or (score_num + GetPlayerScore())
  game_imp:Move("0xE50"):SetDWORD(score_num)
end

function GetTestValues(test)
  local game_imp = GetGameImpulse()
  local unk20 = game_imp:Move("0xE40"):Move("0x20"):GetFLOAT() -- Consistent between death/restart? Previous section time?
  local unk30 = game_imp:Move("0xE40"):Move("0x30"):GetFLOAT() -- Reset between death/restart?
  local unk34 = game_imp:Move("0xE40"):Move("0x34"):GetDWORD()
  local unk3C = game_imp:Move("0xE40"):Move("0x3C"):GetFLOAT() -- Reset between death/restart?
  local lives = game_imp:Move("0xE40"):Move("0xC"):GetDWORD() -- Life count?
  if test then
    game_imp:Move("0xE40"):Move("0x20"):SetDWORD(7)
	game_imp:Move("0xE40"):Move("0x30"):SetDWORD(8)
	game_imp:Move("0xE40"):Move("0x34"):SetDWORD(5)
	game_imp:Move("0xE40"):Move("0x3C"):SetDWORD(9)
  end
  return {unk_20 = unk20, unk_30 = unk30, unk_34 = unk34, unk_3C = unk3C, life_count = lives}
end

function GetMaturityLevel()
  local game_imp = GetGameImpulse()
  return game_imp:Move("0xE40"):Move("0x28"):GetDWORD()
end
function SetMaturityLevel(val)
  local game_imp = GetGameImpulse()
  game_imp:Move("0xE40"):Move("0x28"):SetDWORD(val)
end

function GetMaturity()
  local game_imp = GetGameImpulse()
  return game_imp:Move("0xE40"):Move("0x2C"):GetFLOAT()
end
function SetMaturity(val)
  local game_imp = GetGameImpulse()
  game_imp:Move("0xE40"):Move("0x2C"):SetFLOAT(val)
end

function GetLives()
  local game_imp = GetGameImpulse()
  return game_imp:Move("0xE40"):Move("0xC"):GetDWORD()
end
function SetLives(val)
  local game_imp = GetGameImpulse()
  game_imp:Move("0xE40"):Move("0xC"):SetDWORD(val)
end

local gem_id_list = {
  [0] = "none", 
  [1] = "green", 
  [2] = "red", 
  [3] = "blue",
  [4] = "white",
  [5] = "sky",
  [6] = "yellow",
  [7] = "purple",
  [8] = "super"
}
local gem_order_list = {
  none = 0,
  blue = 1,
  red = 2,
  green = 3,
  purple = 4,
  sky = 5,
  white = 6,
  yellow = 7,
  super = 8
}
function GetHUDGem()
  local game_imp = GetGameImpulse()
  local gem_int = game_imp:Move("0xE40"):Move("0x38"):GetDWORD()
  return gem_id_list[gem_int]
end

function SetHUDGem(val) -- ONLY AFFECTS THE UI AT THE MOMENT
  local game_imp = GetGameImpulse()
  if type(val) == "string" then
    for idx, name in ipairs(gem_id_list) do
	  if name == val then
	    val = idx
		break
	  end
	end
  end
  game_imp:Move("0xE40"):Move("0x38"):SetDWORD(val)
end

function GetCurrentGem(player_id)
  player_id = player_id or 0
  local context = GetCharacterContext(player_id)
  return context:Move("0x250"):GetDWORD()
end

function SetCurrentGem(val, ignore_hud, player_id)
  player_id = player_id or 0
  local context = GetCharacterContext(player_id)
  local gem_id = gem_order_list[val]
  context:Move("0x250"):SetDWORD(gem_id)
  if not ignore_hud then
    SetHUDGem(val)
  end
end

function GetCurrentGaugeValue()
  local game_imp = GetGameImpulse()
  return game_imp:Move("0xE40"):Move("0x24"):GetFLOAT()
end

function SetCurrentGaugeValue(val) -- ONLY AFFECTS UI AT THE MOMENT??
  local game_imp = GetGameImpulse()
  game_imp:Move("0xE40"):Move("0x24"):SetFLOAT(val)
end

local value_to_offset = {
  sonic = {
    initial_offset = nil,
    c_gauge_value = "0x28", -- Current number of points
	c_gauge_max = "0x38", -- Maximum number of points
	c_green = "0x3C", -- Gauge consumption amount when using the Green Gem
	c_red = "0x40",
	c_blue = "0x44",
	c_white = "0x48",
	c_sky = "0x4C",
	c_yellow = "0x50",
	c_purple = "0x54",
	c_super = "0x58",
	c_gauge_heal = "0x5C", -- Number of points restored per second
	c_gauge_heal_delay = "0x60", -- Delay after using a gem (and while in a valid condition) before beginning the heal
	dwords = {}
  },
  shadow = {
    initial_offset = "0x20", -- Perform before trying to get values
	c_gauge_value = "0xC",
    c_gauge_max = "0x14",
	c_gauge_bias = "0x18",
	c_gauge_heal_wait = "0x1C",
	dwords = {
	  c_level = "0x8",
	  c_level_max = "0x20"
	}
  },
  silver = {
    initial_offset = "0x20",
	c_gauge_value = "0x8",
	c_gauge_max = "0xC",
	gauge_valid_time = "0x10", -- Float, increments while the gauge can be replenished. Resets to 0 if it cannot be
	c_psi_gauge_catch_one = "0x1C",
	c_psi_gauge_catch_all = "0x20",
	c_psi_gauge_catch_ride = "0x24",
	c_psi_gauge_catch_smash = "0x28",
	c_psi_gauge_teleport_dash = "0x2C",
	c_psi_gauge_float = "0x30",
	c_psi_gauge_action = "0x34",
	c_psi_gauge_upheave = "0x38",
	c_psi_gauge_burst = "0x3C",
	c_psi_gauge_heal = "0x40",
	c_psi_gauge_water = "0x44",
	c_psi_gauge_heal_delay = "0x48",
	dword = {
	  is_gauge_blocked = "0x14", -- 0 when the gauge can refill, 1 when it can't
	  is_gauge_blocked_air = "0x18", -- Same as above but also returns 1 while airborne
	}
  }
}

function GetGaugeParameter(parameter, player_id)
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  local player_name = GetPlayerName()
  local is_dword = false
  if not value_to_offset[player_name] then
    DebugPrint("GetGaugeParameter: Invalid player name for index: " .. tostring(player_name))
	return
  end
  local gauge = GetCharacterGauge(player_id)
  local initial_offset = value_to_offset[player_name].initial_offset
  local offset = value_to_offset[player_name][parameter] or -1
  if offset == -1 then
    offset = value_to_offset[player_name].dwords[parameter]
	is_dword = true
  end
  if not offset then
    DebugPrint("GetGaugeParameter: Invalid parameter: " .. tostring(parameter))
	return
  end
  if initial_offset then
    gauge = gauge:Move(initial_offset)
  end
  if not is_dword then
    return gauge:Move(offset):GetFLOAT()
  else
    return gauge:Move(offset):GetDWORD()
  end
end

function SetGaugeParameter(parameter, value, player_id)
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  local player_name = GetPlayerName()
  local is_dword = false
  if not value_to_offset[player_name] then
    DebugPrint("SetGaugeParameter: Invalid player name for index: " .. tostring(player_name))
	return
  end
  local gauge = GetCharacterGauge(player_id)
  local offset = value_to_offset[player_name][parameter] or -1
  local initial_offset = value_to_offset[player_name].initial_offset
  if offset == -1 then
    offset = value_to_offset[player_name].dwords[parameter]
	is_dword = true
  end
  if not offset then
    DebugPrint("SetGaugeParameter: Invalid paramter: " .. tostring(parameter))
	return
  end
  if initial_offset then
    gauge = gauge:Move(initial_offset)
  end
  if not is_dword then
    gauge:Move(offset):SetFLOAT(value)
  else
    gauge:Move(offset):SetDWORD(value)
  end
end

function SetHUDTime(val)
  local game_imp = GetGameImpulse()
  game_imp:Move("0xE40"):Move("0x14"):SetFLOAT(val) -- AliveTime
  game_imp:Move("0xE40"):Move("0x18"):SetFLOAT(val) -- TotalTime
end

function GetGameTime()
  local game_imp = GetGameImpulse()
  local HUD = game_imp:Move("0xE40"):Move("0x14"):GetFLOAT() -- AliveTime
  local Results = game_imp:Move("0xE40"):Move("0x18"):GetFLOAT() -- TotalTime
  return HUD, Results
end

function GetHUDRings(val)
  local game_imp = GetGameImpulse()
  if not game_imp:Move("0xE40"):Move("0x4"):IsValidPTR() then
    player.print("INVALID!")
	return
  end
  return game_imp:Move("0xE40"):Move("0x4"):GetDWORD()
end

function SetHUDRings(val)
  local game_imp = GetGameImpulse()
  if not game_imp:Move("0xE40"):Move("0x4"):IsValidPTR() then
    player.print("INVALID!")
	return
  end
  game_imp:Move("0xE40"):Move("0x4"):SetDWORD(val)
end

function SetPlayerTimeScale(val, player_id)
  player_id = player_id or 0
  local ObjPlayer = GetPlayerPointer(player_id)
  Memory(ObjPlayer):Move("0x17C"):SetFLOAT(val)
end

function GetGravityForce(player_id) -- Check 0x3C on gravity
  player_id = player_id or 0
  local gravity_module = GetGravityModule(player_id)
  return gravity_module:Move("0x38"):GetFLOAT()
end

function SetGravityForce(val, player_id)
  player_id = player_id or 0
  val = val or 980
  local gravity_module = GetGravityModule(player_id)
  gravity_module:Move("0x38"):SetFLOAT(val)
end

function SetGravityEnabled(enable, player_id) -- Name's a little off. 0 actually enables gravity
  player_id = player_id or 0
  enable = enable == nil and 0 or enable
  if type(enable) == "boolean" then
    enable = enable == true and 0 or 1
  end
  local context = GetCharacterContext(player_id)
  return context:Move("0xE7"):SetBYTE(enable)
end

function GetAccumulatedGravity(player_id)
  player_id = player_id or 0
  local gravity_module = GetGravityModule(player_id)
  return gravity_module:Move("0x44"):GetFLOAT()
end

function SetAccumulatedGravity(val, player_id)
  player_id = player_id or 0
  local gravity_module = GetGravityModule(player_id)
  gravity_module:Move("0x44"):SetFLOAT(val)
end

function GetPlayerInvuln(player_id) -- Returns 0 or 1
  player_id = player_id or 0
  local context = GetCharacterContext(player_id)
  return context:Move("0xE5"):GetBYTE()
end

function SetPlayerInvuln(enable, player_id) -- 0 disables, 1 enables
  player_id = player_id or 0
  enable = enable == nil and 1 or enable
  if type(enable) == "boolean" then
    enable = enable == true and 1 or 0
  end
  local context = GetCharacterContext(player_id)
  context:Move("0xE5"):SetBYTE(enable)
end

function EnableGhostMode(enable, player_id) -- Disables interactions with rings, kill planes and item boxes.
  player_id = player_id or 0
  enable = enable == nil and 1 or enable
  if type(enable) == "boolean" then
    enable = enable == true and 1 or 0
  end
  local context = GetCharacterContext(player_id)
  context:Move("0xE1"):SetBYTE(enable)
  print("Context status: " .. context:Move("0xE1"):GetBYTE())
end

function GetBlinkMode(player_id)
  player_id = player_id or 0
  local context = GetCharacterContext(player_id)
  return context:Move("0xE2"):GetBYTE() == 1 and true or 0
end

function SetBlinkMode(enable, player_id)
  player_id = player_id or 0
  enable = enable == nil and 1 or enable
  if type(enable) == "boolean" then
    enable = enable == true and 1 or 0
  end
  local context = GetCharacterContext(player_id)
  context:Move("0xE2"):SetBYTE(enable)
end

function GetAnimationRotationLock(player_id) -- Certain animations prevent rotation (e.g., spin kick). Returns 0 when locked
  player_id = player_id or 0
  local context = GetCharacterContext(player_id)
  return context:Move("0xE3"):GetBYTE()
end

function SetAnimationRotationLock(enable, player_id) -- 0 disables, 1 enables
  player_id = player_id or 0
  enable = enable == nil and 1 or enable
  if type(enable) == "boolean" then
    enable = enable == true and 1 or 0
  end
  local context = GetCharacterContext(player_id)
  context:Move("0xE3"):SetBYTE(enable)
end

function ToggleHitboxBound(enable, player_id, override_sonic) -- NOTE: Only works on Sonic? Can break things on everyone else
  player_id = player_id or 0
  if not override_sonic then
    if GetPlayerName(player_id) ~= "sonic" then return end
  end
  enable = enable == nil and 1 or enable
  if type(enable) == "boolean" then
    enable = enable == true and 1 or 0
  end
  local context = GetCharacterContext(player_id)
  context:Move("0x240"):SetBYTE(enable)
end

function ToggleHitboxKick(enable, player_id) -- Needs c_sliding_damage set inside Lua
  enable = enable == nil and 1 or enable
  if type(enable) == "boolean" then
    enable = enable == true and 1 or 0
  end
  player_id = player_id or 0
  local context = GetCharacterContext(player_id)
  context:Move("0xF0"):SetBYTE(enable)
end

function SetCharacterAura(enable, player_id) -- Shadow's Chaos Boost aura, Silver's greenish one, Sonic's (unused) blue one
  player_id = player_id or 0
  local model = GetCharacterModel(player_id)
  enable = enable == nil and 1 or enable
  if type(enable) == "boolean" then
    enable = enable == true and 1 or 0
  end
  model:Move("0x70"):SetBYTE(enable)
  model:Move("0x71"):SetBYTE(enable)
end

function HasGotDrive(player_id) -- Player just grabbed a Chaos Drive/Light Core
  player_id = player_id or 0
  local obj_player = Player(player_id)
  local result = obj_player:Move("0x214"):GetDWORD()
  return result == 4
end

function SetSlidingDamage(val, player_id)
  player_id = player_id or 0
  local obj_player = Player(player_id)
  obj_player:GetIPluginByName("zock"):Move("0xB8"):SetDWORD(val)
end

function GetSlidingDamage(player_id)
  player_id = player_id or 0
  local obj_player = Player(player_id)
  return obj_player:GetIPluginByName("zock"):Move("0xB8"):GetDWORD()
end

function SetSlidingPower(val, player_id)
  player_id = player_id or 0
  local obj_player = Player(player_id)
  obj_player:GetIPluginByName("zock"):Move("0xBC"):SetFLOAT(val) -- BC - Power  B8 - Damage
end

function GetSlidingPower(player_id)
  player_id = player_id or 0
  local obj_player = Player(player_id)
  return obj_player:GetIPluginByName("zock"):Move("0xBC"):GetFLOAT() -- BC - Power  B8 - Damage
end

function SetZockRadius(val, player_id)
  player_id = player_id or 0
  local obj_player = Player(player_id)
  obj_player:GetIPluginByName("zock"):Move("0x94"):SetFLOAT(val)
end
---- CHARACTER SPECIFIC BLOCK ----
function GetRemainingFlightTime(player_id) -- Gets the amount of flight time left as Tails
  player_id = player_id or 0
  local context = GetCharacterContext(player_id)
  return context:Move("0x230"):GetFLOAT()
end

function SetRemainingFlightTime(val, player_id) -- Sets the amount of flight time left as Tails
  player_id = player_id or 0
  local context = GetCharacterContext(player_id)
  context:Move("0x230"):SetFLOAT(val)
end

function GetHammerStatus(player_id)
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  local context = GetCharacterContext(player_id)
  local is_on = context:Move("0x230"):GetBYTE() == 1
  return is_on
end

function SetHammerHitbox(val, player_id)
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  local CapsuleHavok = Player(player_id):GetIPluginByName("amy_weapons"):Move("0x54"):GetPointer():Move("0xC0"):GetPointer():Move("0x24"):GetPointer():Move("0x18"):GetPointer()
  CapsuleHavok:Move("0xC"):SetFLOAT(val)
end

function SetTornadoHitbox(val, player_id)
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  local obj_player = Player(player_id)
  local PhantomA =  obj_player:GetIPluginByName("sonic_weapons"):Move("0x78"):GetPointer():Move("0xE0"):GetPointer() -- 0x78 TorandoWeapon
  local Shape  = PhantomA:Move("0x24"):GetPointer() -- example in my marathon lib (Sonicteam::SoX::Physics::Havok::SphereShapeHavok try look)
  --local HavokShape = Shape:Move("0x18"):GetPointer()  -- if Capsule
  local HavokShape = Shape:Move("0x1C"):GetPointer()  -- if cylinder
  --HavokShape:Move("0x10"):SetFLOAT(10)
  HavokShape:Move("0x10"):SetFLOAT(val)
end

function GetHammerHitbox(player_id)
end

function EnableAmyHammer(enable, player_id)
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  local is_show_hammer = enable
  enable = enable == nil and 1 or enable
  if type(enable) == "boolean" then
    enable = enable == true and 1 or 0
  end
  local context = GetCharacterContext(player_id)
  --ToggleAmyHammerVisual(is_show_hammer) -- Set the visual
  context:Move("0x230"):SetBYTE(enable) -- Set the hitbox
end

function GetRemainingStealthTime(player_id)
  player_id = player_id or 0
  local context = GetCharacterContext(player_id)
  return context:Move("0x238"):GetFLOAT()
end

function SetRemainingStealthTime(val, player_id)
  player_id = player_id or 0
  local context = GetCharacterContext(player_id)
  return context:Move("0x238"):SetFLOAT(val)
end

function GetRemainingJumps(player_id)
  player_id = player_id or 0
  local context = GetCharacterContext(player_id)
  return context:Move("0x234"):GetDWORD()
end

function SetRemainingJumps(val, player_id)
  player_id = player_id or 0
  local context = GetCharacterContext(player_id)
  return context:Move("0x240"):SetFLOAT(val)
end

function GetMachParticles(player_id)
  player_id = player_id or 0
  local context = GetCharacterContext(player_id)
  return context:Move("0x248"):GetBYTE() == 1
end

function GetRemainingBlastTime(player_id) -- Remaining jump acceptance window for Rouge's Blast Jump
  player_id = player_id or 0
  local context = GetCharacterContext(player_id)
  return context:Move("0x230"):GetFLOAT()
end
----------------------------------
local char_flag_table = {
  common = {
    BlinkMode = "0xE2",
	IsGrinding = "0xED", -- Is on a grind rail
    IsPush = "0xEF", -- Reduces jump height/fall speed when pushing against a surface
	IsEdgeGrab = "0xF4", -- Forces you back to your position when this byte was first set
	DisableLand = "0xF7", -- Detaches you from the ground until disabled 
	DisableLandOnce = "0xF8", -- Detaches you from the ground for a moment
	InertiaMode = "0xF9", -- Enables c_posture_inertia_move, prevents rotation
	ResetGravity = "0xFC", -- Resets accumulated gravity
	DisableGravity = "0xFD", -- Resets and disables gravity
	IsInvulnItem = "0x102", -- Invulnerable, likely through the item
	IsBarrier = "0x104", -- Shield powerup
	IsGrabbedIsh = "0x106", -- Weird glitched state
	GrabbedAura = "0x108", -- Green ESP effect when held by Silver
	HoldLock = "0x109", -- Locks rotation, likely for a hold
	SmallCollision = "0x10A", -- Player hurtbox when Antigrav is active
  },
  sonic = {
    IsLockon = "0x23C", -- Homing Lockon properties
	LightDashMode = "0x23D", -- Locks the player to a nearby lightdash path, preventing other movement/rotation. Sticks them if no rings are present
	SlideHitbox = "0x23E", -- Antigrav hitbox
	BoundHitbox = "0x240", -- Bound Attack hitbox
    IsShrink = "0x242", -- Purple Gem effect (Lua values, can enter state 36). Does not cause the shrinking effect
	IsThunderGuard = "0x243", -- Toggles Yellow Gem properties if a shield is already active
	IsTornadoEnabled = "0x244", -- Toggles Green Gem hitbox. Activates tornado vfx when first enabled
	IsBombSearch = "0x245", -- First person camera mode
	ThrowGem = "0x246", -- Spawns the Sky Gem
	IsTimeSlow = "0x247", -- Detects Red Gem's effect
	MachAura = "0x248", -- Enables the Blue Gem particles
	IsFlipReady = "0x24C", -- Makes Sonic enter homing_after1 on his next HA recovery
	PrincessBarrierOn = "0x2B0",
	BoardGroundDisconnect = "0xA7",
	BoardIsColliding = "0xBC",
	BoardRotationLocked = "0xBE",
	BoardIsDead = "0xBF",
	BoardBlinkMode = "0xC1",
  },
  tails = {
    ThrowSnipeBomb = "0x238", -- Instantly launches a dummy ring bomb
	IsBombSearch = "0x239", -- First person camera mode
	ThrowAirBomb = "0x23B", -- Instantly throw a dummy ring bomb with the aerial trajectory
  },
  knuckles = {
    IsComboValid = "0x230", -- Sets to 1 when an X press will continue Knuckles' punch combo
	IsStoneBreaker = "0x231", -- Generates the vfx and hitbox for the third hit of Knuckes' combo
	IsScrewDriver = "0x232", -- Set when in the Screwdriver attack. Influences rotation and movement
	IsGroundShaker = "0x233", -- Forcibly rotates Knuckles downwards. Causes the awkward Dive movement
	GroundShakerHitbox = "0x234", -- Triggers the GroundShaker impulse and stun hitbox. Immediately deactivates
  },
  shadow = {
    HomingGravityOff = "0x260", -- Disables gravity, for use during the homing attack. Immediately cancels the action if disabled mid HA
	LightDashMode = "0x261", -- Same as Sonic's
	IsSnapWait = "0x262", -- Tracks waiting in Chaos Snap?
	IsChaosAttack = "0x263", -- If the Homing Attack detects a lockon, launch it as a Chaos Attack (deals damage, instantly cancels the HA)
	SnapVisualCharge = "0x264", -- Triggers the Chaos Snap charge visual. Does not grant the property, remains stored until an actual Snap is used
	SnapCharge = "0x265", -- Causes your homing attack to launch as a Chaos Snap.
	TornadoHitbox = "0x266", -- Plays the initial Tornado Kick visual and activates the hitbox
	SmashHit = "0x267", -- Set towards the end of the Homing Attack, causes it to inflict Smash Damage. Must be set after the HA has started
  },
  rouge = {
    ThrowCracker = "0x234", -- Spawns the unused Bat Cracker Mine. Object is fully functional
	ThrowBomb = "0x235", -- Spawns a standard bomb
	ThrowMine = "0x236", -- Spawns a Heart Mine
	IsBombSearch = "0x237", -- First person camera mode
  },
  omega = {
    FireBlaster = "0x244", -- Fires the grounded melee attack when activated, even if airborne
	FireShot = "0x245", -- Fires the aerial blast
	FireLockon = "0x247", -- Fires the multi-lockon, if there are targets present.
  },
  silver = {
    IsEspEffect = "0x248", -- Activates the aura vfx, including different quill placement
	IsGaugeBlocked = "0x249", -- Disables gauge regeneration while true
	DoShockwave = "0x24A", -- Generates an impulse that repels objects and stuns enemies. Wider range than stunslap, not sure what it's meant for
	SlapVFX = "0x24B", -- Pulsing green circles, like the ones from stunslap. 0x24C also calls this
	TriggerGrab = "0x24F", -- Enables the properties/effects for grabbing objects. Quickly disables if RT is not held
	IsStickyGrab = "0x250", -- Grabs nearby physics objects without giving Silver the effect. These remain held until thrown or the byte is turned off. 
	DoLaunch = "0x251", -- Launches any held objects
	DoSmash = "0x252", -- Triggers the Hold Smash effect, including the vfx
  }
}
char_flag_table.sonic_mach = char_flag_table.sonic

function GetContextFlag(flag, player_id)
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  local context = GetCharacterContext(player_id)
  local name = GetPlayerName()
  if not char_flag_table[name] then return end
  local offset = char_flag_table.common[flag] or char_flag_table[name][flag]
  if offset == nil then
    DebugPrint("GetContextFlag: Invalid flag " .. tostring(flag) .. " on character " .. tostring(name))
	return
  end
  local result = context:Move(offset):GetBYTE()
  return result == 1
end

function SetContextFlag(flag, value, player_id)
  player_id = player_id or 0
  if not Player(player_id):IsValidPTR() then
    return
  end
  if type(value) == "boolean" then
    value = value == true and 1 or 0
  end
  local context = GetCharacterContext(player_id)
  local name = GetPlayerName()
  local offset = char_flag_table.common[flag] or char_flag_table[name][flag]
  if offset == nil then
    DebugPrint("SetContextFlag: Invalid flag " .. tostring(flag) .. " on character " .. tostring(name))
	return
  end
  context:Move(offset):SetBYTE(value)
end
----------------------------------

function IsPlayerInRange(coords, distance, use_y)
  use_y = use_y or false
  local x, y, z = coords[1], coords[2], coords[3]
  local pCoords = GetPlayerPos()
  
  if not pCoords then return end
  
  local pX, pY, pZ = pCoords.X, pCoords.Y, pCoords.Z
  local diffX = mAbs(pX - x)
  local diffY = mAbs(pY - y)
  local diffZ = mAbs(pZ - z)
  local total_diff = use_y and mAbs(diffX + diffY + diffZ) or mAbs(diffX + diffZ)
  total_diff = mFloor(total_diff)
  return total_diff <= distance, total_diff
end

function SetWorldTimeScale(value)
  local doc = GetDocMarathon()
  doc:Move("0xE8"):SetFLOAT(value) -- Lowest: ~0.0045
end

function TestHUDStuff()
  local csd = GetCSDObject()
  local csd_buffer = Buffer(csd:GetPTR())
  
  Memory("0x82659610"):CallFunc(csd:GetPTR()) --RefCountObjectAddReference
  Memory("0x824CDCE0"):CallFunc(csd_buffer:GetPTR(),"life","character_icon",1) --CellLoadSpriteWithSubAndSpriteIndex
  
  csd_buffer:Free()
end

function CallUIIndex(scene, cast, index)
  local csd = GetCSDObject()
  local csd_buffer = Buffer(csd:GetPTR())
  Memory("0x82659610"):CallFunc(csd:GetPTR()) --RefCountObjectAddReference
  Memory("0x824CDCE0"):CallFunc(csd_buffer:GetPTR(), scene, cast, index) -- example: "life", "character_icon", 0
  csd_buffer:Free()
end

function CallUIAnim(scene, animation)
  local csd = GetCSDObject()
  local csd_buffer = Buffer(csd:GetPTR())
  Memory("0x82659610"):CallFunc(csd:GetPTR()) --RefCountObjectAddReference
  Memory("0x824CE670"):CallFunc(csd_buffer:GetPTR(), scene, animation) -- example: "life_ber_anime", "sonic_in"
  csd_buffer:Free()
end

function CallUIText(scene, cast, text)
  local csd = GetCSDObject()
  local csd_buffer = Buffer(csd:GetPTR())
  Memory("0x82659610"):CallFunc(csd:GetPTR()) --RefCountObjectAddReference
  Memory("0x824CDDF0"):CallFunc(csd_buffer:GetPTR(), scene, cast, text) -- example: "item", "item_text", "1/10"
  csd_buffer:Free()
end

function SetCameraTest()
   Game.ProcessMessage("LEVEL", "FixCamera", {
    eye = {
      -196246.125,
      5793.758,
      -911.341
    },
    target = {
      -196118.266,
      5804.208,
      -903.58
    }
  })
end

function GetCameraCoords()
  local obj_player = Player(0)
  local player_cameraman = obj_player:Move("0x94"):GetPointer():FMove("-0x20")
  local camera_coords = player_cameraman:Move("0xA0"):GetVector()
  return camera_coords
end

function ResetCameraTest()
  local obj_player = Player(0)
  local player_cameraman = obj_player:Move("0x94"):GetPointer():FMove("-0x20")
  local player_cameraman_1 = obj_player:Move("0x94"):GetPointer()
  local player_cameraman_1_vft = player_cameraman_1:GetPointer()
  local player_cameraman_vft_messagefunc = player_cameraman_1_vft:Move("0x4"):GetPointer()
  
  local actor_id = obj_player:GetActorID()
  local message_set = Buffer(81930,1,1,0,Vector(0,0,0,1),Vector(0,0,0,1)) --Fix Camera
  local message_reset = Buffer(81927,0,actor_id,0)
  player_cameraman_vft_messagefunc:CallFunc(player_cameraman_1:GetPTR(),message_set:GetPTR())
  player_cameraman_vft_messagefunc:CallFunc(player_cameraman_1:GetPTR(),message_reset:GetPTR())
  message_set:Free()
  message_reset:Free()
end

function ToggleAmyHammerVisual(is_show_hammer, player_id)
  player_id = player_id or 0
  local obj_player = Player(player_id)
  local AmyWeapons  = obj_player:GetIPluginByName("amy_weapons")
  local AmyHammerWeapon = AmyWeapons:Move("0x54"):GetPointer()

  local AmyHammerWeaponClump = AmyHammerWeapon:Move("0xC4"):GetPointer()
  local AmyHammerWeaponClumpRef = AmyHammerWeapon:FMove("0xC4") -- for actuall ClumpPTR just add :GetPointer()
  local AmyHammerWeaponClumpFunc01 = AmyHammerWeaponClump:GetPointer():Move("0x20"):GetPointer()


  local AmyHammerLoad = AmyHammerWeapon:Move("0x54"):GetPointer()
  local AmyHammerLoadFunc01 = AmyHammerLoad:GetPointer():Move("0x14"):GetPointer()


  local AmyHammerWeaponClumpWorldImpSceneryClmp = AmyHammerWeaponClump:Move("0xC"):GetPointer() == Memory("0x0")

  if (AmyHammerWeaponClumpWorldImpSceneryClmp) and is_show_hammer then -- Display the hammer
    --player.print(AmyHammerWeaponClumpFunc01:GetPTR())
    AmyHammerLoadFunc01:CallFunc(AmyHammerLoad:GetPTR(),AmyHammerWeaponClumpRef:GetPTR())
  elseif not is_show_hammer and not AmyHammerWeaponClumpWorldImpSceneryClmp then -- Hide the hammer
    --player.print(AmyHammerLoadFunc01:GetPTR()) 
	AmyHammerWeaponClumpFunc01:CallFunc(AmyHammerWeaponClump:GetPTR())
  end

end


-- WEAPON BLOCK --
function SetAmyHammerFlags(flag)
  local HavokObject = Player(0):GetIPluginByName("amy_weapons"):Move("0x54"):GetPointer():Move("0xC0"):GetPointer():Move("0x40"):GetPointer()
  local HavokObjectColFlagPTR = HavokObject:Move("0x38") 
  --local HavokObjectColFlag = HavokObject:GetPointer("0x38"):GetPTR()
  HavokObjectColFlagPTR:SetDWORD(flag) -- 0x1C00
end

function SetZockFlags(flag)
  local HavokObject = Player(0):GetIPluginByName("zock"):Move("0x38"):GetPointer():Move("0x40"):GetPointer()
  local HavokObjectColFlagPTR = HavokObject:Move("0x38") 
  HavokObjectColFlagPTR:SetDWORD(flag) -- 0x383 by default
end

function SetSonicSlideFlags(flag)
  local HavokObject = Player(0):GetIPluginByName("sonic_weapons"):Move("0x58"):GetPointer():Move("0xC0"):GetPointer():Move("0x40"):GetPointer() 
  local HavokObjectColFlagPTR = HavokObject:Move("0x38") 
  HavokObjectColFlagPTR:SetDWORD(flag) -- 0x1C80 by default
end
------------------
function ResetGemFlags()
  local gems = { green = {"0x20", 6004}, red =  {"0x28", 6005}, blue = {"0x30", 6006}, white = {"0x38", 6007}, sky = {"0x40", 6008}, yellow = {"0x48", 6009}, purple = {"0x50", 6010} }
  local flags = {}
  local SVector = Player(0):Move("0x1C8")
  local Vector_Start = SVector:Move("0x4"):GetPointer()
  for gem, properties in pairs(gems) do
    Vector_Start:Move(properties[1]):SetDWORD(properties[2])
  end
end
function HalfSwapSonic()
  local PObject = Player(0)
  PObject:OpenPackage("player/sonic_new")
  PObject:RemovePlugin("model")
  PObject:RemovePlugin("effect")
  PObject:RemovePlugin("item")
  local eff_sn = PObject:OpenEffect(11, "player_sonic")
  local eff_tl = PObject:OpenEffect(5, "player_sonic")
  
  local model = PObject:OpenModel(0,0)
  PObject:IDynamicLink(model,eff_sn,eff_tl)
  PObject:IVariable("player/sonic_new.lua",model,eff_sn,eff_tl)
end
function HalfSwapSuper()
    local PObject = Player(0)
    PObject:OpenPackage("player/sonic_super")
	PObject:RemovePlugin("model")
	PObject:RemovePlugin("effect")
	PObject:RemovePlugin("item")
	local eff_sn = PObject:OpenEffect(11, "player_metal")
	local eff_tl = PObject:OpenEffect(5, "player_metal")
	local eff_sso = PObject:OpenEffect(12, "player_metal")
	local item = PObject:OpenOther(8)
	
	local model = PObject:OpenModel(0,0)
	
	--[[
	local frame = Memory(PObject:OpenFrame())
	frame:move("0x70"):SetVector(FrameRFTransformMatrix0x70[1])
	frame:move("0x80"):SetVector(FrameRFTransformMatrix0x70[2])
	frame:move("0x90"):SetVector(FrameRFTransformMatrix0x70[3])
	frame:move("0xA0"):SetVector(FrameRFTransformMatrix0x70[4])
	
	frame:move("0xB0"):SetVector(FrameRFTransformMatrix0xB0[1])
	frame:move("0xC0"):SetVector(FrameRFTransformMatrix0xB0[2])
	frame:move("0xD0"):SetVector(FrameRFTransformMatrix0xB0[3])
	frame:move("0xE0"):SetVector(FrameRFTransformMatrix0xB0[4])
	]]
	PObject:IDynamicLink(model,eff_sn,eff_tl,eff_sso,item)
	PObject:IVariable("player/sonic_super.lua",model,eff_sn,eff_tl,eff_sso,item)
	
	--Memory("0x8265961"):CallFunc(frame.ptr)
	--local PosturePlug = PObject:Move("0xDC"):GetPointer()
	--PosturePlug:Move("0x10"):SetPointer(frame.ptr)
end

function GetCameraOffset(player_id)
  player_id = player_id or 0
  local obj = Player(player_id)
  if not obj:IsValidPTR() then return end
  local offsets = {}
  offsets[1] = obj:Move("0x190"):GetFLOAT()
  offsets[2] = obj:Move("0x194"):GetFLOAT()
  offsets[3] = obj:Move("0x198"):GetFLOAT()
  return offsets
end

function SetCameraOffset(coords, is_absolute, player_id)
  player_id = player_id or 0
  local obj = Player(player_id)
  if not obj:IsValidPTR() then return end
  
  local current = GetCameraOffset(player_id)
  local new = {}
  for i = 1, 3 do
	  if is_absolute then
	    new[i] = coords[i]
	  else
	    local diff = coords[i] + current[i]
	    new[i] = diff
	  end
  end 
  obj:Move("0x190"):SetFLOAT(new[1]) -- X
  obj:Move("0x194"):SetFLOAT(new[2]) -- Y
  --obj:Move("0x194"):SetFLOAT(new[3]) -- Z
end

function SetHUDKeyFrame(frame, char_idx)
  local HUD_Colors = Memory("0x92036BE4") -- Array. This persists through quitting, be careful
  local previous_keyframe = HUD_Colors:Move("0x0"):GetFLOAT()
  HUD_Colors:Move("0x0"):SetFLOAT(frame) -- Update Sonic's HUD
  
  local HUDMainDisplay = GetHUDDisplay()
  local curr_idx = HUDMainDisplay:Move("0x78"):GetDWORD()
  local new_idx = curr_idx == 1 and 0 or 1
  
  -- Update "character" index. Must be different from the the index we try to access below.
  HUDMainDisplay:Move("0x78"):SetDWORD(new_idx)
  local receiver = HUDMainDisplay:FMove("0x28")
  local receiver_function = receiver:GetPointer():Move(4):GetPointer() -- Function pos from VFT. Raw = 824DF0C0
  --[[
  local sub_id = 0
  local sub_index = 2 -- Score
  local is_HUD_on = 1
  local msg_hud_on = Buffer(110660, 0, sub_id, sub_index)
  msg_hud_on:Move("0x4"):SetBYTE(is_HUD_on)
  receiver_function:CallFunc(receiver:GetPTR(), msg_hud_on:GetPTR())
  ]]
  local msg_color_idx = Buffer(110660, 16777216, 5, char_idx)
  receiver_function:CallFunc(receiver:GetPTR(), msg_color_idx:GetPTR())
  msg_color_idx:Free()
  -- msg_hud_on:Free()
  HUD_Colors:Move("0x0"):SetFLOAT(previous_keyframe) -- Since the write persists, reset it in case you quit.
end