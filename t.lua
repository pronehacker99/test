-- Auto Place Pet Eggs with GUI
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local PetEggService = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetEggService")
local EggModels = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Models"):WaitForChild("EggModels")

-- Settings
local delayTime = 1
local autoPlace = false
local selectedEgg = nil
local radius = 10 -- how far from center to place

-- Create GUI
local ScreenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 200, 0, 150)
Frame.Position = UDim2.new(0, 100, 0, 100)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local Dropdown = Instance.new("TextButton", Frame)
Dropdown.Size = UDim2.new(1, 0, 0, 30)
Dropdown.Text = "Select Egg"
Dropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)

local StartButton = Instance.new("TextButton", Frame)
StartButton.Size = UDim2.new(1, 0, 0, 30)
StartButton.Position = UDim2.new(0, 0, 0, 40)
StartButton.Text = "Start Auto Place"
StartButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
StartButton.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Dropdown logic
Dropdown.MouseButton1Click:Connect(function()
    local eggNames = {}
    for _, egg in ipairs(EggModels:GetChildren()) do
        table.insert(eggNames, egg.Name)
    end
    print("Available eggs:", table.concat(eggNames, ", "))
    -- Just pick the first for testing or prompt user in console
    selectedEgg = eggNames[1]
    Dropdown.Text = "Egg: " .. selectedEgg
end)

-- Equip function
local function equipEgg(name)
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:match(name) then
            tool.Parent = LocalPlayer.Character
            return true
        end
    end
    return false
end

-- Get random position near farm center
local function randomNearCenter()
    local center = Workspace.Farm.Farm.Center_Point.Position
    local offsetX = math.random(-radius, radius)
    local offsetZ = math.random(-radius, radius)
    return Vector3.new(center.X + offsetX, center.Y, center.Z + offsetZ)
end

-- Start button logic
StartButton.MouseButton1Click:Connect(function()
    autoPlace = not autoPlace
    StartButton.Text = autoPlace and "Stop Auto Place" or "Start Auto Place"
    if autoPlace then
        task.spawn(function()
            while autoPlace do
                if selectedEgg and equipEgg(selectedEgg) then
                    local pos = randomNearCenter()
                    PetEggService:FireServer("CreateEgg", pos)
                else
                    warn("No egg equipped or selected!")
                end
                task.wait(delayTime)
            end
        end)
    end
end)
