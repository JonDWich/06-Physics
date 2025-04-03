-- @BRIEF: Internal state id documentation

StateID = {
  WAIT = 0,
  WALK = 1,
  RUN = 2,
  FALL = 3,
  JUMP = 4,
  JUMP_WATER = 5,
  STOP = 6,
  QUICK_TURN = 7,
  DEAD = 8,
  DAMAGE_LIGHT = 9,
  PUSH = 10,
  BONK = 11,
  GRIND = 12,
  UK_1 = 13, -- UNKNOWN
  -- 14
  -- 15
  OTTOTTO = 16,
  SPRING = 17,
  ROPE = 18,
  SPRING_2 = 19, -- Unknown
  DASH_PANEL = 20,
  JUMP_PANEL = 21,
  GOAL = 22,
  GOAL_LOOP = 23,
  WIND = 24,
  LANDING = 25,
  DONT_MOVE = 26,
  UP_DOWN_REEL = 27,
  TARZAN = 28,
  BUNGEE = 29,
  POLL = 30,
  CHAINJUMP_LAND = 31,
  RAINBOW_RING = 32,
  WALL_WAIT = 33,
  ROPE_LAND = 34,
  CLIMB = 35,
  GEM_PURPLE = 36,
  TALK = 37,
  HOLD = 38,
  -- 39
  STUN = 40, -- Piyori
  RODEO = 41,
  BALANCER = 42,
  WATER_SLIDE = 43,
  GLIDE = 44,
  GLIDE_END = 45,
  BOMB_SEARCH_TAP = 46,
  BOMB_SEARCH_HOLD = 47,
  AMIGO_SWAP = 48,
  AMIGO_CHASE = 49, -- Only valid as an amigo, might be for lockon?
  -- 49-64???
  SUPER_CHANGE = 50, -- Super State amigo change
  TELEPORT_DASH = 51,
  FLOAT = 52,
  WATER_WALK = 53,
  LIFT = 56,
  ESP_MARK = 57,
  GROUND_THROW = 58,
  AIR_THROW = 59,
  GRAB_ALL = 60,
  PSYCHOSHOCK = 61,
  STUN_SLAP_GROUND = 62,
  STUN_SLAP_AIR = 63,
  HOMING_CHARGE = 65,
  HOMING_RELEASE = 66,
  HOMING_AFTER = 67,
  SLIDING = 68,
  EDGE_ATTACK = 69,
  SPIN_DASH = 70,
  BOUNCE = 71,
  LIGHT_DASH = 72,
  GEM_BLUE = 73,
  GEM_GREEN = 74,
  GEM_GREEN_AIR = 75,
  -- 76?
  GEM_RAINBOW = 77,
  HOVER = 78,
  LAUNCHER = 79,
  LOCKON = 80, -- Omega's multi-lockon attack
  OVERDRIVE = 81,
  CHAOS_SPEAR = 82,
  CHAOS_SPEAR_AFTER = 83,
  CHAOS_BLAST = 84,
  CHAOS_SMASH_WAIT = 85,
  CHAOS_SMASH = 86,
  CHAOS_ATTACK = 87,
  CHAOS_SNAP = 88,
  TORNADO_KICK = 89,
  SHADOW_ATTACK = 90,
  -- Amy states
  STEALTH_START = 92,
  STEALTH_END = 93,
  DOUBLE_JUMP_PRE = 94,
  DOUBLE_JUMP = 95,
  HAMMER_ATTACK = 96,
  -- Blaze states
  ACCEL_TORNADO = 97,
  SPINNING_CLAW = 98,
  FIRE_CLAW = 99,
  -- Knuckles states
  HEAT_KNUCKLE = 100,
  SCREWDRIVER = 101, -- Also applies to the travel part
  SCREWDRIVER_AFTER = 102, -- HA recovery
  SCREW_DIVE = 103,
  -- Rouge states
  BOMB_AIR = 104,
  BOMB_SPEARD = 105, -- Air bomb hold
  HEART_MINE = 106,
  -- Super states
  SUPER_ACTION = 107, -- Light Attack, Super Chaos Lance
  PSYCHO_FIELD = 108, -- Super Silver's grab
  -- Vehicle states
  VEHICLE_ENTER = 109,
  VEHICLE_AUTOTAKE = 110, -- Automatically enter the vehicle on spawn
  BIKE_RIDE = 111,
  JEEP_RIDE = 112,
  HOVER_RIDE = 113,
  GLIDER_RIDE = 114,
  VEHICLE_EXIT = 115,
}
local StateID_Fast = {
  START = 0,
  RUN = 1,
  FALL = 2,
  JUMP = 3,
  DAMAGE = 4,
  DEAD = 5,
  DRAMATIC_JUMP = 6,
  -- 7?
  JUMP_PANEL = 8,
  WIDE_SPRING = 9,
  SPRING = 10, -- Just a guess, seems correct though
  LIGHT_DASH = 11,
  CHAINJUMP = 12,
  CHAINJUMP_FALL = 13,
  GOAL = 14,
} -- Just for my own use, for now

local StateID_Board = {
  RIDE = 0,
  BRAKE = 1,
  CROUCH = 2,
  FALL = 3,
  JUMP = 4,
  JUMP_GIMMICK = 5,
  DAMAGE = 6,
  DEAD = 7,
  GRIND = 8,
  GRIND_BRAKE = 9,
  GRIND_CROUCH = 10,
  COLLIDE = 11,
  LAND = 12
}