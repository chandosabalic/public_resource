-- unified_ae2_monitor.lua
local monitor = peripheral.find("monitor")
local bridge = peripheral.find("me_bridge")

if not monitor then error("Monitor not found") end
if not bridge then error("me_bridge not found") end

monitor.setTextScale(0.5)
monitor.clear()

local selected = 1 -- 1=CPU, 2=Storage, 3=Craft
local scroll = 1
local storageItems = {}

-- Util
local function center(text, y)
  local x = math.floor((64 - #text) / 2)
  monitor.setCursorPos(x, y)
  monitor.write(text)
end

local function drawMenu()
  monitor.setBackgroundColor(colors.black)
  monitor.setTextColor(colors.white)
  monitor.setCursorPos(1,1)
  monitor.clearLine()
  monitor.write(" [1]CPU  [2]Storage  [3]Craft ")
end

local function refreshItems()
  storageItems = bridge.listItems() or {}
  table.sort(storageItems, function(a,b) return a.amount > b.amount end)
end

-- CPU View
local function drawCPU()
  monitor.clear()
  drawMenu()
  local cpus = bridge.getCraftingCPUs()
  monitor.setCursorPos(1,3)
  monitor.write("Crafting CPUs:")
  for i,cpu in ipairs(cpus) do
    local y = i + 3
    if y > 10 then break end
    monitor.setCursorPos(1,y)
    local status = cpu.isBusy and "BUSY" or "IDLE"
    local str = string.format("CPU %d: %s | C: %d | S: %d",
      i, status, cpu.coProcessors, cpu.storage)
    monitor.write(str:sub(1,64))
  end
end

-- Storage View (Scrollable)
local function drawStorage()
  monitor.clear()
  drawMenu()
  refreshItems()
  monitor.setCursorPos(1,3)
  monitor.write("Storage Items (top 7):")
  for i = scroll, math.min(#storageItems, scroll + 6) do
    local y = (i - scroll) + 4
    if y > 10 then break end
    local item = storageItems[i]
    monitor.setCursorPos(1,y)
    local line = string.format("%2d. %-25s x%d", i, item.displayName, item.amount)
    monitor.write(line:sub(1,64))
  end
  -- Arrows
  monitor.setCursorPos(1,10)
  monitor.write("<Scroll Up/Down: Tap Corners>")
end

-- Craft View
local inputName = "minecraft:oak_planks"
local inputAmt = 64
local currentJob = nil

local function drawCraft()
  monitor.clear()
  drawMenu()
  monitor.setCursorPos(1,3)
  monitor.write("Autocraft Interface:")
  monitor.setCursorPos(1,4)
  monitor.write("Item: "..inputName:sub(1,48))
  monitor.setCursorPos(1,5)
  monitor.write("Amount: "..tostring(inputAmt))

  if currentJob then
    local job = bridge.getCraftingJob(currentJob)
    if job then
      monitor.setCursorPos(1,7)
      monitor.write("Job ID: "..currentJob)
      monitor.setCursorPos(1,8)
      monitor.write("Status: "..(job.status or "unknown"))
      monitor.setCursorPos(1,9)
      monitor.write("Progress: "..tostring(job.progress or 0).."/"..tostring(job.total or "?"))
    end
  end

  monitor.setCursorPos(1,10)
  monitor.write("[Tap here to edit/send craft]")
end

-- Input Handler (uses terminal)
local function handleCraftInput()
  term.redirect(term.native())
  print("Enter item name (e.g. minecraft:oak_planks):")
  inputName = read()
  print("Enter amount:")
  inputAmt = tonumber(read()) or 64
  print("Scheduling crafting job...")
  local result = bridge.craftItem({name=inputName, amount=inputAmt})
  if result and result.id then
    currentJob = result.id
    print("Craft job scheduled. Job ID:", currentJob)
  else
    print("Failed to schedule.")
  end
  sleep(2)
  term.redirect(monitor)
  drawCraft()
end

-- Touch Handler
local function handleTouch(x,y)
  if y == 1 then
    if x <= 6 then selected = 1
    elseif x <= 20 then selected = 2
    else selected = 3 end
    redraw()
  elseif selected == 2 then
    if y == 10 then
      if x <= 10 then scroll = math.max(1, scroll - 3)
      elseif x >= 55 then scroll = math.min(#storageItems - 6, scroll + 3) end
      drawStorage()
    end
  elseif selected == 3 and y == 10 then
    handleCraftInput()
  end
end

function redraw()
  if selected == 1 then drawCPU()
  elseif selected == 2 then drawStorage()
  else drawCraft()
  end
end

-- Main loop
redraw()
while true do
  local e, side, x, y = os.pullEvent("monitor_touch")
  handleTouch(x,y)
end
