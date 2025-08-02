local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local HotbarController = Knit.CreateController({
    Name = "HotbarController",
})

local TWEEN_TIME = 0.25
local HOVER_SCALE = 1.2
local DEFAULT_SCALE = 1

local NumberToEnumMap : {[number]: Enum.KeyCode} = {
    [1] = Enum.KeyCode.One,
    [2] = Enum.KeyCode.Two,
    [3] = Enum.KeyCode.Three,
    [4] = Enum.KeyCode.Four,
    [5] = Enum.KeyCode.Five,
    [6] = Enum.KeyCode.Six,
    [7] = Enum.KeyCode.Seven,
    [8] = Enum.KeyCode.Eight,
    [9] = Enum.KeyCode.Nine,
    [0] = Enum.KeyCode.Zero,
}

local function GetKeyCodeForSlot(slotIndex)
    return NumberToEnumMap[slotIndex]
end

function HotbarController:TweenToScale(item, scale)
    local uiScale = item:FindFirstChildOfClass("UIScale")
    if not uiScale then
        uiScale = Instance.new("UIScale")
        uiScale.Scale = DEFAULT_SCALE
        uiScale.Parent = item
    end

    local tween = TweenService:Create(uiScale, TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Scale = scale,
    })
    tween:Play()
end

function HotbarController:ConnectHotbarUI(hotbar)
    local HotbarService = Knit.GetService("HotbarService")
    
    for _, item in hotbar:GetChildren() do
        if item:IsA("Frame") and item.Name:match("SLOT_") then
            local slotIndex = tonumber(item.Name:match("SLOT_(%d+)"))
            
            item.MouseEnter:Connect(function()
                self:TweenToScale(item, HOVER_SCALE)
            end)
            item.MouseLeave:Connect(function()
                self:TweenToScale(item, DEFAULT_SCALE)
            end)

            local keyCode = GetKeyCodeForSlot(slotIndex)
            if keyCode then
                UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if not gameProcessed and input.KeyCode == keyCode then
                        HotbarService:EquipTool(slotIndex)

                    end
                end)
            end
            
            local button = item:FindFirstChild(item.Name)
            if button and (button:IsA("TextButton") or button:IsA("ImageButton")) then
                button.MouseButton1Click:Connect(function()
                    if slotIndex then
                        HotbarService:EquipTool(slotIndex)
                    end
                end)
            end
        end
    end
end

function HotbarController:DisplayHotbarItems(hotbarGui, hotbarData)
    if type(hotbarData) ~= "table" then
        hotbarData = {}
    end
    
    for slotIndex, itemName in hotbarData do
        local slot = hotbarGui:WaitForChild("SLOT_" .. slotIndex)
        print(slot)
        if slot and slot:IsA("Frame") then
            local label = slot:FindFirstChild("Name")
            if label and label:IsA("TextLabel") then
                label.Text = itemName
            end
        end
    end
end

function HotbarController:KnitStart()
    local HotbarService = Knit.GetService("HotbarService")
    local StarterGui = game:GetService("StarterGui")

    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = playerGui:WaitForChild("MainUI")
    local hotbarGui = screenGui:WaitForChild("Hotbar")

    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

    self:ConnectHotbarUI(hotbarGui)

    HotbarService:GetHotbar():andThen(function(hotbarData)
        print("Client hotbar data:", hotbarData)
        self:DisplayHotbarItems(hotbarGui, hotbarData)
    end):catch(function()
        self:DisplayHotbarItems(hotbarGui, {})
    end)
end

function HotbarController:KnitInit() end

return HotbarController