-- @BRIEF: Functions for easily getting input related data.
-- GetStickInput(): Returns a bool or float based on how a specified stick is moved, depending on argument.
-- IsStickNeutral(): Returns true if the left stick is completely idle.
-- GetInput(): Returns a bool based on the button and held status.
-- Get/SetInputLocked(): Checks or sets the remaining input lockout time for automation.

-- Accepts down/hold/released/double_press as entries for ID.
-- is_raw runs GetPlayerRawInput instead of GetPlayerInput, which utilizes different IDs. For now, it's only used for the B button.
-- is_currently_down is an internal value and should not be adjusted.
local button_to_id = {
  a = {down = 1, hold = 2, released = 4, double_press = 32},
  b = {down = 2, hold = 2, is_raw = true, is_currently_down = false},
  x = {down = 256, hold = 512, released = 1024},
  --y = {down = 16},
  y = {down = 16, hold = 16, is_raw = true, is_currently_down = false},
  rt = {down = 65536, hold = 131072, released = 262144, double_press = 524288},
  dpad_right = {down = 1048576},
  dpad_left = {down = 2097152},
  dpad_up = {down = 64, hold = 64, is_raw = true, is_currently_down = false},
  dpad_down = {down = 128, hold = 128, is_raw = true, is_currently_down = false},
  start = {down = 1024, hold = 1024, is_raw = true, is_currently_down = false},
  select = {down = 2048, hold = 2048, is_raw = true, is_currently_down = false},
  lb = {down = 4096, hold = 4096, is_raw = true, is_currently_down = false},
  rb = {down = 8192, hold = 8192, is_raw = true, is_currently_down = false},
  lt = {down = 16384, hold = 16384, is_raw = true, is_currently_down = false},
  l3 = {down = 65536, hold = 65536, is_raw = true, is_currently_down = false},
  r3 = {down = 131072, hold = 131072, is_raw = true, is_currently_down = false},
}
-- String library isn't available, so this handles capital inputs (as well as aliases)
-- UPDATE: String library now available, need to adjust code before release.
local argument_correction = {
  A = "a",
  B = "b",
  X = "x",
  Y = "y",
  RT = "rt",
  Down = "down",
  Released = "released",
  Up = "released",
  up = "released",
  Hold = "hold",
  pad_right = "dpad_right",
  pad_left = "dpad_left",
  left = "L",
  right = "R",
  Left = "L",
  Right = "R"
}
local valid_stick_inputs = {LStickX = true, LStickY = true, RStickX = true, RStickY = true}

function GetStickInput(stick_name, stick_axis, is_raw_data, player_id)
  player_id = player_id or 0
  is_raw_data = is_raw_data or false
  stick_name = argument_correction[stick_name] or stick_name
  local stick = stick_name .. "Stick" .. stick_axis
  if not valid_stick_inputs[stick] then
    DebugPrint("Invalid stick: " .. stick)
	return
  end
  local stick_val = player.GetPlayerRawInput(player_id)[stick]
  return is_raw_data and stick_val or (bit.AND(stick_val, 1) ~= 0)
end

function IsStickNeutral() -- Checks if the left stick is being moved at all
  local input = mAbs(GetStickInput("L", "X", true)) + mAbs(GetStickInput("L", "Y", true))
  return input == 0
end

function CheckIdleInput(player_id)
  player_id = player_id or 0
  local playerRaw = player.GetPlayerRawInput(player_id)
  local button_values = player.GetPlayerInput(player_id) == 0
  if playerRaw.LStickX == 0 and playerRaw.LStickY == 0 and button_values then
    return true
  else
    return false
  end
end

function GetInput(button_name, button_status, player_id)
  player_id = player_id or 0 -- Typically we only need to detect Player 1
  button_name = argument_correction[button_name] and argument_correction[button_name] or button_name -- Converts capital inputs to lower
  if not button_to_id[button_name] then
    DebugPrint("INVALID INPUT: " .. button_name)
	return
  end
  button_status = button_status or "down" -- Makes button_status optional as checking for "down" will likely be the most common argument.
  button_status = argument_correction[button_status] and argument_correction[button_status] or button_status
  local button_id = button_to_id[button_name][button_status]
  if button_id == nil then -- Ensures a valid check was made
    DebugPrint("Invalid press status: " .. button_status .. " for input " .. button_name)
	return
  end
  local button_ref = button_to_id[button_name]
  if not button_ref.is_raw then
    return (bit.AND(player.GetPlayerInput(player_id), button_id) ~= 0)
  else
    local return_value = (bit.AND(player.GetPlayerRawInput(player_id).Buttons, button_id) ~= 0)
	  if not button_ref.is_currently_down and return_value then
	    DebugPrint("Down protection on: " .. button_name)
	    button_ref.is_currently_down = true
		if button_status ~= "down" then
		  return_value = false
		end
	  elseif button_ref.is_currently_down and return_value then -- Protection is active, button is still pressed
	    return_value = button_status == "hold" and true or false
	  elseif button_ref.is_currently_down and not return_value then -- Button is no longer being pressed, disable protection.
	    DebugPrint("Down protection off: " .. button_name)
	    button_ref.is_currently_down = false
		return false, true -- It's *really* hard to detect a "release" specifically, so it's included as a secondary return.
	  end
    return return_value
  end
end

function GetInputLockout(last, player_id)
  last = last or false
  player_id = player_id or 0
  local player_context = Player(player_id):Move("0xE4"):GetPointer():Move("0x50"):GetPointer()
  if not player_context then
    DebugPrint("GetInputLockout: Invalid player context...")
	return
  end
  local my_lockout_address = last and player_context:Move("0x50") or player_context:Move("0x44")
  local lockout_time = my_lockout_address:GetFLOAT()
  return lockout_time, my_lockout_address
end

function SetInputLockout(value, last, player_id)
  last = last or false
  player_id = player_id or 0
  local _, lockout_address = GetInputLockout(last, player_id)
  if not lockout_address then
	return
  end
  lockout_address:SetFLOAT(value)
end

function IsInputLocked(player_id) -- Doesn't work
  player_id = player_id or 0
  local player_context = Player(player_id):Move("0xE4"):GetPointer():Move("0x50"):GetPointer()
  if not player_context then
    DebugPrint("IsInputLocked: Invalid player context...")
	return
  end
  local is_locked = player_context:Move("0x54"):GetDWORD()
  return tostring(is_locked)
end