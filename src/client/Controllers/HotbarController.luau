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

function HotbarController:CreateDragPreview(originalFrame)
    local preview = originalFrame:Clone()
    preview.Name = "DragPreview"
    preview.Parent = originalFrame.Parent.Parent
    preview.BackgroundTransparency = 0.5
    preview.ZIndex = 1000
    preview.Size = originalFrame.Size
    preview.Position = originalFrame.Position
    preview.Active = false
    
    for _, child in preview:GetDescendants() do
        if child:IsA("GuiObject") then
            child.ZIndex = 1000
            child.Active = false
        end
    end
    
    return preview
end

function HotbarController:StartDrag(item, slotIndex, hotbarData)
    if self._isDragging then 
        return 
    end
    
    if not hotbarData or not hotbarData[slotIndex] or hotbarData[slotIndex] == "" then
        return
    end
    
    self._isDragging = true
    self._dragStartSlot = slotIndex
    self._dragPreview = self:CreateDragPreview(item)
    self._dragHandledByGlobal = false
    
    local function updateDragPosition()
        if self._dragPreview then
            local mouse = Players.LocalPlayer:GetMouse()
            self._dragPreview.Position = UDim2.new(0, mouse.X - self._dragPreview.AbsoluteSize.X/2, 0, mouse.Y - self._dragPreview.AbsoluteSize.Y/2)
            
            local guiObjects = Players.LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(mouse.X, mouse.Y)
            for _, obj in ipairs(guiObjects) do
                local isDragPreviewChild = false
                local checkObj = obj
                while checkObj do
                    if checkObj.Name == "DragPreview" then
                        isDragPreviewChild = true
                        break
                    end
                    checkObj = checkObj.Parent
                end
                
                if isDragPreviewChild then
                    continue
                end
                
                local currentObj = obj
                while currentObj do
                    if currentObj.Name:match("SLOT_") then
                        local slotNum = tonumber(currentObj.Name:match("SLOT_(%d+)"))
                        break
                    end
                    currentObj = currentObj.Parent
                end
                break
            end
        end
    end
    
    self._dragUpdateConnection = game:GetService("RunService").Heartbeat:Connect(updateDragPosition)
end

function HotbarController:HandleDragRelease()
    if not self._isDragging then return end
    
    if self._dragHandledByGlobal then return end
    self._dragHandledByGlobal = true
    
    local mouse = Players.LocalPlayer:GetMouse()
    local targetSlot = nil
    
    local guiObjects = Players.LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(mouse.X, mouse.Y)
    
    for i, obj in ipairs(guiObjects) do
        local isDragPreviewChild = false
        local checkObj = obj
        while checkObj do
            if checkObj.Name == "DragPreview" then
                isDragPreviewChild = true
                break
            end
            checkObj = checkObj.Parent
        end
        
        if isDragPreviewChild then
            continue
        end
        
        local currentObj = obj
        while currentObj do
            if currentObj.Name:match("SLOT_") then
                targetSlot = tonumber(currentObj.Name:match("SLOT_(%d+)"))
                break
            end
            currentObj = currentObj.Parent
        end
        
        if targetSlot then
            break
        end
    end
    
    if targetSlot and targetSlot ~= self._dragStartSlot then
        self:EndDrag(targetSlot)
    else
        self:CancelDrag()
    end
end

function HotbarController:CancelDrag()
    if not self._isDragging then return end
    
    if self._dragUpdateConnection then
        self._dragUpdateConnection:Disconnect()
        self._dragUpdateConnection = nil
    end
    
    if self._dragPreview then
        self._dragPreview:Destroy()
        self._dragPreview = nil
    end
    
    self._isDragging = false
    self._dragStartSlot = nil
    self._dragHandledByGlobal = false
end

function HotbarController:EndDrag(targetSlot)
    if not self._isDragging then return end
    
    local HotbarService = Knit.GetService("HotbarService")
    
    if self._dragUpdateConnection then
        self._dragUpdateConnection:Disconnect()
        self._dragUpdateConnection = nil
    end
    
    if self._dragPreview then
        self._dragPreview:Destroy()
        self._dragPreview = nil
    end
    
    if targetSlot and targetSlot ~= self._dragStartSlot then
        print("Attempting to swap slots:", self._dragStartSlot, "->", targetSlot)
        HotbarService:SwapHotbarSlots(self._dragStartSlot, targetSlot):andThen(function(result)
            print("Swap result:", result)
            if not result.success then
                warn("Failed to swap hotbar slots")
            end
        end):catch(function(err)
            warn("Error swapping hotbar slots:", err)
        end)
    end
    
    self._isDragging = false
    self._dragStartSlot = nil
    self._dragHandledByGlobal = false
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
                if not self._isDragging then
                    self:TweenToScale(item, HOVER_SCALE, TWEEN_HOVER_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                end
            end)

            item.MouseLeave:Connect(function()
                self._hoverState[item] = false
                task.wait(0.1)
                if not self._hoverState[item] and not self._isDragging then
                    self:TweenToScale(item, DEFAULT_SCALE, TWEEN_HOVER_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                end
            end)

            local keyCode = GetKeyCodeForSlot(slotIndex)
            if keyCode then
                UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if not gameProcessed and input.KeyCode == keyCode and not self._isDragging then
                        HotbarService:EquipTool(slotIndex)
                        self:PlayClickAnimation(item)
                    end
                end)
            end

            local button = item:FindFirstChild(item.Name)
            if button and (button:IsA("TextButton") or button:IsA("ImageButton")) then
                local dragStartTime = 0
                local isDragThreshold = false
                local dragCheckConnection = nil
                
                button.MouseButton1Down:Connect(function()
                    dragStartTime = tick()
                    isDragThreshold = false
                    
                    if dragCheckConnection then
                        task.cancel(dragCheckConnection)
                        dragCheckConnection = nil
                    end
                    
                    dragCheckConnection = task.spawn(function()
                        task.wait(0.5)
                        if tick() - dragStartTime >= 0.5 then
                            isDragThreshold = true
                            self:StartDrag(item, slotIndex, self._currentHotbarData)
                        end
                    end)
                end)
                
                button.MouseButton1Up:Connect(function()
                    if dragCheckConnection then
                        task.cancel(dragCheckConnection)
                        dragCheckConnection = nil
                    end
                    
                    local timeSinceDown = tick() - dragStartTime
                    
                    if self._isDragging and not self._dragHandledByGlobal then
                        self:HandleDragRelease()
                    elseif timeSinceDown < 0.5 and not self._isDragging then
                        HotbarService:EquipTool(slotIndex)
                        self:PlayClickAnimation(item)
                    end
                    
                    isDragThreshold = false
                    dragStartTime = 0
                end)
            end
        end
    end
end

function HotbarController:DisplayHotbarItems(hotbarGui, hotbarData)
    if type(hotbarData) ~= "table" then
        hotbarData = {}
    end

    self._currentHotbarData = hotbarData
    
    for slotIndex = 1, 10 do
        local slot = hotbarGui:FindFirstChild("SLOT_" .. slotIndex)
        if slot and slot:IsA("Frame") then
            local label = slot:FindFirstChild("Name")
            if label and label:IsA("TextLabel") then
                local itemName = hotbarData[slotIndex]
                if itemName and itemName ~= "" then
                    label.Text = itemName
                else
                    label.Text = ""
                end
            end
        end
    end
end

function HotbarController:KnitStart()
    self._tweenMap = {}
    self._hoverState = {}
    self._isDragging = false
    self._dragStartSlot = nil
    self._dragPreview = nil
    self._dragUpdateConnection = nil
    self._dragHandledByGlobal = false
    self._currentHotbarData = {}
    self._hotbarConnection = nil

    local HotbarService = Knit.GetService("HotbarService")
    local DataController = Knit.GetController("DataController")
    local StarterGui = game:GetService("StarterGui")

    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = playerGui:WaitForChild("MainUI")
    local hotbarGui = screenGui:WaitForChild("Hotbar")
    
    self._hotbarGui = hotbarGui

    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and self._isDragging then
            self:HandleDragRelease()
        end
    end)

    self:ConnectHotbarUI(hotbarGui)

    local function onHotbarDataReplicated()
        print("HotbarController: onReplicated callback triggered")
        local data = DataController.getData()
        print("Hotbar data replicated:", data and data.hotbar)
        if data and data.hotbar then
            print("Updating UI with hotbar data")
            self:DisplayHotbarItems(hotbarGui, data.hotbar)
        else
            print("No hotbar data found or data is nil")
        end
    end

    self._hotbarConnection = DataController.onReplicated("hotbar"):Connect(onHotbarDataReplicated)

    task.spawn(function()
        local data = DataController.waitForData()
        print("Initial hotbar data loaded:", data and data.hotbar)
        if data and data.hotbar then
            self:DisplayHotbarItems(hotbarGui, data.hotbar)
        end
    end)
end

function HotbarController:KnitInit() end

return HotbarController