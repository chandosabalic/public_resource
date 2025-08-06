local modem = peripheral.find("modem")  -- Required for HTTP
assert(modem, "Modem required for HTTP")

local function getDiskSides()
    local sides = {"left", "right", "top", "bottom", "front", "back"}
    local diskA, diskB = nil, nil
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "drive" then
            if not diskA then diskA = side
            elseif not diskB then diskB = side end
        end
    end
    assert(diskA and diskB, "Two disk drives required")
    return diskA, diskB
end

local function drawFrame(frame, monitor)
    for y, line in ipairs(frame) do
        local text, textColor, bgColor = table.unpack(line)
        monitor.setCursorPos(1, y)
        monitor.blit(text, textColor, bgColor)
    end
end

local function playChunkFromDisk(diskSide, monitor)
    local mount = disk.getMountPath(diskSide)
    local chunkFile = fs.combine(mount, "chunk.lua")
    if not fs.exists(chunkFile) then
        print("No chunk.lua on disk at "..diskSide)
        return false
    end
    local ok, frames = pcall(dofile, chunkFile)
    if not ok then
        print("Failed to load chunk from "..diskSide)
        return false
    end

    for i, frame in ipairs(frames) do
        drawFrame(frame, monitor)
        sleep(1/15)
    end
    return true
end

local function eraseDisk(diskSide)
    local mount = disk.getMountPath(diskSide)
    for _, file in ipairs(fs.list(mount)) do
        fs.delete(fs.combine(mount, file))
    end
end

local function downloadChunkToDisk(chunkNum, diskSide)
    local mount = disk.getMountPath(diskSide)
    local url = "https://raw.githubusercontent.com/chandosabalic/public_resource/refs/heads/main/chunks/chunk_"..chunkNum..".lua"
    local filePath = fs.combine(mount, "chunk.lua")
    print("Downloading chunk "..chunkNum.." to "..diskSide)
    return http.request(url), filePath
end

-- MAIN PLAY LOOP
local function playVideo()
    local diskA, diskB = getDiskSides()
    local monitor = peripheral.find("monitor")
    assert(monitor, "No monitor connected")
    monitor.setTextScale(0.5)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()

    local currentDisk = diskA
    local nextDisk = diskB
    local chunkNum = 1

    -- Download first chunk
    print("Downloading first chunk...")
    local _, filePath = downloadChunkToDisk(chunkNum, currentDisk)
    local event, url, handle = os.pullEvent("http_success")
    local content = handle.readAll()
    handle.close()
    local f = fs.open(filePath, "w")
    f.write(content)
    f.close()

    while true do
        print("Playing chunk "..chunkNum.." from "..currentDisk)
        local ok = playChunkFromDisk(currentDisk, monitor)
        if not ok then break end

        chunkNum = chunkNum + 1

        -- Start downloading next chunk to other disk
        eraseDisk(nextDisk)
        local req, nextFilePath = downloadChunkToDisk(chunkNum, nextDisk)
        local event, url, handle = os.pullEvent()
        if event == "http_success" then
            local content = handle.readAll()
            handle.close()
            local f = fs.open(nextFilePath, "w")
            f.write(content)
            f.close()
        else
            print("No more chunks or download failed.")
            break
        end

        -- Swap disks
        currentDisk, nextDisk = nextDisk, currentDisk
    end

    monitor.clear()
    monitor.setCursorPos(1, 1)
    print("Playback finished.")
end

playVideo()
