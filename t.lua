-- Auto Place Selected Pet Egg with GUI
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetEggService = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetEggService")
local LocalPlayer = Players.LocalPlayer
local EggModels = ReplicatedStorage.Assets.Models.EggModels

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 200, 0, 120)
Frame.Position = UDim2.new(0, 50, 0, 50)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local Dropdown = Instance.new("TextButton", Frame)
Dropdown.Size = UDim2.new(1, -20, 0, 30)
Dropdown.Position = UDim2.new(0, 10, 0, 10)
Dropdown.Text = "Select Egg"
Dropdown.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
Dropdown.TextColor3 = Color3.new(1, 1, 1)

local StartButton = Instance.new("TextButton", Frame)
StartButton.Size = UDim2.new(1, -20, 0, 30)
StartButton.Position = UDim2.new(0, 10, 0, 50)
StartButton.Text = "Start Auto Place"
StartButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
StartButton.TextColor3 = Color3.new(1, 1, 1)

local StopButton = Instance.new("TextButton", Frame)
StopButton.Size = UDim2.new(1, -20, 0, 30)
StopButton.Position = UDim2.new(0, 10, 0, 90)
StopButton.Text = "Stop Auto Place"
StopButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
StopButton.TextColor3 = Color3.new(1, 1, 1)

-- Egg List
local EggList = {}
for _, egg in ipairs(EggModels:GetChildren()) do
    table.insert(EggList, egg.Name)
end

-- Dropdown Menu
local DropFrame = Instance.new("Frame", Frame)
DropFrame.Size = UDim2.new(1, -20, 0, #EggList * 25)
DropFrame.Position = UDim2.new(0, 10, 0, 40)
DropFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
DropFrame.Visible = false

for i, eggName in ipairs(EggList) do
    local Btn = Instance.new("TextButton", DropFrame)
    Btn.Size = UDim2.new(1, 0, 0, 25)
    Btn.Position = UDim2.new(0, 0, 0, (i - 1) * 25)
    Btn.Text = eggName
    Btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    Btn.TextColor3 = Color3.new(1, 1, 1)
    Btn.MouseButton1Click:Connect(function()
        Dropdown.Text = eggName
        DropFrame.Visible = false
    end)
end

Dropdown.MouseButton1Click:Connect(function()
    DropFrame.Visible = not DropFrame.Visible
end)

-- Detect Player Plot
local function getMyPlot()
    for _, plot in ipairs(workspace:GetChildren()) do
        if plot:FindFirstChild("Owner") and plot.Owner.Value == LocalPlayer then
            return plot
        end
    end
end

local function randomPositionInPlot(plot)
    if plot:FindFirstChild("Base") then
        local base = plot.Base
        local size = base.Size
        local pos = base.Position
        local x = math.random(pos.X - size.X/2, pos.X + size.X/2)
        local z = math.random(pos.Z - size.Z/2, pos.Z + size.Z/2)
        return Vector3.new(x, pos.Y, z)
    end
end

-- Auto Place
local running = false
local delayTime = 1

StartButton.MouseButton1Click:Connect(function()
    if Dropdown.Text ~= "Select Egg" then
        running = true
        task.spawn(function()
            while running do
                local myPlot = getMyPlot()
                if myPlot then
                    local pos = randomPositionInPlot(myPlot)
                    if pos then
                        -- Equip the egg from backpack if it exists
                        local tool = LocalPlayer.Backpack:FindFirstChild(Dropdown.Text)
                        if tool then
                            tool.Parent = LocalPlayer.Character
                        end
                        PetEggService:FireServer("CreateEgg", pos)
                    end
                end
                task.wait(delayTime)
            end
        end)
    end
end)

StopButton.MouseButton1Click:Connect(function()
    running = false
end)
