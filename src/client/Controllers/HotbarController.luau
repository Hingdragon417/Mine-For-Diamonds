local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local HotbarController = Knit.CreateController({
    Name = "HotbarController",
})

local TWEEN_TIME = 0.25
local HOVER_SCALE = 1.2
local DEFAULT_SCALE = 1

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
    for _, item in hotbar:GetChildren() do
        if item:IsA("Frame") then
            item.MouseEnter:Connect(function()
                self:TweenToScale(item, HOVER_SCALE)
            end)
            item.MouseLeave:Connect(function()
                self:TweenToScale(item, DEFAULT_SCALE)
            end)
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

    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = playerGui:WaitForChild("MainUI")
    local hotbarGui = screenGui:WaitForChild("Hotbar")

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
