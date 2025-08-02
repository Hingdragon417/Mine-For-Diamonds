local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Items = require(ReplicatedStorage.Shared.Modules:WaitForChild("Items"))

local HotbarService = Knit.CreateService({
    Name = "HotbarService",
    Client = {},
    Hotbars = {}
})

-- Example default layout (max 6 slots)
local MAX_SLOTS = 6

function HotbarService:GetDefaultHotbar()
    local hotbar = {}
    for itemName, itemData in Items do
        if itemData.StartWith and #hotbar < MAX_SLOTS then
            table.insert(hotbar, itemName)
        end
    end
    return hotbar
end

function HotbarService:AssignTools(player, hotbar)
    local backpack = player:WaitForChild("Backpack")
    local toolsFolder = ServerStorage:WaitForChild("Tools")

    for _, itemName in hotbar do
        local tool = toolsFolder:FindFirstChild(itemName)
        if tool then
            local clone = tool:Clone()
            clone.Parent = backpack
        end
    end
end

function HotbarService.Client:GetHotbar(player)
    local hotbar = HotbarService.Hotbars[player]
    if type(hotbar) == "table" then
        return hotbar
    else
        local defaultHotbar = HotbarService:GetDefaultHotbar()
        HotbarService.Hotbars[player] = defaultHotbar
        return defaultHotbar
    end
end

function HotbarService:KnitStart()
    Players.PlayerAdded:Connect(function(player)
        local defaultHotbar = self:GetDefaultHotbar()
        self.Hotbars[player] = defaultHotbar

        self:AssignTools(player, defaultHotbar)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self.Hotbars[player] = nil
    end)
end

function HotbarService:KnitInit() end

return HotbarService
