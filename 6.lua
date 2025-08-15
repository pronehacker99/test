-- Auto Place Petegg in Your Farm at Random Locations
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PetEggService = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetEggService")

local LocalPlayer = Players.LocalPlayer
local Y = 0.5 -- slightly above ground level to prevent clipping
local delayTime = 1.5 -- seconds between placements
local autoPlace = true
local eggType = "Petegg" -- specifically for Petegg
local minDistance = 3 -- REDUCED: minimum distance between eggs (3 studs should be enough)
local maxAttempts = 100 -- INCREASED: max attempts to find a position
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
    -- Grid-based approach - try to find a position in a grid pattern
    local gridSize = minDistance * 1.5 -- Grid size slightly larger than min distance
    local gridWidth = math.floor((maxX - minX) / gridSize)
    local gridLength = math.floor((maxZ - minZ) / gridSize)
    
    -- First try a smarter grid-based approach
    for i = 0, gridWidth do
        for j = 0, gridLength do
            local x = minX + i * gridSize
            local z = minZ + j * gridSize
            -- Add small random offset within grid cell
            x = x + (math.random() * gridSize * 0.5)
            z = z + (math.random() * gridSize * 0.5)
            
            local pos = Vector3.new(x, Y, z)
            if isFarEnough(pos) then
                return pos
            end
        end
    end
    
    -- If grid approach failed, fall back to pure random with more attempts
    local attempts = 0
    while attempts < maxAttempts do
        -- Try completely random positions
        local x = minX + (maxX - minX) * math.random()
        local z = minZ + (maxZ - minZ) * math.random()
        local pos = Vector3.new(x, Y, z)
        
        if isFarEnough(pos) then
            return pos
        end
        
        attempts = attempts + 1
    end
    
    -- Last resort: just reduce constraints temporarily
    print("Warning: Using reduced distance constraints to find position")
    for _, eggPos in ipairs(placedEggs) do
        local farthestDistance = 0
        local bestPos = nil
        
        -- Try some more random positions and pick the farthest one
        for i = 1, 20 do
            local x = minX + (maxX - minX) * math.random()
            local z = minZ + (maxZ - minZ) * math.random()
            local pos = Vector3.new(x, Y, z)
            
            local closestDist = math.huge
            for _, existingPos in ipairs(placedEggs) do
                local dx = pos.X - existingPos.X
                local dz = pos.Z - existingPos.Z
                local dist = math.sqrt(dx*dx + dz*dz)
                closestDist = math.min(closestDist, dist)
            end
            
            if closestDist > farthestDistance then
                farthestDistance = closestDist
                bestPos = pos
            end
        end
        
        if bestPos then
            print("Using best available position with distance:", farthestDistance)
            return bestPos
        end
    end
    
    -- If everything fails, just pick a truly random spot
    print("Warning: Could not find suitable position after", maxAttempts, "attempts")
    local x = minX + (maxX - minX) * math.random()
    local z = minZ + (maxZ - minZ) * math.random()
    return Vector3.new(x, Y, z)
end

print("Starting Petegg auto-placement in your farm...")
print("Farm boundaries: X", minX, "to", maxX, "Z", minZ, "to", maxZ)

-- Scan for existing eggs in workspace
local function scanExistingEggs()
    -- Clear previous egg records
    placedEggs = {}
    
    local eggCount = 0
    
    -- Try different methods to find eggs
    local eggTypes = {"Egg", "Petegg", "egg", "PetEgg", "Pet Egg"}
    
    -- Look for eggs in the farm
    if myFarm then
        for _, obj in pairs(myFarm:GetDescendants()) do
            -- Check for any egg-like objects
            for _, eggType in ipairs(eggTypes) do
                if obj:IsA("Model") and obj.Name:find(eggType) then
                    local position = obj:GetPivot().Position
                    table.insert(placedEggs, position)
                    eggCount = eggCount + 1
                    break
                end
            end
        end
        
        -- Also check for any objects with specific "egg" tags or attributes
        for _, obj in pairs(myFarm:GetDescendants()) do
            if obj:IsA("BasePart") then
                -- Check various attributes that might indicate it's an egg
                if obj:GetAttribute("IsEgg") or obj:GetAttribute("EggType") then
                    table.insert(placedEggs, obj.Position)
                    eggCount = eggCount + 1
                end
            end
        end
    end
    
    -- Look more widely for eggs if we didn't find many
    if eggCount < 3 then
        for _, obj in pairs(workspace:GetDescendants()) do
            -- Only check objects near our farm to avoid other players' eggs
            if obj:IsA("Model") then
                local isEgg = false
                for _, eggType in ipairs(eggTypes) do
                    if obj.Name:find(eggType) then
                        isEgg = true
                        break
                    end
                end
                
                if isEgg then
                    -- Check if egg is within our farm boundaries (with some margin)
                    local pos = obj:GetPivot().Position
                    if pos.X >= minX - 5 and pos.X <= maxX + 5 and
                       pos.Z >= minZ - 5 and pos.Z <= maxZ + 5 then
                        table.insert(placedEggs, pos)
                        eggCount = eggCount + 1
                    end
                end
            end
        end
    end
    
    print("Found", #placedEggs, "existing eggs in or near your farm")
end

-- Try to scan for existing eggs before starting
pcall(scanExistingEggs)

-- Add visualization for debugging (shows farm boundaries)
local function visualizeFarm()
    pcall(function()
        -- Create visual indicators at corners of farm (for debugging)
        local markers = {}
        local corners = {
            Vector3.new(minX, Y, minZ),
            Vector3.new(minX, Y, maxZ),
            Vector3.new(maxX, Y, minZ),
            Vector3.new(maxX, Y, maxZ)
        }
        
        for _, corner in ipairs(corners) do
            local p = Instance.new("Part")
            p.Anchored = true
            p.CanCollide = false
            p.Size = Vector3.new(1, 1, 1)
            p.Position = corner
            p.Material = Enum.Material.Neon
            p.BrickColor = BrickColor.new("Really red")
            p.Transparency = 0.7
            p.Parent = workspace
            table.insert(markers, p)
            
            -- Auto-cleanup after 30 seconds
            task.delay(30, function()
                pcall(function() p:Destroy() end)
            end)
        end
    end)
end

-- Visualize the farm boundaries temporarily
pcall(visualizeFarm)

-- Start automatic placement
task.spawn(function()
    -- Track failed attempts
    local consecutiveFailures = 0
    local totalEggsPlaced = 0
    local lastPlacementTime = os.time()
    
    -- Main egg placement loop
    while autoPlace do
        local pos = randomPosition()
        
        if pos then
            -- Place Petegg at random position
            PetEggService:FireServer("CreateEgg", pos, eggType)
            table.insert(placedEggs, pos) -- Track this egg position
            totalEggsPlaced = totalEggsPlaced + 1
            print("✓ Placed Petegg at:", pos, "(Total eggs:", totalEggsPlaced, ")")
            
            -- Reset failure counter on success
            consecutiveFailures = 0
            lastPlacementTime = os.time()
            
            -- Limit how many egg positions we track to prevent memory issues
            if #placedEggs > 50 then
                table.remove(placedEggs, 1) -- Remove oldest egg position
            end
            
            -- Gradually reduce minDistance if we have many eggs
            if totalEggsPlaced > 10 and minDistance > 2 then
                minDistance = minDistance - 0.1
                print("Adjusting minimum distance to:", minDistance)
            end
        else
            -- If we can't find a position
            consecutiveFailures = consecutiveFailures + 1
            print("❌ Farm may be too full of eggs. Waiting longer before next attempt.")
            
            -- Adaptive strategies based on failure count
            if consecutiveFailures >= 3 then
                print("Multiple placement failures. Taking corrective action...")
                
                -- Strategy 1: Rescan the farm for eggs
                if consecutiveFailures % 3 == 0 then
                    print("Rescanning farm for eggs...")
                    pcall(scanExistingEggs)
                end
                
                -- Strategy 2: Reduce minimum distance
                if minDistance > 2 then
                    minDistance = minDistance - 0.5
                    print("Reducing minimum distance to:", minDistance)
                end
                
                -- Strategy 3: If it's been over 60 seconds since last placement, reset tracking
                if os.time() - lastPlacementTime > 60 then
                    print("No successful placements for over a minute. Resetting egg tracking.")
                    placedEggs = {}
                end
            end
            
            -- Wait longer with each failure up to a limit
            local waitTime = math.min(delayTime * 2, delayTime + (consecutiveFailures * 0.5))
            task.wait(waitTime)
        end
        
        task.wait(delayTime)
    end
end)

