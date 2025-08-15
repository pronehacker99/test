-- Auto Place Pet Egg inside your actual farm bounds
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PetEggService = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetEggService")
local GetFarmAsync = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GetFarmAsync"))

local localPlayer = Players.LocalPlayer

local autoPlace = true
local delayTime = 2 -- seconds between placements (tune if needed)
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

