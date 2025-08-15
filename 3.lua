-- Auto Place Pet Egg (Dynamic Farm Detection)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local PetEggService = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetEggService")
local FarmModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CurrentPlayerFarm"))

local delayTime = 1 -- seconds between placements
local autoPlace = true

-- Get the farm model
local function getFarm()
    local farmModel = FarmModule() -- Assuming module returns the player's farm Model
    if farmModel and farmModel:IsA("Model") then
        return farmModel
    end
    return nil
end

-- Get farm boundaries (min/max X/Z)
local function getFarmBounds(farmModel)
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge

    for _, part in ipairs(farmModel:GetDescendants()) do
        if part:IsA("BasePart") then
            local cf, size = part.CFrame, part.Size
            local corners = {
                cf * Vector3.new( size.X/2, 0,  size.Z/2),
                cf * Vector3.new(-size.X/2, 0,  size.Z/2),
                cf * Vector3.new( size.X/2, 0, -size.Z/2),
                cf * Vector3.new(-size.X/2, 0, -size.Z/2)
            }
            for _, corner in ipairs(corners) do
                minX = math.min(minX, corner.X)
                maxX = math.max(maxX, corner.X)
                minZ = math.min(minZ, corner.Z)
                maxZ = math.max(maxZ, corner.Z)
            end
        end
    end

    return minX, maxX, minZ, maxZ, minY
end

-- Pick random position in farm
local function randomFarmPosition(farmModel)
    local minX, maxX, minZ, maxZ, minY = getFarmBounds(farmModel)
    local x = math.random(math.floor(minX), math.floor(maxX))
    local z = math.random(math.floor(minZ), math.floor(maxZ))
    return Vector3.new(x, minY, z)
end

-- Auto place loop
task.spawn(function()
    local farmModel = getFarm()
    if not farmModel then
        warn("Could not find farm for player!")
        return
    end

    local _, _, _, _, groundY = getFarmBounds(farmModel)
    while autoPlace do
        local pos = randomFarmPosition(farmModel)
        pos = Vector3.new(pos.X, groundY, pos.Z)
        PetEggService:FireServer("CreateEgg", pos)
        task.wait(delayTime)
    end
end)
