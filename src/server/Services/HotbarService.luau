local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Items = require(ReplicatedStorage.Shared.Modules:WaitForChild("Items"))
local HotbarConfig = require(ReplicatedStorage.Shared.Modules:WaitForChild("HotbarConfig"))

local HotbarService = Knit.CreateService({
    Name = "HotbarService",
    Client = {}
})

function HotbarService:GetSpawnItems()
    local spawnItems = {}
    for itemName, itemData in Items do
        if itemData.SpawnWith then
            table.insert(spawnItems, itemName)
        end
    end
    return spawnItems
end

function HotbarService:GetDefaultHotbar()
    local hotbar = {}
    
    for i = 1, HotbarConfig.MAX_SLOTS do
        hotbar[i] = ""
    end
    
    local spawnItems = self:GetSpawnItems()
    for i, itemName in ipairs(spawnItems) do
        if i <= HotbarConfig.MAX_SLOTS then
            hotbar[i] = itemName
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

function HotbarService.Client:SwapHotbarSlots(player, fromSlot, toSlot)
    local DataService = Knit.GetService("DataService")
    local session = DataService.getSession(player)
    
    if not session or not session.Data or not session.Data.hotbar then
        return { success = false, hotbar = nil }
    end
    
    local hotbar = session.Data.hotbar
    local fromItem = hotbar[fromSlot]
    
    if not fromItem or fromItem == "" then
        return { success = false, hotbar = hotbar }
    end
    
    local toItem = hotbar[toSlot]
    
    hotbar[fromSlot] = toItem or ""
    hotbar[toSlot] = fromItem
    
    session.Data.hotbar = hotbar
    DataService:Replicate(player, "hotbar")
    
    return { success = true, hotbar = hotbar }
end

function HotbarService.Client:GetHotbar(player)
    local DataService = Knit.GetService("DataService")
    local session = DataService.getSession(player)
    
    if session and session.Data and session.Data.hotbar then
        local hotbar = session.Data.hotbar
        local hasItems = false
        for i = 1, HotbarConfig.MAX_SLOTS do
            if hotbar[i] and hotbar[i] ~= "" then
                hasItems = true
                break
            end
        end
        
        if hasItems then
            return hotbar
        end
    end
    
    local defaultHotbar = HotbarService:GetDefaultHotbar()
    HotbarService:SetHotbar(player, defaultHotbar)
    return defaultHotbar
end

function HotbarService:SetHotbar(player, hotbarData)
    local DataService = Knit.GetService("DataService")
    local session = DataService.getSession(player)
    
    if session and session.Data then
        local formattedHotbar = {}
        for i = 1, HotbarConfig.MAX_SLOTS do
            formattedHotbar[i] = hotbarData[i] or ""
        end
        
        session.Data.hotbar = formattedHotbar
        DataService:Replicate(player, "hotbar")
    end
end

function HotbarService:KnitStart()
    local DataService = Knit.GetService("DataService")
    
    Players.PlayerAdded:Connect(function(player)
        local session = DataService.waitForSession(player)
        
        if session and session.Data then
            if not session.Data.hotbar then
                session.Data.hotbar = {}
            end
            
            local hotbar = session.Data.hotbar
            local hasValidStructure = true
            
            for i = 1, HotbarConfig.MAX_SLOTS do
                if hotbar[i] == nil then
                    hasValidStructure = false
                    break
                end
            end
            
            if not hasValidStructure then
                local defaultHotbar = self:GetDefaultHotbar()
                session.Data.hotbar = defaultHotbar
                DataService:Replicate(player, "hotbar")
            end
        end
    end)
end

function HotbarService:KnitInit() end

return HotbarService