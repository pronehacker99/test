-- Fruit ESP: displays fruit weight (kg) above fruits in the world
-- Scans the world for fruit-like objects by looking for a NumberValue named "Weight"
-- and renders a BillboardGui with the current weight.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer

-- Configuration
local SCAN_ROOTS: {Instance} = {
	Workspace,
	Workspace:FindFirstChild("Farm") or Workspace,
}
local MAX_LABEL_DISTANCE = 1000 -- studs; beyond this we hide labels
local LABEL_OFFSET_Y = 2 -- studs above the fruit's top

-- State
local weightValueToGui: {[Instance]: BillboardGui} = {}
local modelToGui: {[Instance]: BillboardGui} = {}
local weightToType: {[Instance]: string} = {}
local knownTypes: {[string]: boolean} = {}
local selectedType = "All"

local function formatKg(weightValue: number): string
	if typeof(weightValue) ~= "number" then return "" end
	return string.format("%.2f kg", weightValue)
end

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

local function createBillboard(adornee: BasePart): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Name = "FruitESP"
	gui.Size = UDim2.new(0, 140, 0, 36)
	gui.AlwaysOnTop = true
	gui.MaxDistance = MAX_LABEL_DISTANCE
	gui.StudsOffsetWorldSpace = Vector3.new(0, LABEL_OFFSET_Y, 0)
	gui.Adornee = adornee
	gui.Parent = adornee

	local bg = Instance.new("Frame")
	bg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	bg.BackgroundTransparency = 0.25
	bg.BorderSizePixel = 0
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.Parent = gui

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 6)
	uiCorner.Parent = bg

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Transparency = 0.3
	stroke.Parent = bg

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -10, 1, 0)
	label.Position = UDim2.new(0, 5, 0, 0)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.5
	label.Text = ""
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Parent = bg

	return gui
end

local function normalizeFruitName(s: string): string
	if typeof(s) ~= "string" then return "Unknown" end
	-- Remove trailing digits and underscores, compress spaces
	local out = s
	out = out:gsub("_%d+$", "")
	out = out:gsub("%d+$", "")
	out = out:gsub("_", " ")
	out = out:gsub("%s+", " ")
	out = out:gsub("%.$", "")
	return (out:match("^%s*(.-)%s*$") or out)
end

local function determineFruitType(weightValue: NumberValue): string
	local m = weightValue:FindFirstAncestorOfClass("Model")
	if m then
		while m.Parent and m.Parent:IsA("Model") do
			m = m.Parent
		end
		return normalizeFruitName(m.Name)
	end
	if weightValue.Parent then
		return normalizeFruitName(weightValue.Parent.Name)
	end
	return "Unknown"
end

local onlyMyFarm = true

local function isInMyFarm(inst: Instance): boolean
	if not onlyMyFarm then return true end
	-- Heuristic: if there's a model in ancestry with an Owner_Tag, include only if found; otherwise allow by default
	local m = inst:FindFirstAncestorOfClass("Model")
	while m do
		local ownerTag = m:FindFirstChild("Owner_Tag", true)
		if ownerTag then
			-- If an owner tag exists, we assume this is the local player's farm in single-player contexts
			return true
		end
		m = m.Parent and m.Parent:FindFirstAncestorOfClass("Model")
	end
	return true
end

local function shouldShow(typeName: string): boolean
	return selectedType == "All" or typeName == selectedType
end

local function attachEspToWeight(weightValue: NumberValue)
	-- Avoid duplicates
	if weightValueToGui[weightValue] then return end

	-- Find a good adornee (BasePart) near the weight value
	local container = weightValue.Parent
	local adornee = findFirstBasePart(container)
	if not adornee then
		-- Walk up to an ancestor model and try again
		local ancestor = weightValue:FindFirstAncestorOfClass("Model")
		adornee = findFirstBasePart(ancestor or container)
	end
	if not adornee then return end

	local gui = createBillboard(adornee)
	weightValueToGui[weightValue] = gui
	local ancModel = adornee:FindFirstAncestorOfClass("Model")
	modelToGui[ancModel or adornee] = gui

	-- Classify fruit and record known types
	local fruitType = determineFruitType(weightValue)
	weightToType[weightValue] = fruitType
	knownTypes[fruitType] = true

	local function update()
		local text = formatKg(weightValue.Value)
		local label = gui:FindFirstChild("Frame") and gui.Frame:FindFirstChild("Label")
		if label and label:IsA("TextLabel") then
			label.Text = text
		end
		gui.Enabled = shouldShow(fruitType)
	end
	update()
	weightValue:GetPropertyChangedSignal("Value"):Connect(update)
	weightValue.AncestryChanged:Connect(function(_, parent)
		if not weightValue:IsDescendantOf(Workspace) then
			local g = weightValueToGui[weightValue]
			if g then
				weightValueToGui[weightValue] = nil
				g:Destroy()
			end
		end
	end)
end

local function scanInitial()
	local visited = {}
	for _, root in ipairs(SCAN_ROOTS) do
		if root and root:IsDescendantOf(Workspace) and not visited[root] then
			visited[root] = true
			for _, nv in ipairs(root:GetDescendants()) do
				if nv:IsA("NumberValue") and nv.Name == "Weight" then
					if isInMyFarm(nv) then
						attachEspToWeight(nv)
					end
				end
			end
		end
	end
end

local function listenForNewWeights()
	Workspace.DescendantAdded:Connect(function(inst)
		if inst:IsA("NumberValue") and inst.Name == "Weight" then
			if isInMyFarm(inst) then
				attachEspToWeight(inst)
			end
		end
	end)
end

-- UI: Simple dropdown to choose fruit type to ESP
local function buildUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "FruitESP_UI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 240, 0, 150)
	frame.Position = UDim2.new(0, 12, 0, 12)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Text = "Fruit ESP"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextColor3 = Color3.new(1,1,1)
	title.Size = UDim2.new(1, -10, 0, 22)
	title.Position = UDim2.new(0, 10, 0, 8)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame

	local dropdown = Instance.new("TextButton")
	dropdown.Size = UDim2.new(1, -20, 0, 28)
	dropdown.Position = UDim2.new(0, 10, 0, 44)
	dropdown.BackgroundColor3 = Color3.fromRGB(32,32,32)
	dropdown.BorderSizePixel = 0
	dropdown.Text = selectedType
	dropdown.Font = Enum.Font.Gotham
	dropdown.TextSize = 14
	dropdown.TextColor3 = Color3.new(1,1,1)
	dropdown.TextXAlignment = Enum.TextXAlignment.Left
	dropdown.Parent = frame

	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(1, -20, 0, 60)
	list.Position = UDim2.new(0, 10, 0, 76)
	list.BackgroundColor3 = Color3.fromRGB(24,24,24)
	list.BorderSizePixel = 0
	list.Visible = false
	list.CanvasSize = UDim2.new(0,0,0,0)
	list.ScrollBarThickness = 4
	list.Parent = frame

	local uiList = Instance.new("UIListLayout")
	uiList.SortOrder = Enum.SortOrder.LayoutOrder
	uiList.Parent = list

	-- Checkbox-like toggle for farm scope
	local toggle = Instance.new("TextButton")
	toggle.Size = UDim2.new(1, -20, 0, 24)
	toggle.Position = UDim2.new(0, 10, 0, 110)
	toggle.BackgroundColor3 = Color3.fromRGB(32,32,32)
	toggle.BorderSizePixel = 0
	toggle.Text = "Only My Farm: ON"
	toggle.Font = Enum.Font.Gotham
	toggle.TextSize = 14
	toggle.TextColor3 = Color3.new(1,1,1)
	toggle.Parent = frame

	local function refreshCheckbox()
		toggle.Text = onlyMyFarm and "Only My Farm: ON" or "Only My Farm: OFF (All Farms)"
	end

	local function applyFilter()
		for w, g in pairs(weightValueToGui) do
			local t = weightToType[w]
			if g then g.Enabled = shouldShow(t) end
		end
	end

	local function rebuildOptions()
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		local options = {"All"}
		for t,_ in pairs(knownTypes) do table.insert(options, t) end
		table.sort(options)
		for _, name in ipairs(options) do
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -8, 0, 22)
			btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
			btn.BorderSizePixel = 0
			btn.Text = name
			btn.Font = Enum.Font.Gotham
			btn.TextSize = 13
			btn.TextColor3 = Color3.new(1,1,1)
			btn.Parent = list
			btn.MouseButton1Click:Connect(function()
				selectedType = name
				dropdown.Text = selectedType
				list.Visible = false
				applyFilter()
			end)
		end
		list.CanvasSize = UDim2.new(0,0,0,uiList.AbsoluteContentSize.Y + 6)
	end

	dropdown.MouseButton1Click:Connect(function()
		list.Visible = not list.Visible
		if list.Visible then rebuildOptions() end
	end)

	toggle.MouseButton1Click:Connect(function()
		onlyMyFarm = not onlyMyFarm
		refreshCheckbox()
		-- reset and rescan
		for _, g in pairs(weightValueToGui) do if g then g:Destroy() end end
		weightValueToGui = {}
		knownTypes = {}
		weightToType = {}
		scanInitial()
		applyFilter()
	end)

	refreshCheckbox()
	-- initial populate after scan
	task.defer(rebuildOptions)
	return gui
end

-- Kickoff
scanInitial()
listenForNewWeights()
pcall(buildUI)


