local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local HotbarController = Knit.CreateController({
    Name = "HotbarController",
})

local TWEEN_HOVER_TIME = 0.2
local TWEEN_CLICK_IN_TIME = 0.08
local TWEEN_CLICK_OUT_TIME = 0.15
local HOVER_SCALE = 1.15
local CLICK_SCALE = 0.9
local DEFAULT_SCALE = 1

local NumberToEnumMap = {
    [1] = Enum.KeyCode.One, [2] = Enum.KeyCode.Two, [3] = Enum.KeyCode.Three,
    [4] = Enum.KeyCode.Four, [5] = Enum.KeyCode.Five, [6] = Enum.KeyCode.Six,
    [7] = Enum.KeyCode.Seven, [8] = Enum.KeyCode.Eight, [9] = Enum.KeyCode.Nine,
    [0] = Enum.KeyCode.Zero,
}

local function GetKeyCodeForSlot(slotIndex)
    return NumberToEnumMap[slotIndex]
end

function HotbarController:TweenToScale(item, scale, time, easingStyle, easingDirection)
    local uiScale = item:FindFirstChildOfClass("UIScale")
    if not uiScale then
        uiScale = Instance.new("UIScale")
        uiScale.Scale = DEFAULT_SCALE
        uiScale.Parent = item
    end

    local currentTween = self._tweenMap[item]
    if currentTween then
        currentTween:Cancel()
    end

    local tween = TweenService:Create(uiScale, TweenInfo.new(time, easingStyle, easingDirection), { Scale = scale })
    self._tweenMap[item] = tween
    tween:Play()
    tween.Completed:Connect(function()
        if self._tweenMap[item] == tween then
            self._tweenMap[item] = nil
        end
    end)
    return tween
end

function HotbarController:PlayClickAnimation(item)
    local uiScale = item:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", item)
    uiScale.Scale = uiScale.Scale or DEFAULT_SCALE

    local scaleDown = self:TweenToScale(item, CLICK_SCALE, TWEEN_CLICK_IN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    scaleDown.Completed:Once(function()
        task.wait(0.05)
        if self._hoverState[item] then
            self:TweenToScale(item, HOVER_SCALE, TWEEN_CLICK_OUT_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        else
            self:TweenToScale(item, DEFAULT_SCALE, TWEEN_CLICK_OUT_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        end
    end)
end

function HotbarController:ConnectHotbarUI(hotbar)
    local HotbarService = Knit.GetService("HotbarService")

    for _, item in hotbar:GetChildren() do
        if item:IsA("Frame") and item.Name:match("SLOT_") then
            local slotIndex = tonumber(item.Name:match("SLOT_(%d+)"))
            self._hoverState[item] = false

            item.MouseEnter:Connect(function()
                self._hoverState[item] = true
                self:TweenToScale(item, HOVER_SCALE, TWEEN_HOVER_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
            end)

            item.MouseLeave:Connect(function()
                self._hoverState[item] = false
                task.wait(0.1)
                if not self._hoverState[item] then
                    self:TweenToScale(item, DEFAULT_SCALE, TWEEN_HOVER_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                end
            end)

            local keyCode = GetKeyCodeForSlot(slotIndex)
            if keyCode then
                UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if not gameProcessed and input.KeyCode == keyCode then
                        HotbarService:EquipTool(slotIndex)
                        self:PlayClickAnimation(item)
                    end
                end)
            end

            local button = item:FindFirstChild(item.Name)
            if button and (button:IsA("TextButton") or button:IsA("ImageButton")) then
                button.MouseButton1Click:Connect(function()
                    if slotIndex then
                        HotbarService:EquipTool(slotIndex)
                        self:PlayClickAnimation(item)
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
        if slot and slot:IsA("Frame") then
            local label = slot:FindFirstChild("Name")
            if label and label:IsA("TextLabel") then
                label.Text = itemName
            end
        end
    end
end

function HotbarController:KnitStart()
    self._tweenMap = {}
    self._hoverState = {}

    local HotbarService = Knit.GetService("HotbarService")
    local StarterGui = game:GetService("StarterGui")

    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = playerGui:WaitForChild("MainUI")
    local hotbarGui = screenGui:WaitForChild("Hotbar")

    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

    self:ConnectHotbarUI(hotbarGui)

    HotbarService:GetHotbar():andThen(function(hotbarData)
        self:DisplayHotbarItems(hotbarGui, hotbarData)
    end):catch(function()
        self:DisplayHotbarItems(hotbarGui, {})
    end)
end

function HotbarController:KnitInit() end

return HotbarController
