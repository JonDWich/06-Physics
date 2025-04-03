-- @BRIEF: Used to handle miscellaneous events, like invincibility when a shield gets destroyed
local is_shield_active = false
local shield_invuln_counter = 0 -- Counts up to the value specified in PlayerList when the shield is destroyed

local test_timer = 0
function PowerupStep(delta)
  if not Player(0):IsValidPTR() then return end
  local shield_check = GetContextFlag("IsBarrier")
  if shield_invuln_counter > 0 then
    shield_invuln_counter = shield_invuln_counter + delta
	if shield_invuln_counter >= player_reference.powerup_params.shield_invuln_time then
	  shield_invuln_counter = 0
	  SetContextFlag("IsInvulnItem", 0)
	  SetContextFlag("BlinkMode", 0)
	end
  elseif is_shield_active and not shield_check then -- Barrier was destroyed, trigger invulnerability
    if GetPlayerState() ~= 48 then
      SetContextFlag("IsInvulnItem", 1)
	  SetContextFlag("BlinkMode", 1)
	end
	shield_invuln_counter = delta
  elseif not is_shield_active and shield_check and not GetManagedFlag(g_flags.is_super) then
    PlaySound("obj_common", "barrier")
  end
  is_shield_active = GetContextFlag("IsBarrier")
  
  if GetManagedFlag(g_flags.is_super) then
    if GetPlayerAnim(true) == "wait" then
	  test_timer = test_timer + G_DELTA_TIME
	  if test_timer >= 4 then
	    PlaySound("obj_common", "ring_sparkle")
		test_timer = 0
	  end
	else
	  test_timer = 0
	end
    local name = GetPlayerName()
    if (name == "sonic" or name == "sonic_mach") and GetPlayerState() ~= 48 then 
      SetContextFlag("IsBarrier", true)
	end
	if name == "sonic_mach" or GetMaturityLevel() >= player_reference.sonic_gem_params.super.ring_attraction_level then
	  local thresh = name == "sonic" and player_reference.sonic_gem_params.super.ring_attraction_speed or player_reference.mach_params.SUPER_RING_ATTRACTION_SPD
      if GetPlayerSpeed("total") >= thresh then
	    SetContextFlag("IsThunderGuard", true)
	  else
	    SetContextFlag("IsThunderGuard", false)
	  end
	end
  end
end