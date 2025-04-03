--@BRIEF: Loads additional libraries and defines some common functions.

USE_DEBUG_COMMENTS = true -- Constant for error handling and other checks.
USE_DLL_HELPERS = true
mAbs, mRad, mDeg, mSin, mFloor, mMin, mMax, mAcos, mSqrt, mCos = math.abs, math.rad, math.deg, math.sin, math.floor, math.min, math.max, math.acos, math.sqrt, math.cos

-- Extended State globals
LEOS_StateOnAnyPre        = -15 
LEOS_StateOnAnyPost        = -14
LEOS_StateOnAnyNo        = -13 

LEOS_StateOnStartPre    = 17 
LEOS_StateOnStartPost    = 18
LEOS_StateOnStartNo        = 19
                    
LEOS_StateOnUpdatePre    = 33
LEOS_StateOnUpdatePost    = 34 
LEOS_StateOnUpdateNo    = 35
                    
LEOS_StateOnEndPre        = 49
LEOS_StateOnEndPost        = 50
LEOS_StateOnEndNo        = 51

-- Since some callers may not have access to the Game library, we're setting up aliases.
Game = Game or {}
Game.ExecScript = Game.ExecScript or script.reload
print = print or Game.Log

function PrintOutput(tabl, name)
  if type(tabl) ~= "table" then
    print(name .. " IS NOT A TABLE! Type of: " .. type(tabl))
	return
  end
  name = name or tostring(tabl)
  print("----------------")
  print("OUTPUTTING: " .. name)
  for k, v in pairs(tabl) do
    if type(k) == "string" then
      print("KEY: " .. tostring(k))
	  print("VAL: " .. tostring(v))
	else
	  print(k .. " VAL: " .. tostring(v))
	end
  end
  print("FINISHED")
end

function DebugPrint(msg)
  if USE_DEBUG_COMMENTS then
    print(msg)
  end
end

function HEX(hex_str)
  return tonumber(hex_str, 16)
end

function QuatMultiply(q1, q2)
    local w1, x1, y1, z1 = q1[4], q1[1], q1[2], q1[3]
    local w2, x2, y2, z2 = q2[4], q2[1], q2[2], q2[3]
    
    local w = w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2
    local x = w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2
    local y = w1 * y2 + y1 * w2 + z1 * x2 - x1 * z2
    local z = w1 * z2 + z1 * w2 + x1 * y2 - y1 * x2
    
    return {x, y, z, w}
end 

Game.ExecScript("scripts/stage/khronos/threads.lua")
if USE_DLL_HELPERS then
  Game.ExecScript("scripts/stage/khronos/dll_helpers/input_detection.lua")
  Game.ExecScript("scripts/stage/khronos/dll_helpers/pointers_and_memory.lua")
  Game.ExecScript("scripts/stage/khronos/dll_helpers/player_lua_modification.lua")
  Game.ExecScript("scripts/stage/khronos/dll_helpers/player_utilites.lua")
  Game.ExecScript("scripts/stage/khronos/dll_helpers/animation_utilities.lua")
  Game.ExecScript("scripts/stage/khronos/dll_helpers/debug_suite.lua")
  
  Game.ExecScript("scripts/stage/khronos/wip/state_enums.lua")
  Game.ExecScript("scripts/stage/khronos/wip/flag_manager.lua")
end

function SetDeepMetaTable(target, fallback) -- Creates a lookup table that also supports checking nested values
  for k, v in pairs(target) do
    if type(v) == "table" then
      -- If the value is a table, recursively apply metatables
      if type(fallback[k]) == "table" then
        SetDeepMetaTable(v, fallback[k])
      end
      -- Set the metatable for this table
      setmetatable(v, { __index = fallback[k] })
    end
  end
  -- Set the metatable for the top-level table
  setmetatable(target, { __index = fallback })
end
