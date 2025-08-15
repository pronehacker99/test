-- Auto Place Pet Egg inside your actual farm bounds
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PetEggService = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetEggService")
local GetFarmAsync = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GetFarmAsync"))

local localPlayer = Players.LocalPlayer

local autoPlace = true
local delayTime = 0.1 -- seconds between placements (tune if needed)
local margin = 5 -- shrink edges so it doesn't hug plot borders

local function getFarmBounds()
	local farm = GetFarmAsync(localPlayer)
	if not farm then return nil end
	-- farm is a Folder in this place; compute AABB from its BaseParts
	local minX, maxX = math.huge, -math.huge
	local minZ, maxZ = math.huge, -math.huge
	local center = nil
	local anchor = farm:FindFirstChild("Spawn_Point", true) or farm:FindFirstChild("Owner_Tag", true)
	if anchor and anchor:IsA("BasePart") then
		center = anchor.Position
	end
	for _, inst in ipairs(farm:GetDescendants()) do
		if inst:IsA("BasePart") then
			local pos = inst.Position
			local size = inst.Size
			minX = math.min(minX, pos.X - size.X * 0.5)
			maxX = math.max(maxX, pos.X + size.X * 0.5)
			minZ = math.min(minZ, pos.Z - size.Z * 0.5)
			maxZ = math.max(maxZ, pos.Z + size.Z * 0.5)
			if not center then center = pos end
		end
	end
	if minX == math.huge or maxX == -math.huge then return nil end
	local halfX = math.max(0, ((maxX - minX) * 0.5) - margin)
	local halfZ = math.max(0, ((maxZ - minZ) * 0.5) - margin)
	center = center or Vector3.new((minX + maxX) * 0.5, 0, (minZ + maxZ) * 0.5)
	return {
		center = center,
		rangeX = halfX,
		rangeZ = halfZ,
		farm = farm,
	}
end

local function raycastToGround(farm, x, yStart, z)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { farm }
	local origin = Vector3.new(x, yStart + 200, z)
	local result = Workspace:Raycast(origin, Vector3.new(0, -1000, 0), params)
	if result then
		return result.Position.Y
	end
	return yStart
end

local function randomPosition()
	local bounds = getFarmBounds()
	if not bounds then return nil end
	local x = bounds.center.X + math.random(-bounds.rangeX, bounds.rangeX)
	local z = bounds.center.Z + math.random(-bounds.rangeZ, bounds.rangeZ)
	local y = raycastToGround(bounds.farm, x, bounds.center.Y, z)
	return Vector3.new(x, y, z)
end

task.spawn(function()
	while autoPlace do
		local pos = randomPosition()
		if pos then
			-- Server-side is expected to handle creating an egg at this position
			PetEggService:FireServer("CreateEgg", pos)
		end
		task.wait(delayTime)
	end
end)

-- UI: Dropdown for egg, delay textbox, start/stop toggle
local function makeUI()
	local gui = Instance.new("ScreenGui")
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Name = "EggAutoUI"
	gui.Parent = localPlayer:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 260, 0, 210)
	frame.Position = UDim2.new(0, 12, 0, 150)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -10, 0, 24)
	title.Position = UDim2.new(0, 10, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "Auto Egg Placer"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextColor3 = Color3.new(1,1,1)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame

	local delayLabel = Instance.new("TextLabel")
	delayLabel.Size = UDim2.new(0, 80, 0, 24)
	delayLabel.Position = UDim2.new(0, 10, 0, 44)
	delayLabel.BackgroundTransparency = 1
	delayLabel.Text = "Delay (s)"
	delayLabel.Font = Enum.Font.Gotham
	delayLabel.TextSize = 14
	delayLabel.TextColor3 = Color3.fromRGB(220,220,220)
	delayLabel.TextXAlignment = Enum.TextXAlignment.Left
	delayLabel.Parent = frame

	local delayBox = Instance.new("TextBox")
	delayBox.Size = UDim2.new(0, 70, 0, 24)
	delayBox.Position = UDim2.new(0, 100, 0, 44)
	delayBox.BackgroundColor3 = Color3.fromRGB(32,32,32)
	delayBox.BorderSizePixel = 0
	delayBox.Text = "0.1"
	delayBox.PlaceholderText = "0.1"
	delayBox.ClearTextOnFocus = false
	delayBox.Font = Enum.Font.Gotham
	delayBox.TextSize = 14
	delayBox.TextColor3 = Color3.fromRGB(255,255,255)
	delayBox.Parent = frame

	local startBtn = Instance.new("TextButton")
	startBtn.Size = UDim2.new(0, 80, 0, 28)
	startBtn.Position = UDim2.new(0, 180, 0, 42)
	startBtn.BackgroundColor3 = Color3.fromRGB(38, 142, 84)
	startBtn.BorderSizePixel = 0
	startBtn.Text = "Start"
	startBtn.Font = Enum.Font.GothamBold
	startBtn.TextSize = 14
	startBtn.TextColor3 = Color3.new(1,1,1)
	startBtn.Parent = frame

	local ddLabel = Instance.new("TextLabel")
	ddLabel.Size = UDim2.new(1, -20, 0, 20)
	ddLabel.Position = UDim2.new(0, 10, 0, 84)
	ddLabel.BackgroundTransparency = 1
	ddLabel.Text = "Select Egg"
	ddLabel.Font = Enum.Font.Gotham
	ddLabel.TextSize = 14
	ddLabel.TextColor3 = Color3.fromRGB(220,220,220)
	ddLabel.TextXAlignment = Enum.TextXAlignment.Left
	ddLabel.Parent = frame

	local dropdown = Instance.new("TextButton")
	dropdown.Size = UDim2.new(1, -20, 0, 28)
	dropdown.Position = UDim2.new(0, 10, 0, 108)
	dropdown.BackgroundColor3 = Color3.fromRGB(32,32,32)
	dropdown.BorderSizePixel = 0
	dropdown.Text = "CommonEgg"
	dropdown.Font = Enum.Font.Gotham
	dropdown.TextSize = 14
	dropdown.TextColor3 = Color3.new(1,1,1)
	dropdown.TextXAlignment = Enum.TextXAlignment.Left
	dropdown.Parent = frame

	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(1, -20, 0, 70)
	list.Position = UDim2.new(0, 10, 0, 142)
	list.BackgroundColor3 = Color3.fromRGB(24,24,24)
	list.BorderSizePixel = 0
	list.Visible = false
	list.CanvasSize = UDim2.new(0,0,0,0)
	list.ScrollBarThickness = 4
	list.Parent = frame

	local uiList = Instance.new("UIListLayout")
	uiList.SortOrder = Enum.SortOrder.LayoutOrder
	uiList.Parent = list

	local selectedEggName = dropdown.Text

	local function refreshEggOptions()
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		local eggFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Models"):WaitForChild("EggModels")
		for _, m in ipairs(eggFolder:GetChildren()) do
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -8, 0, 24)
			btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
			btn.BorderSizePixel = 0
			btn.Text = m.Name
			btn.Font = Enum.Font.Gotham
			btn.TextSize = 13
			btn.TextColor3 = Color3.new(1,1,1)
			btn.Parent = list
			btn.MouseButton1Click:Connect(function()
				selectedEggName = btn.Text
				dropdown.Text = selectedEggName
				list.Visible = false
			end)
		end
		list.CanvasSize = UDim2.new(0,0,0,uiList.AbsoluteContentSize.Y + 8)
	end

	dropdown.MouseButton1Click:Connect(function()
		list.Visible = not list.Visible
		if list.Visible then refreshEggOptions() end
	end)

	local placing = false
	local function parseDelay()
		local n = tonumber(delayBox.Text)
		if n and n > 0 then return n end
		return 0.1
	end

	local function toNiceEggNames(name)
		if typeof(name) ~= "string" then return {} end
		local withSpaces = name:gsub("(%l)(%u)", "%1 %2")
		if not withSpaces:lower():find("egg") then
			withSpaces = withSpaces .. " Egg"
		end
		local collapsed = select(1, withSpaces:gsub("%s%s+", " ")) or withSpaces
		return {name, withSpaces, collapsed}
	end
	
	local function equipEggFuzzy(target)
		local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum:UnequipTools() end
		local candidates = {}
		for _, container in ipairs({localPlayer.Backpack, char}) do
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") then
					local eggNameAttr = tool:GetAttribute("EggName") or tool:GetAttribute("ItemName")
					local toolName = eggNameAttr or tool.Name
					if typeof(toolName) == "string" then
						local t = string.lower(toolName)
						for _, variant in ipairs(toNiceEggNames(target)) do
							if typeof(variant) ~= "string" then continue end
							local v = string.lower(variant)
							if string.find(t, v) or string.find(v, t) then
								table.insert(candidates, tool)
								break
							end
						end
					end
				end
			end
		end
		if #candidates > 0 then
			candidates[1].Parent = char
			return true
		end
		return false
	end

	local function runPlacer()
		if placing then return end
		placing = true
		autoPlace = true
		startBtn.Text = "Stop"
		while placing do
			delayTime = parseDelay()
			local _ = equipEggFuzzy(selectedEggName)
			local pos = randomPosition()
			if pos then
				PetEggService:FireServer("CreateEgg", pos)
			end
			task.wait(delayTime)
		end
	end

	local function stopPlacer()
		placing = false
		autoPlace = false
		startBtn.Text = "Start"
	end

	startBtn.MouseButton1Click:Connect(function()
		if placing then stopPlacer() else runPlacer() end
	end)

	refreshEggOptions()
	return gui
end

pcall(makeUI)
