-- Auto Place Pet Egg with Dynamic Plot & Egg Selection GUI
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PetEggService = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetEggService")

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 200, 0, 250)
Frame.Position = UDim2.new(0, 50, 0, 50)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "Auto Egg Placer"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

local EggDropdown = Instance.new("TextButton", Frame)
EggDropdown.Size = UDim2.new(1, 0, 0, 30)
EggDropdown.Position = UDim2.new(0, 0, 0, 40)
EggDropdown.Text = "Select Egg"
EggDropdown.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
EggDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)

local EggListFrame = Instance.new("ScrollingFrame", Frame)
EggListFrame.Size = UDim2.new(1, 0, 0, 100)
EggListFrame.Position = UDim2.new(0, 0, 0, 70)
EggListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
EggListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
EggListFrame.Visible = false

local StartButton = Instance.new("TextButton", Frame)
StartButton.Size = UDim2.new(1, 0, 0, 30)
StartButton.Position = UDim2.new(0, 0, 0, 180)
StartButton.Text = "Start Placing"
StartButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
StartButton.TextColor3 = Color3.fromRGB(255, 255, 255)

local StopButton = Instance.new("TextButton", Frame)
StopButton.Size = UDim2.new(1, 0, 0, 30)
StopButton.Position = UDim2.new(0, 0, 0, 215)
StopButton.Text = "Stop"
StopButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
StopButton.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Variables
local selectedEgg = nil
local autoPlace = false

-- Find player's plot
local function getMyPlot()
    for _, plot in ipairs(workspace:GetChildren()) do
        if plot:FindFirstChild("Owner") and plot.Owner.Value == LocalPlayer then
            return plot
        end
    end
end

-- Get largest part in plot (assumed ground)
local function getPlacementBase(plot)
    local largestPart = nil
    local largestSize = 0
    for _, obj in ipairs(plot:GetDescendants()) do
        if obj:IsA("BasePart") then
            local size = obj.Size.X * obj.Size.Z
            if size > largestSize then
                largestSize = size
                largestPart = obj
            end
        end
    end
    return largestPart
end

-- Get random position in part
local function randomPositionInPart(part)
    local size = part.Size
    local pos = part.Position
    local x = math.random(pos.X - size.X/2, pos.X + size.X/2)
    local z = math.random(pos.Z - size.Z/2, pos.Z + size.Z/2)
    return Vector3.new(x, pos.Y, z)
end

-- Equip egg from backpack
local function equipEgg(eggName)
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:match(eggName) then
            LocalPlayer.Character.Humanoid:EquipTool(tool)
            break
        end
    end
end

-- Fill egg list in dropdown
local function populateEggList()
    local eggsFolder = ReplicatedStorage:FindFirstChild("Assets"):FindFirstChild("Models"):FindFirstChild("EggModels")
    if eggsFolder then
        EggListFrame:ClearAllChildren()
        local yPos = 0
        for _, egg in ipairs(eggsFolder:GetChildren()) do
            local btn = Instance.new("TextButton", EggListFrame)
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.Position = UDim2.new(0, 0, 0, yPos)
            btn.Text = egg.Name
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.MouseButton1Click:Connect(function()
                selectedEgg = egg.Name
                EggDropdown.Text = "Egg: " .. egg.Name
                EggListFrame.Visible = false
            end)
            yPos = yPos + 30
        end
        EggListFrame.CanvasSize = UDim2.new(0, 0, 0, yPos)
    end
end

-- Toggle dropdown visibility
EggDropdown.MouseButton1Click:Connect(function()
    if EggListFrame.Visible then
        EggListFrame.Visible = false
    else
        populateEggList()
        EggListFrame.Visible = true
    end
end)

-- Start placing eggs
StartButton.MouseButton1Click:Connect(function()
    if selectedEgg then
        autoPlace = true
        task.spawn(function()
            while autoPlace do
                equipEgg(selectedEgg)
                local plot = getMyPlot()
                if plot then
                    local base = getPlacementBase(plot)
                    if base then
                        local pos = randomPositionInPart(base)
                        PetEggService:FireServer("CreateEgg", pos)
                    end
                end
                task.wait(1)
            end
        end)
    else
        warn("No egg selected!")
    end
end)

-- Stop placing eggs
StopButton.MouseButton1Click:Connect(function()
    autoPlace = false
end)
