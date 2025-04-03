-- @BRIEF: Functions for retrieving the underlying structures used by other functions.

local player_init = {
  {init = false, p_custom = {}}, {init = false, p_custom = {}}, {init = false, p_custom = {}}, {init = false, p_custom = {}}
}
function InitPlayer(player_id)
  player_id = player_id + 1 -- Tables start at index 1
  if (player_id) > table.getn(player_init) then
    DebugPrint("InitPlayer: Invalid player_id when accessing table")
	return
  end
  if not player_init[player_id].init then
    player_init[player_id].init = true
	player_init[player_id].p_custom = Player(player_id - 1)
  end
end

function ReloadPlayer()
  DebugPrint("Reload. Status: " .. tostring(is_reloading))
  is_reloading = true
  for playerID, player_data in ipairs(player_init) do
    if player_data.init then
	  DebugPrint("Reloading ID: " .. playerID - 1)
	  player_init[playerID].p_custom = Player(playerID-1)
	  local data = player_init[playerID].p_custom
	  print("DATA IS: " .. tostring(data))
	  data:Reload()
	end
  end
  is_reloading = false
  DebugPrint("Reload finished")
end

function GetPlayerData(player_id) -- Gets the raw data, like from Player(0).
  local index = player_id + 1
  InitPlayer(player_id)
  local plr = player_init[index].p_custom
  plr:Reload()
  return plr
end

function GetPlayerPointer(player_id) -- ObjectPlayer  ObjPlayer:Move("0x17C"):GetFLOAT()
  player_id = player_id + 1
  if not player_init[player_id].init then
	InitPlayer(player_id - 1)
	DebugPrint("Init player: " .. player_id - 1 .. " id of: " .. tostring(player_init[player_id].p_custom))
  end
  local plr = player_init[player_id].p_custom
  plr:Reload()
  local player_pointer = plr:GetPTR()
  --player_pointer:Reload()
  return player_pointer
end

function GetPlayerPosture(player_id)
  player_id = player_id or 0
  local object_player = GetPlayerPointer(player_id)
  if object_player == nil then
    DebugPrint("GetPlayerPosture: Invalid player pointer. P_ID: " .. player_id)
	return
  end
  local posture_ptr = Memory(object_player):Move("0xDC"):GetPointer():GetPTR()
  --DebugPrint("POSTURE: " .. tostring(posture_ptr))
  return posture_ptr
end

function GetPlayerMachine(player_id)
  player_id = player_id or 0
  local player_pointer = GetPlayerPointer(player_id)
  if player_pointer == nil then
    DebugPrint("GetPlayerMachine: Invalid player pointer. P_ID: " .. player_id)
	return
  end
  local msh_ptr = memory.GetPointer(player_pointer, 228)
  if msh_ptr then
    return msh_ptr
  else
    DebugPrint("GetPlayerMachine: Nil machine pointer.")
	return
  end
end

function GetPlayerRootFrame(player_id)
  player_id = player_id or 0
  local player_pointer = GetPlayerPointer(player_id) -- ObjectPlayer
  if not player_pointer then
    DebugPrint("GetPlayerRootFrame:  Invalid player pointer...")
	return
  end
  local root_frame = Memory(player_pointer):Move("0xCC"):GetPointer()
  if root_frame then
    return root_frame
  else
    DebugPrint("GetPlayerRootFrame: Invalid root frame...")
    return
  end
end

function GetAnimationHierarchy(player_id)
  player_id = player_id or 0
  local player_pointer = Player(player_id)
  if not player_pointer:IsValidPTR() then
    DebugPrint("GetAnimationHierarchy: Invalid player pointer...")
	return
  end
  local model = player_pointer:Move("0xD4"):GetPointer()
  local pmodel = model:Move("0x30"):GetPointer()
  local AnimationPackageModel = pmodel:Move("0x98"):GetPointer()
  if AnimationPackageModel:GetPointer() == Memory("0x8200CA6C") then -- Try removing GetPointer() from this line
    AnimationPackageModel = AnimationPackageModel:Move("0xC"):GetPointer()
  end
  local AnimationHierarchy = AnimationPackageModel:Move("0x4"):GetPointer()
  return AnimationHierarchy
end

function GetCharacterModel(player_id)
  player_id = player_id or 0
  local player_pointer = Player(player_id)
  if not player_pointer:IsValidPTR() then
    DebugPrint("GetCharacterModel: Invalid player pointer...")
	return
  end
  local model = player_pointer:Move("0xD4"):GetPointer()
  return model
end


function GetCharacterGauge(player_id)
  player_id = player_id or 0
  local obj_player = Player(player_id)
  local gauge = obj_player:Move("0x104"):GetPointer()
  return gauge
end

function GetCharacterContext(player_id) -- Current method of getting character context. Works with chaining values.
  player_id = player_id or 0
  if Player(player_id):IsValidPTR() then
    local character_context = Player(player_id):Move("0xE4"):GetPointer():Move("0x50"):GetPointer()
	return character_context
  else
    DebugPrint("GetCharacterContext: Invalid pointer...")
	return
  end
end

function TestWeaponValues()
  local obj = Player(0)
  local cCtx = obj:GetIPluginByName("sonic_weapons")
  local prefix = "0x"
  for i = 0,4000, 4 do
    local hex = string.format("%x", i)
	local offset = prefix .. hex
	local output = cCtx:Move(offset):GetDWORD()
	if output >= 0.1 and output <= 200 then
	  print(offset .. ": " .. output)
	end
  end
end

local byte_table = {}
local first_go = true
function TestCharBytes()
  local cCtx = GetCharacterModel(0)
  local prefix = "0x"
  for i = 0, 1000 do
    local hex = string.format("%x", i)
	local offset = prefix .. hex
	local output = cCtx:Move(offset):GetBYTE()
	if output == 0 or output == 1 then
	  --print(offset .. ": " .. output)
	  if first_go then
	    byte_table[offset] = output
	  else
	    if byte_table[offset] ~= output then
		  print(offset .. ": " .. output)
		end
	  end
	end
  end
  if not first_go then byte_table = {} end
  first_go = not first_go
end

local test_offsets = {"0x8D", "0x242",}
function TestIndividualByte(idx)
  player.print(test_offsets[idx])
  local cCtx = GetCharacterModel(0)
  local my_offset = test_offsets[idx]
  local status = GetInput("rt", "hold") and 0 or 1
  print("STATUS: " .. status)
  cCtx:Move(my_offset):SetBYTE(status)
end

-- 0x23c: lockon for Sonic, ignore Y speed
-- 0xE7: Gravity application
-- 0xE3: Force forward movement
-- 0xE9: Moves the player off the ground, briefly?
-- 0x10B: Goal cam mode?
-- 0x10D: Kill if 0 rings
function TestByteThing()
  local cCtx = GetCharacterContext(0)
  local dd, de, df, e4, e5, e6, e8, eb, ec, ed, ee, ef
  dd = cCtx:Move("0xDD"):GetBYTE()
  de = cCtx:Move("0xDE"):GetBYTE()
  df = cCtx:Move("0xDF"):GetBYTE()
  e4 = cCtx:Move("0xE4"):GetBYTE()
  e5 = cCtx:Move("0xE5"):GetBYTE()
  e6 = cCtx:Move("0xE6"):GetBYTE()
  e8 = cCtx:Move("0xE8"):GetBYTE()
  eb = cCtx:Move("0xEB"):GetBYTE()
  ec = cCtx:Move("0xEC"):GetBYTE()
  ed = cCtx:Move("0xED"):GetBYTE()
  ee = cCtx:Move("0xEE"):GetBYTE()
  ef = cCtx:Move("0xEF"):GetBYTE()
  local space = " | "
  player.print("BYTE: " .. e4 .. space .. e5 .. space .. e6 .. space .. e8 .. space .. eb .. space .. ec .. space .. ed .. space .. ee .. space .. ef)
  --player.print("WATER: " .. tostring(value))
end

function GetPlayerContext(player_id) -- Legacy method, kept for backwards compatibility.
  player_id = player_id or 0
  local msh_ptr = GetPlayerMachine(player_id)
  if msh_ptr == nil then
    DebugPrint("GetPlayerContext: Invalid machine pointer...")
	return
  end
  local player_context = memory.GetPointer(msh_ptr, 80)
  return player_context
end

function GetGravityModule(player_id)
  player_id = player_id or 0
  local gravity_module = Player(player_id):Move("0xEC"):GetPointer()
  -- Move("0x50")/54/58 for the X/Y/Z gravity vector
  return gravity_module
end

function GetPlayerMemoryValue(data_type, memory_id, player_id)
  memory_id = memory_id or 0
  player_id = player_id or 0
  data_type = string.lower(data_type)
  local msh_ptr = GetPlayerMachine(player_id) -- Get a reference to the player's general data
  if (msh_ptr == nil) then
    DebugPrint("GetPlayerMemoryValue: Invalid machine pointer...")
	return
  end
  local player_context = memory.GetPointer(msh_ptr, 80) --GetPlayerContext(player_id) -- Pointer to specific information
  local mem_GetVal = function() return nil end
  if data_type == "float" then
    mem_GetVal = memory.GetFLOAT
  elseif data_type == "add" then
    mem_GetVal = memory.ADD
  elseif data_type == "pointer" then
    mem_GetVal = memory.GetPointer
  elseif data_type == "dword" then
    mem_GetVal = memory.GetDWORD
  elseif data_type == "byte" then
    mem_GetVal = memory.GetBYTE
  end
  return mem_GetVal(player_context, memory_id)
end

function SetPlayerMemoryValue(data_type, mem_ptr, value, player_id)
  player_id = player_id or 0
  data_type = string.lower(data_type)
  local msh_ptr = GetPlayerMachine(player_id)
  if (msh_ptr) == nil then -- Ensures the player exists before we try to do *anything*
    DebugPrint("SetPlayerMemoryValue: Invalid machine pointer...")
	return
  end
  local mem_SetVal = function() return end
  if data_type == "float" then
    mem_SetVal = memory.SetFLOAT
  elseif data_type == "byte" then
    mem_SetVal = memory.SetBYTE
  elseif data_type == "dword" then
    mem_SetVal = memory.SetDWORD
  elseif data_type == "pointer" then
    mem_SetVal = memory.SetPointerValue
  end
  mem_SetVal(mem_ptr, value)
end

-----------MISSION BLOCK-----------
function GetDocMarathon() -- DocMarathonImp
  local doc_marathon_impulse = Memory("0x82D3B348"):GetPointer():Move("0x180"):GetPointer()
  if not doc_marathon_impulse then
    DebugPrint("GetDocMarathon: Failed to get...")
    return
  end
  return doc_marathon_impulse
end

function GetDocMode() -- DocCurrentMode
  local dmi = GetDocMarathon()
  if not dmi then
    DebugPrint("GetDocMode: Invalid DMI...")
	return
  end
  local current_mode = dmi:Move("0x8"):GetPointer()
  return current_mode
end

function GetGameImpulse() -- DocModeGameIMP
  local mode = GetDocMode()
  if not mode then
    DebugPrint("GetGameImpulse: Failed to get current mode...")
	return
  end
  local impulse = mode:Move("0x6C"):GetPointer()
  return impulse
end

function GetMissionCore() -- MissionCore
  local game_impulse = GetGameImpulse()
  if not game_impulse then
    DebugPrint("GetMissionCore: Failed to get game impulse...")
	return
  end
  local mission_core = game_impulse:Move("0x1714"):GetPointer()
  return mission_core
end

function GetMissionPointer() -- VirtualMashineMission
  local mission_core = GetMissionCore()
  if not mission_core then
    DebugPrint("GetMissionPointer: Failed to get mission core...")
	return
  end
  local virtual_mashine_mission = mission_core:Move("0x10"):GetPointer().ptr
  return virtual_mashine_mission
end
-----------------------------------

-----------HUD BLOCK---------------
function GetDisplayTask()
  local game_impulse = GetGameImpulse()
  local main_display = game_impulse:Move("0x1230"):GetPointer()
  return main_display
end

function GetHUDDisplay()
  local main_display = GetDisplayTask()
  local hud_main_display = main_display:Move("0x4C"):GetPointer()
  return hud_main_display
end

function GetCSDObject()
  local hud_main_display = GetHUDDisplay()
  local csd_obj = hud_main_display:Move("0x54"):GetPointer()
  return csd_obj
end
-----------------------------------