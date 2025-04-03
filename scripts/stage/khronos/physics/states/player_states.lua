-- NOTE: This is *not* a manager for the game's actual states. This is a helper script for any new stuff I want to add, like
-- balancing or crouching on rails. This particular script sets up the base state stuff. Individual state scripts are brought in at the
-- bottom of this file.

-- This is sort of a bad way to do exit functions, but it'll work for my purposes.
----------CLASS EXIT BLOCK----------
function DefaultReturnHandler()
  return
end
function ResetRailParams()
  player_reference.rail_params.balance_multiplier = 1.0
  player_reference.rail_params.balance_state = "balanced"
  player_reference.rail_params.use_physics = false
  player_reference.rail_params.is_crouched = false
  player_reference.slope_params.speed_cap = 3300
end
------------------------------------
PlayerList = {
  general = {
    slope_params = { -- Variable list for slope physics. Affects top accel/deccel and the like
	  MASS = 20,
	  GRAVITY = 9.8 * 100,
	  MAX_SPEED = 1700, -- Top running speed of the player. Used to calculate slope angle by speed.
	  BASE_ROTATION_SPEED = 800, -- c_rotation_speed default value. Lower values = larger turning radius.
	  BASE_ROTATION_BORDER = 0, -- c_rotation_speed_border default value. Higher values = tighter turns (but not necessarily the opposite).
	  DOWNWARDS_BIAS = 1.1, -- Speed multiplier when going downhill
	  UPWARDS_BIAS = 0.9, -- Lightens deceleration when going uphill
	  TOP_AIR_SPEED = 0, -- Maximum gimmick speed while airborne. Unused currently
	  SLIPBACK_ANGLE = 46, -- Angle of the slope before initiating a slipback (at low speed). Currently unused.
	  SLIPBACK_RETURN = 25, -- Angle before exiting a slipback. Currently unused.
	  ROLL_RESTRICTED_HIGH_SPD = 4000, -- While rolling, shift to more aggressive rotation resistance when above this speed.
	  ROLL_RESTRICTED_MID_SPD = 2250,
	  ROLL_CONSTANT_BRAKE = 50/60, -- Constant speed decay on roll. Value should be small.
	  ROLL_GRAVITY_MULTIPLIER = 1.75, -- Multiplier on Gravity Force while rolling
	  speed_cap = 3300, -- Speed softcap, adjusted during rolls/grinding/etc. Not applied while input is locked.
	},
	mach_params = {
	  RUN_MAX_SPEED = 8000,
	  RUN_MAX_SPEED_SUPER = 9000, -- Speed value for Super Sonic
	  MIN_GROUND_SPEED = 1500,
	  MIN_GROUND_SPEED_SUPER = 2000,
	  ACCELERATION_RATE = 312.5 * 2, -- Grounded acceleration
	  DECELERATION_RATE = 2000, -- Grounded deceleration
	  MAX_AIR_SPEED = 8000, -- Speed to target when the left stick is held
	  MAX_AIR_SPEED_SUPER = 9000,
	  MIN_AIR_SPEED = 3000, -- Speed to target when the left stick is released
	  MIN_AIR_SPEED_SUPER = 4000,
	  AIR_ACCELERATION_RATE = 312.5 * 2.5,
	  AIR_DECELERATION_RATE = 1500,
	  BASE_JUMP_SPEED = 900, -- Initial jump impulse
	  BASE_JUMP_SPEED_SUPER = 1100,
	  BASE_MIN_JUMP = 150, -- Lowest vertical speed while jumping
	  BASE_MIN_JUMP_SUPER = 250,
	  JUMP_BRAKE = 1800, -- Vertical decel rate when releasing A
	  MACH_GRAVITY_MULTIPLIER = 2.65, -- Multiplier on gravity rate outside of automation (980 * this)
	  MAX_LAUNCH_UP = 4000, -- Maximum vertical speed applied by a slope launch
	  MAX_LAUNCH_DOWN = -1000, -- Highest vertical speed (applied downward) by a slope launch
	  stumble_threshold = 4500, -- Sustain damage if at or above this speed threshold on collision
	  DAMAGE_DECEL_RATE = 1000, -- Speed reduction whil in the Damage state
	  BONK_THRESHOLD = 1500, -- Enter the bonk state if above this speed. Otherwise, allow Sonic to remain idle
	  AIR_BONK_THRESHOLD = 5500, -- (Jumping) Enter bonk in the air if above this speed
	  damage_invuln_time = 1.25, -- Time to remain in the damage state
	  bonk_time = 1, -- Time to remain in the bonk state
	  starting_time = 1.1,
	  STARTING_LAUNCH = 4000, -- Impulse when exiting the Starting state
	  STARTING_LAUNCH_SUPER = 4500,
	  JOG_ANIM_THRESHOLD = 1000, -- Set animation by speed value
	  RUN_ANIM_THRESHOLD = 2250,
	  DASH_ANIM_THRESHOLD = 3250,
	  JET_ANIM_THRESHOLD = 5000,
	  bonk_spd = -1000, -- Impulse applied when entering the Bonk state
	  MACH_AURA_ENABLE_SPD = 7000, -- Enable the Blue Gem particles and a hitbox if above this speed
	  MACH_AURA_DISABLE_SPD = 6000, -- Once enabled, turn the aura off if the player drops below this speed
	  SUPER_RING_ATTRACTION_SPD = 2000,
	},
	rail_params = { -- Variables for the new rail mechanics.
	  MAX_RAIL_SPEED = 6000, -- Maximum attainable base speed while grinding.
	  MAX_CROUCH_SPEED = 6000,
	  MIN_RAIL_SPEED = 1500, -- Lowest possible base speed while grinding.
	  MIN_CROUCH_SPEED = 250, --250,
	  ["balanced"] = { -- Parameters to use while properly balanced.
	    MAX_SPEED_MULTIPLIER = 1.2, -- Maximum speed multiplier attainable while balanced.
		MIN_SPEED_MULTIPLIER = 0.75, -- Mininimum speed multiplier attainable. Quickly accelerate to this value if below it.
		CROUCH_MAX_MULTIPLIER = 1.5, -- Maximum multiplier while crouched.
		CROUCH_MIN_MULTIPLIER = 0.5 -- Minimum multiplier while crouched. Quickly accelerate to this value if below it while crouched.
	  },
	  ["unbalanced"] = { -- Parameters to use while slightly off balance (neutral on a curve, leaning on a straightaway.)
	    MAX_SPEED_MULTIPLIER = 0.85,
		MIN_SPEED_MULTIPLIER = 0.65, 
		CROUCH_MAX_MULTIPLIER = 0.75, 
		CROUCH_MIN_MULTIPLIER = 0.35 
	  },
	  ["flailing"] = { -- Parameters to use while very off balance (incorrect lean on a curve, any mistake while crouching.)
	    MAX_SPEED_MULTIPLIER = 0.5,
		MIN_SPEED_MULTIPLIER = 0.35, 
		CROUCH_MAX_MULTIPLIER = 0.35, 
		CROUCH_MIN_MULTIPLIER = 0.15 
	  },
	  balance_multiplier = 1.0, -- Current speed multiplier, clamped by your balance state.
	  balance_state = "balanced",
	  use_physics = false, -- Toggles on when you're crouching, enables gravitational acceleration and the like.
	  is_crouched = false
	},
	custom_gauge_params = {
	  action_gauge_regen_valid = false, -- Gauge can regen over time
	  action_gauge_use_regen_delay = true, -- After expending meter, delay slightly before regenerating
	  action_gauge_regen_delay = 0.5, -- Time to delay before resuming regeneration
	  current_action_gauge = 0, -- Float between 0 and 1, tracks the gauge's visual
	  action_gauge_time_add = 1/60, -- Amount to increase the Gauge by per frame
	  action_gauge_core_add = 10/100, -- Amount to increase the Gauge by when collecting a Light Core/Chaos Drive.
	  action_gauge_maturity_valid = false, -- Maturity Bar can increase when grabbing a Core/Drive
	  action_gauge_maturity_current = 0, -- Float between 0 and 1, Maturity Bar visual
	  action_gauge_maturity_level_initial = 0, -- Starting value for the Maturity Level. Defaults back to this on death/restart
	  action_gauge_maturity_level = 0, -- Current Maturity Level
	  action_gauge_maturity_add = 0.34, -- Increase for the Maturity Bar when collecting a Core/Drive
	},
	powerup_params = {
	  shield_invuln_time = 2, -- Time in seconds after a shield breaks
	},
	base_jump_speed_default = 900,
	base_jump_speed = 900,
  },
  sonic = {
    custom_anims = { -- Used for setting the proper anim IDs with ChangeAnim
	  Grinding = { -- Anim set for new grinding mechanics
	    lean_L = "overdrive",
		lean_R = "overdrive_l",
		
		grind_loop = "grind_l", -- These are just used to register the normal grind anims as part of the grinding state as well
		grind_trick = "grindturn_l"
	  },
	  Grinding_Crouch = {
	    crouch = "teleport_dash_l",
	    lean_L = "esp_one_l", -- Placeholders until I can get a crouch lean anim
		lean_R = "esp_one_r"
	  },
	  Rolling = {
		charge = "fly",
		charge_super = "super_fly_down",
	    default = "jump_alt",
		release = "spindash"
	  },
	  SpinDash = {
	    
	    default = "spindash",
	  },
	  Attacking = { 
	    default = "attack",
		jumpup = "jumpup",
		sault = "bungee_fly",
		sliding = "sliding",
		slide_stand = "sliding_stand"
	  },
	  Plugins = {
	    badnik_bounce = "bounce"
	  }
	},
	custom_sounds = {
	  badnik_bounce = { impact = {"player_sonic", "boundattack"}, dash = {"player_sonic", "homing_shoot"} }
	},
	base_jump_speed_default = 900, -- Used to restore jump height if something modifies the following value
	base_jump_speed = 900, -- Retail max height attainable during a jump
	max_run_spd_default = 1700, -- Used to restore max run spd if something modifies the following value
	max_run_spd = 1700, -- Should match the value defined in the character's lua script
	downforce_override = false, -- Prevents downforce from being set on slopes. Activated during certain states.
	action_gauge_function = nil, -- Assigned in another script
	bound_accel_rate = 450,
	bound_decel_rate = 1000,
	bound_spd_min = 900,
	bound_decel_rate_idle = 2000,
	custom_gauge_params = {
	  action_gauge_regen_valid = false, -- Relying on the patch
	  action_gauge_maturity_valid = true,
	  action_gauge_maturity_level_initial = 1,
	  action_gauge_core_add = 15,
	},
	sonic_gem_params = {
	  none = {
	    current_maturity_value = 0, -- Bar
	    current_maturity_level = 1,
	    gauge_heal_delay_by_level = { 0.75, 0.5, 0.25 }, -- Delay before resuming gauge heal
	    gauge_heal_rate_by_level = { 25, 50, 75 } -- Amount of points restored per second
	  },
	  green = {
		current_maturity_value = 0, -- Bar
		current_maturity_level = 1,
		gauge_drain_by_level = { 50, 30, 20 },
		lua_values_by_level = {
		  [1] = {},
		  [2] = {},
		  [3] = {}
		},
		max_move_spd = 900, -- Maximum speed while in the grounded tornado state
		max_move_by_level = {
		  [1] = 350,
		  [2] = 600,
		  [3] = 900
		},
		move_acc_rate = 900/60, -- Acceleration rate, used when the left stick isn't neutral
		move_dec_rate = 1800/60, -- Deceleration rate when the stick is neutral
	  },
	  red = {
		current_maturity_value = 0, -- Bar
		current_maturity_level = 1,
		gauge_drain_by_level = { 75, 50, 20 },
		lua_values_by_level = {
		  [1] = {},
		  [2] = {},
		  [3] = {}
		},
		max_level_speed_bonus = 0.5 -- Additional timescale multiplier when the gem is used at max level.
	  },
	  blue = {
		current_maturity_value = 0, -- Bar
		current_maturity_level = 1,
		gauge_drain_by_level = { 33, 25, 20 },
		lua_values_by_level = {
		  [1] = { c_custom_action_machspeed_time = 0.0   },
		  [2] = { c_custom_action_machspeed_time = 0.0   },
		  [3] = { c_custom_action_machspeed_time = 0.0   }
		},
		hitbox_duration = 30, -- Time given in frames. Duration of the hitbox at max level
	  },
	  white = {
		current_maturity_value = 0, -- Bar
		current_maturity_level = 1,
		gauge_drain_by_level = { 33, 33, 33 },
		lua_values_by_level = {
		  [1] = { c_homing_smash_charge = 0.5  },
		  [2] = { c_homing_smash_charge = 0.25 },
		  [3] = { c_homing_smash_charge = 0    }
		},
		smash_max_charge = 4000, -- Maximum additional speed from White Gem
		smash_charge_rate = 500/60 -- Additional speed accrued by the White Gem while charging
	  },
	  sky = {
		current_maturity_value = 0, -- Bar
		current_maturity_level = 1,
		gauge_drain_by_level = { 70, 50, 30 },
		lua_values_by_level = {
		  [1] = {},
		  [2] = {},
		  [3] = {}
		}
	  },
	  yellow = {
		current_maturity_value = 0, -- Bar
		current_maturity_level = 1,
		gauge_drain_by_level = { 60, 40, 20 },
		lua_values_by_level = {
		  [1] = {},
		  [2] = {},
		  [3] = {}
		}
	  },
	  purple = {
		current_maturity_value = 0, -- Bar
		current_maturity_level = 1,
		gauge_drain_by_level = { 33, 25, 15 },
		lua_values_by_level = {
		  [1] = {c_scale_jump_speed = 0.5 * 900},
		  [2] = {c_scale_jump_speed = 0.75 * 900},
		  [3] = {c_scale_jump_speed = 1 * 900}
		},
		air_drag_rate = 1,
		air_drag_by_level = {
		  [1] = 0.75,
		  [2] = 0.5,
		  [3] = 0,
		}
	  },
	  super = {
	    USE_RING_REQ = true, -- Controls whether you need a certain number of rings to transform
		ring_requirement = 50, -- Transformation requirement, if applicable
		current_maturity_value = 0, -- Bar
		current_maturity_level = 1,
		gauge_drain_by_level = { 100, 100, 100 },
		lua_values_by_level = {
		  [1] = {},
		  [2] = {},
		  [3] = {}
		},
		my_damage_rates = { -- Easier to access this info across scripts
		  c_sliding_damage = 1, -- Contact damage rate
		  c_homing_damage = 1,
		},
		additional_values_by_level = {
		  [1] = { 
		    {param = "c_sliding_damage", value = 1, is_plugin = true, plugin_name = "zock"}, 
			{param = "c_homing_damage", value = 1, is_plugin = true, plugin_name = "homing"}, 
			{param = "c_jump_speed", value = 900, is_plugin = false},
			{param = "c_run_speed_max", value = 1700, is_plugin = false}, -- Might be an issue if player lua doesn't match
		  },
		  [2] = { 
		    {param = "c_sliding_damage", value = 2, is_plugin = true, plugin_name = "zock"},
			{param = "c_homing_damage", value = 2, is_plugin = true, plugin_name = "homing"},
			{param = "c_jump_speed", value = 1000, is_plugin = false},
			{param = "c_run_speed_max", value = 1900, is_plugin = false}, -- Might be an issue if player lua doesn't match
		  },
		  [3] = { 
		    {param = "c_sliding_damage", value = 3, is_plugin = true, plugin_name = "zock"},
			{param = "c_homing_damage", value = 3, is_plugin = true, plugin_name = "homing"},
			{param = "c_jump_speed", value = 1100, is_plugin = false},
			{param = "c_run_speed_max", value = 2100, is_plugin = false}, -- Might be an issue if player lua doesn't match
		  },
		},
		flight_values_by_level = {
		  -- Drain/Sec, instant on activation, max horizontal speed, deceleration if above top speed, acceleration when ascending/descending
		  [1] = {cost = 50, initial = 10, top_speed = 2000, over_run_decel = 1000, up_rate = 750, down_rate = -1250},
		  [2] = {cost = 32.5, initial = 10, top_speed = 2100, over_run_decel = 1000, up_rate = 850, down_rate = -1350},
		  [3] = {cost = 25, initial = 10, top_speed = 2500, over_run_decel = 1000, up_rate = 950, down_rate = -1450},
		},
		ring_attraction_speed = 2500, -- Speed threshold for ring attraction
		ring_attraction_level = 2, -- Minimum gem level before ring attraction can kick in
	  }
	},
	current_state = "Init",
	current_class = "none",
	classes = { -- Somewhat optional, states can register under a class. Makes it easier to detect when you should be in a state.
	  Grind = { anims = {}, Reset = ResetRailParams, root_state = 12 },
	  Roll = { anims = {}, Reset = DefaultReturnHandler, root_state = 23 },
	  Flight = { anims = {}, Reset = DefaultReturnHandler, root_state = 23 },
	  Smash = { anims = {}, Reset = DefaultReturnHandler, root_state = 65 },
	  Attack = { anims = {}, Reset = DefaultReturnHandler, root_state = 69 },
	  Bound = { anims = {}, Reset = DefaultReturnHandler, root_state = 71 },
	  Tornado = { anims = {}, Reset = DefaultReturnHandler, root_state = 74 }
	},
	states = {}, -- Populated by RegisterState
	state_id_list = { -- Pairs a stateID to a Lua state. Used to transition from Init to a proper state.
	  --["0x17"] = "Grinding",
	  --["0x45"] = "Attacking",
	  --["0x52"] = "Rolling"
	  [12] = "Grinding",
	  [65] = "Smashing",
	  [68] = "Attacking", -- Antigrav
	  [69] = "Attacking", -- Edge attack
	  [70] = "Rolling",
	  [71] = "Bounding",
	  [74] = "Tornadoing"
	},
	state_plugins = {} -- Populated by RegisterStatePlugin. Pairs a string handle to a function
  },
  sonic_mach = {
    custom_anims = { -- Used for setting the proper anim IDs with ChangeAnim
	  ChainJumping = { fall = "fall", move = "run", land = "landing" }
	},
	custom_sounds = {
	  badnik_bounce = { impact = {"player_sonic", "boundattack"}, dash = {"player_sonic", "homing_shoot"} }
	},
	base_jump_speed_default = 900,
	base_jump_speed = 900, -- Retail max height attainable during a jump
	max_run_spd_default = 8000,
	max_run_spd = 8000, -- Should match the value defined in the character's lua script
	downforce_override = false, -- Prevents downforce from being set on slopes. Activated during certain states.
	current_state = "Init",
	current_class = "none",
	classes = { -- Somewhat optional, states can register under a class. Makes it easier to detect when you should be in a state.
	  Start = { anims = {}, Reset = DefaultReturnHandler, root_state = 23 },
	  Jump = { anims = {}, Reset = DefaultReturnHandler, root_state = 23 },
	  Fall = { anims = {}, Reset = DefaultReturnHandler, root_state = 23 },
	  Damage = { anims = {}, Reset = DefaultReturnHandler, root_state = 23 },
	  Bonk = { anims = {}, Reset = DefaultReturnHandler, root_state = 23 },
	  ChainJump = { anims = {}, Reset = DefaultReturnHandler, root_state = 31 }
	},
	states = {}, -- Populated by RegisterState
	state_id_list = {}, -- Pairs a stateID to a Lua state. Used to transition from Init to a proper state.
	state_plugins = {} -- Populated by RegisterStatePlugin. Pairs a string handle to a function
  },
  tails = {
    custom_anims = { -- Used for setting the proper anim IDs with ChangeAnim
	  Grinding = { -- Anim set for new grinding mechanics
	    lean_L = "overdrive_l",
		lean_R = "overdrive",
		
		grind_loop = "grind_l", -- These are just used to register the normal grind anims as part of the grinding state as well
		grind_trick = "grindturn_l"
	  },
	  Grinding_Crouch = {
	    crouch = "teleport_dash_l",
	    lean_L = "esp_one_l", -- Placeholders until I can get a crouch lean anim
		lean_R = "esp_one_r"
	  },
	  Rolling = {
		
	    default = "jump_alt",
		release = "spindash"
	  },
	  Plugins = {
	    badnik_bounce = "jump"
	  }
	},
	custom_sounds = {
	  badnik_bounce = { impact = {"enemy_robot_common", "ImpactL"}, dash = {"player_tails", "bomb_throw"} }
	},
	flight_params = {
	  flight_decel = 1000/60, -- Force subtracted when not holding the A button
	  gauge_brake = 1/180, -- Gauge decrease rate while holding A
	  gauge_brake_idle = (1/180)/2, -- decrease rate while not holding A
	  brake_by_level = {   
	    [1] = { gauge_brake = 1/120, gauge_brake_idle = (1/120)/2 },
		[2] = { gauge_brake = 1/180, gauge_brake_idle = (1/180)/2 },
		[3] = { gauge_brake = 1/240, gauge_brake_idle = (1/240)/2 },
	  },
	},
	base_jump_speed_default = 900,
	base_jump_speed = 900, -- max height attainable during a jump
	max_run_spd_default = 1500,
	max_run_spd = 1500,
	downforce_override = false, -- Prevents downforce from being set on slopes. Activated during certain states.
	action_gauge_function = nil, -- Assigned in another script
	custom_gauge_params = {
	  action_gauge_regen_valid = true,
	  action_gauge_use_regen_delay = false,
	  action_gauge_maturity_valid = true,
	  action_gauge_maturity_level_initial = 1,
	  -- Level/Meter Amount might be better off in here so that characters can store state independently
	},
	current_state = "Init",
	current_class = "none",
	classes = { -- Somewhat optional, states can register under a class. Makes it easier to detect when you should be in a state.
	  Grind = { anims = {}, Reset = ResetRailParams, root_state = 12 },
	  Roll = { anims = {}, Reset = DefaultReturnHandler, root_state = 23 },
	  Attack = { anims = {}, Reset = DefaultReturnHandler, root_state = 23 },
	  Fly = { anims = {}, Reset = DefaultReturnHandler, root_state = 44 },
	},
	states = {}, -- Populated by RegisterState
	state_id_list = { -- Pairs a stateID to a Lua state. Used to transition from Init to a proper state.
	  [12] = "Grinding",
	  [44] = "Flying"
	},
	state_plugins = {} -- Populated by RegisterStatePlugin. Pairs a string handle to a function
  },
  knuckles = {
    custom_anims = { -- Used for setting the proper anim IDs with ChangeAnim
	  Grinding = { -- Anim set for new grinding mechanics
	    lean_L = "overdrive",
		lean_R = "overdrive_l",
		
		grind_loop = "grind_l", -- These are just used to register the normal grind anims as part of the grinding state as well
		grind_trick = "grindturn_l"
	  },
	  Grinding_Crouch = {
	    crouch = "teleport_dash_l",
	    lean_L = "esp_one_l",
		lean_R = "esp_one_r"
	  },
	  Rolling = {
	    default = "jump_alt",
	  },
	  Plugins = {
	    badnik_bounce = "jump"
	  }
	},
	custom_sounds = {
	  badnik_bounce = { impact = {"enemy_robot_common", "ImpactL"}, dash = {"player_knuckles", "punch"} }
	},
	base_jump_speed = 900, -- max height attainable during a jump
	max_run_spd_default = 1400,
	max_run_spd = 1400,
	downforce_override = false, -- Prevents downforce from being set on slopes. Activated during certain states.
	current_state = "Init",
	current_class = "none",
	classes = { -- Somewhat optional, states can register under a class. Makes it easier to detect when you should be in a state.
	  Grind = { anims = {}, Reset = ResetRailParams, root_state = 12 },
	  Roll = { anims = {}, Reset = DefaultReturnHandler, root_state = 23 },
	  Glide = { anims = {}, Reset = DefaultReturnHandler, root_state = 44 },
	  Attack = { anims = {}, Reset = DefaultReturnHandler, root_state = 100 },
	  Dive = { anims = {}, Reset = DefaultReturnHandler, root_state = 103 }
	},
	states = {}, -- Populated by RegisterState
	state_id_list = { -- Pairs a stateID to a Lua state. Used to transition from Init to a proper state.
	  [12] = "Grinding",
	  [44] = "Gliding",
	  [100] = "Attacking",
	  [103] = "Diving"
	},
	state_plugins = {} -- Populated by RegisterStatePlugin. Pairs a string handle to a function
  },
  shadow = {
    custom_anims = { -- Used for setting the proper anim IDs with ChangeAnim
	  Grinding = { -- Anim set for new grinding mechanics
	    lean_L = "esp_w",
		lean_R = "esp_w_up",
		
		grind_loop = "grind_l", -- These are just used to register the normal grind anims as part of the grinding state as well
		grind_trick = "grindturn_l"
	  },
	  Grinding_Crouch = {
	    crouch = "teleport_dash_l",
	    lean_L = "esp_one_l",
		lean_R = "esp_one_r"
	  },
	  Rolling = {
		
	    default = "jump_alt",
		release = "spindash"
	  },
	  Attacking = { 
	    default = "attack",
		jumpup = "jumpup",
		sault = "bungee_fly",
		sliding = "sliding",
		tornado = "spinattack_s",
		tornado_l = "spinattack_l",
		tornado_e = "spinattack_e"
	  },
	  Plugins = {
	    badnik_bounce = "bounce"
	  }
	},
	custom_sounds = {
	  badnik_bounce = { impact = {"enemy_robot_common", "ImpactL"}, dash = {"player_shadow", "attack"} },
	  SpinDash = { charge = {}, release_1 = {"player_shadow", "kickback"}, release_2 = {"player_shadow", "spin_kick"} }
	},
	max_run_spd_default = 1500,
	max_run_spd = 1500,
	base_jump_speed = 900, -- max height attainable during a jump
	downforce_override = false, -- Prevents downforce from being set on slopes. Activated during certain states.
	spindash_duration = 180, -- Spin dash duration in frames
	current_state = "Init",
	current_class = "none",
	classes = { -- Somewhat optional, states can register under a class. Makes it easier to detect when you should be in a state.
	  Grind = { anims = {}, Reset = ResetRailParams, root_state = 12 },
	  Roll = { anims = {}, Reset = DefaultReturnHandler, root_state = 23 },
	  Attack = { anims = {}, Reset = DefaultReturnHandler, root_state = 69 },
	},
	states = {}, -- Populated by RegisterState
	state_id_list = { -- Pairs a stateID to a Lua state. Used to transition from Init to a proper state.
	  --["0x17"] = "Grinding",
	  --["0x45"] = "Attacking",
	  --["0x52"] = "Rolling"
	  [12] = "Grinding",
	  [89] = "Attacking", -- Shadow tornado kick
	  [90] = "Attacking", -- Shadow edge attack
	},
	state_plugins = {} -- Populated by RegisterStatePlugin. Pairs a string handle to a function
  },
  rouge = {
    custom_anims = { -- Used for setting the proper anim IDs with ChangeAnim
	  Grinding = { -- Anim set for new grinding mechanics
	    lean_L = "overdrive",
		lean_R = "overdrive_l",
		
		grind_loop = "grind_l", -- These are just used to register the normal grind anims as part of the grinding state as well
		grind_trick = "grindturn_l"
	  },
	  Grinding_Crouch = {
	    crouch = "teleport_dash_l",
	    lean_L = "esp_one_l",
		lean_R = "esp_one_r"
	  },
	  Rolling = {
	    default = "jump_alt",
	  },
	  Plugins = {
	    badnik_bounce = "jump"
	  }
	},
	custom_sounds = {
	  badnik_bounce = { impact = {"enemy_robot_common", "ImpactL"}, dash = {"player_rouge", "bomb_throw"} }
	},
	max_run_spd_default = 1300,
	max_run_spd = 1300,
	base_jump_speed = 900, -- max height attainable during a jump
	downforce_override = false, -- Prevents downforce from being set on slopes. Activated during certain states.
	current_state = "Init",
	current_class = "none",
	classes = { -- Somewhat optional, states can register under a class. Makes it easier to detect when you should be in a state.
	  Grind = { anims = {}, Reset = ResetRailParams, root_state = 12 },
	  Roll = { anims = {}, Reset = DefaultReturnHandler, root_state = 23 },
	  Blast = { anims = {}, Reset = DefaultReturnHandler, root_state = 36 },
	  Glide = { anims = {}, Reset = DefaultReturnHandler, root_state = 44 },
	  Throw = { anims = {}, Reset = DefaultReturnHandler, root_state = 104 },
	  Dive = { anims = {}, Reset = DefaultReturnHandler, root_state = 23 }
	},
	states = {}, -- Populated by RegisterState
	state_id_list = { -- Pairs a stateID to a Lua state. Used to transition from Init to a proper state.
	  [12] = "Grinding",
	  [36] = "Blasting",
	  [44] = "Gliding",
	  [104] = "Throwing",
	},
	state_plugins = {} -- Populated by RegisterStatePlugin. Pairs a string handle to a function
  },
  omega = {
    custom_anims = { -- Used for setting the proper anim IDs with ChangeAnim
	  Grinding = { -- Anim set for new grinding mechanics
	    lean_L = "overdrive",
		lean_R = "overdrive_l",
		
		grind_loop = "grind_l", -- These are just used to register the normal grind anims as part of the grinding state as well
		grind_trick = "grindturn_l"
	  },
	  Grinding_Crouch = {
	    crouch = "teleport_dash_l",
	    lean_L = "esp_one_l",
		lean_R = "esp_one_r"
	  },
	  Rolling = {
	    default = "jump_alt",
	  },
	  Plugins = {
	    badnik_bounce = "jump"
	  }
	},
	custom_sounds = {
	  badnik_bounce = { impact = {"enemy_robot_common", "ImpactL"}, dash = {"player_knuckles", "punch"} }
	},
	hover_params = {
	  gauge_brake = 1/180,
	  base_hover_speed = 800,
	  brake_by_level = {
	    [1] = 1/120,
		[2] = 1/180,
		[3] = 1/240
	  },
	},
	max_run_spd_default = 2000,
	max_run_spd = 2000,
	base_jump_speed = 900, -- max height attainable during a jump
	downforce_override = false, -- Prevents downforce from being set on slopes. Activated during certain states.
	action_gauge_function = nil,
	custom_gauge_params = {
	  action_gauge_regen_valid = true,
	  action_gauge_maturity_valid = true,
	  action_gauge_maturity_level_initial = 1,
	},
	current_state = "Init",
	current_class = "none",
	classes = { -- Somewhat optional, states can register under a class. Makes it easier to detect when you should be in a state.
	  Grind = { anims = {}, Reset = ResetRailParams, root_state = 12 },
	  Hover = { anims = {}, Reset = DefaultReturnHandler, root_state = 78 },
	},
	states = {}, -- Populated by RegisterState
	state_id_list = { -- Pairs a stateID to a Lua state. Used to transition from Init to a proper state.
	  [12] = "Grinding",
	  [78] = "Hovering"
	},
	state_plugins = {} -- Populated by RegisterStatePlugin. Pairs a string handle to a function
  },
  silver = {
    custom_anims = { -- Used for setting the proper anim IDs with ChangeAnim
	  Grinding = { -- Anim set for new grinding mechanics
	    lean_L = "overdrive",
		lean_R = "overdrive_l",
		
		grind_loop = "grind_l", -- These are just used to register the normal grind anims as part of the grinding state as well
		grind_trick = "grindturn_l"
	  },
	  Grinding_Crouch = {
	    crouch = "bungee_fly",
	    lean_L = "sliding_stand", -- Placeholders until I can get a crouch lean anim
		lean_R = "jeep_ride"
	  }
	},
	max_run_spd_default = 1200,
	max_run_spd = 1200,
	base_jump_speed = 900, -- max height attainable during a jump
	downforce_override = false, -- Prevents downforce from being set on slopes. Activated during certain states.
	current_state = "Init",
	current_class = "none",
	classes = { -- Somewhat optional, states can register under a class. Makes it easier to detect when you should be in a state.
	  Grind = { anims = {}, Reset = ResetRailParams, root_state = 12 },
	},
	states = {}, -- Populated by RegisterState
	state_id_list = { -- Pairs a stateID to a Lua state. Used to transition from Init to a proper state.
	  [12] = "Grinding",
	},
	state_plugins = {} -- Populated by RegisterStatePlugin. Pairs a string handle to a function
  },
  blaze = {
    custom_anims = { -- Used for setting the proper anim IDs with ChangeAnim
	  Grinding = { -- Anim set for new grinding mechanics
	    lean_L = "overdrive_l",
		lean_R = "overdrive",
		
		grind_loop = "grind_l", -- These are just used to register the normal grind anims as part of the grinding state as well
		grind_trick = "grindturn_l"
	  },
	  Grinding_Crouch = {
	    crouch = "teleport_dash_l",
	    lean_L = "esp_one_l", -- Placeholders until I can get a crouch lean anim
		lean_R = "esp_one_r"
	  },
	  Plugins = {
	    badnik_bounce = "bounce"
	  }
	},
	custom_sounds = {
	  badnik_bounce = { impact = {"enemy_robot_common", "ImpactL"}, dash = {"player_blaze", "attack"} }
	},
	max_run_spd_default = 1700,
	max_run_spd = 1700,
	base_jump_speed = 900, -- max height attainable during a jump
	downforce_override = false, -- Prevents downforce from being set on slopes. Activated during certain states.
	current_state = "Init",
	current_class = "none",
	classes = { -- Somewhat optional, states can register under a class. Makes it easier to detect when you should be in a state.
	  Grind = { anims = {}, Reset = ResetRailParams, root_state = 12 },
	  Roll = { anims = {}, Reset = DefaultReturnHandler, root_state = 23 },
	  Attack = { anims = {}, Reset = DefaultReturnHandler, root_state = 23 }
	},
	states = {}, -- Populated by RegisterState
	state_id_list = { -- Pairs a stateID to a Lua state. Used to transition from Init to a proper state.
	  [12] = "Grinding",
	},
	state_plugins = {} -- Populated by RegisterStatePlugin. Pairs a string handle to a function
  },
  amy = {
    custom_anims = { -- Used for setting the proper anim IDs with ChangeAnim
	  Grinding = { -- Anim set for new grinding mechanics
	    lean_L = "overdrive",
		lean_R = "overdrive_l",
		
		grind_loop = "grind_l", -- These are just used to register the normal grind anims as part of the grinding state as well
		grind_trick = "grindturn_l"
	  },
	  Grinding_Crouch = {
	    crouch = "teleport_dash_l",
	    lean_L = "esp_one_l", -- Placeholders until I can get a crouch lean anim
		lean_R = "esp_one_r"
	  },
	  DoubleJumping = {
	    default = "jump_double_0",
		second = "jump_double_1"
	  },
	  Plugins = {
	    badnik_bounce = "bounce"
	  }
	},
	custom_sounds = {
	  badnik_bounce = { impact = {"enemy_robot_common", "ImpactS"}, dash = {"player_amy", "hammer_attack"} }
	},
	hammer_params = {
	  base_double_jump_count = 1, -- The amount of double jumps Amy has by default. Value should be the same as the one set in her player Lua file.
	  stealth_double_jump_count = 2, -- The amount of DJ's available while invisible
	  stealth_max_velocity = 2500, -- The maximum speed you can accelerate to while invisible
	  stealth_accel = mFloor(2500 * 0.42), -- Grounded acceleration while invisible. This is written to the player Lua, so it automatically gets divided. 1042
	  stealth_gauge_brake = 1/720, -- Action Gauge drain rate while invisible
	  quick_entry_speed = 1100, -- Speed threshold for entering the grounded hammer attack on button press (instead of on release)
	  attack_brake_base = 700/60, -- Base speed brake when in State 96 (grounded hammer attack)
	  attack_brake_gimmick = 1500/60, -- Gimmick speed brake
	  vault_horizontal_brake = 700/60, -- Speed brake while in a Hammer Vault
	  vault_min_spd = 900, -- Minimum forward speed during a Vault
	  air_swing_brake = 700/60, -- Forward speed brake during an Air Swing
	  air_swing_vault_add = 850, -- Additional speed upon a successful transition from Air Swing to Vault 900
	  spinning_gauge_brake = 1/200, -- Action Gauge drain rate while Spinning
	  spin_brake = 700/60, -- Base speed brake while Spinning
	  spin_max_spd = 1800, -- Speed to target while Spinning
	  spin_min_spd = 900, -- Lowest speed attainable while turning. Speed can drop to 0 if stick is neutral
	  spin_accel = 900/60, -- Acceleration rate if under max run speed while spinning
	  spin_rotation_brake = 400/60, -- Deceleration rate while turning in a Spin
	  hammer_visible_by_speed = false, -- If enabled, draw Amy's hammer while running >= the threshold
	  hammer_visible_threshold = 1100,
	  hammer_visible_animation = "dush", -- Otherwise, draw the hammer while she's in this animation
	},
	max_run_spd_default = 1500,
	max_run_spd = 1500,
	base_jump_speed = 900, -- max height attainable during a jump
	downforce_override = false, -- Prevents downforce from being set on slopes. Activated during certain states.
	action_gauge_function = nil,
	custom_gauge_params = {
	  action_gauge_regen_valid = true,
	  action_gauge_time_add = 1/120,
	},
	current_state = "Init",
	current_class = "none",
	classes = { -- Somewhat optional, states can register under a class. Makes it easier to detect when you should be in a state.
	  Grind = { anims = {}, Reset = ResetRailParams, root_state = 12 },
	  Roll = { anims = {}, Reset = DefaultReturnHandler, root_state = 23 },
	  DoubleJump = { anims = {}, Reset = DefaultReturnHandler, root_state = 95 },
	  Attack = { anims = {}, Reset = DefaultReturnHandler, root_state = 96 },
	  Vault = { anims = {}, Reset = DefaultReturnHandler, root_state = 23 }, -- Hammer Jump
	  Spin = { anims = {}, Reset = DefaultReturnHandler, root_state = 23 }, -- Hammer Spin
	  Dizzy = { anims = {}, Reset = DefaultReturnHandler, root_state = 0 }, -- Post-Spin-Dizziness 
	  AirSwing = { anims = {}, Reset = DefaultReturnHandler, root_state = 23 }, -- Air Hammer Attack
	  Stealth = { anims = {}, Reset = DefaultReturnHandler, root_state = -1 }
	},
	states = {}, -- Populated by RegisterState
	state_id_list = { -- Pairs a stateID to a Lua state. Used to transition from Init to a proper state.
	  [12] = "Grinding",
	  [92] = "Stealthing",
	  [94] = "DoubleJumping",
	  [95] = "DoubleJumping",
	  [96] = "Attacking"
	},
	state_plugins = {} -- Populated by RegisterStatePlugin. Pairs a string handle to a function
  },
  state_utilities = {
    plugins = {}
  }
}
local _, err = pcall(dofile, "game:\\TestFile.lua")

-- Allows every player to lookup values set in PlayerList.general.
-- If the value is also present in PlayerList[character], it will overwrite that specific value
for player, _ in pairs(PlayerList) do
  if player ~= "general" then
    SetDeepMetaTable(PlayerList[player], PlayerList.general)
  end
end
player_reference = "" -- Type is actually a table

function PlayerList.OnPlayerChange()
  -- Init slope parameters
  player_reference.max_run_spd = GetPlayerLuaValue("c_run_speed_max")
  player_reference.slope_params.BASE_ROTATION_SPEED = GetRotationSpeed()
  player_reference.slope_params.BASE_ROTATION_BORDER = GetRotationSpeedBorder()
end

function SetUpwardsBias(val)
  player_reference.slope_params.UPWARDS_BIAS = val
end
function SetDownwardsBias(val)
  player_reference.slope_params.DOWNWARDS_BIAS = val
end

function GetLuaClass()
  return player_reference.current_class
end
function GetLuaMaxSpeed()
  return player_reference.slope_params.speed_cap
end
function SetLuaMaxSpeed(val)
  player_reference.slope_params.speed_cap = val
end


StateText = DebugLabel("", 525, 575)
gravity_text = DebugLabel("", 525, 600)
local PlayerStateBase = {}
function RegisterState(parent, state_name, class_name)
  if parent[state_name] ~= nil then
    print("STATE " .. state_name .. " already exists!")
	return
  end
  parent.states[state_name] = { name = state_name, player = parent, my_plugins = {} }
  local new_state = parent.states[state_name]
  new_state.anim_ref = new_state.player.custom_anims[new_state.name]
  if class_name then
    if parent.classes[class_name] then
	  -- Register the state within a class, give the state a reference to its class
      new_state.class = class_name --parent.classes[class_name]
      table.insert(parent.classes[class_name], state_name) -- Passing just the name since everything is indexed by string anyway.
	  
	  -- Register the state's animations within the class. This is used to tell when you've completely left the class.
	  local new_anims = parent.custom_anims[state_name]
	  if new_anims ~= nil then
	    local class_anims = parent.classes[class_name].anims
	    for _, cue in pairs(new_anims) do
		  local cue_ID = tostring(GetAnimValue(cue))
		  if not class_anims[cue_ID] then
		    class_anims[cue_ID] = true
		  end
		end
	  end  
	else
	  DebugPrint(class_name .. " is not a valid class.")
	end
  end
  setmetatable(new_state, {__index = PlayerStateBase})
  return new_state
end

function RegisterStatePlugin(character, plugin_name, my_plugin) -- string, string, func
  if not PlayerList.state_utilities.plugins[plugin_name] then
    PlayerList.state_utilities.plugins[plugin_name] = my_plugin
  else
    DebugPrint("Plugin " .. plugin_name .. " is already present!")
  end
end

function AttachPluginState(character, attach_to, plugin_func) -- string, string, function
  if not PlayerList[character].states[attach_to] then
    DebugPrint("AttachPluginState: INVALID CHAR/STATE COMBO: " .. character .. " " .. attach_to)
  end
  table.insert(PlayerList[character].states[attach_to].my_plugins, plugin_func) -- Insert the string into the list of Plugins
end

local delay_state = false -- Force the player to remain in a state for at least a frame. Prevents a softlock if a state uses the same button to enter/exit
g_delay_override = false -- Causes the above to get ignored. Used for Sonic's spin dash
function PlayerStateBase:SwitchState(next_state)
  if delay_state and not g_delay_override then return end
  if not next_state then
    print("SwitchState: No state provided...")
	return
  elseif next_state == "RESET" then
    self.player.current_state = "Init"
	self.player.current_class = "none"
	return self:SwitchState("Init")
  end
  self:StateExit() -- Call exit behavior.
  print("Switching to: " .. next_state)
  if rawget(self.player.states[next_state], "StateMain") then
    self.player.current_state = next_state
	delay_state = true
    return self.player.states[next_state]:Startup()
  else
    print("SwitchState: " .. next_state .. " has no Main. Returning to default.")
	self.player.current_state = "Init"
	self.player.current_class = "none"
	return self:SwitchState("Init")
  end
end

function PlayerStateBase:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class or "none"
  return self:StateEnter()
end

function PlayerStateBase:StateEnter()
  --print("Entered state " .. self.name)
  return self:StateMain()
end

function PlayerStateBase:StateMain(buttons)
  --print("Main state: " .. self.name)
end
function PlayerStateBase:StateExit()
  --print("Leaving state: " .. self.name)
end

local name_init_delay = 0
local has_got_name = false
function StateStep(delta)
  if not Player(0):IsValidPTR() then
    return
  end
  --[[if not has_got_name then
    name_init_delay = name_init_delay + 1
	if name_init_delay >= 15 then
	  name_init_delay = 0
	  has_got_name = true
	end
	return
  ]]
  --else
    local new_name = GetPlayerName()
	if new_name ~= cur_player_name then
	  cur_player_name = new_name
	  player_reference = PlayerList[cur_player_name] or PlayerList["sonic"]
	  PlayerList.OnPlayerChange()
	end
  --end
  local state = player_reference.current_state
  local my_states = player_reference.states
  local _, err = pcall(PlayerStateObserver)
  if not _ then
    print("Step err: " .. tostring(err))
	return
  end
  for handle, func in pairs(my_states[state].my_plugins) do
    func(delta)
  end
  if GetManagedFlag(g_flags.stage_restart) then
    ResetOnDeath()
  end
  if player_reference.action_gauge_function and GetPlayerState() ~= 8 then
    player_reference.action_gauge_function()
  end
end

RegisterState(PlayerList.sonic, "Init")
RegisterState(PlayerList.sonic_mach, "Init")
RegisterState(PlayerList.tails, "Init")
RegisterState(PlayerList.knuckles, "Init")
RegisterState(PlayerList.shadow, "Init")
RegisterState(PlayerList.rouge, "Init")
RegisterState(PlayerList.omega, "Init")
RegisterState(PlayerList.silver, "Init")
RegisterState(PlayerList.blaze, "Init")
RegisterState(PlayerList.amy, "Init")
-- This is a default "manager" state. If you're not currently in an action that needs to be handled, reset back to this one.
local hitbox_on = false
local invuln_on = false
function ValidateRollTransition(my_state)
  -- 23 is the Roll root state
  local flag = GetGroundAirFlags()
  if bit.AND(flag, 64) ~= 0 or bit.AND(flag, 131072) ~= 0 or bit.AND(flag, 4) ~= 0 then
    SetPlayerState(0)
    return false
  elseif GetInputLockout() ~= 0 then 
    return false
  elseif my_state == 23 or my_state <= 2 or my_state == StateID.LANDING or my_state == StateID.SPIN_DASH or my_state == StateID.GEM_BLUE or my_state == StateID.TORNADO_KICK then
    return true
  else
    print("VALIDATION FAILED. STATE: " .. my_state)
    return false
  end
end

local valid_flight_states = {
  [0] = true,
  [1] = true,
  [2] = true,
  [3] = true,
  [4] = true,
  [5] = true,
  [17] = true,
  [18] = true,
  [19] = true,
  [20] = true,
  [21] = true,
  [32] = true,
  [71] = true,
}
function ValidateFlightTransition(is_roll)
  local my_state = GetPlayerState()
  if g_is_super_active and 
	 GetInput("rt", "hold") and 
	 GetLuaClass() ~= "Flight" and 
	 GetInputLockout() == 0 and 
	 (is_roll or valid_flight_states[my_state]) and
	 GetGaugeParameter("c_gauge_value") > 0 then
	   return true
  else
    return false
  end
end

local valid_badnik_bounce_states = {
  [StateID.JUMP] = true,
  [StateID.JUMP_WATER] = true,
  [StateID.FALL] = true,
  [StateID.SPRING] = true, -- For Sky Gem
  [StateID.GEM_PURPLE] = true,
  [StateID.GLIDE_END] = true,
  [StateID.HOMING_AFTER] = false, -- Anim doesn't update
  [StateID.BOUNCE] = true,
}
function ValidateBadnikBounceEnable(my_state)
  if GetInputLockout() ~= 0 then return false end
  
  if valid_badnik_bounce_states[my_state] then
    return true
  else
    return false
  end
end

function ManageBadnikEnable(my_state)
  local held, released = GetInput("b", "hold")
  if held and ValidateBadnikBounceEnable(my_state) then
    hitbox_on = true
    if GetPlayerName() == "sonic" then ToggleHitboxBound(true) else ToggleHitboxKick(true) end
    SetPlayerInvuln(true)
    invuln_on = true
    ChangePlayerAnim("bounce")
  elseif released then
    hitbox_on = false
    if GetPlayerName() == "sonic" then ToggleHitboxBound(false) else ToggleHitboxKick(false) end
    SetPlayerInvuln(false)
    invuln_on = false
	if GetPlayerState() == 4 or GetPlayerState() == 3 or GetPlayerState() == 45 then
      ChangePlayerAnim("fall")
	end
  end
end

function DisableBadnikProperties()
  if hitbox_on and IsGrounded() then
    hitbox_on = false
	if GetPlayerName() == "sonic" then 
	  ToggleHitboxBound(false) 
	else 
	  ToggleHitboxKick(false) 
	  local pos = GetPlayerPos()
	  --Game.NewActor("particle",{bank="enemycommon", name = "sonic_small_g", cycle = 0, cyclewidth = 0, sebank = "", sename = ""},{Position = Vector(pos.X,pos.Y + 25,pos.Z) , Rotation = Vector(1,0,0,0)})
	end
	if invuln_on then
	  SetPlayerInvuln(false)
	  invuln_on = false
	end
	SetPlayerState(2)
	local spd = GetPlayerSpeed("total")
	local diff = 0
	if spd < player_reference.bounce_speed_max then
	  diff = mMin(player_reference.bounce_speed_min, player_reference.bounce_speed_max - spd)
	end
	if diff > 0 then
	  SetPlayerSpeed("x", diff, true)
	end
	if GetPlayerSpeed("y", false) ~= 0 then
	  SetPlayerSpeed("y", 0, false)
	end
	if player_reference.custom_sounds then
	  local badnik_sounds = player_reference.custom_sounds.badnik_bounce
	  Game.ProcessMessage("LEVEL", "PlaySE", {bank = badnik_sounds.impact[1], id = badnik_sounds.impact[2]})
	  --Game.ProcessMessage("LEVEL", "PlaySE", {bank = badnik_sounds.impact_alt[1], id = badnik_sounds.impact_alt[2]})
	  Game.ProcessMessage("LEVEL", "PlaySE", {bank = badnik_sounds.dash[1], id = badnik_sounds.dash[2]})
	end
  end
end

function ResetOnDeath()
  homing_charge_count = 1
  purple_jump_count = 3
  hitbox_on = false
  invuln_on = false
  local player_name = GetPlayerName()
  if player_name == "sonic" then
    g_is_super_active = false
	initial_rings = 0
    ToggleHitboxBound(false)
	ResetGemStatus()
	SetManagedFlag(g_flags.is_super, false)
  else
    ToggleHitboxKick(false)
	player_reference.custom_gauge_params.current_action_gauge = 0
    player_reference.custom_gauge_params.action_gauge_maturity_current = 0
    player_reference.custom_gauge_params.action_gauge_maturity_level = player_reference.custom_gauge_params.action_gauge_maturity_level_initial
    SetMaturityLevel(player_reference.custom_gauge_params.action_gauge_maturity_level_initial)
    SetMaturity(0)
  end
  player_reference.base_jump_speed = player_reference.base_jump_speed_default
  player_reference.max_run_spd = player_reference.max_run_spd_default
end

local homing_charge_count = 1
local purple_jump_count = 3
local refresh_homing_charge = {
  [StateID.JUMP] = true,
  [StateID.HOMING_AFTER] = true,
  [StateID.SPRING] = true,
  [StateID.ROPE] = true,
  [StateID.JUMP_PANEL] = true,
  [StateID.UP_DOWN_REEL] = true,
  
}
function ManageAdditionalHomingAttack(my_state)
  local button = GetPlayerName() == "blaze" and "x" or "a"
  local status = GetPlayerName() == "blaze" and "released" or "down"
  if my_state == StateID.HOMING_RELEASE or my_state == StateID.FIRE_CLAW then
    homing_charge_count = mMax(0, homing_charge_count - 1)
  elseif GetInputLockout() == 0 and 
	(my_state == StateID.BOUNCE or my_state == StateID.FALL or my_state == StateID.SPRING or my_state == StateID.ACCEL_TORNADO or (my_state == StateID.CHAOS_SPEAR and (GetPlayerAnim(true) == "chaos_spear_s" or GetPlayerAnim(true) == "chaos_spear_l"))) then
    if (GetInput(button, status) and homing_charge_count > 0) then
	  homing_charge_count = homing_charge_count - 1
	  SetPlayerState(4)
    end
  elseif refresh_homing_charge[my_state] then
    homing_charge_count = 1
  end
end
g_my_total_spd = 0
function PlayerList.sonic.states.Init:StateMain()
  local pos = GetPlayerPos()
  local my_state = GetPlayerState()
  g_my_total_spd = GetPlayerSpeed("total")
  if my_state == 8 then 
    ResetOnDeath()
    return 
  elseif my_state == 9 then
    return
  elseif my_state == 23 and GetPlayerAnim(true) ~= "super" then
    SetPlayerState(0)
	--player.print("Exited here")
  elseif my_state == 67 then
    self.player.dash_available = true
  end
  
  if ValidateFlightTransition() then
	SetPlayerState(23)
	return self:SwitchState("Flying")
  end
  if IsGrounded() or GetPlayerState() == 53 then
    homing_charge_count = 1
	purple_jump_count = 3
	self.player.dash_available = true
    DisableBadnikProperties()
    if sonic_variant ~= 3 and GetInput("b") and ValidateRollTransition(my_state) and my_state ~= 23 then
	  SetPlayerState(StateID.GOAL_LOOP)
      self:SwitchState("Rolling")
	end
  else
    if sonic_variant == 3 then
	  if GetContextFlag("PrincessBarrierOn") then
	    SetPlayerInvuln(true)
		if GetInput("y") and self.player.dash_available then
		  SetPlayerState(23)
		  homing_charge_count = 1
		  return self:SwitchState("Dashing")
		end
	  elseif my_state ~= 68 then
	    SetPlayerInvuln(false)
	  end
	else
	  ManageBadnikEnable(my_state)
	end
	ManageAdditionalHomingAttack(my_state)
	if my_state == StateID.GEM_PURPLE then
	  if GetInput("a") then
	    purple_jump_count = purple_jump_count - 1
		if purple_jump_count == 0 then
		  SetPlayerState(3)
		  purple_jump_count = 3
		  homing_charge_count = 0
		end
	  elseif GetInput("x") then
	    SetPlayerState(71)
	  end
	end
  end
end

local automation_states = {
  [17] = true, -- Spring
  [18] = true, -- Wide Spring
  [19] = true, -- Spring2
  [20] = true, -- Dash Panel
  [21] = true, -- Jump Panel
  [30] = true, -- Poll
  [32] = true, -- Rainbow Ring
  [72] = true, -- Light Dash
}
local has_run_knee = false
local was_wide = false
local my_time = 0
local preserve_anim_time = 0

function UpdateAnimByLean(base_anim, left_anim, right_anim)
  local new_anim = base_anim
  local stick = GetStickInput("L", "X", true)
  if mAbs(stick) >= 0.3 then
	new_anim = stick < 0 and left_anim or right_anim
  end
  return new_anim
end

function UpdateRunAnimation()
  local my_spd = GetPlayerSpeed("x", false)
  local mach_vars = player_reference.mach_params
  if my_spd >= mach_vars.JET_ANIM_THRESHOLD then
    local new_anim = UpdateAnimByLean("wait3", "jeep_ride_l", "jeep_ride_r")
    local current_anim = GetPlayerAnim(true)
    if current_anim ~= new_anim then
	  preserve_anim_time = GetCurrentAnimationTime()
	  ChangePlayerAnim(new_anim)
    end
  elseif my_spd >= mach_vars.DASH_ANIM_THRESHOLD then
    local new_anim = UpdateAnimByLean("dush", "bike_ride_l", "bike_ride_r")
    local current_anim = GetPlayerAnim(true)
    if current_anim ~= new_anim then
	  preserve_anim_time = GetCurrentAnimationTime()
	  ChangePlayerAnim(new_anim)
    end
  elseif my_spd >= mach_vars.RUN_ANIM_THRESHOLD then
    ChangePlayerAnim("run")
  else
    ChangePlayerAnim("wait2")
  end
end

function PlayerList.sonic_mach.states.Init:Startup()
  self.player.current_state = self.name
  self.player.current_class = self.class
  SetContextFlag("BlinkMode", false)
  return self:StateEnter()
end

function PlayerList.sonic_mach.states.Init:StateMain()
  --SetPlayerInvuln(true)
  local pos = GetPlayerPos()
  local my_state = GetPlayerState()
  if my_state == 18 then was_wide = true end
  if my_state == 8 or GetManagedFlag(g_flags.stage_restart) then
    SetRotationSpeed(75)
    has_run_knee = false
    return
  elseif automation_states[my_state] then
	local prev = GetPlayerSpeed("x", true, true)
    local prev_y = GetPlayerSpeed("y", true, true)
    local cur = GetPlayerSpeed("x", false)
	SetRotationSpeed(75)
	if my_state ~= 31 then
      if prev > 0 and prev ~= cur then
        SetPlayerSpeed("x", prev, true)
	    SetPlayerSpeed("y", prev_y, true)
	    local last = GetInputLockout(true)
	    SetInputLockout(last)
      end
	end
    return
  elseif my_state == 9 then
    SetPlayerState(23)
    return self:SwitchState("Damaging")
  elseif my_state == 25 then
    SetInputLockout(0)
	SetInputLockout(0, true)
	local last_spd = GetPlayerSpeed("x", true, true)
	SetPlayerSpeed("x", last_spd, false)
	SetPlayerSpeed("x", 0, true)
	SetPlayerSpeed("y", 0, true)
	SetPreviousSpeed("x", 0)
	SetPreviousSpeed("y", 0)
	return
  elseif my_state == 31 then
    return self:SwitchState("ChainJumping")
  end
  if not has_run_knee then
    has_run_knee = true
	SetInputLockout(0.1)
	SetPlayerState(23)
	return self:SwitchState("Starting")
  end
  SetAnimationRotationLock(false)
  local my_spd = GetPlayerSpeed("x", false)
  local my_flag = GetGroundAirFlags()
  if bit.AND(my_flag, 16) ~= 0 then
    if my_spd >= player_reference.mach_params.BONK_THRESHOLD then
	  SetPlayerState(23)
      return self:SwitchState("Damaging")
	else
	  --SetPlayerSpeed("x", -100, false)
	  --return
	end
  end
  local my_stick = mAbs(GetStickInput("L", "Y", true))
  if false and (GetInput("rb", "hold") or GetInput("lb", "hold") or GetInput("b", "hold")) then
      local force = mMax(600, my_spd * 0.25)
	  SetPostureLuaValue("c_posture_inertia_move", force)
	  SetContextFlag("InertiaMode", true)
	  --return
	elseif false then
	  SetContextFlag("InertiaMode", false)
	  SetPostureLuaValue("c_posture_inertia_move", 300)
	end
  local rot_spd = GetRotationSpeed()
  local cap = my_spd < 3000 and 50 or my_spd < 5000 and 75 or 100
  if rot_spd ~= cap then
    local increase = (cap * 1.5) * G_DELTA_TIME/3
	if rot_spd > cap then increase = increase * -1 end
	rot_spd = rot_spd + increase
	if mAbs(rot_spd - cap) < 1 then
	  rot_spd = cap
	end
	SetRotationSpeed(rot_spd)
  end
  if GetInputLockout(true) ~= 0 then 
	if was_wide then
	  was_wide = false
	  SetInputLockout(0, true)
	  return
	end
    ExitOnAutomationCollision(self)
    return 
  end
  if GetInput("x") then
    SetPlayerState(0)
	return
  end
  if IsGrounded() then
    if GetPlayerState() == 23 then
      SetPlayerState(2)
	  SetPlayerSpeed("y", 0, false)
	  SetPlayerSpeed("y", 0, true)
	  return
	end
	SetPlayerSpeed("x", 0, true)
    SetPlayerSpeed("y", 0, false)
	SetPlayerSpeed("y", 0, true)
	SetPreviousSpeed("x", 0)
    SetPreviousSpeed("y", 0)
    if GetInput("a") then
	  SetPlayerState(23)
	  return self:SwitchState("Jumping")
	end
	local mach_vars = player_reference.mach_params
	local accel_rate = mach_vars.ACCELERATION_RATE * G_DELTA_TIME
    local decel_rate = mach_vars.DECELERATION_RATE * G_DELTA_TIME
	local MIN_GROUND_SPEED = not GetManagedFlag(g_flags.is_super) and mach_vars.MIN_GROUND_SPEED or mach_vars.MIN_GROUND_SPEED_SUPER
	local RUN_MAX_SPEED = not GetManagedFlag(g_flags.is_super) and mach_vars.RUN_MAX_SPEED or mach_vars.RUN_MAX_SPEED_SUPER
	if not IsStickNeutral() or my_spd < MIN_GROUND_SPEED then
	  my_spd = mMin(RUN_MAX_SPEED, my_spd + accel_rate)
	else
	  my_spd = mMax(MIN_GROUND_SPEED, my_spd - decel_rate)
	end
	if preserve_anim_time ~= 0 then
	  SetCurrentAnimationTime(preserve_anim_time + 1/60)
	  preserve_anim_time = 0
	end
	SetPlayerSpeed("x", my_spd, false)
	UpdateRunAnimation()
  else
    SetPlayerState(23)
    return self:SwitchState("Falling")
  end
end

function PlayerList.shadow.states.Init:StateMain()
  local my_state = GetPlayerState()
  if my_state == 8 then 
    ResetOnDeath()
    return 
  elseif my_state == 9 then
    return
  elseif my_state == 23 then
    SetPlayerState(0)
  end
  --if GetInput("y") then PlayProcess("ActionTest") end
  if my_state == 88 then
    local flag = GetGroundAirFlags()
	if GetInput("y") then
	  SetPlayerState(67)	
	elseif flag == 0 then
	  SetPlayerSpeed("x", 900, false)
	end
  elseif my_state == 85 then
    if GetInput("y") then
	  SetPlayerState(67)
	end
  elseif my_state == 67 or (my_state == 66 and GetPlayerAnim(true) == "chaos_wait") then
    if GetInput("x") then SetPlayerState(82) homing_charge_count = 1 end
  elseif my_state == 81 then
    CallCameraEvent(self.player.custom_cameras.Boost)
  end
  if IsGrounded() then
    homing_charge_count = 1
	self.player.spear_count = self.player.spear_max
    DisableBadnikProperties()
    if GetInput("b") and ValidateRollTransition(my_state) and my_state ~= 23 then
      --SetPlayerState(70)
	  SetPlayerState(StateID.GOAL_LOOP)
      self:SwitchState("Rolling")
	elseif GetInput("x", "hold") and GetInputLockout() == 0 and not GetInput("x") and GetPlayerSpeed("total") == 0 then
	  SetPlayerState(23)
	  return self:SwitchState("SpinDash")
	end
  else
    ManageBadnikEnable(my_state)
	ManageAdditionalHomingAttack(my_state)
  end
end

g_last_grav = 0
function PlayerList.omega.states.Init:StateMain()
  local my_state = GetPlayerState()
  if my_state == 8 then 
    ResetOnDeath()
    return 
  elseif my_state == 9 then
    return
  elseif my_state == 23 then
    SetPlayerState(0)
  elseif my_state == 80 and not IsGrounded() then
    return self:SwitchState("Attacking")
  end
  g_my_total_spd = GetPlayerSpeed("total")
  g_last_grav = GetAccumulatedGravity()
end

local has_moved_up = false
local prevent_stupid_attack_crash = true -- If Tails starts a stage or respawns then attacks before taking literally *any* other action, he softlocks
-- when trying to get/set the animation time. This prevents that for some unfathomable reason.
function PlayerList.tails.states.Init:StateMain()
  local my_state = GetPlayerState()
  if my_state == 8 then 
    ResetOnDeath()
	prevent_stupid_attack_crash = true
    return 
  elseif my_state == 9 then
    return
  elseif (my_state == 17 or my_state == 21) and GetInputLockout() == 0 then
    if GetInput("a") then
	  SetPlayerState(4)
	end
  elseif my_state == 23 then
    SetPlayerState(0)
  end
  if GetPlayerState() == 48 or GetManagedFlag(g_flags.stage_restart) then
    prevent_stupid_attack_crash = false
  elseif prevent_stupid_attack_crash then
    prevent_stupid_attack_crash = false
	SetPlayerState(25)
  end
  --if GetInput("y") then PlayProcess("ActionTest") end
  if IsGrounded() then
    DisableBadnikProperties()
	if GetInput("y") then
	  SetPlayerState(23)
	  return self:SwitchState("Attacking")
	end
	if (my_state == 17 or my_state == 21) then
	  has_moved_up = true
	  SetPlayerPos(0, 25, 0)
	  print("Yeet")
	end
	if my_state == 2 then
	has_moved_up = false
	end
    if GetInput("b") and ValidateRollTransition(my_state) and my_state ~= 23 then
      --SetPlayerState(70)
	  SetPlayerState(StateID.GOAL_LOOP)
      self:SwitchState("Rolling")
	end
  else
    has_moved_up = true
    ManageBadnikEnable(my_state)
  end
end

function PlayerList.knuckles.states.Init:StateMain()
  local my_state = GetPlayerState()
  if my_state == 8 then 
    ResetOnDeath()
    return 
  elseif my_state == 9 then
    return
  elseif my_state == 17 and GetInputLockout() == 0 then
    if GetInput("a") then
	  SetPlayerState(4)
	end
  elseif my_state == 23 then
    SetPlayerState(0)
  end
  --if GetInput("y") then PlayProcess("ActionTest") end
  if IsGrounded() then
    DisableBadnikProperties()
    if GetInput("b") and ValidateRollTransition(my_state) then
	  SetPlayerState(StateID.GOAL_LOOP)
      self:SwitchState("Rolling")
	end
  else
    ManageBadnikEnable(my_state)
  end
end

local in_move = false
function PlayerList.rouge.states.Init:StateMain()
  local my_state = GetPlayerState()
  if my_state == 8 then 
    ResetOnDeath()
    return 
  elseif my_state == 9 then
    return
  elseif my_state == 17 and GetInputLockout() == 0 then
    if GetInput("a") then
	  SetPlayerState(4)
	end
  elseif my_state == 23 then
    SetPlayerState(0)
  end
  if IsGrounded() then
    DisableBadnikProperties()
    if GetInput("b") and ValidateRollTransition(my_state) and my_state ~= 23 then
	  -- The state check here prevents occasional locks when transitioning from an aerial State 23 to this
	  SetPlayerState(StateID.GOAL_LOOP)
      return self:SwitchState("Rolling")
	end
  else
    ManageBadnikEnable(my_state)
	if GetInput("y") then
      SetPlayerState(StateID.GOAL_LOOP)
      return self:SwitchState("Diving")
	end
  end
end

function PlayerList.silver.states.Init:StateMain()
  local my_state = GetPlayerState()
  if my_state == 8 then 
    ResetOnDeath()
    return 
  elseif my_state == 9 then
    return
  elseif my_state == 23 then
    SetPlayerState(0)
  end
end

local anim_idx = 0
local anim_list = {"bungee_fly", "sliding_stand", "jeep_ride", "bike_ride"}
function PlayerList.blaze.states.Init:StateMain()
  local my_state = GetPlayerState()
  if my_state == 8 then 
    ResetOnDeath()
    return 
  elseif my_state == 9 then
    return
  elseif my_state == 23 then
    SetPlayerState(0)
  end
  if GetInput("dpad_right") then
    --local pos = GetPlayerPos()
    --Game.NewActor("particle",{bank="player_blaze", name = "homingcrow", cycle = 0, cyclewidth = 0, sebank = "", sename = ""},{Position = Vector(pos.X,pos.Y + 25,pos.Z) , Rotation = Vector(1,0,0,0)})
	anim_idx = mMin(table.getn(anim_list), anim_idx + 1)
	--ChangePlayerAnim(anim_list[anim_idx])
  elseif GetInput("dpad_left") then
    anim_idx = mMax(1, anim_idx - 1)
	--ChangePlayerAnim(anim_list[anim_idx])
  end
  if GetInput("a") then
    if my_state == StateID.SPINNING_CLAW then
	  if IsGrounded() then
	    PlayProcess("SDJ")
	  else
	    SetPlayerState(StateID.JUMP)
	  end
    elseif my_state == StateID.FALL or (my_state == StateID.SPRING and GetInputLockout() == 0) then
	  SetPlayerState(StateID.JUMP)
	end
  end
  if IsGrounded() then
    homing_charge_count = 1
    DisableBadnikProperties()
	if GetInput("y") and GetInputLockout() == 0 then
	  SetPlayerState(StateID.GOAL_LOOP)
	  return self:SwitchState("Attacking")
	elseif GetInput("b") and ValidateRollTransition(my_state) and my_state ~= 23 then
      --SetPlayerState(70)
	  SetPlayerState(StateID.GOAL_LOOP)
      self:SwitchState("Rolling")
	end
  else
    ManageBadnikEnable(my_state)
	ManageAdditionalHomingAttack(my_state)
  end
end

function PlayerList.amy.states.Init:StateMain()
  local my_state = GetPlayerState()
  if my_state == 8 then 
    ResetOnDeath()
    return 
  elseif my_state == 9 then
    return
  elseif my_state == 23 then
    --SetPlayerState(0)
  end
  if GetInput("rt") then
    --ToggleAmyHammerVisual()
  end
  local my_total_spd = GetPlayerSpeed("total")
  if IsGrounded() then
    DisableBadnikProperties()
	if GetInputLockout() == 0 then
	  if GetInput("x") and my_total_spd >= player_reference.hammer_params.quick_entry_speed then
	    SetPlayerState(96)
	    return self:SwitchState("Attacking")
	  elseif GetInput("y") then
	    SetPlayerState(23)
		return self:SwitchState("Spinning")
	  end
	end
    if GetInput("b") and ValidateRollTransition(my_state) and my_state ~= 23 then
	  SetPlayerState(StateID.GOAL_LOOP)
	  --ToggleAmyHammerVisual(false)
      return self:SwitchState("Rolling")
	end
  else
    ManageBadnikEnable(my_state)
	if GetInputLockout() == 0 then
	  if GetInput("x") then
	    SetPlayerState(23)
		return self:SwitchState("AirSwinging")
	  elseif GetInput("a") and GetRemainingJumps() > 0 and my_state == 3 then
	    SetPlayerState(94)
	    return self:SwitchState("DoubleJumping")
	  end
	end
  end
  if self.player.hammer_params.hammer_visible_by_speed then
    if my_total_spd >= self.player.hammer_params.hammer_visible_threshold then
	  SetHammerHitbox(0)
	  EnableAmyHammer(true)
    else
	  SetHammerHitbox(1.25)
	  EnableAmyHammer(false)
    end
  else
    if GetPlayerAnim(true) == self.player.hammer_params.hammer_visible_animation then
	  SetHammerHitbox(0)
	  EnableAmyHammer(true)
    else
	  SetHammerHitbox(1.25)
	  EnableAmyHammer(false)
    end
  end
end

function PlayerList.amy.states.Init:StateExit()
  SetHammerHitbox(1.25)
  EnableAmyHammer(false)
end

function PlayerStateObserver()
  local my_state = player_reference.current_state
  local my_init = player_reference.states["Init"]
  StateText:SetText("Current state: " .. my_state)
  local my_class = player_reference.current_class
  local state_decimal_id = GetPlayerAnim()
  local player_state_id = GetPlayerState()
  delay_state = false
  g_delay_override = false
  if my_state == "Init" then
    --[[local dec_id = -1
	for id, state_name in pairs(player_reference.state_id_list) do
	  dec_id = HEX(id)
	  if state_decimal_id == dec_id then
	    return ini:SwitchState(state_name)
	  end
	end]]
	if player_reference.state_id_list[player_state_id] then
	  local state_name = player_reference.state_id_list[player_state_id]
	  return my_init:SwitchState(state_name) --ini:SwitchState(state_name)
	end
	my_init:StateMain()
  elseif my_class ~= "none" then
    local is_in_class = false
	-- In this case, the indices are strings (storing is a bit weird), so I need to do string comparison.
	state_decimal_id = tostring(state_decimal_id)
	local root_state = player_reference.classes[my_class].root_state
	if root_state == player_state_id or root_state == -1 or player_reference.classes[my_class].anims[state_decimal_id] then
	  is_in_class = true
	end
	if not is_in_class then
	  player_reference.classes[my_class].Reset()
	  player_reference.states[my_state]:SwitchState("RESET") -- Go back to the default state.
	else
	  player_reference.states[my_state]:StateMain()
	end
  end
end

G_SHAKE_ITERATIONS = 15 -- Number of iterations
G_SHAKE_UP = 75 -- Camera offset up
G_SHAKE_DOWN = 68 -- Camera offset down
G_SHAKE_DELAY = 2/60 -- Time between iterations
G_SHAKE_LEFT = 0
G_SHAKE_RIGHT = 0
function CameraShake()
  while true do
    for i = 1, G_SHAKE_ITERATIONS do
	  local offset = math.mod(i, 2) == 0 and G_SHAKE_DOWN or G_SHAKE_UP
	  local offset_left = math.mod(i, 2) == 0 and G_SHAKE_RIGHT or G_SHAKE_LEFT
      SetCameraOffset({offset_left, offset, 0}, true)
	  RestFor("CamShake", G_SHAKE_DELAY)
	end
	SetCameraOffset({0, 0, 0})
    coroutine.yield()
  end
end

function CallCameraEvent(params)
  if params.call == "CamShake" then
    G_SHAKE_ITERATIONS = params.iterations
	G_SHAKE_UP = params.up
	G_SHAKE_DOWN = params.down
	G_SHAKE_LEFT = params.left
	G_SHAKE_RIGHT = params.right
	G_SHAKE_DELAY = params.delay
	PlayProcess("CamShake")
  end
end
---------Ability Managers---------
function ManageSpindashJump()
  while true do
    SetDownforce(16)
    SetPlayerPos(0, 25, 0)
    RestFor("SDJ", 1/60)
    SetPlayerState(4)
    coroutine.yield()
  end
end

function ManageMoonsault()
  local is_other_exit = false
  while true do
    SetDownforce(16)
    SetPlayerPos(0, 25, 0)
	RestFor("MS", 1/60)
    --SetPlayerState(4)
	SetPlayerSpeed("y", 850, false)
	RestFor("MS", 1/60)
    SetPlayerState(3)
	RestFor("MS", 1/60)
    ChangePlayerAnim("bungee_fly")
	for i = 1, 30 do
	  if GetInput("a") then
		break
	  elseif GetPlayerState() ~= 3 then
	    is_other_exit = true
		break
	  end
      RestFor("MS", 1/60)
	end
	if not is_other_exit then
      SetPlayerState(4)
	else
	  is_other_exit = false
	end
    coroutine.yield()
  end
end

function ManageEdgeJump()
  while true do
    ChangePlayerAnim("edge_jump")
	RestFor("EJ", 10/60)
    SetDownforce(16)
	SetPlayerPos(0, 25, 0)
	RestFor("EJ", 1/60)
	SetPlayerState(4)
    coroutine.yield()
  end
end

function ManageEdgeShuffle(...)
  local dir_anim = ""
  while true do
    local X, Z = arg[1], arg[2]
	local stick = GetStickInput("L", "X", true) * -1
	if stick < -0.5 then
	  X = X * -1
	  Z = Z * -1
	  dir_anim = "launcher_l"
	else
	  dir_anim = "launcher_r"
	end
	print("X: " .. tostring(X) .. " Z: " .. tostring(Z))
	ChangePlayerAnim(dir_anim)
	for i = 1, 30 do
	  SetPlayerPos(X, 0, Z, false)
	  RestFor("ES", 1/60)
	end
    coroutine.yield()
  end
end

function LaunchDecay()
  while true do
	RestFor("LD", 40/60)
	if GetPlayerState() == StateID.FALL then
	  local my_y = GetPlayerSpeed("y", true)
	  local percent_dec = my_y * 0.009 -- 2 second fall off
	  local dec = 10
	  if my_y >= dec then
	    repeat 
	      SetPlayerSpeed("y", GetPlayerSpeed("y", true) - percent_dec, true)
	      RestFor("LD", 1/60)
	    until (GetPlayerSpeed("y", true) < 10)
	    SetPlayerSpeed("y", 0, true)
	  elseif my_y < 0 then
	    percent_dec = percent_dec * -1
	    repeat
	      SetPlayerSpeed("y", GetPlayerSpeed("y", true) + percent_dec, true)
		  RestFor("LD", 1/60)
	    until (GetPlayerSpeed("y", true) >= 0)
	    SetPlayerSpeed("y", 0, true)
	  end
	end
    coroutine.yield()
  end
end

function ActionTest()
  while true do
    local pos_y = 0
    while IsGrounded() do
      pos_y = GetPlayerPos("y")
	  RestFor("ActionTest", 1/60)
	end
	while GetPlayerState() ~= StateID.HOMING_AFTER do RestFor("ActionTest", 1/60) end
	RestFor("ActionTest", 8/60)
	pos_y = mAbs(GetPlayerPos("y")) - mAbs(pos_y)
	local pos = GetPlayerPos()
	--Game.NewActor("particle",{bank="enemycommon", name = "appear_machine_small", cycle = 0, cyclewidth = 0, sebank = "", sename = ""},{Position = Vector(pos.X,pos.Y + 75,pos.Z) , Rotation = Vector(1,0,0,0)})
	
	SetPlayerPos(0, -pos_y, 0)
	RestFor("ActionTest", 1/60)
	pos = GetPlayerPos()
	Game.NewActor("particle",{bank="enemycommon", name = "appear_machine_small", cycle = 0, cyclewidth = 0, sebank = "", sename = ""},{Position = Vector(pos.X,pos.Y + 75,pos.Z) , Rotation = Vector(1,0,0,0)})
	SetPlayerState(StateID.GOAL_LOOP)
	ChangePlayerAnim("landing")
	RestFor("ActionTest", 12/60)
	ChangePlayerAnim("tornado_s")
	RestFor("ActionTest", 25/60)
	ToggleHitboxBound(1)
	SetPlayerInvuln(1)
	SetPlayerState(StateID.GEM_BLUE)
	RestFor("ActionTest", 1/60)
	SetAnimationRotationLock(1)
	RestFor("ActionTest", 45/60)
	ToggleHitboxBound(0)
	SetPlayerInvuln(0)
	SetAnimationRotationLock(0)
    coroutine.yield()
  end
end

frame_skip_from = 0
frame_skip_to = 0
function ModifyAnimationTiming()
  while true do
    local my_state = GetPlayerState()
    RestFor("MAT", frame_skip_from/60)
	if GetPlayerState() == my_state then
	  SetCurrentAnimationTime(frame_skip_to/60)
	  RestFor("MAT", 1/60)
	  SetCurrentAnimationTime((frame_skip_from + 1)/60)
	  RestFor("MAT", (frame_skip_to - frame_skip_from - 1)/60)
	  SetCurrentAnimationTime((frame_skip_to + 1)/60)
	end
    coroutine.yield()
  end
end

local anims_test = {14, 15, 39, 49, 50, 51, 54, 55, 60, 64, 76}
function AnimTest()
  while true do
    for i = 1, table.getn(anims_test) do
	  SetPlayerState(anims_test[i])
	  player.print("State: " .. anims_test[i])
	  RestFor("AT", 30/60)
	  player.print("DONE!")
	end
    coroutine.yield()
  end
end

function CT()
  while true do
    local c_l_x = GetPlayerSpeed("x", true, true)
	local c_l_y = GetPlayerSpeed("y", true, true)
	local c_l_g = GetAccumulatedGravity()
	local last_lock = GetInputLockout(true)
	local last_state = GetPlayerState()
	PlayerSwap("sonic_new")
	RestFor("CHECK_TEST", 1/60)
	SetPreviousSpeed("x", c_l_x)
	SetPreviousSpeed("y", c_l_y)
	SetPlayerState(last_state)
	RestFor("CHECK_TEST", 1/60)
	SetInputLockout(last_lock)
	SetPlayerSpeed("x", c_l_x, true)
	SetPlayerSpeed("y", c_l_y, true)
	SetAccumulatedGravity(c_l_g)
	
    coroutine.yield()
  end
end

function Interpolate(start_point, end_point, sub_count)
  local height = start_point[2]
  local s_X, s_Y, s_Z = start_point[1], start_point[2], start_point[3]
  local e_X, e_Y, e_Z = end_point[1], end_point[2], end_point[3]
  local diff_X = s_X - e_X
  local diff_Y = s_Y - e_Y
  local diff_Z = s_Z - e_Z
  diff_X = s_X > e_X and (diff_X * -1) or mAbs(diff_X)
  diff_Y = s_Y > e_Y and (diff_Y * -1) or mAbs(diff_Y)
  diff_Z = s_Z > e_Z and (diff_Z * -1) or mAbs(diff_Z)
  local interval_X, interval_Y, interval_Z = diff_X/sub_count, diff_Y/sub_count, diff_Z/sub_count
  local mid_X, mid_Y, mid_Z = s_X + mAbs(diff_X/2), s_Y + mAbs(diff_Y/2), s_Z + mAbs(diff_Z/2)
  local entry = { {start_point[1], start_point[2], start_point[3]} } -- Add start point target
  --print("Intervals: " .. tostring(interval_X) .. " " .. tostring(interval_Z))
  --entry.interp_X = interval_X/30
  --entry.interp_Z = interval_Z/30
  for i = 1, sub_count-1 do
    local grab_point = {}
	grab_point[1] = entry[i][1] + interval_X
	grab_point[2] = entry[i][2] + interval_Y
	grab_point[3] = entry[i][3] + interval_Z
	--print(string.format("Added points: %d, %d, %d", grab_point[1], grab_point[2], grab_point[3]))
    entry[i+1] = grab_point
  end
  if sub_count == 0 then
    table.insert(entry, {mid_X, mid_Y, mid_Z}) -- Add mid point target
  end
  return entry
end

function GetVectorDirection(playerPos, targetPos)
  local dir = {
    targetPos[1] - playerPos[1],
	0,
	targetPos[3] - playerPos[3]
  }
  
  local magnitude = math.sqrt(dir[1]^2 + dir[3]^2)
  if magnitude > 0 then
    dir[1] = dir[1]/magnitude
	dir[3] = dir[3]/magnitude
  end
  
  return dir
end

function CalcYaw(direction)
  return math.atan(direction[3], direction[1])
end

function yawToQuat(yaw)
  local halfYaw = yaw * 0.5
  local sinHalf = math.sin(halfYaw)
  local cosHalf = math.cos(halfYaw)
  
  return {
    0,
	sinHalf,
	0,
	cosHalf
  }
end

function GenerateCircle(radius, numPoints)
  local m_pos = GetPlayerPos()
  local pos = {}
  pos[1] = m_pos.X
  pos[2] = m_pos.Y
  pos[3] = m_pos.Z
  
  local points = {}
  local angleStep = 2 * math.pi/numPoints
  
  for i = 1, numPoints do
    local angle = angleStep * i
	local x = pos[1] + radius * math.cos(angle)
	local z = pos[3] + radius * math.sin(angle)
	
	local y = pos[2]
	
	table.insert(points, {x,y,z})
  end
  
  return points
end
--local points = GenerateCircle(500, 20)
G_TIME_DELAY = 1/60
G_STEP_COUNT = 3
G_SMOOTHING_COUNT = 3
G_SAMPLE_COUNT = 10
G_RADIUS = 500
G_SMOOTHING_COUNT_FINAL = 10
function ObjTest()
  local poses = {
	  {-2091,  551, 13950},
	  {-1897,  551, 13886},
	  {-1864,  551, 13712},
	  {-1907,  551, 13513},
	  {-2078,  551, 13423},
	  {-2288,  551, 13438},
	  {-2398,  551, 13606},
	  {-2414,  551, 13806},
	  {-2318,  551, 13901},
	  {-2091,  551, 13950},
	  {-1897,  551, 13886},
	  height = 551
	}
  while true do
    local poses = GenerateCircle(G_RADIUS, G_SAMPLE_COUNT)
	local player = GetPlayerPos()
	local p = {}
	p[1] = player.X
	p[2] = player.Y
	p[3] = player.Z
	local emeralds = {b = 1, r = 3, g = 5, p = 7, s = 9, w = 11, y = 13}
    for i = 1, table.getn(poses) do
	  local cap = table.getn(poses)
	  for k, v in pairs(emeralds) do
	    if v > cap then
		  v = v - cap
		  emeralds[k] = v
		end
	    Game.NewActor("objectphysics",{objectName="emerald_" .. k,restart = false},{Position = Vector(poses[v][1],poses[v][2]+50,poses[v][3]), Rotation = Vector(0,0,0,0), Preload = true})
	  end
	  local step = 1
	  while step <= G_STEP_COUNT do
	    if poses[i+1] == nil then break end
		local em_poses = { r = {}, b = {}, g = {}, p = {}, s = {}, w = {}, y = {} }
		for k, v in pairs(emeralds) do
		  local next_idx = v+1
		  
		  if poses[next_idx] == nil then next_idx = 1 end
		  local my_pos = Interpolate(poses[v], poses[next_idx], G_SMOOTHING_COUNT)
		  table.insert(em_poses[k], my_pos)
		  if next_idx == 1 then emeralds[k] = 1 end
		  emeralds[k] = emeralds[k] + 1
		end
		local pos_count = table.getn(em_poses.r[1])
		for j = 1, pos_count do
		  for k, v in pairs(em_poses) do
		    Game.NewActor("objectphysics",{objectName="emerald_" .. k,restart = false},{Position = Vector(v[1][j][1],v[1][j][2]+50,v[1][j][3]), Rotation = Vector(0,0,0,0), Preload = true})
		  end
		  RestFor("OT", G_TIME_DELAY)
		end
	    step = step + 1
	  end
	end
	local em_poses = { r = {}, b = {}, g = {}, p = {}, s = {}, w = {}, y = {} }
	for k, v in pairs(emeralds) do
	  local next_idx = v+1
	  
	  if poses[next_idx] == nil then next_idx = 1 end
	  local my_pos = Interpolate(poses[v], p, G_SMOOTHING_COUNT_FINAL)
	  table.insert(em_poses[k], my_pos)
	  if next_idx == 1 then emeralds[k] = 1 end
	  emeralds[k] = emeralds[k] + 1
	end
	for j = 1, G_SMOOTHING_COUNT_FINAL do
	  for k, v in pairs(em_poses) do
		Game.NewActor("objectphysics",{objectName="emerald_" .. k,restart = false},{Position = Vector(v[1][j][1],v[1][j][2]+50,v[1][j][3]) , Rotation = Vector(0,0,0,0), Preload = true} )
	  end
	  RestFor("OT", G_TIME_DELAY)
	end
	--ResetCameraTest()
    coroutine.yield()
  end
end

local cam_poses = {
  {-6549, 551, 18874},
  {-4000, 551, 17280},
  {-3599, 551, 16644},
  {-2461, 551, 15819},
  {-2567, 943, 15039},
  {-2961, 551, 12942},
  {-3792, 551, 11863},
  {-5524, 67, 13077},
  {-7587, -638, 14494},
  {-4358, -694, 19421},
  {-6278, -638, 20955},
  {-12994, 1301, 14670},
  {-17392, 0, 6232},
  {-9596, 1164, -32},
  {-11340, 705, -4480},
  {-11093, 243, -5781}
}

function UpdateMyCam(my_eye, my_tgt)
  Game.ProcessMessage("LEVEL", "FixCamera", {
    eye = my_eye,
    target = my_tgt
  })
end
G_TGT_OFFSET = 1
G_EYE_OFFSET = 1
g_cam_poses = {
  {-6549, 551, 18874},
  {-4000, 551, 17280},
  {-3599, 551, 16644},
  {-2461, 551, 15819},
  {-2567, 943, 15039},
  {-2961, 551, 12942},
  {-3792, 551, 11863},
  {-5524, 67, 13077},
  {-7587, -638, 14494},
  {-4358, -694, 19421},
  {-6278, -638, 20955},
  {-12994, 1301, 14670},
  {-17392, 0, 6232},
  {-9596, 1164, -32},
  {-11340, 705, -4480},
  {-11093, 243, -5781}
}
function CamPath()
  while true do
    for i = 1, table.getn(g_cam_poses) do
	  local step = 1
	  while step <= G_STEP_COUNT do
	    if g_cam_poses[i+1] == nil then break end
		
	    local my_pos = Interpolate(g_cam_poses[i], g_cam_poses[i+1], G_SMOOTHING_COUNT)
		for i = 1, table.getn(my_pos) do
		  UpdateMyCam(my_pos[i+G_EYE_OFFSET] or my_pos[i], (my_pos[i+G_TGT_OFFSET] or my_pos[i]))
		  RestFor("CPT", G_TIME_DELAY)
		end
	    step = step + 1
	  end
	end
	ResetCameraTest()
    coroutine.yield()
  end
end
--[[
function ObjTest()
  local poses = {
	  {-2091,  551, 13950},
	  {-1897,  551, 13886},
	  {-1864,  551, 13712},
	  {-1907,  551, 13513},
	  {-2078,  551, 13423},
	  {-2288,  551, 13438},
	  {-2398,  551, 13606},
	  {-2414,  551, 13806},
	  {-2318,  551, 13901},
	  {-2091,  551, 13950},
	  {-1897,  551, 13886},
	  height = 551
	}
  while true do
    local poses = GenerateCircle(G_RADIUS, G_SAMPLE_COUNT)
	local emeralds = {b = 1, r = 3, g = 5, p = 7, s = 9, w = 11, y = 13}
    for i = 1, table.getn(poses) do
	  local cap = table.getn(poses)
	  for k, v in pairs(emeralds) do
	    if v > cap then
		  v = v - cap
		  emeralds[k] = v
		end
	    Game.NewActor("objectphysics",{objectName="emerald_" .. k,restart = false},{Position = Vector(poses[v][1],poses[v][2],poses[v][3]) , Rotation = Vector(0,0,0,0)})
	  end
	  local step = 1
	  while step <= G_STEP_COUNT do
	    if poses[i+1] == nil then break end
		local em_poses = {}
		
	    local my_pos = Interpolate(poses[i], poses[i+1], G_SMOOTHING_COUNT)
		for i = 1, table.getn(my_pos) do
		--print("SPAWNED: " .. tostring(my_pos[i][1]) .. "   " .. tostring(my_pos[i][3]))
		  Game.NewActor("objectphysics",{objectName=G_OBJ_NAME,restart = false},{Position = Vector(my_pos[i][1],my_pos[i][2],my_pos[i][3]) , Rotation = Vector(0,0,0,0)})	
		  RestFor("OT", G_TIME_DELAY)
		end
	    step = step + 1
	  end
	end
	ResetCameraTest()
    coroutine.yield()
  end
end
]]

DefineProcess("CHECK_TEST", CT)
DefineProcess("MS", ManageMoonsault)
DefineProcess("SDJ", ManageSpindashJump)
DefineProcess("EJ", ManageEdgeJump)
DefineProcess("ES", ManageEdgeShuffle)
DefineProcess("OT", ObjTest)
DefineProcess("CamShake", CameraShake)
DefineProcess("CPT", CamPath)

DefineProcess("MAT", ModifyAnimationTiming)
DefineProcess("AT", AnimTest)


DefineProcess("LD", LaunchDecay)
---------------------------------


---------Script Reload----------
Game.ExecScript("scripts/stage/khronos/wip/custom_gauges.lua")
Game.ExecScript("scripts/stage/khronos/wip/rail_states.lua")
Game.ExecScript("scripts/stage/khronos/wip/standard_states.lua")
---------------------------------