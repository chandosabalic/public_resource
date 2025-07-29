-- storage_monitor_display.lua
local monitor = peripheral.find("monitor")
local bridge = peripheral.find("me_bridge")

if not monitor then error("Monitor not found") end
if not bridge then error("ME Bridge not found") end

monitor.setTextScale(0.5)

while true do
  local items = bridge.getAvailableItems()
  monitor.clear()
  monitor.setCursorPos(1,1)
  monitor.write("AE2 Storage Contents:")

  local y = 2
  for i, item in ipairs(items) do
    if y > 19 then break end -- fit max ~18 lines depending on monitor size
    monitor.setCursorPos(1, y)
    monitor.write(string.format("%s x%d", item.displayName, item.amount))
    y = y + 1
  end

  os.sleep(10)
end
