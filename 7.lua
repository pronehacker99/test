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
	local cf = farm:GetPivot()
	local size = farm:GetExtentsSize()
	local halfX = math.max(0, (size.X * 0.5) - margin)
	local halfZ = math.max(0, (size.Z * 0.5) - margin)
	return {
		center = cf.Position,
		rangeX = halfX,
		rangeZ = halfZ,
		farm = farm,
	}
end

local function raycastToGround(farm, x, yStart, z)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Whitelist
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

