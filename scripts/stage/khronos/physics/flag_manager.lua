-- @BRIEF: Bit flags, basically. The number of temporary flags is limited, so I'm reserving Flag 10 as a bitfield and using bitflags to check properties.

local mission_ptr = 0 -- There's some weird timing stuff due to the player scripts loading this file. Easiest to just set the pointer when a func is called.
local KHRONOS_FLAG_HANDLE = 10 -- Handle for the TempFlag that we'll be using.
local GEM_FLAG_HANDLE = 11 -- Handle for gem levels
g_flags = {
  enemy_dead = 1, -- Enemy has been recently killed
  bounce_ready = 2, -- Enemy has been killed with the player in close proximity
  stage_restart = 4, -- NotifyRestart message received
  gauge_empty = 8, -- Action Gauge is fully depleted
  bound_hitbox = 16, -- Player has a Bound Attack hitbox active (SONIC ONLY)
  rotation_lock = 32, -- Character rotation is locked
  is_princess = 64, -- Playing as Sonic + Elise
  is_super = 128, -- Super Sonic active, preserve between sections
  is_snow_board = 256, -- Playing as a Snowboard
}
function SetManagedFlag(flag, status) -- int, bool
  if mission_ptr == 0 then
    mission_ptr = GetMissionPointer()
  end
  if mission_ptr == 0 or mission_ptr == nil then
    player.print("INVALID PTR!")
	return
  end
  if status == GetManagedFlag(flag) then -- If I want to activate and it's already on? Skip. If I want to deactivate and it's already off? Skip.
    return
  end
  local my_val = GetTemporaryFlag(mission_ptr, KHRONOS_FLAG_HANDLE)
  if status == true then -- It would be safer to set this flag by OR'ing, but this *should* be okay since I don't have a bit.NOT.
    my_val = my_val + flag
  elseif status == false then
    my_val = my_val - flag
  end
  SetTemporaryFlag(mission_ptr, KHRONOS_FLAG_HANDLE, my_val)
end

function GetManagedFlag(check_flag) -- int
  if mission_ptr == 0 then
    mission_ptr = GetMissionPointer()
  end
  if mission_ptr == 0 or mission_ptr == nil then
    player.print("INVALID PTR!")
	return
  end
  return bit.AND(GetTemporaryFlag(mission_ptr, KHRONOS_FLAG_HANDLE), check_flag) ~= 0
end


-- SONIC GEM BLOCK --
-- Gem levels need to be preserved between sections.
local gem_pos = {none = 1, blue = 2, green = 3, red = 4, purple = 5, sky = 6, white = 7, yellow = 8, super = 9}

function ParseGemLevelFlag(position, new_val)
  if mission_ptr == 0 then
    mission_ptr = GetMissionPointer()
  end
  if mission_ptr == 0 or mission_ptr == nil then
    player.print("INVALID PTR!")
	return
  end
  if type(position) == "string" then
    position = gem_pos[position]
  end
  local flag = GetTemporaryFlag(mission_ptr, GEM_FLAG_HANDLE)
  if flag == 0 then flag = 111111111 end
  local idx = 10^position
  local divisor = 10^(position-1)
  local modu = math.mod(flag, idx)
  local divided = modu/divisor
  local lead = mFloor(divided)
  if new_val then
    local new = divided - lead
	new = new + new_val
	new = new * divisor
	flag = (flag - modu) + new
	SetTemporaryFlag(mission_ptr, GEM_FLAG_HANDLE, flag)
  end
  return lead
end