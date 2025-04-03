-- @BRIEF: Implementation for Rail Grind states.

--$$ REGISTER BLOCK $$--
RegisterState(PlayerList.sonic, "Grinding", "Grind")
RegisterState(PlayerList.sonic, "Grinding_Crouch", "Grind")
RegisterState(PlayerList.sonic, "Grinding_Trick", "Grind")

RegisterState(PlayerList.tails, "Grinding", "Grind")
RegisterState(PlayerList.tails, "Grinding_Crouch", "Grind")
RegisterState(PlayerList.tails, "Grinding_Trick", "Grind")

RegisterState(PlayerList.knuckles, "Grinding", "Grind")
RegisterState(PlayerList.knuckles, "Grinding_Crouch", "Grind")
RegisterState(PlayerList.knuckles, "Grinding_Trick", "Grind")

RegisterState(PlayerList.shadow, "Grinding", "Grind")
RegisterState(PlayerList.shadow, "Grinding_Crouch", "Grind")
RegisterState(PlayerList.shadow, "Grinding_Trick", "Grind")

RegisterState(PlayerList.rouge, "Grinding", "Grind")
RegisterState(PlayerList.rouge, "Grinding_Crouch", "Grind")
RegisterState(PlayerList.rouge, "Grinding_Trick", "Grind")

RegisterState(PlayerList.omega, "Grinding", "Grind")
RegisterState(PlayerList.omega, "Grinding_Crouch", "Grind")
RegisterState(PlayerList.omega, "Grinding_Trick", "Grind")

RegisterState(PlayerList.silver, "Grinding", "Grind")
RegisterState(PlayerList.silver, "Grinding_Crouch", "Grind")
RegisterState(PlayerList.silver, "Grinding_Trick", "Grind")

RegisterState(PlayerList.blaze, "Grinding", "Grind")
RegisterState(PlayerList.blaze, "Grinding_Crouch", "Grind")
RegisterState(PlayerList.blaze, "Grinding_Trick", "Grind")

RegisterState(PlayerList.amy, "Grinding", "Grind")
RegisterState(PlayerList.amy, "Grinding_Crouch", "Grind")
RegisterState(PlayerList.amy, "Grinding_Trick", "Grind")


local my_lean = "straight" -- Sets whether you're leaning left, right or neutral. Passed to the rail manager.
local speed_cap_normal = 1000
local speed_cap_crouch = 2250
--$$ GENERIC FUNCTIONS $$--
local animation_timer_table = {
  general = { 21/60, 22/60 }, -- Normal, Crouch
  knuckles = { 6/60, 22/60 },
  princess = { 6/60, 22/60 }, -- Princess, specifically
  omega = { 10/60, 25/60 }
}
local anim_reset_frame = 21/60

local function GrindStartup(self)
  SetAlgo(false)
  self.player.slope_params.speed_cap = speed_cap_normal
  self.player.rail_params.use_physics = true
  local player_name = GetPlayerName()
  if player_name == "sonic" and GetManagedFlag(g_flags.is_princess) then
    player_name = "princess"
  end
  if animation_timer_table[player_name] then
    anim_reset_frame = animation_timer_table[player_name][1]
  else
    anim_reset_frame = animation_timer_table.general[1]
  end
end

local function GrindMain(self)
  if GetInput("x") then
    return self:SwitchState("Grinding_Trick")
  elseif GetInput("rt", "hold") then
    return self:SwitchState("Grinding_Crouch")
  end

  local anim_time = GetCurrentAnimationTime()
  if anim_time >= anim_reset_frame then -- 0.35
    SetCurrentAnimationTime(0) -- 3/60
  end
  
  local stickX = GetStickInput("L", "X", true) 
  if stickX >= 0.1 then
    my_lean = "right"
    ChangePlayerAnim(self.anim_ref.lean_R)
  elseif stickX <= -0.1 then
    my_lean = "left"
    ChangePlayerAnim(self.anim_ref.lean_L)
  else
    my_lean = "straight"
	ChangePlayerAnim("grind_l")
  end
  SetRailBalance(my_lean)
end

local function GrindExit(self)
end

local function CrouchStartup(self)
  local player_name = GetPlayerName()
  if player_name == "sonic" and GetManagedFlag(g_flags.is_princess) then
    player_name = "princess"
  end
  if animation_timer_table[player_name] then
    anim_reset_frame = animation_timer_table[player_name][2]
  else
    anim_reset_frame = animation_timer_table.general[2]
  end
  self.player.rail_params.is_crouched = true
  self.player.rail_params.use_physics = true
  SetAlgo(true)
  self.player.slope_params.speed_cap = speed_cap_crouch
end

local function CrouchMain(self)
  if GetInput("x") then
    return self:SwitchState("Grinding_Trick")
  elseif GetInput("rt", "released") then
    return self:SwitchState("Grinding")
  end
  
  local anim_time = GetCurrentAnimationTime()
  if anim_time >= anim_reset_frame then -- 0.34
    SetCurrentAnimationTime(0/60) -- 2/60
  end
  
  local stickX = GetStickInput("L", "X", true) 
  if stickX >= 0.1 then
    my_lean = "right"
    ChangePlayerAnim(self.anim_ref.lean_R)
  elseif stickX <= -0.1 then
    my_lean = "left"
    ChangePlayerAnim(self.anim_ref.lean_L)
  else
    my_lean = "straight"
    ChangePlayerAnim(self.anim_ref.crouch)
  end
  SetRailBalance(my_lean)
end

local function CrouchExit(self)
  self.player.rail_params.is_crouched = false
  SetAlgo(false)
end

local trick_frame_counter = 0 -- Prevents a nasty bug that corrupts the debug log
local function TrickStartup(self)
  self.player.rail_params.use_physics = false
  self.player.slope_params.speed_cap = speed_cap_normal
  trick_frame_counter = 0
  my_lean = "straight"
  SetRailBalance(my_lean)
end

local function TrickMain(self)
  if not GetCurrentAnimation("0x18", true) then
    trick_frame_counter = trick_frame_counter + 1
	if trick_frame_counter >= 5 then
      self:SwitchState("Grinding")
	end
  else
    trick_frame_counter = 0
  end
end

local function TrickExit(self)
  self.player.rail_params.use_physics = true
  trick_frame_counter = 0
end

--$$ SHADOW DECLARATIONS $$--

function PlayerList.shadow.states.Grinding:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  GrindStartup(self)
  return self:StateEnter()
end

function PlayerList.shadow.states.Grinding:StateMain()
  GrindMain(self)
end

function PlayerList.shadow.states.Grinding_Crouch:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  CrouchStartup(self)
  return self:StateEnter()
end

function PlayerList.shadow.states.Grinding_Crouch:StateMain()
  CrouchMain(self)
end

function PlayerList.shadow.states.Grinding_Crouch:StateExit()
  CrouchExit(self)
end

function PlayerList.shadow.states.Grinding_Trick:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  TrickStartup(self)
  return self:StateEnter()
end

function PlayerList.shadow.states.Grinding_Trick:StateMain()
  TrickMain(self)
end

function PlayerList.shadow.states.Grinding_Trick:StateExit()
  TrickExit(self)
end

--$$ ROUGE DECLARATIONS $$--
function PlayerList.rouge.states.Grinding:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  GrindStartup(self)
  return self:StateEnter()
end

function PlayerList.rouge.states.Grinding:StateMain()
  GrindMain(self)
end


function PlayerList.rouge.states.Grinding_Crouch:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  CrouchStartup(self)
  return self:StateEnter()
end

function PlayerList.rouge.states.Grinding_Crouch:StateMain()
  CrouchMain(self)
end

function PlayerList.rouge.states.Grinding_Crouch:StateExit()
  CrouchExit(self)
end

function PlayerList.rouge.states.Grinding_Trick:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  TrickStartup(self)
  return self:StateEnter()
end
function PlayerList.rouge.states.Grinding_Trick:StateMain()
  TrickMain(self)
end
function PlayerList.rouge.states.Grinding_Trick:StateExit()
  TrickExit(self)
end

--$$ OMEGA DECLARATIONS $$--
function PlayerList.omega.states.Grinding:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  GrindStartup(self)
  return self:StateEnter()
end

function PlayerList.omega.states.Grinding:StateMain()
  GrindMain(self)
end


function PlayerList.omega.states.Grinding_Crouch:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  CrouchStartup(self)
  return self:StateEnter()
end

function PlayerList.omega.states.Grinding_Crouch:StateMain()
  CrouchMain(self)
end

function PlayerList.omega.states.Grinding_Crouch:StateExit()
  CrouchExit(self)
end

function PlayerList.omega.states.Grinding_Trick:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  TrickStartup(self)
  return self:StateEnter()
end
function PlayerList.omega.states.Grinding_Trick:StateMain()
  TrickMain(self)
end
function PlayerList.omega.states.Grinding_Trick:StateExit()
  TrickExit(self)
end

--$$ SONIC DECLARATIONS $$--
function PlayerList.sonic.states.Grinding:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  GrindStartup(self)
  return self:StateEnter()
end

function PlayerList.sonic.states.Grinding:StateMain()
  GrindMain(self)
end


function PlayerList.sonic.states.Grinding_Crouch:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  CrouchStartup(self)
  return self:StateEnter()
end

function PlayerList.sonic.states.Grinding_Crouch:StateMain()
  CrouchMain(self)
end

function PlayerList.sonic.states.Grinding_Crouch:StateExit()
  CrouchExit(self)
end

function PlayerList.sonic.states.Grinding_Trick:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  TrickStartup(self)
  return self:StateEnter()
end
function PlayerList.sonic.states.Grinding_Trick:StateMain()
  TrickMain(self)
end
function PlayerList.sonic.states.Grinding_Trick:StateExit()
  TrickExit(self)
end

--$$ TAILS DECLARATIONS $$--
function PlayerList.tails.states.Grinding:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  GrindStartup(self)
  return self:StateEnter()
end

function PlayerList.tails.states.Grinding:StateMain()
  GrindMain(self)
end


function PlayerList.tails.states.Grinding_Crouch:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  CrouchStartup(self)
  return self:StateEnter()
end

function PlayerList.tails.states.Grinding_Crouch:StateMain()
  CrouchMain(self)
end

function PlayerList.tails.states.Grinding_Crouch:StateExit()
  CrouchExit(self)
end

function PlayerList.tails.states.Grinding_Trick:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  TrickStartup(self)
  return self:StateEnter()
end
function PlayerList.tails.states.Grinding_Trick:StateMain()
  TrickMain(self)
end
function PlayerList.tails.states.Grinding_Trick:StateExit()
  TrickExit(self)
end

--$$ KNUCKLES DECLARATIONS $$--
function PlayerList.knuckles.states.Grinding:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  GrindStartup(self)
  return self:StateEnter()
end

function PlayerList.knuckles.states.Grinding:StateMain()
  GrindMain(self)
end

function PlayerList.knuckles.states.Grinding_Crouch:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  CrouchStartup(self)
  return self:StateEnter()
end

function PlayerList.knuckles.states.Grinding_Crouch:StateMain()
  CrouchMain(self)
end

function PlayerList.knuckles.states.Grinding_Crouch:StateExit()
  CrouchExit(self)
end

function PlayerList.knuckles.states.Grinding_Trick:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  TrickStartup(self)
  return self:StateEnter()
end

function PlayerList.knuckles.states.Grinding_Trick:StateMain()
  TrickMain(self)
end

function PlayerList.knuckles.states.Grinding_Trick:StateExit()
  TrickExit(self)
end

--$$ SILVER DECLARATIONS $$--
function PlayerList.silver.states.Grinding:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  GrindStartup(self)
  return self:StateEnter()
end

function PlayerList.silver.states.Grinding:StateMain()
  GrindMain(self)
end

function PlayerList.silver.states.Grinding_Crouch:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  CrouchStartup(self)
  return self:StateEnter()
end

function PlayerList.silver.states.Grinding_Crouch:StateMain()
  CrouchMain(self)
end

function PlayerList.silver.states.Grinding_Crouch:StateExit()
  CrouchExit(self)
end

function PlayerList.silver.states.Grinding_Trick:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  TrickStartup(self)
  return self:StateEnter()
end

function PlayerList.silver.states.Grinding_Trick:StateMain()
  TrickMain(self)
end

function PlayerList.silver.states.Grinding_Trick:StateExit()
  TrickExit(self)
end

--$$ BLAZE DECLARATIONS $$--
function PlayerList.blaze.states.Grinding:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  GrindStartup(self)
  return self:StateEnter()
end

function PlayerList.blaze.states.Grinding:StateMain()
  GrindMain(self)
end


function PlayerList.blaze.states.Grinding_Crouch:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  CrouchStartup(self)
  return self:StateEnter()
end

function PlayerList.blaze.states.Grinding_Crouch:StateMain()
  CrouchMain(self)
end

function PlayerList.blaze.states.Grinding_Crouch:StateExit()
  CrouchExit(self)
end

function PlayerList.blaze.states.Grinding_Trick:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  TrickStartup(self)
  return self:StateEnter()
end
function PlayerList.blaze.states.Grinding_Trick:StateMain()
  TrickMain(self)
end
function PlayerList.blaze.states.Grinding_Trick:StateExit()
  TrickExit(self)
end

--$$ AMY DECLARATIONS $$--
function PlayerList.amy.states.Grinding:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  GrindStartup(self)
  return self:StateEnter()
end

function PlayerList.amy.states.Grinding:StateMain()
  GrindMain(self)
end


function PlayerList.amy.states.Grinding_Crouch:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  CrouchStartup(self)
  return self:StateEnter()
end

function PlayerList.amy.states.Grinding_Crouch:StateMain()
  CrouchMain(self)
end

function PlayerList.amy.states.Grinding_Crouch:StateExit()
  CrouchExit(self)
end

function PlayerList.amy.states.Grinding_Trick:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  TrickStartup(self)
  return self:StateEnter()
end
function PlayerList.amy.states.Grinding_Trick:StateMain()
  TrickMain(self)
end
function PlayerList.amy.states.Grinding_Trick:StateExit()
  TrickExit(self)
end