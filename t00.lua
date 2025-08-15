-- Auto Place Selected Pet Egg (GUI + Auto Plot)

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Remotes & models
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local PetEggService = GameEvents:WaitForChild("PetEggService")
local EggModels = ReplicatedStorage.Assets.Models:WaitForChild("EggModels")

--============================ Helpers ============================--

local function escapePattern(s) return (s:gsub("(%W)","%%%1")) end

-- Find egg tool by fuzzy match
local function findToolByBaseName(baseName)
    local pattern = "^" .. escapePattern(baseName) .. "%s*x?%d*$"
    local function findIn(container)
        if not container then return nil end
        for _, inst in ipairs(container:GetDescendants()) do
            if inst:IsA("Tool") and (inst.Name == baseName or inst.Name:lower():match(pattern:lower())) then
                return inst
            end
        end
        return nil
    end
    return findIn(LocalPlayer.Character) or findIn(LocalPlayer.Backpack)
end

-- Force equip
local function ensureEquipped(tool)
    if not tool then return false end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        local ok = pcall(function() hum:EquipTool(tool) end)
        if not ok or tool.Parent ~= char then
            tool.Parent = char
        end
    else
        tool.Parent = char
    end
    return tool.Parent == char
end

-- Auto-detect player plot
local function getMyPlot()
    local uid, name = LocalPlayer.UserId, LocalPlayer.Name
    for _, inst in ipairs(workspace:GetDescendants()) do
        local owner = inst:FindFirstChild("Owner")
        if owner then
            if owner:IsA("ObjectValue") and owner.Value == LocalPlayer then return inst end
            if owner:IsA("IntValue") and owner.Value == uid then return inst end
            if owner:IsA("StringValue") and owner.Value == name then return inst end
        end
        local ownerUserId = inst:FindFirstChild("OwnerUserId")
        if ownerUserId and ownerUserId:IsA("IntValue") and ownerUserId.Value == uid then return inst end
    end
end

-- Find largest base part
local function getPlotBasePart(plot)
    if not plot then return nil end
    local best, bestArea = nil, -1
    for _, inst in ipairs(plot:GetDescendants()) do
        if inst:IsA("BasePart") then
            local area = inst.Size.X * inst.Size.Z
            local nameBonus = (inst.Name == "Base") and 1e12 or 0
            if area + nameBonus > bestArea then
                best = inst
                bestArea = area + nameBonus
            end
        end
    end
    return best
end

-- Random position on base part
local function randomPointOnBase(basePart)
    local halfX = basePart.Size.X * 0.45
    local halfZ = basePart.Size.Z * 0.45
    local lx = (math.random() * 2 - 1) * halfX
    local lz = (math.random() * 2 - 1) * halfZ
    local topY = basePart.Size.Y * 0.5 + 0.15
    return (basePart.CFrame * CFrame.new(lx, topY, lz)).Position
end

--============================ GUI ============================--

local gui = Instance.new("ScreenGui")
gui.Name = "AutoEggPlacerUI"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 210)
frame.Position = UDim2.new(0, 20, 0, 120)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -12, 0, 26)
title.Position = UDim2.new(0, 6, 0, 6)
title.Text = "Auto Place Pet Eggs"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local dropdownBtn = Instance.new("TextButton")
dropdownBtn.Size = UDim2.new(1, -20, 0, 30)
dropdownBtn.Position = UDim2.new(0, 10, 0, 40)
dropdownBtn.Text = "Select Egg"
dropdownBtn.Font = Enum.Font.Gotham
dropdownBtn.TextSize = 14
dropdownBtn.TextColor3 = Color3.new(1,1,1)
dropdownBtn.BackgroundColor3 = Color3.fromRGB(55,55,55)
dropdownBtn.Parent = frame
Instance.new("UICorner", dropdownBtn).CornerRadius = UDim.new(0, 8)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 0, 90)
scroll.Position = UDim2.new(0, 10, 0, 75)
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.ScrollBarThickness = 6
scroll.Visible = false
scroll.BackgroundColor3 = Color3.fromRGB(45,45,45)
scroll.Parent = frame
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 8)

local list = Instance.new("UIListLayout", scroll)
list.Padding = UDim.new(0, 4)
list.SortOrder = Enum.SortOrder.LayoutOrder

local selectedEggBaseName = nil
do
    local eggs = {}
    for _, m in ipairs(EggModels:GetChildren()) do
        table.insert(eggs, m.Name)
    end
    table.sort(eggs)
    for _, name in ipairs(eggs) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -10, 0, 26)
        b.Text = name
        b.Font = Enum.Font.Gotham
        b.TextSize = 14
        b.TextColor3 = Color3.new(1,1,1)
        b.BackgroundColor3 = Color3.fromRGB(60,60,60)
        b.Parent = scroll
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.MouseButton1Click:Connect(function()
            selectedEggBaseName = name
            dropdownBtn.Text = "Egg: " .. name
            scroll.Visible = false
        end)
    end
    task.defer(function()
        local c = 0
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("GuiObject") then c += child.AbsoluteSize.Y + 4 end
        end
        scroll.CanvasSize = UDim2.new(0,0,0,math.max(c, 90))
    end)
end

dropdownBtn.MouseButton1Click:Connect(function()
    scroll.Visible = not scroll.Visible
end)

local delayBox = Instance.new("TextBox")
delayBox.Size = UDim2.new(0, 90, 0, 30)
delayBox.Position = UDim2.new(0, 10, 0, 170)
delayBox.PlaceholderText = "Delay (s)"
delayBox.Text = "0.8"
delayBox.Font = Enum.Font.Gotham
delayBox.TextSize = 14
delayBox.TextColor3 = Color3.new(1,1,1)
delayBox.BackgroundColor3 = Color3.fromRGB(55,55,55)
delayBox.ClearTextOnFocus = false
delayBox.Parent = frame
Instance.new("UICorner", delayBox).CornerRadius = UDim.new(0, 8)

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(0, 70, 0, 30)
startBtn.Position = UDim2.new(0, 110, 0, 170)
startBtn.Text = "Start"
startBtn.Font = Enum.Font.Gotham
startBtn.TextSize = 14
startBtn.TextColor3 = Color3.new(1,1,1)
startBtn.BackgroundColor3 = Color3.fromRGB(40,170,95)
startBtn.Parent = frame
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 8)

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0, 70, 0, 30)
stopBtn.Position = UDim2.new(0, 190, 0, 170)
stopBtn.Text = "Stop"
stopBtn.Font = Enum.Font.Gotham
stopBtn.TextSize = 14
stopBtn.TextColor3 = Color3.new(1,1,1)
stopBtn.BackgroundColor3 = Color3.fromRGB(170,40,40)
stopBtn.Parent = frame
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 8)

local statusLbl = Instance.new("TextLabel")
statusLbl.BackgroundTransparency = 1
statusLbl.Size = UDim2.new(1, -20, 0, 20)
statusLbl.Position = UDim2.new(0, 10, 0, 145)
statusLbl.Text = "Idle"
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextSize = 12
statusLbl.TextColor3 = Color3.fromRGB(220,220,220)
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = frame

--============================ Runner ============================--

local running = false

local function placeOnce()
    if not selectedEggBaseName then
        statusLbl.Text = "Select an egg first"
        return
    end
    local tool = findToolByBaseName(selectedEggBaseName)
    if not tool then
        statusLbl.Text = ("Tool not found: %s"):format(selectedEggBaseName)
        return
    end
    ensureEquipped(tool)
    local plot = getMyPlot()
    if not plot then
        statusLbl.Text = "Plot not found"
        return
    end
    local base = getPlotBasePart(plot)
    if not base then
        statusLbl.Text = "Plot base not found"
        return
    end
    local pos = randomPointOnBase(base)
    local ok, err = pcall(function()
        PetEggService:FireServer("CreateEgg", pos)
    end)
    if not ok then
        statusLbl.Text = "CreateEgg failed"
        warn("[AutoEgg] CreateEgg error:", err)
    else
        statusLbl.Text = ("Placed at (%.1f, %.1f, %.1f)"):format(pos.X, pos.Y, pos.Z)
    end
end

startBtn.MouseButton1Click:Connect(function()
    if running then return end
    running = true
    statusLbl.Text = "Running..."
    local delayNum = tonumber(delayBox.Text) or 0.8
    task.spawn(function()
        while running do
            placeOnce()
            task.wait(delayNum)
        end
    end)
end)

stopBtn.MouseButton1Click:Connect(function()
    running = false
    statusLbl.Text = "Stopped"
end)
