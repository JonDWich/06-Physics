-- @BRIEF: Helpful debug functions such as player data printouts.

function InitText()
  if new_dbg_text == nil then
    print("ACTIVATING INIT")
  else
    print("ALREADY ACTIVE!")
	return
  end
  new_dbg_text =  DebugLabel("", 0, 275)
  --dbg_text = 	  DebugLabel("", 0, 275)
  --spd_text = 	  DebugLabel("", 0, 300)
  --gmk_text =      DebugLabel("", 0, 325)
  --total_text =    DebugLabel("", 0, 350)
  --gmk_prev_text = DebugLabel("", 0, 375)
  position_text = DebugLabel("", 0, 450)
  --slope_angle =   DebugLabel("", 0, 475)
  --slope_spd =	  DebugLabel("", 0, 500)
  lerped_spd =    DebugLabel("", 0, 525)
  
  reticle = DebugLabel("", 600, 350)
end

local use_text = true
function UpdateText()
  local pos = GetPlayerPos()
  local my_X, my_Y, my_Z = pos.X, pos.Y, pos.Z

  local on_ground = tostring(IsGrounded())
  local spd_x = GetPlayerSpeed("x", false) or 0
  local gimmick_x = GetPlayerSpeed("x", true) or 0
  local last_gimmick_x = GetPlayerSpeed("x", true, true) or 0
  local total_speed = spd_x + gimmick_x
  local spd_y = GetPlayerSpeed("y", false) or 0
  local gimmick_y = GetPlayerSpeed("y", true) or 0
  local last_gimmick_y = GetPlayerSpeed("y", true, true) or 0
  local total_y = spd_y + gimmick_y
  local my_anim = GetPlayerAnim(true) or ""
  local my_state = GetPlayerState() or 0
  local my_flag = GetGravityModule(0):Move("0x24"):GetDWORD() or 0
  local acc_grav = GetAccumulatedGravity()
  local format_strings = {
    {str = "(X: %d,  Y:  %d,  Z:  %d)\n", enabled = true, vars = {my_X, my_Y, my_Z}},
    {str = "is_grounded: %s\n", enabled = true, vars = {on_ground}},
	{str = "x_base_spd: %.2f\n", enabled = true, vars = {spd_x}},
	{str = "x_gimmick_spd: %.2f\n", enabled = true, vars = {gimmick_x}},
	{str = "x_prev_gimmick_spd: %.2f\n", enabled = true, vars = {last_gimmick_x}},
	{str = "x_total_spd: %.2f\n", enabled = true, vars = {total_speed}},
	{str = "y_base_spd: %.2f\n", enabled = true, vars = {spd_y}},
	{str = "y_gimmick_spd: %.2f\n", enabled = true, vars = {gimmick_y}},
	{str = "y_prev_gimmick_spd: %.2f\n", enabled = true, vars = {last_gimmick_y}},
	{str = "y_total_spd: %.2f\n", enabled = true, vars = {total_y}},
	{str = "Anim: %s\n", enabled = true, vars = {my_anim}},
	{str = "StateID: %d\n", enabled = true, vars = {my_state}},
	{str = "GroundFlag: %d\n", enabled = true, vars = {my_flag}},
	{str = "Acc_Grav: %.2f\n", enabled = true, vars = {acc_grav}}
  }
  local formatted = ""
  local format_vars = {}
  for k, v in ipairs(format_strings) do
    if v.enabled then
	  formatted = formatted .. v.str
	  for _, var in ipairs(v.vars) do
	    table.insert(format_vars, var)
	  end
	end
  end
  --dbg_text:SetText(string.format("%18s %6s", "is_grounded:", tostring(on_ground)))
  --spd_text:SetText(string.format("%18s %6.2f", "x_spd:", spd_x/100))
  --gmk_text:SetText(string.format("%18s %6.2f", "gimmick_spd:", gimmick_x/100))
  --total_text:SetText(string.format("%18s %6.2f", "total_speed:", total_speed/100))
  --gmk_prev_text:SetText(string.format("%18s %6.2f", "prev_gimmick_spd:", last_gimmick_x/100))
  if use_text then
    --new_dbg_text:SetText(string.format(formatted, my_X, my_Y, my_Z, on_ground, spd_x, gimmick_x, last_gimmick_x, total_speed, spd_y, gimmick_y, last_gimmick_y, total_y, my_anim, my_state, my_flag, acc_grav))
	new_dbg_text:SetText(string.format(formatted, unpack(format_vars)))
  else
    new_dbg_text:SetText("")
  end
  if GetInput("rt", "double_press") then
    use_text = not use_text
  end
end

function UpdatePosition(extra_data)
    local save_btn, load_btn = extra_data.save_button, extra_data.load_button
	local x, y, z = extra_data.stored_pos.X, extra_data.stored_pos.Y, extra_data.stored_pos.Z
	if GetInput(save_btn) then
	  extra_data.stored_pos = GetPlayerPos("ALL")
	elseif GetInput(load_btn) then
	  SetPlayerPos(x, y, z, true)
	end
	position_text:SetText(string.format("%s %20s %.2f  %20s %.2f  %20s %.2f", "Stored Values:", "\nX:", x, "\nY:", y, "\nZ:", z))
end

local DebugFunctions = {
  speed_info = { func = UpdateText, enabled = true, extra = {} },
  position_warp = { func = UpdatePosition, enabled = false, extra = {save_button = "b", load_button = "y", stored_pos = {X = 0, Y = 0, Z = 0}} }
}

function DebugStep(delta)
  --if true then return end
  for k, data in pairs(DebugFunctions) do
    if data.enabled then
	  data.func(data.extra)
	end
  end
  if GetCurrentAnimation("bomb_search_l") or GetCurrentAnimation("bomb_search_s") then
    reticle:SetText(">>  <<")
  else
    reticle:SetText("")
  end
end