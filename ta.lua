-- Simple GUI Auto Egg Placer
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local PetEggService = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetEggService")
local EggModels = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Models"):WaitForChild("EggModels")

-- Farm placement bounds (adjust for your plot)
local minX, maxX = 70, 80
local minZ, maxZ = -105, -95
local Y = 0
local delayTime = 1

local autoPlace = false
local selectedEggName = nil

-- GUI creation
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 200, 0, 100)
Frame.Position = UDim2.new(0, 50, 0, 50)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local Dropdown = Instance.new("TextButton", Frame)
Dropdown.Size = UDim2.new(1, 0, 0, 25)
Dropdown.Text = "Select Egg"
Dropdown.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
Dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)

local EggListFrame = Instance.new("Frame", Frame)
EggListFrame.Size = UDim2.new(1, 0, 0, 75)
EggListFrame.Position = UDim2.new(0, 0, 0, 25)
EggListFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
EggListFrame.Visible = false

local UIListLayout = Instance.new("UIListLayout", EggListFrame)

-- Populate egg names
for _, egg in ipairs(EggModels:GetChildren()) do
    local btn = Instance.new("TextButton", EggListFrame)
    btn.Size = UDim2.new(1, 0, 0, 20)
    btn.Text = egg.Name
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)

    btn.MouseButton1Click:Connect(function()
        selectedEggName = egg.Name
        Dropdown.Text = "Egg: " .. selectedEggName
        EggListFrame.Visible = false
    end)
end

Dropdown.MouseButton1Click:Connect(function()
    EggListFrame.Visible = not EggListFrame.Visible
end)

-- Equip tool (fuzzy match)
local function equipEggTool()
    if not selectedEggName then return end
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if string.find(tool.Name:lower(), selectedEggName:lower()) then
            tool.Parent = LocalPlayer.Character
            return true
        end
    end
    return false
end

-- Random farm position
local function randomPosition()
    return Vector3.new(
        math.random(minX, maxX),
        Y,
        math.random(minZ, maxZ)
    )
end

-- Auto-place loop
task.spawn(function()
    while true do
        if autoPlace and selectedEggName then
            if equipEggTool() then
                PetEggService:FireServer("CreateEgg", randomPosition())
            end
            task.wait(delayTime)
        else
            task.wait(0.5)
        end
    end
end)

-- Toggle button
local ToggleBtn = Instance.new("TextButton", Frame)
ToggleBtn.Size = UDim2.new(1, 0, 0, 25)
ToggleBtn.Position = UDim2.new(0, 0, 0, 75)
ToggleBtn.Text = "Start Placing"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

ToggleBtn.MouseButton1Click:Connect(function()
    autoPlace = not autoPlace
    ToggleBtn.Text = autoPlace and "Stop Placing" or "Start Placing"
    ToggleBtn.BackgroundColor3 = autoPlace and Color3.fromRGB(100, 0, 0) or Color3.fromRGB(0, 100, 0)
end)
