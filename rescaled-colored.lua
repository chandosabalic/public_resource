-- scaled_ae2_monitor_ui.lua

-- SETTINGS
local monitor = peripheral.wrap("top")  -- Change if needed
local bridge = peripheral.find("me_bridge")

if not monitor then error("Monitor not found") end
if not bridge then error("me_bridge not found") end

-- CONFIG
monitor.setTextScale(2)
local w, h = monitor.getSize()  -- For scale=2, expect ~33x20

local selected = 1  -- 1 = CPU, 2 = Storage, 3 = Crafting
local scroll = 1
local storageItems = {}
local inputName = "minecraft:oak_planks"
local inputAmt = 64
local currentJob = nil

-- UTILS
local function clear()
  monitor.setBackgroundColor(colors.black)
  monitor.clear()
end

local function center(text, y, color)
  color = color or colors.white
  monitor.setTextColor(color)
  local x = math.floor((w - #text) / 2)
  monitor.setCursorPos(x, y)
  monitor.write(text)
end

-- MENU DRAW
local function drawMenu()
  monitor.setBackgroundColor(colors.gray)
  monitor.setTextColor(colors.black)
  monitor.setCursorPos(1,1)
  monitor.clearLine()
  local menu = {"[1] CPU", "[2] Storage", "[3] Craft"}
  for i, label in ipairs(menu) do
    local x = (i - 1) * 11 + 2
    monitor.setCursorPos(x, 1)
    if selected == i then
      monitor.setBackgroundColor(colors.orange)
      monitor.setTextColor(colors.black)
    else
      monitor.setBackgroundColor(colors.gray)
      monitor.setTextColor(colors.white)
    end
    monitor.write(label)
  end
  monitor.setBackgroundColor(colors.black)
end

-- CPU View
local function drawCPU()
  clear()
  drawMenu()
  local cpus = bridge.getCraftingCPUs()
  center("Crafting CPUs", 3, colors.cyan)
  local y = 5
  for i, cpu in ipairs(cpus) do
    if y > h then break end
    monitor.setCursorPos(2, y)
    local statusColor = cpu.isBusy and colors.red or colors.lime
    monitor.setTextColor(statusColor)
    local label = string.format("CPU %d: %s", i, cpu.isBusy and "BUSY" or "IDLE")
    monitor.write(label)
    y = y + 2
  end
end

-- STORAGE View
local function refreshStorage()
  storageItems = bridge.listItems() or {}
  table.sort(storageItems, function(a,b) return a.amount > b.amount end)
end

local function drawStorage()
  clear()
  drawMenu()
  center("Top Stored Items", 3, colors.cyan)
  refreshStorage()
  local y = 5
  for i = scroll, math.min(scroll + 7, #storageItems) do
    local item = storageItems[i]
    monitor.setCursorPos(2, y)
    monitor.setTextColor(colors.yellow)
    local name = item.displayName:sub(1, 20)
    monitor.write(string.format("%2d. %-20s", i, name))
    monitor.setCursorPos(24, y)
    monitor.setTextColor(colors.white)
    monitor.write("x"..item.amount)
    y = y + 2
  end
  -- Scroll instructions
  monitor.setCursorPos(2, h)
  monitor.setTextColor(colors.gray)
  monitor.write("< Tap left/right edge to scroll >")
end

-- CRAFT View
local function drawCraft()
  clear()
  drawMenu()
  center("AutoCrafting", 3, colors.cyan)
  monitor.setCursorPos(2, 5)
  monitor.setTextColor(colors.white)
  monitor.write("Item: ")
  monitor.setTextColor(colors.yellow)
  monitor.write(inputName:sub(1, 20))

  monitor.setCursorPos(2, 7)
  monitor.setTextColor(colors.white)
  monitor.write("Amount: ")
  monitor.setTextColor(colors.yellow)
  monitor.write(tostring(inputAmt))

  if currentJob then
    local job = bridge.getCraftingJob(currentJob)
    monitor.setCursorPos(2, 9)
    monitor.setTextColor(colors.white)
    monitor.write("Status: ")
    monitor.setTextColor(colors.green)
    monitor.write(job.status or "unknown")

    monitor.setCursorPos(2, 11)
    monitor.setTextColor(colors.white)
    monitor.write("Progress: ")
    monitor.write(tostring(job.progress or 0).."/"..tostring(job.total or "?"))
  end

  monitor.setCursorPos(2, h)
  monitor.setTextColor(colors.orange)
  monitor.write("Tap bottom row to edit & send")
end

-- Handle Craft Input via Terminal
local function handleCraftInput()
  term.redirect(term.native())
  print("Enter item name (e.g. minecraft:oak_planks):")
  inputName = read()
  print("Enter amount:")
  inputAmt = tonumber(read()) or 64
  print("Sending job...")
  local result = bridge.craftItem({name=inputName, amount=inputAmt})
  if result and result.id then
    currentJob = result.id
    print("Craft job started. ID: "..currentJob)
  else
    print("Failed to craft.")
  end
  sleep(2)
  term.redirect(monitor)
  drawCraft()
end

-- TOUCH HANDLING
local function handleTouch(x, y)
  if y == 1 then
    if x <= 10 then selected = 1
    elseif x <= 21 then selected = 2
    else selected = 3 end
    redraw()
  elseif selected == 2 and y == h then
    if x < w / 2 then scroll = math.max(1, scroll - 5)
    else scroll = math.min(#storageItems - 7, scroll + 5) end
    drawStorage()
  elseif selected == 3 and y == h then
    handleCraftInput()
  end
end

-- RENDER SWITCH
function redraw()
  if selected == 1 then drawCPU()
  elseif selected == 2 then drawStorage()
  elseif selected == 3 then drawCraft()
  end
end

-- MAIN LOOP
redraw()
while true do
  local e, side, x, y = os.pullEvent("monitor_touch")
  handleTouch(x, y)
end
