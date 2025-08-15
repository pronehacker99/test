-- Auto Shovel Fruit
-- Equips a shovel and deletes fruit models (objects with a NumberValue named "Weight")
-- Defaults to only acting inside your own farm

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local GetFarmAsync = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GetFarmAsync"))

-- SETTINGS
local ENABLED = false          -- controlled by UI Start/Stop
local ONLY_MY_FARM = true      -- true: only shovel in your farm
local LOOP_DELAY = 0.15        -- seconds between delete attempts
local SELECTED_TYPE = "All"    -- fruit type filter ("All" or specific)
local THRESHOLD_KG = 3         -- shovel fruits with weight strictly below this

-- INTERNAL STATE
local myFarm: Instance? = nil
local knownTypes: {[string]: boolean} = { All = true }

local function refreshMyFarm()
	pcall(function()
		myFarm = GetFarmAsync(localPlayer)
	end)
end

local function isInMyFarm(inst: Instance): boolean
	if not ONLY_MY_FARM then return true end
	if not myFarm or not myFarm.Parent then return true end
	return inst:IsDescendantOf(myFarm)
end

local function unequipAllTools()
	local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum:UnequipTools()
		return true
	end
	return false
end

local function equipShovel(): boolean
	local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	if not char then return false end

	-- Already equipped?
	for _, tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") and tool.Name:lower():find("shovel") then
			return true
		end
	end

	-- Search backpack
	local backpack = localPlayer:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and tool.Name:lower():find("shovel") then
				unequipAllTools()
				tool.Parent = char
				task.wait(0.1)
				return true
			end
		end
	end
	return false
end

local function getFruitModelFromWeight(weightValue: NumberValue): Instance
	-- Use the nearest containing model (fruit) instead of the top-most model (tree)
	local m = weightValue:FindFirstAncestorOfClass("Model")
	return m or weightValue.Parent
end

local function getDeleteRemote(): RemoteEvent?
	-- Try deep search for robustness across places
	local ev = ReplicatedStorage:FindFirstChild("DeleteObject", true)
	if ev and ev:IsA("RemoteEvent") then return ev end
	-- Fallback: search within GameEvents (also deep)
	local ge = ReplicatedStorage:FindFirstChild("GameEvents", true)
	if ge then
		local e2 = ge:FindFirstChild("DeleteObject")
		if e2 and e2:IsA("RemoteEvent") then return e2 end
	end
	return nil
end

local function getRemoveItemRemote(): RemoteEvent?
	-- Deep search for Remove_Item remote
	local ev = ReplicatedStorage:FindFirstChild("Remove_Item", true)
	if ev and ev:IsA("RemoteEvent") then return ev end
	local ge = ReplicatedStorage:FindFirstChild("GameEvents", true)
	if ge then
		local e2 = ge:FindFirstChild("Remove_Item")
		if e2 and e2:IsA("RemoteEvent") then return e2 end
	end
	return nil
end


local function tryDeleteFruit(weightValue: NumberValue, removeItemRemote: RemoteEvent?, deleteRemote: RemoteEvent?)
	local target = getFruitModelFromWeight(weightValue)
	if not target then return end
	if not isInMyFarm(target) then return end
	-- Prefer Remove_Item for non-placeable items (fruit); fallback to DeleteObject
	if removeItemRemote then
		removeItemRemote:FireServer(target)
		return
	end
	if deleteRemote then
		deleteRemote:FireServer(target)
	end
end

local function normalizeFruitName(s: string): string
	if typeof(s) ~= "string" then return "Unknown" end
	local out = s
	out = out:gsub("_%d+$", "")
	out = out:gsub("%d+$", "")
	out = out:gsub("_", " ")
	out = out:gsub("%s+", " ")
	return (out:match("^%s*(.-)%s*$") or out)
end

local function deduceFruitType(weightValue: NumberValue): string
	-- Use nearest model name to avoid classifying as tree or world model
	local m = weightValue:FindFirstAncestorOfClass("Model")
	local name = m and m.Name or (weightValue.Parent and weightValue.Parent.Name) or "Unknown"
	return normalizeFruitName(name)
end

local function collectKnownTypes()
	for _, inst in ipairs(Workspace:GetDescendants()) do
		if inst:IsA("NumberValue") and inst.Name == "Weight" then
			if isInMyFarm(inst) then
				local t = deduceFruitType(inst)
				knownTypes[t] = true
			end
		end
	end
end

local function scanAndDelete()
	refreshMyFarm()
	while true do
		if not ENABLED then
			-- idle wait while disabled
			task.wait(0.25)
			refreshMyFarm()
			continue
		end

		-- Ensure we have at least one removal remote; retry until available
		local removeItemRemote = getRemoveItemRemote()
		local deleteRemote = getDeleteRemote()
		if not removeItemRemote and not deleteRemote then
			warn("AutoShovel: Removal RemoteEvent not found. Retrying...")
			task.wait(0.5)
			continue
		end

		-- Ensure shovel stays equipped
		equipShovel()

		-- Iterate all weight values (fruit) and delete
		for _, inst in ipairs(Workspace:GetDescendants()) do
			if not ENABLED then break end
			if inst:IsA("NumberValue") and inst.Name == "Weight" then
				-- filter by farm first
				if isInMyFarm(inst) then
					local t = deduceFruitType(inst)
					knownTypes[t] = true
					if (SELECTED_TYPE == "All" or t == SELECTED_TYPE) then
						local w = tonumber(inst.Value) or 0
						if w <= THRESHOLD_KG then
							tryDeleteFruit(inst, removeItemRemote, deleteRemote)
							task.wait(LOOP_DELAY)
						end
					end
				end
			end
		end
		-- periodic refresh
		refreshMyFarm()
		task.wait(LOOP_DELAY)
	end
end

task.spawn(scanAndDelete)

-- ========================= UI =========================
local function buildUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "AutoShovel_UI"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = localPlayer:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 300, 0, 190)
	frame.Position = UDim2.new(0.5, -150, 0.5, -95)
	frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Text = "Auto Shovel Fruit"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextColor3 = Color3.new(1,1,1)
	title.Size = UDim2.new(1, -10, 0, 22)
	title.Position = UDim2.new(0, 10, 0, 8)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame

	-- Dropdown for fruit type
	local dd = Instance.new("TextButton")
	dd.Size = UDim2.new(1, -20, 0, 28)
	dd.Position = UDim2.new(0, 10, 0, 44)
	dd.BackgroundColor3 = Color3.fromRGB(32,32,32)
	dd.BorderSizePixel = 0
	dd.Text = SELECTED_TYPE
	dd.Font = Enum.Font.Gotham
	dd.TextSize = 14
	dd.TextColor3 = Color3.new(1,1,1)
	dd.TextXAlignment = Enum.TextXAlignment.Left
	dd.Parent = frame

	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(1, -20, 0, 70)
	list.Position = UDim2.new(0, 10, 0, 76)
	list.BackgroundColor3 = Color3.fromRGB(24,24,24)
	list.BorderSizePixel = 0
	list.Visible = false
	list.CanvasSize = UDim2.new(0,0,0,0)
	list.ScrollBarThickness = 4
	list.ZIndex = 10
	list.Parent = frame

	local uiList = Instance.new("UIListLayout")
	uiList.SortOrder = Enum.SortOrder.LayoutOrder
	uiList.Parent = list

	local function rebuildOptions()
		collectKnownTypes()
		for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		local options = {"All"}
		for t,_ in pairs(knownTypes) do if t ~= "All" then table.insert(options, t) end end
		table.sort(options)
		for _, name in ipairs(options) do
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -8, 0, 24)
			btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
			btn.BorderSizePixel = 0
			btn.Text = name
			btn.Font = Enum.Font.Gotham
			btn.TextSize = 14
			btn.TextColor3 = Color3.new(1,1,1)
			btn.ZIndex = 11
			btn.Parent = list
			btn.MouseButton1Click:Connect(function()
				SELECTED_TYPE = name
				dd.Text = SELECTED_TYPE
				list.Visible = false
			end)
		end
		list.CanvasSize = UDim2.new(0,0,0,uiList.AbsoluteContentSize.Y + 6)
	end

	dd.MouseButton1Click:Connect(function()
		list.Visible = not list.Visible
		if list.Visible then rebuildOptions() end
	end)

	-- Threshold textbox
	local thLabel = Instance.new("TextLabel")
	thLabel.BackgroundTransparency = 1
	thLabel.Text = "Threshold (kg)"
	thLabel.Font = Enum.Font.Gotham
	thLabel.TextSize = 14
	thLabel.TextColor3 = Color3.fromRGB(220,220,220)
	thLabel.Size = UDim2.new(0, 120, 0, 24)
	thLabel.Position = UDim2.new(0, 10, 0, 150-54)
	thLabel.TextXAlignment = Enum.TextXAlignment.Left
	thLabel.Parent = frame

	local thBox = Instance.new("TextBox")
	thBox.Size = UDim2.new(0, 70, 0, 24)
	thBox.Position = UDim2.new(0, 140, 0, 96)
	thBox.BackgroundColor3 = Color3.fromRGB(32,32,32)
	thBox.BorderSizePixel = 0
	thBox.ClearTextOnFocus = false
	thBox.Text = tostring(THRESHOLD_KG)
	thBox.Font = Enum.Font.Gotham
	thBox.TextSize = 14
	thBox.TextColor3 = Color3.new(1,1,1)
	thBox.Parent = frame

	-- Only my farm toggle
	local farmToggle = Instance.new("TextButton")
	farmToggle.Size = UDim2.new(1, -20, 0, 24)
	farmToggle.Position = UDim2.new(0, 10, 0, 126)
	farmToggle.BackgroundColor3 = Color3.fromRGB(32,32,32)
	farmToggle.BorderSizePixel = 0
	farmToggle.Text = ONLY_MY_FARM and "Only My Farm: ON" or "Only My Farm: OFF"
	farmToggle.Font = Enum.Font.Gotham
	farmToggle.TextSize = 14
	farmToggle.TextColor3 = Color3.new(1,1,1)
	farmToggle.Parent = frame

	farmToggle.MouseButton1Click:Connect(function()
		ONLY_MY_FARM = not ONLY_MY_FARM
		farmToggle.Text = ONLY_MY_FARM and "Only My Farm: ON" or "Only My Farm: OFF"
		refreshMyFarm()
		-- reset known types so dropdown reflects current scope
		knownTypes = { All = true }
	end)

	-- Start/Stop button
	local startBtn = Instance.new("TextButton")
	startBtn.Size = UDim2.new(0, 90, 0, 28)
	startBtn.Position = UDim2.new(1, -100, 1, -38)
	startBtn.BackgroundColor3 = Color3.fromRGB(38,142,84)
	startBtn.BorderSizePixel = 0
	startBtn.Text = "Start"
	startBtn.Font = Enum.Font.GothamBold
	startBtn.TextSize = 14
	startBtn.TextColor3 = Color3.new(1,1,1)
	startBtn.Parent = frame

	local function parseThreshold()
		local n = tonumber(thBox.Text)
		if n and n > 0 then return n end
		return THRESHOLD_KG
	end

	-- Apply new threshold when the box loses focus or Enter is pressed
	thBox.FocusLost:Connect(function(enterPressed)
		THRESHOLD_KG = parseThreshold()
	end)

	startBtn.MouseButton1Click:Connect(function()
		THRESHOLD_KG = parseThreshold()
		ENABLED = not ENABLED
		startBtn.Text = ENABLED and "Stop" or "Start"
		if ENABLED then
			-- ensure shovel equipped
			equipShovel()
		end
	end)

	return gui
end

pcall(buildUI)

-- Keep options fresh when new fruits spawn
Workspace.DescendantAdded:Connect(function(inst)
	if inst:IsA("NumberValue") and inst.Name == "Weight" then
		if isInMyFarm(inst) then
			local t = deduceFruitType(inst)
			knownTypes[t] = true
		end
	end
end)


