-- Auto Place Petegg in Your Farm at Random Locations
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PetEggService = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetEggService")

local LocalPlayer = Players.LocalPlayer
local Y = 0.5 -- slightly above ground level to prevent clipping
local delayTime = 1.5 -- seconds between placements
local autoPlace = true
local eggType = "Petegg" -- specifically for Petegg
local minDistance = 5 -- minimum distance between eggs (increase this if still too close)
local placedEggs = {} -- to track placed egg positions

-- Find the player's farm
local function findMyFarm()
    -- Look for farm in Workspace.Farm
    if not workspace:FindFirstChild("Farm") then
        print("Farm folder not found in workspace!")
        return nil
    end
    
    -- Method 1: Look for farm with owner value matching player name
    for _, farm in pairs(workspace.Farm:GetChildren()) do
        local data = farm:FindFirstChild("Important")
        if data and data:FindFirstChild("Data") then
            local ownerValue = data.Data:FindFirstChild("Owner")
            if ownerValue and ownerValue.Value == LocalPlayer.Name then
                print("Found farm owned by", LocalPlayer.Name)
                return farm
            end
        end
    end
    
    -- Method 2: Look for farm named after the player
    local playerFarm = workspace.Farm:FindFirstChild(LocalPlayer.Name)
    if playerFarm then
        print("Found farm named", LocalPlayer.Name)
        return playerFarm
    end
    
    print("Could not find your farm. Using default coordinates.")
    return nil
end

-- Calculate farm boundaries from farm model or use defaults
local function getFarmBounds(farm)
    if not farm then
        -- Default fallback values
        return 70, 80, -105, -95
    end
    
    -- Try to find plot boundaries
    local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
    local plotFound = false
    
    -- Look for plot parts in the farm model
    for _, obj in pairs(farm:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name == "Plot" or obj.Name == "Base" or obj.Name == "Ground") then
            plotFound = true
            local size = obj.Size
            local pos = obj.Position
            
            -- Calculate boundaries
            local halfSizeX = size.X/2
            local halfSizeZ = size.Z/2
            
            minX = pos.X - halfSizeX + 1 -- Add margin
            maxX = pos.X + halfSizeX - 1
            minZ = pos.Z - halfSizeZ + 1
            maxZ = pos.Z + halfSizeZ - 1
            
            print("Found plot with boundaries:", minX, maxX, minZ, maxZ)
            break
        end
    end
    
    if not plotFound then
        -- If no specific plot part found, use the whole farm's boundaries
        for _, obj in pairs(farm:GetDescendants()) do
            if obj:IsA("BasePart") then
                minX = math.min(minX, obj.Position.X - obj.Size.X/2)
                maxX = math.max(maxX, obj.Position.X + obj.Size.X/2)
                minZ = math.min(minZ, obj.Position.Z - obj.Size.Z/2)
                maxZ = math.max(maxZ, obj.Position.Z + obj.Size.Z/2)
            end
        end
        
        -- Add margin to avoid edge placement
        minX = minX + 1
        maxX = maxX - 1
        minZ = minZ + 1
        maxZ = maxZ - 1
        
        print("Calculated farm boundaries:", minX, maxX, minZ, maxZ)
    end
    
    return minX, maxX, minZ, maxZ
end

-- Find my farm and get boundaries
local myFarm = findMyFarm()
local minX, maxX, minZ, maxZ = getFarmBounds(myFarm)

-- Check if position is far enough from existing eggs
local function isFarEnough(position)
    for _, eggPos in ipairs(placedEggs) do
        -- Calculate distance in XZ plane only (ignore Y)
        local dx = position.X - eggPos.X
        local dz = position.Z - eggPos.Z
        local distance = math.sqrt(dx*dx + dz*dz)
        
        if distance < minDistance then
            return false -- too close to an existing egg
        end
    end
    return true -- far enough from all eggs
end

-- Generate a random position within farm bounds that's not too close to other eggs
local function randomPosition()
    -- Try up to 50 times to find a valid position
    local maxAttempts = 50
    local attempts = 0
    
    while attempts < maxAttempts do
        local x = math.random(minX, maxX)
        local z = math.random(minZ, maxZ)
        local pos = Vector3.new(x, Y, z)
        
        if isFarEnough(pos) then
            return pos
        end
        
        attempts = attempts + 1
    end
    
    -- If we couldn't find a position after max attempts, 
    -- either farm is full or minDistance is too large
    print("Warning: Could not find suitable position after", maxAttempts, "attempts")
    return nil
end

print("Starting Petegg auto-placement in your farm...")
print("Farm boundaries: X", minX, "to", maxX, "Z", minZ, "to", maxZ)

-- Scan for existing eggs in workspace
local function scanExistingEggs()
    for _, obj in pairs(workspace:GetDescendants()) do
        -- Common names for eggs in many Roblox games
        if obj:IsA("Model") and (obj.Name:find("Egg") or obj.Name:find("Petegg")) then
            local position = obj:GetPivot().Position
            table.insert(placedEggs, position)
            print("Found existing egg at:", position)
        end
    end
    print("Found", #placedEggs, "existing eggs")
end

-- Try to scan for existing eggs before starting
pcall(scanExistingEggs)

-- Start automatic placement
task.spawn(function()
    while autoPlace do
        local pos = randomPosition()
        
        if pos then
            -- Place Petegg at random position
            PetEggService:FireServer("CreateEgg", pos, eggType)
            table.insert(placedEggs, pos) -- Track this egg position
            print("Placed Petegg at:", pos, "(Total eggs:", #placedEggs, ")")
            
            -- Limit how many egg positions we track to prevent memory issues
            if #placedEggs > 50 then
                table.remove(placedEggs, 1) -- Remove oldest egg position
            end
        else
            -- If we can't find a position, wait longer before trying again
            print("Farm may be too full of eggs. Waiting longer before next attempt.")
            task.wait(delayTime * 2)
        end
        
        task.wait(delayTime)
    end
end)

