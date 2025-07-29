local monitor = peripheral.wrap("top")
monitor.setTextScale(0.5)
monitor.clear()

local w, h = monitor.getSize()
monitor.setCursorPos(1,1)
monitor.write("Monitor size: "..w.."x"..h)

-- Draw a centered banner
local function center(text, y)
  local x = math.floor((w - #text) / 2)
  monitor.setCursorPos(x, y)
  monitor.write(text)
end

center("==== Unified AE2 Monitor ====", 3)
center("[1] CPU   [2] Storage   [3] Craft", 5)
