-- 动物透视增强脚本（透视 + 移速 + 秒互动）
-- 横版UI，死亡不丢失，复活自动恢复
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 根据属性分类
local function classifyNPC(model)
    local attrs = model:GetAttributes()
    if attrs["Skinwalker"] == true then return "fake" end
    if attrs["IsPatient"] == true then return "real" end
    local name = model.Name:lower()
    if name == "nurse" then return "real" end
    if name == "jumpscaredummy" then return "fake" end
    return "unknown"
end

-- 获取所有 NPC
local function getAllNPCs()
    local npcs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= player.Character then
            local humanoid = obj:FindFirstChild("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if humanoid and hrp then
                table.insert(npcs, obj)
            end
        end
    end
    return npcs
end

local currentLanguage = "Chinese"

local LANG = {
    Chinese = {
        title = "动物医院脚本(作者b站:英吉利超入_)",
        esp = "透视显示",
        showLabels = "显示名字标签",
        range = "扫描范围",
        speed = "移动速度",
        instantInteract = "秒互动",
        notice = "红色：伪动物  绿色：真动物  蓝色：未知",
        floatText = "b站:英吉利超入_",
        langSelected = "你已选择中文语言",
        espOn = "透视已开启",
        instantOn = "秒互动已开启",
    },
    English = {
        title = "Animal ESP Enhanced (Author: bilibili Yingjili Chaoru_)",
        esp = "ESP",
        showLabels = "Show Name Tags",
        range = "Scan Range",
        speed = "Walk Speed",
        instantInteract = "Instant Interact",
        notice = "Red: Fake   Green: Real   Blue: Unknown",
        floatText = "bilibili: Yingjili Chaoru_",
        langSelected = "You have selected English",
        espOn = "ESP enabled",
        instantOn = "Instant Interact enabled",
    }
}

local function showNotification(title, content, duration)
    duration = duration or 2
    print("[动物透视] " .. title .. (content ~= "" and " - " .. content or ""))
    StarterGui:SetCore("SendNotification", { Title = title, Text = content, Duration = duration })
end

-- 语言选择界面
local function createLanguageSelection()
    local langGui = Instance.new("ScreenGui")
    langGui.Name = "LanguageSelector"
    langGui.Parent = playerGui
    langGui.AncestryChanged:Connect(function() if not langGui.Parent then langGui.Parent = playerGui end end)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 240, 0, 120)
    frame.Position = UDim2.new(0.5, -120, 0.5, -60)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = langGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Color3.fromRGB(255, 100, 100)
    stroke.Parent = frame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 18
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.Text = "Select Language / 选择语言"
    titleLabel.Parent = frame

    local chineseBtn = Instance.new("TextButton")
    chineseBtn.Size = UDim2.new(0, 100, 0, 40)
    chineseBtn.Position = UDim2.new(0.5, -110, 0, 45)
    chineseBtn.Text = "中文"
    chineseBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
    chineseBtn.TextColor3 = Color3.new(1, 1, 1)
    chineseBtn.Font = Enum.Font.SourceSansBold
    chineseBtn.TextSize = 18
    chineseBtn.Parent = frame
    Instance.new("UICorner", chineseBtn).CornerRadius = UDim.new(0, 8)

    local englishBtn = Instance.new("TextButton")
    englishBtn.Size = UDim2.new(0, 100, 0, 40)
    englishBtn.Position = UDim2.new(0.5, 10, 0, 45)
    englishBtn.Text = "English"
    englishBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
    englishBtn.TextColor3 = Color3.new(1, 1, 1)
    englishBtn.Font = Enum.Font.SourceSansBold
    englishBtn.TextSize = 18
    englishBtn.Parent = frame
    Instance.new("UICorner", englishBtn).CornerRadius = UDim.new(0, 8)

    local function addHover(btn)
        local orig = btn.BackgroundColor3
        btn.MouseEnter:Connect(function() btn.BackgroundColor3 = orig:Lerp(Color3.new(1,1,1), 0.2) end)
        btn.MouseLeave:Connect(function() btn.BackgroundColor3 = orig end)
    end
    addHover(chineseBtn)
    addHover(englishBtn)

    chineseBtn.MouseButton1Click:Connect(function() currentLanguage = "Chinese"; langGui:Destroy(); createMainGui() end)
    englishBtn.MouseButton1Click:Connect(function() currentLanguage = "English"; langGui:Destroy(); createMainGui() end)
end

function createMainGui()
    local lang = LANG[currentLanguage]
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AnimalESPUI"
    screenGui.Parent = playerGui
    screenGui.AncestryChanged:Connect(function() if not screenGui.Parent then screenGui.Parent = playerGui end end)
    task.spawn(function() while true do if not screenGui.Parent then screenGui.Parent = playerGui end; task.wait(1) end end)

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 500, 0, 360)
    mainFrame.Position = UDim2.new(0.5, -250, 0.4, -180)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = mainFrame

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Thickness = 2
    mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainStroke.Color = Color3.fromRGB(255, 100, 100)
    mainStroke.Parent = mainFrame

    local lastPosition = mainFrame.Position
    local lastSize = mainFrame.Size
    local isMaximized = false
    mainFrame:GetPropertyChangedSignal("Position"):Connect(function() if not isMaximized then lastPosition = mainFrame.Position end end)
    mainFrame:GetPropertyChangedSignal("Size"):Connect(function() if not isMaximized then lastSize = mainFrame.Size end end)

    -- 标题栏
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 32)
    titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -70, 1, 0)
    titleLabel.Position = UDim2.new(0, 12, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = lang.title
    titleLabel.TextScaled = true
    titleLabel.Parent = titleBar

    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 26, 0, 26)
    minimizeBtn.Position = UDim2.new(1, -56, 0, 3)
    minimizeBtn.Text = "─"
    minimizeBtn.Font = Enum.Font.SourceSansBold
    minimizeBtn.TextSize = 16
    minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Parent = titleBar
    Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 5)

    local maximizeBtn = Instance.new("TextButton")
    maximizeBtn.Size = UDim2.new(0, 26, 0, 26)
    maximizeBtn.Position = UDim2.new(1, -28, 0, 3)
    maximizeBtn.Text = "□"
    maximizeBtn.Font = Enum.Font.SourceSansBold
    maximizeBtn.TextSize = 16
    maximizeBtn.TextColor3 = Color3.new(1, 1, 1)
    maximizeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    maximizeBtn.BorderSizePixel = 0
    maximizeBtn.Parent = titleBar
    Instance.new("UICorner", maximizeBtn).CornerRadius = UDim.new(0, 5)

    local function addHover(btn)
        local orig = btn.BackgroundColor3
        btn.MouseEnter:Connect(function() btn.BackgroundColor3 = orig:Lerp(Color3.new(1,1,1), 0.2) end)
        btn.MouseLeave:Connect(function() btn.BackgroundColor3 = orig end)
    end
    addHover(minimizeBtn)
    addHover(maximizeBtn)

    -- 内容区域
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Size = UDim2.new(1, -24, 1, -44)
    contentFrame.Position = UDim2.new(0, 12, 0, 38)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ScrollBarThickness = 4
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 500)
    contentFrame.Parent = mainFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 6)
    listLayout.Parent = contentFrame

    -- 控件创建函数
    local function createToggleButton(text, parent, order)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 38)
        btn.Text = text
        btn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 14
        btn.LayoutOrder = order
        btn.Parent = parent
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        return btn
    end

    local function createSlider(title, min, max, default, parent, order)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 42)
        frame.BackgroundTransparency = 1
        frame.LayoutOrder = order
        frame.Parent = parent

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 18)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.SourceSans
        label.TextSize = 12
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = title .. ": " .. tostring(default)
        label.Parent = frame

        local input = Instance.new("TextBox")
        input.Size = UDim2.new(1, 0, 0, 20)
        input.Position = UDim2.new(0, 0, 0, 20)
        input.Text = tostring(default)
        input.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        input.TextColor3 = Color3.new(1,1,1)
        input.Font = Enum.Font.SourceSans
        input.TextSize = 12
        input.Parent = frame

        return {
            SetValue = function(val) input.Text = tostring(val); label.Text = title .. ": " .. tostring(val) end,
            GetValue = function() return tonumber(input.Text) or default end,
            Frame = frame
        }
    end

    -- 创建控件
    local espBtn = createToggleButton(lang.esp, contentFrame, 1)
    local showLabelsBtn = createToggleButton(lang.showLabels, contentFrame, 2)
    local rangeCtrl = createSlider(lang.range, 20, 200, 80, contentFrame, 3)
    local speedCtrl = createSlider(lang.speed, 16, 100, 16, contentFrame, 4)
    local instantBtn = createToggleButton(lang.instantInteract, contentFrame, 5)

    local noticeLabel = Instance.new("TextLabel")
    noticeLabel.Size = UDim2.new(1, 0, 0, 24)
    noticeLabel.LayoutOrder = 6
    noticeLabel.BackgroundTransparency = 1
    noticeLabel.Font = Enum.Font.SourceSans
    noticeLabel.TextSize = 11
    noticeLabel.TextColor3 = Color3.fromRGB(180,180,180)
    noticeLabel.TextXAlignment = Enum.TextXAlignment.Center
    noticeLabel.Text = lang.notice
    noticeLabel.Parent = contentFrame
    -- 悬浮窗
    local floatFrame = Instance.new("Frame")
    floatFrame.Size = UDim2.new(0, 260, 0, 40)
    floatFrame.Position = UDim2.new(0.5, -130, 0, 10)
    floatFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    floatFrame.BackgroundTransparency = 0.1
    floatFrame.BorderSizePixel = 0
    floatFrame.Visible = false
    floatFrame.Active = true
    floatFrame.Draggable = true
    floatFrame.Parent = screenGui

    local floatCorner = Instance.new("UICorner")
    floatCorner.CornerRadius = UDim.new(0, 20)
    floatCorner.Parent = floatFrame

    local floatStroke = Instance.new("UIStroke")
    floatStroke.Thickness = 1.5
    floatStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    floatStroke.Color = Color3.fromRGB(255, 100, 100)
    floatStroke.Parent = floatFrame

    local floatLabel = Instance.new("TextLabel")
    floatLabel.Size = UDim2.new(1, -20, 1, 0)
    floatLabel.Position = UDim2.new(0, 10, 0, 0)
    floatLabel.BackgroundTransparency = 1
    floatLabel.Font = Enum.Font.SourceSansBold
    floatLabel.TextSize = 16
    floatLabel.TextColor3 = Color3.new(1, 1, 1)
    floatLabel.Text = lang.floatText
    floatLabel.TextXAlignment = Enum.TextXAlignment.Center
    floatLabel.Parent = floatFrame

    local touchStartPos = nil
    floatFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            touchStartPos = input.Position
        end
    end)
    floatFrame.InputEnded:Connect(function(input)
        if touchStartPos and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            if (input.Position - touchStartPos).Magnitude < 5 then
                mainFrame.Visible = true
                floatFrame.Visible = false
            end
            touchStartPos = nil
        end
    end)

    minimizeBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false; floatFrame.Visible = true end)
    maximizeBtn.MouseButton1Click:Connect(function()
        if not isMaximized then
            lastPosition = mainFrame.Position; lastSize = mainFrame.Size
            mainFrame.Size = UDim2.new(1, 0, 1, 0); mainFrame.Position = UDim2.new(0, 0, 0, 0)
            maximizeBtn.Text = "❐"; isMaximized = true
        else
            mainFrame.Size = lastSize; mainFrame.Position = lastPosition
            maximizeBtn.Text = "□"; isMaximized = false
        end
    end)

    showNotification("Language", lang.langSelected, 2)

    -- 透视逻辑
    local espEnabled = false
    local showLabels = false
    local espTag = "AnimalESP"

    local function removeAllLabels()
        for _, npc in ipairs(getAllNPCs()) do
            local billboard = npc:FindFirstChild("ESP_Label")
            if billboard then billboard:Destroy() end
            npc:SetAttribute(espTag, nil)
        end
    end

    local function addLabel(model, text, color)
        if model:GetAttribute(espTag) then return end
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Label"
        billboard.Size = UDim2.new(0, 200, 0, 30)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        local adornee = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
        if not adornee then return end
        billboard.Adornee = adornee
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 14
        label.TextColor3 = color
        label.TextStrokeTransparency = 0.5
        label.Text = text
        label.Parent = billboard
        billboard.Parent = model
        model:SetAttribute(espTag, true)
    end

    local function updateESP()
        removeAllLabels()
        if not espEnabled then return end
        local scanRange = rangeCtrl.GetValue()
        local char = player.Character
        local myPos = char and char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart.Position
        for _, npc in ipairs(getAllNPCs()) do
            local hrp = npc:FindFirstChild("HumanoidRootPart")
            if hrp and (not myPos or (hrp.Position - myPos).Magnitude <= scanRange) then
                local category = classifyNPC(npc)
                local color, labelText
                if category == "real" then
                    color = Color3.new(0, 1, 0); labelText = "真动物"
                elseif category == "fake" then
                    color = Color3.new(1, 0, 0); labelText = "伪动物"
                else
                    color = Color3.new(0, 0.5, 1); labelText = "未知"
                end
                if showLabels then addLabel(npc, labelText, color) end
            end
        end
    end

    local espThread = nil
    local function espLoop() while espEnabled or showLabels do updateESP(); task.wait(0.5) end end

    espBtn.MouseButton1Click:Connect(function()
        espEnabled = not espEnabled
        if espEnabled then
            espBtn.Text = lang.esp .. " (ON)"; espBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            if not espThread then espThread = task.spawn(espLoop) end
            showNotification(lang.espOn, "", 2)
        else
            espBtn.Text = lang.esp; espBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
            removeAllLabels()
            if not showLabels then if espThread then task.cancel(espThread) end; espThread = nil end
        end
    end)

    showLabelsBtn.MouseButton1Click:Connect(function()
        showLabels = not showLabels
        if showLabels then
            showLabelsBtn.Text = lang.showLabels .. " (ON)"; showLabelsBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            if not espThread then espThread = task.spawn(espLoop) end
        else
            showLabelsBtn.Text = lang.showLabels; showLabelsBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
            removeAllLabels()
            if not espEnabled then if espThread then task.cancel(espThread) end; espThread = nil end
        end
        updateESP()
    end)

    -- 移速功能
    local function applyWalkSpeed(speed)
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then humanoid.WalkSpeed = speed end
        end
    end

    local speedInput = speedCtrl.Frame:FindFirstChild("TextBox")
    if speedInput then
        speedInput:GetPropertyChangedSignal("Text"):Connect(function()
            local speed = tonumber(speedInput.Text)
            if speed then
                speed = math.clamp(speed, 16, 100)
                applyWalkSpeed(speed)
            end
        end)
    end

    player.CharacterAdded:Connect(function(char) applyWalkSpeed(speedCtrl.GetValue()) end)
    if player.Character then applyWalkSpeed(speedCtrl.GetValue()) end

    -- 秒互动功能
    local instantEnabled = false
    local originalDurations = {}
    local descendantAddedConn = nil

    local function modifyPrompt(prompt, enable)
        if enable then
            if not originalDurations[prompt] then originalDurations[prompt] = prompt.HoldDuration end
            prompt.HoldDuration = 0
        else
            local original = originalDurations[prompt]
            if original and prompt.Parent then prompt.HoldDuration = original end
        end
    end

    local function processAllPrompts(enable)
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then modifyPrompt(obj, enable) end
        end
    end

    local function onDescendantAdded(descendant)
        if descendant:IsA("ProximityPrompt") then modifyPrompt(descendant, true) end
    end

    instantBtn.MouseButton1Click:Connect(function()
        instantEnabled = not instantEnabled
        if instantEnabled then
            instantBtn.Text = lang.instantInteract .. " (ON)"; instantBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            processAllPrompts(true)
            descendantAddedConn = Workspace.DescendantAdded:Connect(onDescendantAdded)
            showNotification(lang.instantOn, "", 2)
        else
            instantBtn.Text = lang.instantInteract; instantBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
            if descendantAddedConn then descendantAddedConn:Disconnect(); descendantAddedConn = nil end
            for prompt, original in pairs(originalDurations) do
                if prompt.Parent then prompt.HoldDuration = original end
            end
            originalDurations = {}
        end
    end)

    -- 悬停效果
    local function addToggleHover(btn, getActive, activeColor)
        local orig = btn.BackgroundColor3
        btn.MouseEnter:Connect(function() if not getActive() then btn.BackgroundColor3 = orig:Lerp(Color3.new(1,1,1), 0.15) end end)
        btn.MouseLeave:Connect(function() if getActive() and activeColor then btn.BackgroundColor3 = activeColor else btn.BackgroundColor3 = orig end end)
    end
    addToggleHover(espBtn, function() return espEnabled end, Color3.fromRGB(200,50,50))
    addToggleHover(showLabelsBtn, function() return showLabels end, Color3.fromRGB(200,50,50))
    addToggleHover(instantBtn, function() return instantEnabled end, Color3.fromRGB(200,50,50))

    RunService.Heartbeat:Connect(function()
        local hue = (tick() * 0.5) % 1
        local color = Color3.fromHSV(hue, 1, 1)
        mainStroke.Color = color
        floatStroke.Color = color
    end)
end

createLanguageSelection()
