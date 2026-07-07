--[[
    医院透视治疗脚本(作者b站:英吉利超入_)
    功能：透视区分人类/伪人（红绿标签）+ 治疗人类
          调试：扫描范围、显示标签、自动治疗
          横版UI，死亡不丢失，复活自动恢复
    作者：英吉利超入
--]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 治疗远程事件（根据实际游戏修改！）
local treatmentEvent = nil
local function getTreatmentEvent()
    -- 示例：假设治疗事件在这里，如果不存在则忽略
    local event = ReplicatedStorage:FindFirstChild("TreatmentEvent")
    if event and event:IsA("RemoteEvent") then
        treatmentEvent = event
        return true
    end
    return false
end

-- 尝试获取治疗事件
getTreatmentEvent()

-- NPC 分类规则（需要根据游戏修改！）
-- 返回 "human" 或 "fake" 或 "unknown"
local function classifyNPC(model)
    -- 示例：根据名称判断
    local name = model.Name:lower()
    if name:find("human") then return "human" end
    if name:find("fake") or name:find("伪人") then return "fake" end

    -- 示例：根据属性或Tag
    -- if model:GetAttribute("IsFake") then return "fake" end

    return "unknown" -- 无法识别的不显示
end

-- 获取所有 NPC（非玩家角色，且有 Humanoid）
local function getAllNPCs()
    local npcs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= player.Character then
            local humanoid = obj:FindFirstChild("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if humanoid and hrp and humanoid.Health > 0 then
                table.insert(npcs, obj)
            end
        end
    end
    return npcs
end

local currentLanguage = "Chinese"

local LANG = {
    Chinese = {
        title = "医院透视治疗脚本(作者b站:英吉利超入_)",
        esp = "透视显示",
        showLabels = "显示名字标签",
        range = "扫描范围",
        autoHeal = "自动治疗人类",
        healRange = "治疗范围",
        notice = "红色：伪人  绿色：人类  蓝色：未知",
        floatText = "b站:英吉利超入_",
        langSelected = "你已选择中文语言",
        espOn = "透视已开启",
        healOn = "治疗已开启",
    },
    English = {
        title = "Hospital ESP & Heal Script (Author: bilibili Yingjili Chaoru_)",
        esp = "ESP",
        showLabels = "Show Name Tags",
        range = "Scan Range",
        autoHeal = "Auto Heal Humans",
        healRange = "Heal Range",
        notice = "Red: Fake   Green: Human   Blue: Unknown",
        floatText = "bilibili: Yingjili Chaoru_",
        langSelected = "You have selected English",
        espOn = "ESP enabled",
        healOn = "Heal enabled",
    }
}

local function showNotification(title, content, duration)
    duration = duration or 2
    print("[医院脚本] " .. title .. (content ~= "" and " - " .. content or ""))
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = content,
        Duration = duration,
    })
end

local function createLanguageSelection()
    local langGui = Instance.new("ScreenGui")
    langGui.Name = "LanguageSelector"
    langGui.Parent = playerGui

    langGui.AncestryChanged:Connect(function()
        if not langGui.Parent then langGui.Parent = playerGui end
    end)

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

    chineseBtn.MouseButton1Click:Connect(function()
        currentLanguage = "Chinese"
        langGui:Destroy()
        createMainGui()
    end)
    englishBtn.MouseButton1Click:Connect(function()
        currentLanguage = "English"
        langGui:Destroy()
        createMainGui()
    end)
end

function createMainGui()
    local lang = LANG[currentLanguage]

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HospitalUI"
    screenGui.Parent = playerGui

    screenGui.AncestryChanged:Connect(function()
        if not screenGui.Parent then screenGui.Parent = playerGui end
    end)
    task.spawn(function()
        while true do
            if not screenGui.Parent then screenGui.Parent = playerGui end
            task.wait(1)
        end
    end)

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

    mainFrame:GetPropertyChangedSignal("Position"):Connect(function()
        if not isMaximized then lastPosition = mainFrame.Position end
    end)
    mainFrame:GetPropertyChangedSignal("Size"):Connect(function()
        if not isMaximized then lastSize = mainFrame.Size end
    end)

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
            SetValue = function(val)
                input.Text = tostring(val)
                label.Text = title .. ": " .. tostring(val)
            end,
            GetValue = function()
                return tonumber(input.Text) or default
            end,
            Frame = frame
        }
    end

    -- 控件
    local espBtn = createToggleButton(lang.esp, contentFrame, 1)
    local showLabelsBtn = createToggleButton(lang.showLabels, contentFrame, 2)
    local rangeCtrl = createSlider(lang.range, 20, 200, 80, contentFrame, 3)

    local healBtn = createToggleButton(lang.autoHeal, contentFrame, 4)
    local healRangeCtrl = createSlider(lang.healRange, 10, 50, 20, contentFrame, 5)

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

    minimizeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        floatFrame.Visible = true
    end)
    maximizeBtn.MouseButton1Click:Connect(function()
        if not isMaximized then
            lastPosition = mainFrame.Position
            lastSize = mainFrame.Size
            mainFrame.Size = UDim2.new(1, 0, 1, 0)
            mainFrame.Position = UDim2.new(0, 0, 0, 0)
            maximizeBtn.Text = "❐"
            isMaximized = true
        else
            mainFrame.Size = lastSize
            mainFrame.Position = lastPosition
            maximizeBtn.Text = "□"
            isMaximized = false
        end
    end)

    showNotification("Language", lang.langSelected, 2)

    -- 透视逻辑
    local espEnabled = false
    local showLabels = false
    local healEnabled = false
    local espTag = "HospitalESP"
    local highlightContainer = Instance.new("Folder")
    highlightContainer.Name = "ESP_Highlights"
    highlightContainer.Parent = Workspace -- 存放 Highlight 对象

    -- 移除所有高亮
    local function clearHighlights()
        for _, child in ipairs(highlightContainer:GetChildren()) do
            child:Destroy()
        end
    end

    -- 为模型添加高亮
    local function addHighlight(model, color)
        local highlight = Instance.new("Highlight")
        highlight.Name = model.Name
        highlight.FillColor = color
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = color
        highlight.OutlineTransparency = 0
        highlight.Adornee = model
        highlight.Parent = highlightContainer
    end

    -- 添加名字标签
    local function addLabel(model, text, color)
        if model:GetAttribute(espTag) then return end
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Label"
        billboard.Size = UDim2.new(0, 200, 0, 30)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
        if not billboard.Adornee then return end
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

    -- 移除标签
    local function removeLabel(model)
        local billboard = model:FindFirstChild("ESP_Label")
        if billboard then billboard:Destroy() end
        model:SetAttribute(espTag, nil)
    end

    -- 刷新透视
    local function updateESP()
        clearHighlights()
        -- 移除所有标签
        for _, npc in ipairs(getAllNPCs()) do
            removeLabel(npc)
        end

        if not espEnabled then return end
        local scanRange = rangeCtrl.GetValue()
        local char = player.Character
        local myPos = char and char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart.Position
        for _, npc in ipairs(getAllNPCs()) do
            local hrp = npc:FindFirstChild("HumanoidRootPart")
            if hrp and (not myPos or (hrp.Position - myPos).Magnitude <= scanRange) then
                local category = classifyNPC(npc)
                local color
                local labelText
                if category == "human" then
                    color = Color3.new(0, 1, 0) -- 绿
                    labelText = "人类"
                elseif category == "fake" then
                    color = Color3.new(1, 0, 0) -- 红
                    labelText = "伪人"
                else
                    color = Color3.new(0, 0.5, 1) -- 蓝
                    labelText = "未知"
                end
                addHighlight(npc, color)
                if showLabels then
                    addLabel(npc, labelText, color)
                end
            end
        end
    end

    -- 治疗逻辑
    local function healHumans()
        if not treatmentEvent then return end
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local myPos = char.HumanoidRootPart.Position
        local healRange = healRangeCtrl.GetValue()
        for _, npc in ipairs(getAllNPCs()) do
            if classifyNPC(npc) == "human" then
                local hrp = npc:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - myPos).Magnitude <= healRange then
                    pcall(function()
                        treatmentEvent:FireServer(npc) -- 假设参数是目标模型，根据游戏调整
                        print("[医院脚本] 治疗: " .. npc.Name)
                    end)
                end
            end
        end
    end

    -- 循环
    local espThread = nil
    local function espLoop()
        while espEnabled or healEnabled do
            if espEnabled then
                updateESP()
            end
            if healEnabled then
                healHumans()
            end
            task.wait(0.5)
        end
    end

    -- 按钮事件
    espBtn.MouseButton1Click:Connect(function()
        espEnabled = not espEnabled
        if espEnabled then
            espBtn.Text = lang.esp .. " (ON)"
            espBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            if not espThread then
                espThread = task.spawn(espLoop)
            end
            showNotification(lang.espOn, "", 2)
        else
            espBtn.Text = lang.esp
            espBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
            clearHighlights()
            -- 移除所有标签
            for _, npc in ipairs(getAllNPCs()) do
                removeLabel(npc)
            end
            if not healEnabled then
                if espThread then task.cancel(espThread) end
                espThread = nil
            end
        end
    end)

    showLabelsBtn.MouseButton1Click:Connect(function()
        showLabels = not showLabels
        if showLabels then
            showLabelsBtn.Text = lang.showLabels .. " (ON)"
            showLabelsBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        else
            showLabelsBtn.Text = lang.showLabels
            showLabelsBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
            for _, npc in ipairs(getAllNPCs()) do
                removeLabel(npc)
            end
        end
        updateESP()
    end)

    healBtn.MouseButton1Click:Connect(function()
        healEnabled = not healEnabled
        if healEnabled then
            if not treatmentEvent then
                showNotification("错误", "未找到治疗事件，请配置脚本", 3)
                healEnabled = false
                return
            end
            healBtn.Text = lang.autoHeal .. " (ON)"
            healBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            if not espThread then
                espThread = task.spawn(espLoop)
            end
            showNotification(lang.healOn, "", 2)
        else
            healBtn.Text = lang.autoHeal
            healBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
            if not espEnabled then
                if espThread then task.cancel(espThread) end
                espThread = nil
            end
        end
    end)

    local function addToggleHover(btn, getActive, activeColor)
        local orig = btn.BackgroundColor3
        btn.MouseEnter:Connect(function()
            if not getActive() then btn.BackgroundColor3 = orig:Lerp(Color3.new(1,1,1), 0.15) end
        end)
        btn.MouseLeave:Connect(function()
            if getActive() and activeColor then btn.BackgroundColor3 = activeColor
            else btn.BackgroundColor3 = orig end
        end)
    end
    addToggleHover(espBtn, function() return espEnabled end, Color3.fromRGB(200,50,50))
    addToggleHover(showLabelsBtn, function() return showLabels end, Color3.fromRGB(200,50,50))
    addToggleHover(healBtn, function() return healEnabled end, Color3.fromRGB(200,50,50))

    RunService.Heartbeat:Connect(function()
        local hue = (tick() * 0.5) % 1
        local color = Color3.fromHSV(hue, 1, 1)
        mainStroke.Color = color
        floatStroke.Color = color
    end)
end

createLanguageSelection()
