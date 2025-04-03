-- @BRIEF: Super Sonic behavior manager. Implemented through the EventManager system.

local is_transforming = false
g_is_super_active = false
USE_SUPER_CUTSCENE = true
initial_rings = 0
local last_rings = 0
local swap_by_amigo = false

local HUD_COLOR_IDX = 0 -- Sonic's idx in the HUD colors array
local HUD_KEYFRAME_SUPER = 3
local HUD_KEYFRAME_SONIC = 0

function Custom.SuperSonic.Step(self, delta)
  if not Player(0):IsValidPTR() then return end
  
  if GetPlayerName() == "sonic" and not GetManagedFlag(g_flags.is_super) then
    if player_reference.sonic_gem_params.super.USE_RING_REQ then
	  if GetRingCount() < player_reference.sonic_gem_params.super.ring_requirement then
	    SetGaugeParameter("c_super", 101)
	  else
	    SetGaugeParameter("c_super", player_reference.sonic_gem_params.super.gauge_drain_by_level[GetMaturityLevel()])
	  end
	end
  end
  if GetPlayerAnim(true) == "super" and not is_transforming and not GetManagedFlag(g_flags.is_super) then
    is_transforming = true
	StartEvent("SwapToSuper")
  end
  if is_transforming and g_is_super_active then
    StartEvent("ManageSuper")
  end
  if not g_is_super_active and GetManagedFlag(g_flags.is_super) then
    if not Player(0):IsValidPTR() then return end
	if sonic_variant == 0 then
	  g_is_super_active = true
	  PlayerSwap("sonic_super")
	  SetHUDKeyFrame(HUD_KEYFRAME_SUPER, HUD_COLOR_IDX)
	  CallUIIndex("life", "character_icon", 10)
	  CallUIAnim("life", "in")
	  CallUIAnim("life_ber_anime", "super_in")
	  StartEvent("ManageSuper")
	elseif sonic_variant == 4 then
	  if GetPlayerName() == "sonic_mach" then
	    g_is_super_active = true
	    --PlayerSwap("super_mach")
		SetHUDKeyFrame(HUD_KEYFRAME_SONIC, HUD_COLOR_IDX)
	    initial_rings = GetRingCount()
	    StartEvent("ManageSuper")
	  end
	end
  end
  if swap_by_amigo and GetPlayerName() == "sonic" then
    swap_by_amigo = false
	if GetPlayerState() ~= 41 then 
	  CallUIIndex("life", "character_icon", 0)
	  CallUIAnim("life", "in")
	  CallUIAnim("life_ber_anime", "sonic_in")
	  ResetSuperAttributes()
	  return 
	else
      g_is_super_active = true
	  SetManagedFlag(g_flags.is_super, true)
	  SetHUDKeyFrame(HUD_KEYFRAME_SUPER, HUD_COLOR_IDX)
	  CallUIIndex("life", "character_icon", 10)
	  CallUIAnim("life", "in")
	  CallUIAnim("life_ber_anime", "super_in")
	  StartEvent("ManageSuper")
	end -- This is ONLY for the Orca rn
  end
end

function UpdateCutsceneCamera(my_eye, my_tgt)
  Game.ProcessMessage("LEVEL", "FixCamera", {
    eye = my_eye,
    target = my_tgt
  })
end

function SwapToSuper()
  if player_reference.USE_EMERALDS then
    PlayProcess("OT")
  end
  local plr = Player(0)
  plr:Reload()
  --plr:SetStateID(75)
  WaitFor(1/60)
  initial_rings = GetRingCount()
  last_rings = initial_rings
  SetPlayerState(23)
  SetPlayerSpeed("x", 0, false)
  SetPlayerSpeed("x", 0, true)
  SetInputLockout(88/60)
  WaitFor(1/60)
  ChangePlayerAnim("super")
  local pos = GetPlayerPos()
  --local cam = Player(0):GetCamera()
  --local c_pos = cam:GetPosition()
  --local c_rot = cam:GetRotation()
  local tgt = {pos.X, pos.Y + 50, pos.Z}
  local eye = {pos.X + -300, pos.Y + 200, pos.Z + 250}
  --Game.NewActor("particle",{bank="enemycommon", name = "super_activate", cycle = 0, cyclewidth = 0, sebank = "", sename = ""},{Position = Vector(pos.X,pos.Y + 75,pos.Z) , Rotation = Vector(1,0,0,0)})
  --PlaySound("obj_common", "lightcore")
  PlaySound("player_sonic", "super")
  PlaySound("player_sonic", "homing_charge")
  if USE_SUPER_CUTSCENE then
    UpdateCutsceneCamera(eye, tgt)
    local ACCEL_BIAS_X, ACCEL_BIAS_Y, ACCEL_BIAS_Z = 2.5, 2, 1 -- Acceleration multipliers for the camera coords during the cutscene
    --for i = 1, 120 do  -- VALUES SYNCED FOR 2 SECONDS
    --for i = 1, 98 do -- VALUES SYNCED TO SPAWN OF PARTICLE
    for i = 1, 87 do
	  if eye[1] < pos.X + 424 then --500    424
	    eye[1] = eye[1] + (4.1666667) * ACCEL_BIAS_X
	  end
	  if eye[2] > pos.Y + 50 then --50
	    eye[2] = eye[2] + (-1.6667) * ACCEL_BIAS_Y
	  end
	  if eye[3] > pos.Z + 38 then --38
	    eye[3] = eye[3] + (-2.083333) * ACCEL_BIAS_Z
	  end
	  UpdateCutsceneCamera(eye, tgt)
	  if i == 82 then
	    CallUIAnim("life", "out")
		CallUIAnim("life_ber_anime", "sonic_out")
	  end
	  WaitFor(1/60)
    end
  else
    WaitFor(87/60)
  end
  PlaySound("system", "deside")
  PlayerSwap("sonic_super")
  SetContextFlag("IsTornadoEnabled", true)
  SetTornadoHitbox(0)
  SetHUDKeyFrame(HUD_KEYFRAME_SUPER, HUD_COLOR_IDX)
  CallUIAnim("life", "in")
  CallUIAnim("life_ber_anime", "super_in")
  CallUIIndex("life", "character_icon", 10)
  WaitFor(1/60) -- Wait a frame before trying to set a new animation
  --SetContextFlag("IsTornadoEnabled", false)
  PlaySound("obj_common", "ring_sparkle")
  SetContextFlag("IsInvulnItem", true)
  local damage_rates = player_reference.sonic_gem_params.super.my_damage_rates
  SetPluginValue("zock", "c_sliding_damage", damage_rates.c_sliding_damage)
  SetPluginValue("homing", "c_homing_damage", damage_rates.c_homing_damage)
  ChangePlayerAnim("fly") -- Continue the super anim from the "pop-off" moment. Thanks to Fen for splitting the anim.
  --SetCurrentGem("super")
  ResetCameraTest()
  SetInputLockout(34/60)
  local hitbox_radius = 0
  WaitFor(5/60)
  for i = 1, 11 do
    hitbox_radius = hitbox_radius + 0.3
	SetTornadoHitbox(hitbox_radius)
    WaitFor(1/60)
  end
  SetContextFlag("IsTornadoEnabled", false)
  WaitFor(18/60) -- Let the animation finish, then go back to idle --34
  SetPlayerState(0)
  ChangePlayerAnim("wait")
  g_is_super_active = true
  SetManagedFlag(g_flags.is_super, true)
  SetGaugeParameter("c_super", 101)
  if USE_SUPER_CUTSCENE then
    --ResetCameraTest()
    --tgt = {pos.X, pos.Y, pos.Z} -- Reset the camera back to where the player had it
    --eye = {c_pos[1], c_pos[2], c_pos[3]}
    --UpdateCutsceneCamera(eye, tgt)
  end
end

function ResetSuperAttributes()
  local base_jump, base_run, base_jump_run = player_reference.base_jump_speed_default, player_reference.max_run_spd_default, player_reference.slope_params.BASE_JUMP_RUN_DEFAULT
  player_reference.base_jump_speed = base_jump
  player_reference.max_run_spd = base_run
  player_reference.slope_params.base_jump_run = base_jump_run
  SetPlayerLuaValue("c_jump_speed", base_jump)
  SetPlayerLuaValue("c_run_speed_max", base_run)
  SetPlayerLuaValue("c_run_acc", player_reference.run_acc_default)
  SetPlayerLuaValue("c_jump_run", base_jump_run)
  SetPluginValue("zock", "c_sliding_damage", 1)
  SetPluginValue("homing", "c_homing_damage", 1)
  SetGaugeParameter("c_super", 100)
end

local function Detransform()
  g_is_super_active = false
  SetManagedFlag(g_flags.is_super, false)
  SetRingCount(0)
  SetHUDRings(0)
  while GetInputLockout() ~= 0 do
    WaitFor(1/60)
  end
  CallUIAnim("life", "out")
  CallUIAnim("life_ber_anime", "super_out")
  local character = sonic_variant == 4 and "sonic_mach" or "sonic_new"
  PlayerSwap(character)
  SetInputLockout(10/60)
  WaitFor(1/60)
  SetHUDKeyFrame(HUD_KEYFRAME_SONIC, HUD_COLOR_IDX)
  local pos = GetPlayerPos()
  Game.NewActor("particle",{bank="player_metal", name = "boot_flare", cycle = 0, cyclewidth = 0, sebank = "", sename = ""},{Position = Vector(pos.X,pos.Y + 50,pos.Z) , Rotation = Vector(1,0,0,0)})
  Game.NewActor("particle",{bank="player_metal", name = "gage_up_g", cycle = 0, cyclewidth = 0, sebank = "", sename = ""},{Position = Vector(pos.X,pos.Y + 50,pos.Z) , Rotation = Vector(1,0,0,0)})
  ResetSuperAttributes()
  ChangePlayerAnim("landing")
  SetCurrentGem("super")
  SetContextFlag("IsInvulnItem", false)
  SetContextFlag("SlideHitbox", false)
  SetSonicSlideFlags("0x1C80")
  PlaySound("obj_common", "dashring")
  PlaySound("obj_common", "chaosdrive_get")
  WaitFor(4/60)
  CallUIIndex("life", "character_icon", 0)
  CallUIAnim("life", "in")
  CallUIAnim("life_ber_anime", "sonic_in")
end

function ManageSuper()
  is_transforming = false
  while g_is_super_active do
    local name = GetPlayerName()
    if (name ~= "sonic" and name ~= "sonic_mach" and name ~= "sonic_super") or GetPlayerState() == 48 then
	  swap_by_amigo = true
	  g_is_super_active = false
	  SetManagedFlag(g_flags.is_super, false)
	  --ResetSuperAttributes()
	  --SetRingCount(initial_rings) -- Active
	  break
	end
    if GetCurrentGem() ~= "super" then SetCurrentGem("super") end
    SetContextFlag("IsInvulnItem", true)
	SetContextFlag("SlideHitbox", true)
	if GetPlayerState() ~= 68 and GetPlayerName() ~= "sonic_mach" then
	  SetSonicSlideFlags("0x1000") -- 1080
	else
	  SetSonicSlideFlags("0x1C80")
	end
	local real_rings = GetRingCount()
	if real_rings > last_rings then
	  local diff = real_rings - last_rings
	  --initial_rings = initial_rings + diff
	end
	--initial_rings = initial_rings - 1
	--last_rings = real_rings
	local my_rings = GetRingCount()
	my_rings = mMax(0, my_rings - 1)
	SetRingCount(my_rings)
	if my_rings >= 1 then --initial_rings >= 0 and real_rings > 0 then
	  --SetHUDRings(initial_rings)
	  WaitFor(1)
	  if initial_rings > 0 then -- Only delay if the player is left with 1 or more rings, otherwise drop to 0 and instantly detransform
	    --WaitFor(1)
	  else
	    --SetHUDRings(initial_rings)
	  end
	else
	  Detransform()
	end
  end
end