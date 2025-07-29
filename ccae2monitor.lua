-- cpu_monitor_display.lua
local monitor = peripheral.find("monitor")
local bridge = peripheral.find("me_bridge")

if not monitor then error("Monitor not found") end
if not bridge then error("ME Bridge not found") end

monitor.setTextScale(0.5)

while true do
  local cpus = bridge.getCraftingCPUs()
  monitor.clear()
  monitor.setCursorPos(1,1)
  monitor.write("Crafting CPUs:")
  
  local y = 2
  for i, c in ipairs(cpus) do
    local busy = c.busy and "BUSY" or "IDLE"
    monitor.setCursorPos(1, y)
    monitor.write(string.format("CPU %d: %s", i, busy))
    y = y + 1
  end

  os.sleep(5)
end
