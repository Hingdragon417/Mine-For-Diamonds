local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local OreChances = require(ReplicatedStorage.Shared.Modules.OreChances)
local oresFolder = ReplicatedStorage:WaitForChild("Ores")

local MineService = Knit.CreateService({
	Name = "MineService",
})

local mineLength = 25
local mineWidth = 25
local mineHeight = 250
local oreSize = Vector3.new(4, 4, 4)
local mineRootPosition = Vector3.new(0, 0, 0)
local mineOrientation = CFrame.Angles(0, math.rad(90), 0)

local placedOres = {}

function MineService:getOre()
	local totalChance = 0
	for _, chance in pairs(OreChances) do
		totalChance += chance
	end

	local roll = math.random(1, totalChance)
	local cumulative = 0

	for oreName, chance in pairs(OreChances) do
		cumulative += chance
		if roll <= cumulative then
			local model = oresFolder:FindFirstChild(oreName)
			if model then
				return model:Clone()
			end
		end
	end

	return nil
end

function MineService:generateBlock(x, y, z, parent)
	if x < 0 or x >= mineLength or y < 0 or y >= mineHeight or z < 0 or z >= mineWidth then return end

	local key = x .. "," .. y .. "," .. z
	if placedOres[key] then return end
	placedOres[key] = true

	local ore = self:getOre()
	if not ore then return end

	local localPos = Vector3.new(x * oreSize.X, -y * oreSize.Y, z * oreSize.Z)
	local worldCFrame = CFrame.new(mineRootPosition) * mineOrientation * CFrame.new(localPos)
	ore:PivotTo(worldCFrame)

	for _, part in ipairs(ore:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end

	ore.Destroying:Connect(function()
		for _, offset in ipairs({
			Vector3.new(1, 0, 0),
			Vector3.new(-1, 0, 0),
			Vector3.new(0, 1, 0),
			Vector3.new(0, -1, 0),
			Vector3.new(0, 0, 1),
			Vector3.new(0, 0, -1),
			}) do
			self:generateBlock(x + offset.X, y + offset.Y, z + offset.Z, parent)
		end
	end)

	ore.Parent = parent
end

function MineService:KnitStart()
	local mine = Instance.new("Model")
	mine.Name = "Mine"
	mine.Parent = workspace

	for x = 0, mineLength - 1 do
		for z = 0, mineWidth - 1 do
			self:generateBlock(x, 0, z, mine)
		end
	end
end

return MineService
