local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local OresFolder = ReplicatedStorage.Ores
local OreChances = require(ReplicatedStorage.Shared.Modules.OreChances)

local Knit = require(Packages.Knit)

local StartPoint = Vector3.new(0, 0, 0) -- Example start point, adjust as needed

local GenerateController = Knit.CreateService({
    Name = "GenerateController",
    Client = {}
})

function GenerateController:ChooseOreFromChances()
    local totalChance = 0
    for _, chance in pairs(OreChances) do
        totalChance += chance
    end

    local randomValue = math.random(1, totalChance)
    local cumulativeChance = 0

    for oreType, chance in pairs(OreChances) do
        cumulativeChance += chance
        if randomValue <= cumulativeChance then
            return oreType
        end
    end
    return nil
end

function GenerateController:GenerateOre(chosenOre)
    local ore = OresFolder:FindFirstChild(chosenOre)

    task.spawn(function()
        if ore then
            local oreClone = ore:Clone()
            oreClone.PrimaryPart.Position = StartPoint + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10)) -- Random position around the start point
            oreClone.Parent = workspace -- Adjust parent as needed
        else
            warn("Ore type not found: " .. tostring(chosenOre))
        end
    end)
end


function GenerateController:KnitStart()
    self:GenerateOre(self:ChooseOreFromChances())
end

function GenerateController:KnitInit() 

end

return GenerateController
