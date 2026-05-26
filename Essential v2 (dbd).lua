-- Essential GUI - Стабильная версия с ограничением дистанции обводки
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local CoreGui
pcall(function() CoreGui = game:GetService("CoreGui") end)

local LocalPlayer = Players.LocalPlayer
local connections = {}

-- Настройки по умолчанию
local ManiacESPEnabled = false
local ManiacR, ManiacG, ManiacB = 239, 68, 68

local SurvivorESPEnabled = false
local SurvivorR, SurvivorG, SurvivorB = 34, 197, 94

local GeneratorESPEnabled = false
local GeneratorR, GeneratorG, GeneratorB = 255, 255, 0

local PalletESPEnabled = false
local PalletR, PalletG, PalletB = 255, 128, 0

local FOVEnabled = false
local currentFOV = 70
local SpeedhackEnabled = false
local SpeedhackValue = 32

local FlashlightEnabled = false
local FlashR, FlashG, FlashB = 255, 255, 255
local FlashRange = 60
local currentLight = nil

local trackedGenerators = {}
local trackedPallets = {}

-- ОГРАНИЧЕНИЕ ДИСТАНЦИИ ОБВОДКИ (Защита от вылетов)
local MAX_ESP_DISTANCE = 100 

-- Цветовая палитра интерфейса
local AccentColor = Color3.fromRGB(151, 71, 255) 
local BgMain = Color3.fromRGB(14, 14, 15)
local BgHeader = Color3.fromRGB(20, 20, 21)
local BgSidebar = Color3.fromRGB(17, 17, 18)
local BgElement = Color3.fromRGB(24, 24, 26)
local BgDark = Color3.fromRGB(10, 10, 11)
local TextColor = Color3.fromRGB(235, 235, 240)
local TextMuted = Color3.fromRGB(140, 140, 145)

-- Инициализация ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EssentialUI"
ScreenGui.ResetOnSpawn = false
if CoreGui then
    pcall(function() ScreenGui.Parent = CoreGui end)
end
if not ScreenGui.Parent then 
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") 
end

-- Главное окно
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 520, 0, 370)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = BgMain
MainFrame.BorderSizePixel = 0
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(35, 35, 38)
MainStroke.Thickness = 1.2

local MenuScale = Instance.new("UIScale", MainFrame)
MenuScale.Scale = 1

-- Шапка (Header)
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 42)
Header.BackgroundColor3 = BgHeader
Header.BorderSizePixel = 0
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)

local HeaderBottom = Instance.new("Frame", Header)
HeaderBottom.Size = UDim2.new(1, 0, 0, 10)
HeaderBottom.Position = UDim2.new(0, 0, 1, -10)
HeaderBottom.BackgroundColor3 = BgHeader
HeaderBottom.BorderSizePixel = 0

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -30, 1, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Essential"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Логика перетаскивания (Drag)
local dragging, dragInput, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
table.insert(connections, UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end))
table.insert(connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end))

-- Открытие/Закрытие на RightShift
local isMenuOpen = true
local tweenScale
local tweenStyleIn = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local tweenStyleOut = TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        isMenuOpen = not isMenuOpen
        if tweenScale then tweenScale:Cancel() end
        
        if isMenuOpen then
            MainFrame.Visible = true
            MenuScale.Scale = 0.85
            tweenScale = TweenService:Create(MenuScale, tweenStyleIn, {Scale = 1})
            tweenScale:Play()
        else
            tweenScale = TweenService:Create(MenuScale, tweenStyleOut, {Scale = 0.85})
            tweenScale:Play()
            task.delay(0.25, function()
                if not isMenuOpen then MainFrame.Visible = false end
            end)
        end
    end
end))

-- Основная рабочая область
local Body = Instance.new("Frame", MainFrame)
Body.Size = UDim2.new(1, 0, 1, -42)
Body.Position = UDim2.new(0, 0, 0, 42)
Body.BackgroundTransparency = 1

local Sidebar = Instance.new("Frame", Body)
Sidebar.Size = UDim2.new(0, 140, 1, 0)
Sidebar.BackgroundColor3 = BgSidebar
Sidebar.BorderSizePixel = 0
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

local TabContainer = Instance.new("Frame", Sidebar)
TabContainer.Size = UDim2.new(1, 0, 1, 0)
TabContainer.BackgroundTransparency = 1
local TabListLayout = Instance.new("UIListLayout", TabContainer)
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 5)
local TabPadding = Instance.new("UIPadding", TabContainer)
TabPadding.PaddingTop = UDim.new(0, 12)
TabPadding.PaddingLeft = UDim.new(0, 10)
TabPadding.PaddingRight = UDim.new(0, 10)

local ContentArea = Instance.new("Frame", Body)
ContentArea.Size = UDim2.new(1, -140, 1, 0)
ContentArea.Position = UDim2.new(0, 140, 0, 0)
ContentArea.BackgroundTransparency = 1
local ContentPadding = Instance.new("UIPadding", ContentArea)
ContentPadding.PaddingTop = UDim.new(0, 12)
ContentPadding.PaddingLeft = UDim.new(0, 12)
ContentPadding.PaddingRight = UDim.new(0, 12)
ContentPadding.PaddingBottom = UDim.new(0, 12)

-- Функции библиотеки UI
local tabs = {}
local function CreateTab(name)
    local btn = Instance.new("TextButton", TabContainer)
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = AccentColor
    btn.BackgroundTransparency = 1
    btn.Text = name
    btn.TextColor3 = TextMuted
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamSemibold
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local page = Instance.new("ScrollingFrame", ContentArea)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 65)
    page.BorderSizePixel = 0
    page.Visible = false
    
    local layout = Instance.new("UIListLayout", page)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 5)
    end)

    table.insert(tabs, {btn = btn, page = page})
    
    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do
            t.page.Visible = false
            TweenService:Create(t.btn, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1, TextColor3 = TextMuted}):Play()
        end
        page.Visible = true
        TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.88, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    end)
    return page, btn
end

local function CreateToggle(parent, text, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 42)
    frame.BackgroundColor3 = BgElement
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(40, 40, 42)
    stroke.Thickness = 1
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = TextColor
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 36, 0, 18)
    btn.Position = UDim2.new(1, -48, 0.5, -9)
    btn.BackgroundColor3 = default and AccentColor or Color3.fromRGB(45, 45, 48)
    btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    
    local circle = Instance.new("Frame", btn)
    circle.Size = UDim2.new(0, 12, 0, 12)
    circle.Position = UDim2.new(0, default and 21 or 3, 0.5, -6)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    
    local state = default
    local function setState(newState)
        state = newState
        local circlePos = state and UDim2.new(0, 21, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
        local bgColor = state and AccentColor or Color3.fromRGB(45, 45, 48)
        
        TweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = circlePos}):Play()
        TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = bgColor}):Play()
        
        callback(state)
    end
    btn.MouseButton1Click:Connect(function() setState(not state) end)
    return setState
end

local function CreateSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 54)
    frame.BackgroundColor3 = BgElement
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", frame).Color = Color3.fromRGB(40, 40, 42)
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -20, 0, 24)
    label.Position = UDim2.new(0, 12, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = TextColor
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local valLabel = Instance.new("TextLabel", frame)
    valLabel.Size = UDim2.new(0, 38, 0, 18)
    valLabel.Position = UDim2.new(1, -50, 0, 8)
    valLabel.BackgroundColor3 = BgDark
    valLabel.Text = tostring(default)
    valLabel.TextColor3 = Color3.fromRGB(200, 200, 205)
    valLabel.TextSize = 11
    valLabel.Font = Enum.Font.Gotham
    Instance.new("UICorner", valLabel).CornerRadius = UDim.new(0, 4)
    
    local bar = Instance.new("Frame", frame)
    bar.Size = UDim2.new(1, -24, 0, 5)
    bar.Position = UDim2.new(0, 12, 0, 38)
    bar.BackgroundColor3 = BgDark
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
    
    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
    fill.BackgroundColor3 = AccentColor
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    
    local btn = Instance.new("TextButton", bar)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    
    local dragging = false
    btn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
    table.insert(connections, UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end))
    
    local function setVal(val)
        valLabel.Text = tostring(val)
        fill.Size = UDim2.new((val - min)/(max - min), 0, 1, 0)
        callback(val)
    end
    
    table.insert(connections, RunService.RenderStepped:Connect(function()
        if dragging then
            local mouseX = UserInputService:GetMouseLocation().X
            local barX = bar.AbsolutePosition.X
            local barSize = bar.AbsoluteSize.X
            local percent = math.clamp((mouseX - barX) / barSize, 0, 1)
            local val = math.floor(min + (max - min) * percent)
            setVal(val)
        end
    end))
    return setVal
end

local function CreateButton(parent, text, bgCol, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = bgCol or BgElement
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamSemibold
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", btn).Color = Color3.fromRGB(40, 40, 42)
    
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function CreateInput(parent, placeholder, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 42)
    frame.BackgroundColor3 = BgElement
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", frame).Color = Color3.fromRGB(40, 40, 42)
    
    local box = Instance.new("TextBox", frame)
    box.Size = UDim2.new(1, -24, 1, 0)
    box.Position = UDim2.new(0, 12, 0, 0)
    box.BackgroundTransparency = 1
    box.Text = ""
    box.PlaceholderText = placeholder
    box.TextColor3 = TextColor
    box.PlaceholderColor3 = TextMuted
    box.TextSize = 13
    box.Font = Enum.Font.Gotham
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    
    box.FocusLost:Connect(function() callback(box.Text) end)
    
    return function(txt)
        box.Text = txt
        callback(txt)
    end
end

local function CreateLabel(parent, defaultText)
    local label = Instance.new("TextLabel", parent)
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = defaultText
    label.TextColor3 = TextMuted
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Center
    return function(txt) label.Text = txt end
end

local function CreateDropdownSection(parent, titleText)
    local mainFrame = Instance.new("Frame", parent)
    mainFrame.Size = UDim2.new(1, 0, 0, 42)
    mainFrame.BackgroundColor3 = BgElement
    mainFrame.ClipsDescendants = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 6)
    mainFrame.BorderSizePixel = 0
    Instance.new("UIStroke", mainFrame).Color = Color3.fromRGB(40, 40, 42)
    
    local triggerBtn = Instance.new("TextButton", mainFrame)
    triggerBtn.Size = UDim2.new(1, 0, 0, 42)
    triggerBtn.BackgroundTransparency = 1
    triggerBtn.Text = ""
    
    local label = Instance.new("TextLabel", mainFrame)
    label.Size = UDim2.new(1, -60, 0, 42)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = titleText
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 13
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local arrow = Instance.new("TextLabel", mainFrame)
    arrow.Size = UDim2.new(0, 40, 0, 42)
    arrow.Position = UDim2.new(1, -45, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = TextColor
    arrow.TextSize = 18
    arrow.Font = Enum.Font.GothamBold
    
    local container = Instance.new("Frame", mainFrame)
    container.Position = UDim2.new(0, 10, 0, 46)
    container.Size = UDim2.new(1, -20, 0, 0)
    container.BackgroundTransparency = 1
    
    local list = Instance.new("UIListLayout", container)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 6)
    
    local isOpen = false
    triggerBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        local targetHeight = isOpen and (list.AbsoluteContentSize.Y + 56) or 42
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()
        arrow.Text = isOpen and "▲" or "▼"
        arrow.TextColor3 = isOpen and AccentColor or TextColor
    end)
    
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if isOpen then
            mainFrame.Size = UDim2.new(1, 0, 0, list.AbsoluteContentSize.Y + 56)
        end
        container.Size = UDim2.new(1, -20, 0, list.AbsoluteContentSize.Y)
    end)
    
    return container
end

-- Создание вкладок
local MainPage, MainBtn = CreateTab("Main")
local VisualPage, VisualBtn = CreateTab("Visual")
local MiscPage, MiscBtn = CreateTab("Misc")
local ConfigPage, ConfigBtn = CreateTab("Config")

MainBtn.BackgroundTransparency = 0.88
MainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MainPage.Visible = true

-- ==================================
-- НАСТРОЙКИ НА ВКЛАДКАХ
-- ==================================
local maniacDropdown = CreateDropdownSection(MainPage, "Maniac ESP")
local toggleManiac = CreateToggle(maniacDropdown, "Enable Maniac ESP", false, function(state) ManiacESPEnabled = state end)
local sliderMR = CreateSlider(maniacDropdown, "Color: Red (R)", 0, 255, 239, function(val) ManiacR = val end)
local sliderMG = CreateSlider(maniacDropdown, "Color: Green (G)", 0, 255, 68, function(val) ManiacG = val end)
local sliderMB = CreateSlider(maniacDropdown, "Color: Blue (B)", 0, 255, 68, function(val) ManiacB = val end)

local survivorDropdown = CreateDropdownSection(MainPage, "Survivor ESP")
local toggleSurvivor = CreateToggle(survivorDropdown, "Enable Survivor ESP", false, function(state) SurvivorESPEnabled = state end)
local sliderSR = CreateSlider(survivorDropdown, "Color: Red (R)", 0, 255, 34, function(val) SurvivorR = val end)
local sliderSG = CreateSlider(survivorDropdown, "Color: Green (G)", 0, 255, 197, function(val) SurvivorG = val end)
local sliderSB = CreateSlider(survivorDropdown, "Color: Blue (B)", 0, 255, 94, function(val) SurvivorB = val end)

local generatorDropdown = CreateDropdownSection(MainPage, "Generator ESP")
local toggleGenerator = CreateToggle(generatorDropdown, "Enable Generator ESP", false, function(state) GeneratorESPEnabled = state end)
local sliderGR = CreateSlider(generatorDropdown, "Color: Red (R)", 0, 255, 255, function(val) GeneratorR = val end)
local sliderGG = CreateSlider(generatorDropdown, "Color: Green (G)", 0, 255, 255, function(val) GeneratorG = val end)
local sliderGB = CreateSlider(generatorDropdown, "Color: Blue (B)", 0, 255, 0, function(val) GeneratorB = val end)

local palletDropdown = CreateDropdownSection(MainPage, "Pallet ESP")
local togglePallet = CreateToggle(palletDropdown, "Enable Pallet ESP", false, function(state) PalletESPEnabled = state end)
local sliderPR = CreateSlider(palletDropdown, "Color: Red (R)", 0, 255, 255, function(val) PalletR = val end)
local sliderPG = CreateSlider(palletDropdown, "Color: Green (G)", 0, 255, 128, function(val) PalletG = val end)
local sliderPB = CreateSlider(palletDropdown, "Color: Blue (B)", 0, 255, 0, function(val) PalletB = val end)

local flashDropdown = CreateDropdownSection(VisualPage, "Custom Flashlight")
local toggleFlashlight = CreateToggle(flashDropdown, "Enable Flashlight", false, function(state) FlashlightEnabled = state end)
local sliderFlashRange = CreateSlider(flashDropdown, "Flashlight Range", 10, 150, 60, function(val) FlashRange = val end)
local sliderFlashR = CreateSlider(flashDropdown, "Color: Red (R)", 0, 255, 255, function(val) FlashR = val end)
local sliderFlashG = CreateSlider(flashDropdown, "Color: Green (G)", 0, 255, 255, function(val) FlashG = val end)
local sliderFlashB = CreateSlider(flashDropdown, "Color: Blue (B)", 0, 255, 255, function(val) FlashB = val end)

local toggleFOVSet = CreateToggle(MiscPage, "Enable FOV Changer", false, function(state) FOVEnabled = state end)
local sliderSet = CreateSlider(MiscPage, "FOV Changer Value", 70, 120, 70, function(val) currentFOV = val end)
local toggleSpeedSet = CreateToggle(MiscPage, "Enable Speedhack", false, function(state) SpeedhackEnabled = state end)
local sliderSpeedSet = CreateSlider(MiscPage, "WalkSpeed Value", 16, 150, 32, function(val) SpeedhackValue = val end)

-- ==================================
-- СИСТЕМА КОНФИГОВ
-- ==================================
local configFolder = "EssentialConfigs"
pcall(function()
    if makefolder and not isfolder(configFolder) then makefolder(configFolder) end
end)

local function GetConfigs()
    local files = {}
    pcall(function()
        if listfiles then
            for _, file in ipairs(listfiles(configFolder)) do
                local name = file:match("([^/\\]+)%.json$")
                if name then table.insert(files, name) end
            end
        end
    end)
    return files
end

local CurrentConfigName = ""
local SetConfigNameText = CreateInput(ConfigPage, "Enter Config Name...", function(val)
    CurrentConfigName = val
end)

local StatusLabel = CreateLabel(ConfigPage, "Status: Ready")
local ConfigListSection = CreateDropdownSection(ConfigPage, "Available Configs ▼")

local function RefreshConfigList()
    for _, child in ipairs(ConfigListSection:GetChildren()) do
        if child:IsA("TextButton") and child.Name == "CfgFileBtn" then child:Destroy() end
    end
    
    local files = GetConfigs()
    for _, cfgName in ipairs(files) do
        local btn = CreateButton(ConfigListSection, cfgName, BgDark, function()
            SetConfigNameText(cfgName)
            StatusLabel("Status: Selected '" .. cfgName .. "'")
        end)
        btn.Name = "CfgFileBtn"
    end
end

CreateButton(ConfigPage, "Save Config", BgElement, function()
    if CurrentConfigName == "" or CurrentConfigName:match("^%s*$") then
        StatusLabel("Status: Error - Name cannot be empty!") return
    end
    
    local files = GetConfigs()
    local exists = false
    for _, f in ipairs(files) do if f == CurrentConfigName then exists = true break end end
    
    if not exists and #files >= 5 then
        StatusLabel("Status: Error - Limit reached (Max 5 configs)!") return
    end
    
    local data = {
        ManiacESP = ManiacESPEnabled, MR = ManiacR, MG = ManiacG, MB = ManiacB,
        SurvESP = SurvivorESPEnabled, SR = SurvivorR, SG = SurvivorG, SB = SurvivorB,
        GenESP = GeneratorESPEnabled, GR = GeneratorR, GG = GeneratorG, GB = GeneratorB,
        PalletESP = PalletESPEnabled, PR = PalletR, PG = PalletG, PB = PalletB,
        FOVOn = FOVEnabled, FOV = currentFOV, Speedhack = SpeedhackEnabled, WalkSpeed = SpeedhackValue,
        FlashOn = FlashlightEnabled, FRange = FlashRange, FR = FlashR, FG = FlashG, FB = FlashB
    }
    
    pcall(function()
        if writefile then
            writefile(configFolder .. "/" .. CurrentConfigName .. ".json", HttpService:JSONEncode(data))
            StatusLabel("Status: Saved '" .. CurrentConfigName .. "'!")
            RefreshConfigList()
        end
    end)
end)

CreateButton(ConfigPage, "Load Config", BgElement, function()
    if CurrentConfigName == "" then return end
    local path = configFolder .. "/" .. CurrentConfigName .. ".json"
    
    pcall(function()
        if readfile and isfile and isfile(path) then
            local data = HttpService:JSONDecode(readfile(path))
            if type(data) == "table" then
                toggleManiac(data.ManiacESP or false) sliderMR(data.MR or 239) sliderMG(data.MG or 68) sliderMB(data.MB or 68)
                toggleSurvivor(data.SurvESP or false) sliderSR(data.SR or 34) sliderSG(data.SG or 197) sliderSB(data.SB or 94)
                toggleGenerator(data.GenESP or false) sliderGR(data.GR or 255) sliderGG(data.GG or 255) sliderGB(data.GB or 0)
                togglePallet(data.PalletESP or false) sliderPR(data.PR or 255) sliderPG(data.PG or 128) sliderPB(data.PB or 0)
                toggleFOVSet(data.FOVOn or false) sliderSet(data.FOV or 70)
                toggleSpeedSet(data.Speedhack or false) sliderSpeedSet(data.WalkSpeed or 32)
                toggleFlashlight(data.FlashOn or false) sliderFlashRange(data.FRange or 60) sliderFlashR(data.FR or 255) sliderFlashG(data.FG or 255) sliderFlashB(data.FB or 255)
                
                StatusLabel("Status: Loaded '" .. CurrentConfigName .. "'!")
            end
        else
            StatusLabel("Status: Error - Config not found!")
        end
    end)
end)

CreateButton(ConfigPage, "Delete Config", BgElement, function()
    if CurrentConfigName == "" then return end
    local path = configFolder .. "/" .. CurrentConfigName .. ".json"
    
    pcall(function()
        if delfile and isfile and isfile(path) then
            delfile(path)
            StatusLabel("Status: Deleted '" .. CurrentConfigName .. "'!")
            SetConfigNameText("")
            RefreshConfigList()
        else
            StatusLabel("Status: Error - Config not found!")
        end
    end)
end)

RefreshConfigList()

local sep = Instance.new("Frame", ConfigPage)
sep.Size = UDim2.new(1, 0, 0, 1)
sep.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
sep.BorderSizePixel = 0

-- ==================================
-- СКАНИРОВАНИЕ КАРТЫ (БЕЗ НАГРУЗКИ)
-- ==================================
local function CheckObject(obj)
    if obj:IsA("Model") or obj:IsA("BasePart") then
        local name = string.lower(obj.Name)
        if string.match(name, "generator") or name == "gen" then
            table.insert(trackedGenerators, obj)
        elseif string.match(name, "pallet") then
            table.insert(trackedPallets, obj)
        end
    end
end

task.spawn(function()
    local allObjs = workspace:GetDescendants()
    for i = 1, #allObjs do
        CheckObject(allObjs[i])
        if i % 1000 == 0 then task.wait() end
    end
end)

table.insert(connections, workspace.DescendantAdded:Connect(CheckObject))

-- Вспомогательная функция определения роли (вынесена из цикла для стабильности)
local function isPlayerManiac(player)
    if not player or not player.Character then return false end
    if player.Team and (string.find(string.lower(player.Team.Name), "killer") or string.find(string.lower(player.Team.Name), "maniac")) then return true end
    local role = player:GetAttribute("Role") or player.Character:GetAttribute("Role")
    if role and (string.match(string.lower(tostring(role)), "killer") or string.match(string.lower(tostring(role)), "maniac")) then return true end
    
    local function checkItems(parent)
        if not parent then return false end
        for _, item in ipairs(parent:GetChildren()) do
            if item:IsA("Tool") then
                local tName = string.lower(item.Name)
                if string.find(tName, "spear") or string.find(tName, "knife") or string.find(tName, "bat") or string.find(tName, "weapon") or string.find(tName, "axe") then return true end
            end
        end
        return false
    end
    if checkItems(player.Character) or checkItems(player:FindFirstChild("Backpack")) then return true end
    
    local hum = player.Character:FindFirstChild("Humanoid")
    if hum and hum.MaxHealth > 100 and hum.MaxHealth < 9999 then return true end
    return false
end

local function UnloadScript()
    for _, conn in ipairs(connections) do if conn then conn:Disconnect() end end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("EssentialESP") then p.Character.EssentialESP:Destroy() end
    end
    for _, gen in ipairs(trackedGenerators) do
        if gen and gen.Parent and gen:FindFirstChild("EssentialESP") then gen.EssentialESP:Destroy() end
    end
    for _, pallet in ipairs(trackedPallets) do
        if pallet and pallet.Parent and pallet:FindFirstChild("EssentialESP") then pallet.EssentialESP:Destroy() end
    end
    if currentLight then currentLight:Destroy() end
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = 70 end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = 16 end
    ScreenGui:Destroy()
end

CreateButton(ConfigPage, "Unload Script", AccentColor, UnloadScript)

-- ==================================
-- ГЛАВНЫЙ ЦИКЛ (ОТРИСОВКА И ОГРАНИЧЕНИЕ)
-- ==================================
table.insert(connections, RunService.RenderStepped:Connect(function()
    if workspace.CurrentCamera then
        workspace.CurrentCamera.FieldOfView = FOVEnabled and currentFOV or 70
    end

    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        if humanoid and SpeedhackEnabled then humanoid.WalkSpeed = SpeedhackValue end
        
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if FlashlightEnabled and rootPart then
            if not currentLight or currentLight.Parent ~= rootPart then
                if currentLight then currentLight:Destroy() end
                currentLight = Instance.new("PointLight")
                currentLight.Shadows = false
                currentLight.Brightness = 1.2
                currentLight.Parent = rootPart
            end
            currentLight.Color = Color3.fromRGB(FlashR, FlashG, FlashB)
            currentLight.Range = FlashRange
        else
            if currentLight then currentLight:Destroy() currentLight = nil end
        end
    end

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if myRoot then
        local myPos = myRoot.Position

        -- Генераторы (Отрисовка только если <= 100 студов)
        for i = #trackedGenerators, 1, -1 do
            local gen = trackedGenerators[i]
            if gen and gen.Parent then
                local highlight = gen:FindFirstChild("EssentialESP")
                local targetPart = gen:IsA("Model") and gen.PrimaryPart or gen:IsA("BasePart") and gen or gen:FindFirstChildWhichIsA("BasePart")
                
                if targetPart then
                    local dist = (myPos - targetPart.Position).Magnitude
                    
                    if GeneratorESPEnabled and dist <= MAX_ESP_DISTANCE then
                        if not highlight then
                            highlight = Instance.new("Highlight")
                            highlight.Name = "EssentialESP"
                            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                            highlight.FillTransparency = 0.5
                            highlight.OutlineTransparency = 0.2
                            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            highlight.Parent = gen
                        end
                        highlight.FillColor = Color3.fromRGB(GeneratorR, GeneratorG, GeneratorB)
                    else
                        if highlight then highlight:Destroy() end
                    end
                end
            else
                table.remove(trackedGenerators, i)
            end
        end

        -- Палетки (Отрисовка только если <= 100 студов)
        for i = #trackedPallets, 1, -1 do
            local pallet = trackedPallets[i]
            if pallet and pallet.Parent then
                local highlight = pallet:FindFirstChild("EssentialESP")
                local targetPart = pallet:IsA("Model") and pallet.PrimaryPart or pallet:IsA("BasePart") and pallet or pallet:FindFirstChildWhichIsA("BasePart")
                
                if targetPart then
                    local dist = (myPos - targetPart.Position).Magnitude
                    
                    if PalletESPEnabled and dist <= MAX_ESP_DISTANCE then
                        if not highlight then
                            highlight = Instance.new("Highlight")
                            highlight.Name = "EssentialESP"
                            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                            highlight.FillTransparency = 0.5
                            highlight.OutlineTransparency = 0.2
                            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            highlight.Parent = pallet
                        end
                        highlight.FillColor = Color3.fromRGB(PalletR, PalletG, PalletB)
                    else
                        if highlight then highlight:Destroy() end
                    end
                end
            else
                table.remove(trackedPallets, i)
            end
        end
    end

    -- Игроки (Маньяк / Выжившие)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local isManiac = isPlayerManiac(player)
            local highlight = player.Character:FindFirstChild("EssentialESP")
            local shouldHighlight = false
            local highlightColor = Color3.fromRGB(255, 255, 255)
            
            if isManiac and ManiacESPEnabled then
                shouldHighlight = true
                highlightColor = Color3.fromRGB(ManiacR, ManiacG, ManiacB)
            elseif not isManiac and SurvivorESPEnabled then
                shouldHighlight = true
                highlightColor = Color3.fromRGB(SurvivorR, SurvivorG, SurvivorB)
            end
            
            if shouldHighlight then
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "EssentialESP"
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0.2
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = player.Character
                end
                highlight.FillColor = highlightColor
            else
                if highlight then highlight:Destroy() end
            end
        end
    end
end))

print("[Essential]: Script Loaded Successfully!")