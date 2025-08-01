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
local mineHeight = 1
local oreSize = Vector3.new(4, 4, 4)
local mineRootPosition = Vector3.new(0, 0, 0)
local mineOrientation = CFrame.Angles(0, math.rad(90), 0)

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

function MineService:KnitStart()
	local mine = Instance.new("Model")
	mine.Name = "Mine"
	mine.Parent = workspace

	for x = 0, mineLength - 1 do
		for z = 0, mineWidth - 1 do
			for y = 0, mineHeight - 1 do
				task.spawn(function()
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
					ore.Parent = mine
				end)
			end
		end
	end
end

return MineService
