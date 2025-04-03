--@Brief: Scheduler script

-- $$INSTRUCTIONS:$$
-- Define a coroutine via DefineProcess(string handle, function to register)
-- Execute via PlayProcess(string handle)
-- Pause via RestFor(string handle, time)

processes = {
  _ProcessList = {},
  _SleptProcesses = {} -- func, sleep_time
}

function CheckProcessExists(name) -- Make sure a coroutine exists. Return the internal sleep_time and the coroutine's status.
  if processes._ProcessList[name] then
    local sleep = processes._SleptProcesses[name] and processes._SleptProcesses[name].sleep_time or 0
	local status = coroutine.status(processes._ProcessList[name])
    return true, sleep, status
  else
    return false
  end
end

function DefineProcess(name, func) -- Register a new coroutine to a string handle and add it to the processes table.
  if processes._ProcessList[name] then
    return 
  else
	processes._ProcessList[name] = coroutine.create(func)
	print("Defined process " .. name .. " type: " .. tostring(processes._ProcessList[name]))
  end
end

function RestFor(name, time, ...) -- Pauses a coroutine via its string handle for a length of time. If time is not provided, default to 1 frame.
  time = time or 1/60
  local exists = CheckProcessExists(name)
  if not exists then
    DebugPrint("RestFor: Invalid coroutine " .. tostring(name))
	return
  end
  local co = processes._ProcessList[name]
  processes._SleptProcesses[name] = {func = co, sleep_time = time}
  --print("Rested " .. name .. " For time: " .. processes._SleptProcesses[name].sleep_time)
  coroutine.yield(co)
end

function PlayProcess(name, ...) -- Starts a coroutine via its string handle.
  local exists, sleep_time, status = CheckProcessExists(name)
  if not exists then
    return 
  elseif status == "dead" then
    DebugPrint("Coroutine " .. tostring(name) .. " is dead")
	processes._SleptProcesses[name] = nil
	processes._ProcessList[name] = nil
	collectgarbage() -- Clean up the dead coroutine.
	return
  end
  if sleep_time <= 0 then
    processes._SleptProcesses[name] = nil
    coroutine.resume(processes._ProcessList[name], unpack(arg))
  end
end

function RedefineProcess(name, func) -- Currently unused. Re-registers a coroutine if it dies.
  local exists, _, status = CheckProcessExists(name)
  if exists then
    processes._SleptProcesses[name] = nil
	processes._ProcessList[name] = nil
	collectgarbage() -- Clean up the dead coroutine.
	DefineProcess(name, func)
  end
end

function SleepStep(delta) -- Iterate over slept coroutines, automatically resume them when time expires.
  for name, v in pairs(processes._SleptProcesses) do
    v.sleep_time = v.sleep_time - delta
    if v.sleep_time <= 0 then
	  PlayProcess(name)
	end
  end
end