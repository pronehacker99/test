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

	local function update()
		local text = formatKg(weightValue.Value)
		local label = gui:FindFirstChild("Frame") and gui.Frame:FindFirstChild("Label")
		if label and label:IsA("TextLabel") then
			label.Text = text
		end
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
					attachEspToWeight(nv)
				end
			end
		end
	end
end

local function listenForNewWeights()
	Workspace.DescendantAdded:Connect(function(inst)
		if inst:IsA("NumberValue") and inst.Name == "Weight" then
			attachEspToWeight(inst)
		end
	end)
end

-- Kickoff
scanInitial()
listenForNewWeights()


