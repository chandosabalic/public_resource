-- unified_ae2_monitor.lua
local monitor = peripheral.find("monitor")
local bridge = peripheral.find("meBridge")

if not monitor then error("Monitor not found") end
if not bridge then error("ME Bridge not found") end

monitor.setTextScale(0.5)
monitor.clear()

local selected = 1 -- 1 = CPU, 2 = Storage, 3 = Crafting

-- Draw menu bar
local function drawMenu()
  monitor.setBackgroundColor(colors.black)
  monitor.setTextColor(colors.white)
  monitor.setCursorPos(1,1)
  monitor.clearLine()
  monitor.write("[1]CPU  [2]Storage  [3]Craft")
end

-- Draw CPU status
local function drawCPU()
  local cpus = bridge.getCraftingCPUs()
  monitor.clear()
  drawMenu()
  monitor.setCursorPos(1,3)
  monitor.write("Crafting CPUs:")
  local y = 4
  for i, c in ipairs(cpus) do
    local busy = c.busy and "BUSY" or "IDLE"
    monitor.setCursorPos(1,y)
    monitor.write(string.format("CPU %d: %s", i, busy))
    y = y + 1
  end
end

-- Draw storage info
local function drawStorage()
  local items = bridge.getAvailableItems()
  monitor.clear()
  drawMenu()
  monitor.setCursorPos(1,3)
  monitor.write("Top Stored Items:")
  local y = 4
  table.sort(items, function(a,b) return a.amount > b.amount end)
  for i=1,math.min(12, #items) do
    local item = items[i]
    monitor.setCursorPos(1,y)
    monitor.write(string.format("%s x%d", item.displayName:sub(1,18), item.amount))
    y = y + 1
  end
end

-- Crafting screen
local function drawCrafting()
  monitor.clear()
  drawMenu()
  monitor.setCursorPos(1,3)
  monitor.write("Crafting oak_planks x64")
  local ok, err = pcall(function()
    local job = bridge.scheduleCrafting("item", "minecraft:oak_planks", 64)
    monitor.setCursorPos(1,5)
    monitor.write("Job started: ID "..tostring(job))
  end)
  if not ok then
    monitor.setCursorPos(1,5)
    monitor.write("Failed to craft: "..err)
  end
end

-- Redraw selected screen
local function redraw()
  if selected == 1 then drawCPU()
  elseif selected == 2 then drawStorage()
  elseif selected == 3 then drawCrafting()
  end
end

-- Touch detection
local function handleTouch(x, y)
  if y == 1 then
    if x >= 1 and x <= 6 then selected = 1
    elseif x >= 9 and x <= 17 then selected = 2
    elseif x >= 20 and x <= 27 then selected = 3
    end
    redraw()
  end
end

-- Main loop
redraw()
while true do
  local e, side, x, y = os.pullEvent("monitor_touch")
  handleTouch(x, y)
end
