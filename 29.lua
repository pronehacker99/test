-- Auto Shovel Fruit
-- Equips a shovel and deletes fruit models (objects with a NumberValue named "Weight")
-- Defaults to only acting inside your own farm

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
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

-- Known fruit/produce names (normalized) observed in this place
local FRUIT_NAME_WHITELIST: {[string]: boolean} = {
	["Carrot"] = true, ["Strawberry"] = true, ["Blueberry"] = true, ["Orange Tulip"] = true,
	["Tomato"] = true, ["Corn"] = true, ["Daffodil"] = true, ["Apple"] = true,
	["Chocolate Carrot"] = true, ["Red Lollipop"] = true, ["Blue Lollipop"] = true,
	["Nightshade"] = true, ["Glowshroom"] = true, ["Mint"] = true, ["Rose"] = true,
	["Foxglove"] = true, ["Crocus"] = true, ["Delphinium"] = true, ["Manuka Flower"] = true,
	["Lavender"] = true, ["Nectarshade"] = true, ["Peace Lily"] = true, ["Wild Carrot"] = true,
	["Pear"] = true, ["Horsetail"] = true, ["Monoblooma"] = true, ["Dezen"] = true,
	["Artichoke"] = true, ["Spring Onion"] = true,
}

local function findFirstBasePart(container: Instance): BasePart?
	if container == nil then return nil end
	if container:IsA("BasePart") then return container end
	if container:IsA("Model") then
		local model = container :: Model
		if model.PrimaryPart then return model.PrimaryPart end
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then return d end
		end
	end
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("BasePart") then return d end
	end
	return nil
end

local function getModelPivotPosition(m: Model): Vector3?
	local ok, cf = pcall(function()
		return m:GetPivot()
	end)
	if ok and typeof(cf) == "CFrame" then
		return cf.Position
	end
	local bp = findFirstBasePart(m)
	return bp and bp.Position or nil
end

local function findAncestorFolderByName(inst: Instance, folderName: string): Instance?
	local cur = inst.Parent
	while cur do
		if cur:IsA("Folder") and cur.Name == folderName then
			return cur
		end
		cur = cur.Parent
	end
	return nil
end

local function getModelExtentsMagnitude(m: Model): number
	local ok, size = pcall(function()
		return m:GetExtentsSize()
	end)
	if ok and typeof(size) == "Vector3" then
		return (size.X * size.X + size.Y * size.Y + size.Z * size.Z) ^ 0.5
	end
	return math.huge
end

local function isProbablyTreeOrStructure(m: Model): boolean
	if CollectionService:HasTag(m, "PlaceableObject") then return true end
	if CollectionService:HasTag(m, "Tree") then return true end
	local lname = string.lower(m.Name or "")
	if lname:find("tree") or lname:find("sapling") or lname:find("trunk") or lname:find("stump") or lname:find("bush") then
		return true
	end
	return false
end

local function normalizeName(s: string): string
	local out = s or ""
	out = out:gsub("_%d+$", ""):gsub("%d+$", ""):gsub("_", " "):gsub("%s+", " ")
	return (out:match("^%s*(.-)%s*$") or out)
end

local function getFruitModelFromWeight(weightValue: NumberValue): Instance
	-- 1) If this weight lives under a 'Fruits' folder, return the specific fruit model child
	local fruitsFolder = findAncestorFolderByName(weightValue, "Fruits")
	if fruitsFolder then
		for _, child in ipairs(fruitsFolder:GetChildren()) do
			if child:IsA("Model") and weightValue:IsDescendantOf(child) then
				return child
			end
		end
		-- As a fallback, pick the closest small model under the Fruits folder
		local allFruitModels: {Model} = {}
		for _, child in ipairs(fruitsFolder:GetChildren()) do
			if child:IsA("Model") then table.insert(allFruitModels, child) end
		end
		if #allFruitModels > 0 then
			local weightPart = findFirstBasePart(weightValue.Parent)
			local weightPos = weightPart and weightPart.Position or nil
			local best, bestScore = nil, math.huge
			for _, m in ipairs(allFruitModels) do
				local sizeMag = getModelExtentsMagnitude(m)
				local pos = getModelPivotPosition(m) or weightPos
				local dist = (weightPos and pos) and (pos - weightPos).Magnitude or 0
				local score = dist + sizeMag * 0.25
				if score < bestScore then best, bestScore = m, score end
			end
			if best then return best end
		end
	end

	-- 2) Otherwise, pick among ancestors with strong filters (non-placeable, non-tree), favoring small/close
	local ancestorModels: {Model} = {}
	local cur = weightValue:FindFirstAncestorOfClass("Model")
	while cur and cur:IsA("Model") do
		table.insert(ancestorModels, cur)
		cur = cur.Parent and cur.Parent:FindFirstAncestorOfClass("Model") or nil
	end

	local candidatesGrowable: {Model} = {}
	local candidatesWhitelist: {Model} = {}
	local candidatesSafe: {Model} = {}

	-- Reference position near this weight to choose closest sub-model (fruit)
	local weightPos: Vector3? = nil
	local weightPart = findFirstBasePart(weightValue.Parent)
	if weightPart then weightPos = weightPart.Position end

	for _, m in ipairs(ancestorModels) do
		local norm = normalizeName(m.Name or "")
		local isGrowable = CollectionService:HasTag(m, "Growable")
		local isPlaceable = CollectionService:HasTag(m, "PlaceableObject")
		local isTreeLike = isProbablyTreeOrStructure(m)
		if FRUIT_NAME_WHITELIST[norm] and not isPlaceable and not isTreeLike then
			table.insert(candidatesWhitelist, m)
		end
		if isGrowable and not isPlaceable and not isTreeLike then
			table.insert(candidatesGrowable, m)
		end
		if not isPlaceable and not isTreeLike then
			table.insert(candidatesSafe, m)
		end
	end

	local function pickSmallest(list: {Model}): Model?
		local best, bestMag = nil, math.huge
		for _, m in ipairs(list) do
			local mag = getModelExtentsMagnitude(m)
			if mag < bestMag then
				best = m
				bestMag = mag
			end
		end
		return best
	end

	local function pickClosestSmall(list: {Model}): Model?
		if not weightPos then return pickSmallest(list) end
		local best, bestScore = nil, math.huge
		for _, m in ipairs(list) do
			local pos = getModelPivotPosition(m) or weightPos
			local sizeMag = getModelExtentsMagnitude(m)
			local dist = (pos - weightPos).Magnitude
			-- Weighted score favors near and small
			local score = dist + sizeMag * 0.25
			if score < bestScore then
				best = m
				bestScore = score
			end
		end
		return best
	end

	return pickClosestSmall(candidatesWhitelist)
		or pickClosestSmall(candidatesGrowable)
		or pickClosestSmall(candidatesSafe)
		or ancestorModels[1]
		or weightValue.Parent
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
	-- Never delete placeable objects (e.g., entire trees) from this tool
	if target:IsA("Model") then
		if CollectionService:HasTag(target, "PlaceableObject") then return end
		if isProbablyTreeOrStructure(target) then return end
	end
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


