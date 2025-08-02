local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Items = require(ReplicatedStorage.Shared.Modules:WaitForChild("Items"))

local HotbarService = Knit.CreateService({
    Name = "HotbarService",
    Client = {}
})

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

function HotbarService.Client:EquipTool(player, slotIndex)
    local DataService = Knit.GetService("DataService")
    local session = DataService.getSession(player)
    
    if not session or not session.Data or not session.Data.hotbar then
        return
    end
    
    local itemName = session.Data.hotbar[slotIndex]
    if not itemName then
        return
    end
    
    local character = player.Character
    if not character then
        return
    end
    
    local toolsFolder = ServerStorage:WaitForChild("Tools")
    local existingTool = character:FindFirstChild(itemName)
    
    if existingTool then
        existingTool:Destroy()
    else
        local tool = toolsFolder:FindFirstChild(itemName)
        if tool then
            local clone = tool:Clone()
            clone.Parent = character
        end
    end
end

function HotbarService.Client:GetHotbar(player)
    local DataService = Knit.GetService("DataService")
    local session = DataService.getSession(player)
    
    if session and session.Data then
        local hotbar = session.Data.hotbar
        if type(hotbar) == "table" and #hotbar > 0 then
            print("Server hotbar data:", hotbar)
            return hotbar
        end
    end
    
    local defaultHotbar = HotbarService:GetDefaultHotbar()
    HotbarService:SetHotbar(player, defaultHotbar)
    print("Server hotbar data:", defaultHotbar)
    return defaultHotbar
end

function HotbarService:SetHotbar(player, hotbarData)
    local DataService = Knit.GetService("DataService")
    local session = DataService.getSession(player)
    
    if session and session.Data then
        session.Data.hotbar = hotbarData
        DataService:Replicate(player, "hotbar")
    end
end

function HotbarService:KnitStart()
    local DataService = Knit.GetService("DataService")
    
    Players.PlayerAdded:Connect(function(player)
        local session = DataService.waitForSession(player)
        
        if session and session.Data then
            if not session.Data.hotbar or #session.Data.hotbar == 0 then
                local defaultHotbar = self:GetDefaultHotbar()
                session.Data.hotbar = defaultHotbar
                DataService:Replicate(player, "hotbar")
            end
        end
    end)
end

function HotbarService:KnitInit() end

return HotbarService