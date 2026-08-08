local Player = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

-- ============================================
-- ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
-- ============================================
_G.espEnabled = false
_G.autoFarm = false
_G.infiniteJump = false
_G.fullBright = false
_G.noclipEnabled = false
_G.antiAFK = false
_G.walkSpeed = 16
_G.jumpPower = 50
_G.currentCave = 1
_G.maxCave = 10
_G.gravity = 196.2
_G.espColor = Color3.fromRGB(0, 150, 255)
_G.showNames = true
_G.showGold = true
_G.showHitbox = true
_G.soundVolume = 15
_G.autoFlyToCave = false

local espObjects = {}
local farmConnection = nil
local noclipConnection = nil
local antiAFKConnection = nil
local spectateConnection = nil
local flyConnection = nil
local startTime = os.time()
local currentSound = nil
local isSpectating = false
local spectatingPlayer = nil
local isFlyingToCave = false
local flyPart = nil
local targetCavePosition = nil
local flyStartTime = 0
local flyStartPos = nil

-- КООРДИНАТЫ 10-Й ПЕЩЕРЫ
local CAVE_10_POSITION = Vector3.new(-196.37, 49.80, 8298.89)

local colorOptions = {
    {name = "Синий", color = Color3.fromRGB(0, 150, 255)},
    {name = "Красный", color = Color3.fromRGB(255, 0, 0)},
    {name = "Зелёный", color = Color3.fromRGB(0, 255, 0)},
    {name = "Жёлтый", color = Color3.fromRGB(255, 255, 0)},
    {name = "Фиолетовый", color = Color3.fromRGB(200, 0, 255)},
    {name = "Оранжевый", color = Color3.fromRGB(255, 150, 0)},
    {name = "Белый", color = Color3.fromRGB(255, 255, 255)},
}

-- ============================================
-- ФУНКЦИИ
-- ============================================
function getGold(plr)
    local ls = plr:FindFirstChild("leaderstats")
    if ls then
        local names = {"Gold", "Money", "Coins", "Cash", "Gems", "Diamonds"}
        for _, name in ipairs(names) do
            local stat = ls:FindFirstChild(name)
            if stat then
                if stat:IsA("NumberValue") or stat:IsA("IntValue") then
                    return stat.Value
                end
            end
        end
    end
    
    local folders = {"Data", "Save", "Stats", "Values"}
    for _, folderName in ipairs(folders) do
        local folder = plr:FindFirstChild(folderName)
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("NumberValue") or child:IsA("IntValue") then
                    local name = child.Name:lower()
                    if name:find("gold") or name:find("money") or name:find("coin") or name:find("cash") then
                        return child.Value
                    end
                end
            end
        end
    end
    
    return 0
end

function getTimePlayed()
    local timeInSeconds = os.time() - startTime
    local hours = math.floor(timeInSeconds / 3600)
    local minutes = math.floor((timeInSeconds % 3600) / 60)
    local seconds = math.floor(timeInSeconds % 60)
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

function playMusic()
    if currentSound then
        currentSound:Stop()
        currentSound:Destroy()
        currentSound = nil
    end
    
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://142376088"
    sound.Volume = _G.soundVolume / 100
    sound.Parent = Player.Character or workspace
    sound:Play()
    currentSound = sound
    
    return sound
end

function stopMusic()
    if currentSound then
        currentSound:Stop()
        currentSound:Destroy()
        currentSound = nil
    end
end

function updateVolume()
    if currentSound then
        currentSound.Volume = _G.soundVolume / 100
    end
end

-- ============================================
-- ПОИСК ПЕЩЕРЫ
-- ============================================
function findCavePart(caveNumber)
    local boatStages = workspace:FindFirstChild("BoatStages")
    if not boatStages then return nil end
    local normalStages = boatStages:FindFirstChild("NormalStages")
    if not normalStages then return nil end
    local caveStage = normalStages:FindFirstChild("CaveStage" .. caveNumber)
    if not caveStage then return nil end
    local darknessPart = caveStage:FindFirstChild("DarknessPart")
    if darknessPart and darknessPart:IsA("BasePart") then
        return darknessPart
    end
    return nil
end

function teleportToCavePart(caveNumber)
    local char = Player.Character
    if not char then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local part = findCavePart(caveNumber)
    if not part then return false end
    root.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
    root.Velocity = Vector3.new(0, 0, 0)
    root.RotVelocity = Vector3.new(0, 0, 0)
    return true
end

function killPlayer()
    local char = Player.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then humanoid.Health = 0 end
end

function setGravity(value)
    workspace.Gravity = value
end

-- ============================================
-- ФУНКЦИЯ ПОЛЕТА К ПЕЩЕРЕ (ИСПРАВЛЕННАЯ)
-- ============================================
function startFlyToCave()
    -- ПРОВЕРКА: если уже летим - НЕ ЗАПУСКАЕМ НОВЫЙ
    if isFlyingToCave then 
        print("⚠️ Уже летим! Не запускаем повторно.")
        return 
    end
    
    if not _G.autoFlyToCave then return end
    
    local char = Player.Character
    if not char then 
        task.wait(1)
        char = Player.Character
        if not char then return end
    end
    
    -- УДАЛЯЕМ СТАРУЮ ПЛАТФОРМУ ЕСЛИ ЕСТЬ
    if flyPart then
        flyPart:Destroy()
        flyPart = nil
    end
    
    -- ТЕЛЕПОРТ К 1-Й ПЕЩЕРЕ
    print("🚀 Телепорт к 1-й пещере...")
    local success = teleportToCavePart(1)
    if not success then
        warn("❌ Не удалось телепортироваться к 1-й пещере!")
        return
    end
    
    task.wait(0.5)
    
    char = Player.Character
    if not char then return end
    
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    isFlyingToCave = true
    targetCavePosition = CAVE_10_POSITION
    flyStartPos = rootPart.Position
    flyStartTime = tick()
    
    -- ПЛАТФОРМА (ТОЛЬКО 1)
    flyPart = Instance.new("Part")
    flyPart.Size = Vector3.new(3, 0.2, 3)
    flyPart.Position = rootPart.Position - Vector3.new(0, 2, 0)
    flyPart.Anchored = true
    flyPart.CanCollide = true
    flyPart.Transparency = 0.3
    flyPart.Material = Enum.Material.SmoothPlastic
    flyPart.BrickColor = BrickColor.new("Bright blue")
    flyPart.Name = "FlyPlatform"
    flyPart.Parent = workspace
    
    local glow = Instance.new("SelectionBox", flyPart)
    glow.Adornee = flyPart
    glow.Color3 = Color3.fromRGB(0, 200, 255)
    glow.Transparency = 0.3
    
    local particles = Instance.new("ParticleEmitter", flyPart)
    particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    particles.Rate = 20
    particles.SpreadAngle = Vector2.new(360, 360)
    particles.Lifetime = NumberRange.new(0.2, 0.6)
    particles.Speed = NumberRange.new(0.5, 2)
    particles.Size = NumberSequence.new(0.3, 0.8)
    particles.Transparency = NumberSequence.new(0.3, 1)
    particles.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255))
    particles.Enabled = true
    
    workspace.Gravity = 0
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    
    print("✈️ Начинаем полет к 10-й пещере! Скорость: 300")
    
    -- УБЕЖДАЕМСЯ ЧТО СТАРОЕ СОЕДИНЕНИЕ УДАЛЕНО
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    
    flyConnection = RunService.Heartbeat:Connect(function()
        if not isFlyingToCave or not _G.autoFlyToCave then
            stopFlyToCave()
            return
        end
        
        local char = Player.Character
        if not char then
            stopFlyToCave()
            return
        end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then
            stopFlyToCave()
            return
        end
        
        local elapsed = tick() - flyStartTime
        local newZ = flyStartPos.Z + (300 * elapsed)
        local newPos = Vector3.new(flyStartPos.X, flyStartPos.Y, newZ)
        
        if newZ >= CAVE_10_POSITION.Z then
            newPos = CAVE_10_POSITION
            print("🎯 Достигли 10-й пещеры! Умираем...")
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.Health = 0
            end
            stopFlyToCave()
            return
        end
        
        root.CFrame = CFrame.new(newPos)
        root.Velocity = Vector3.new(0, 0, 0)
        root.RotVelocity = Vector3.new(0, 0, 0)
        
        if flyPart then
            flyPart.Position = root.Position - Vector3.new(0, 2, 0)
        end
    end)
end

function stopFlyToCave()
    isFlyingToCave = false
    targetCavePosition = nil
    flyStartPos = nil
    flyStartTime = 0
    
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    
    if flyPart then
        flyPart:Destroy()
        flyPart = nil
    end
    
    workspace.Gravity = _G.gravity or 196.2
    
    local char = Player.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- Автоматический старт полета при спавне (ТОЛЬКО 1 РАЗ)
function onCharacterAdded(char)
    task.wait(0.5)
    if _G.autoFlyToCave and not isFlyingToCave then
        startFlyToCave()
    end
end

Player.CharacterAdded:Connect(onCharacterAdded)

if Player.Character then
    task.wait(1)
    if _G.autoFlyToCave and not isFlyingToCave then
        startFlyToCave()
    end
end

-- ============================================
-- SPECTATE
-- ============================================
function startSpectate(playerName)
    if spectateConnection then
        spectateConnection:Disconnect()
        spectateConnection = nil
    end
    
    local targetPlayer = nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name == playerName then
            targetPlayer = plr
            break
        end
    end
    
    if not targetPlayer then return false end
    
    spectatingPlayer = targetPlayer
    isSpectating = true
    
    local camera = workspace.CurrentCamera
    camera.CameraSubject = targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid")
    
    spectateConnection = RunService.Heartbeat:Connect(function()
        if not isSpectating or not targetPlayer or not targetPlayer.Character then
            return
        end
        local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            camera.CameraSubject = humanoid
        end
    end)
    
    return true
end

function stopSpectate()
    isSpectating = false
    spectatingPlayer = nil
    if spectateConnection then
        spectateConnection:Disconnect()
        spectateConnection = nil
    end
    local camera = workspace.CurrentCamera
    camera.CameraSubject = Player.Character and Player.Character:FindFirstChild("Humanoid")
end

function getPlayerList()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
            table.insert(list, plr.Name)
        end
    end
    return list
end

-- ============================================
-- REJOIN И SERVER HOP
-- ============================================
function rejoinGame()
    local placeId = game.PlaceId
    local jobId = game.JobId
    TeleportService:Teleport(placeId, Player, jobId)
end

function serverHop()
    local placeId = game.PlaceId
    local HttpService = game:GetService("HttpService")
    local servers = {}
    
    task.spawn(function()
        local success, result = pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?limit=10"
            local response = HttpService:GetAsync(url)
            local data = HttpService:JSONDecode(response)
            if data and data.data then
                for _, server in ipairs(data.data) do
                    if server.id ~= game.JobId and server.playing < server.maxPlayers then
                        table.insert(servers, server.id)
                    end
                end
            end
        end)
        
        if success and #servers > 0 then
            TeleportService:TeleportToPlaceInstance(placeId, servers[math.random(1, #servers)], Player)
        else
            warn("❌ Не удалось найти другой сервер, перезаход на этот же")
            rejoinGame()
        end
    end)
end

-- ============================================
-- GUI
-- ============================================
local Gui = Instance.new("ScreenGui")
Gui.Name = "R.E.G"
Gui.ResetOnSpawn = false
Gui.Parent = Player.PlayerGui

local Frame = Instance.new("Frame", Gui)
Frame.Size = UDim2.new(0, 540, 0, 620)
Frame.Position = UDim2.new(0.5, -270, 0.1, 0)
Frame.BackgroundColor3 = Color3.fromRGB(12, 12, 28)
Frame.BackgroundTransparency = 0.1
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 12)

local Stroke = Instance.new("UIStroke", Frame)
Stroke.Color = Color3.fromRGB(80, 80, 160)
Stroke.Thickness = 2

local Top = Instance.new("Frame", Frame)
Top.Size = UDim2.new(1, 0, 0, 45)
Top.BackgroundColor3 = Color3.fromRGB(28, 28, 52)
Top.BorderSizePixel = 0
Instance.new("UICorner", Top).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel", Top)
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, -90, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "R.E.G ULTIMATE 2.1"
Title.TextSize = 22
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left

local Min = Instance.new("TextButton", Top)
Min.Size = UDim2.new(0, 30, 0, 30)
Min.Position = UDim2.new(1, -70, 0, 7)
Min.Text = "−"
Min.Font = Enum.Font.GothamBold
Min.TextSize = 24
Min.TextColor3 = Color3.fromRGB(255, 255, 255)
Min.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
Min.BorderSizePixel = 0
Instance.new("UICorner", Min).CornerRadius = UDim.new(1, 0)

local Close = Instance.new("TextButton", Top)
Close.Size = UDim2.new(0, 30, 0, 30)
Close.Position = UDim2.new(1, -35, 0, 7)
Close.Text = "х"
Close.Font = Enum.Font.GothamBold
Close.TextSize = 18
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
Close.BorderSizePixel = 0
Instance.new("UICorner", Close).CornerRadius = UDim.new(1, 0)

local Open = Instance.new("TextButton", Gui)
Open.Size = UDim2.new(0, 55, 0, 55)
Open.Position = UDim2.new(0.02, 0, 0.5, -27)
Open.Text = "R.E.G"
Open.Font = Enum.Font.GothamBold
Open.TextSize = 20
Open.TextColor3 = Color3.fromRGB(255, 255, 255)
Open.BackgroundColor3 = Color3.fromRGB(35, 35, 70)
Open.BorderSizePixel = 0
Open.Visible = false
Open.Active = true
Open.Draggable = true
Instance.new("UICorner", Open).CornerRadius = UDim.new(0, 12)

-- ============================================
-- ВКЛАДКИ
-- ============================================
local tabNames = {"Auto", "ВИЗУАЛЫ", "Настройки", "Наблюдать", "Профиль", "Sound"}
local tabButtons = {}
local tabContents = {}

local tabFrame = Instance.new("Frame", Frame)
tabFrame.Size = UDim2.new(0, 85, 1, -50)
tabFrame.Position = UDim2.new(0, 5, 0, 50)
tabFrame.BackgroundTransparency = 1

for i, name in ipairs(tabNames) do
    local btn = Instance.new("TextButton", tabFrame)
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.Position = UDim2.new(0, 0, 0, (i - 1) * 40 + 5)
    btn.BackgroundColor3 = (i == 1) and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(30, 30, 55)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local content = Instance.new("ScrollingFrame", Frame)
    content.Size = UDim2.new(1, -100, 1, -55)
    content.Position = UDim2.new(0, 95, 0, 50)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.ScrollBarThickness = 4
    content.Visible = (i == 1)

    tabButtons[i] = btn
    tabContents[i] = content

    btn.MouseButton1Click:Connect(function()
        for j = 1, #tabNames do
            tabContents[j].Visible = (j == i)
            tabButtons[j].BackgroundColor3 = (j == i) and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(30, 30, 55)
        end
    end)
end

-- ============================================
-- GUI ФУНКЦИИ
-- ============================================
local function createHeader(parent, text)
    local label = Instance.new("TextLabel", parent)
    label.Size = UDim2.new(1, 0, 0, 28)
    label.Position = UDim2.new(0, 0, 0, yPos)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 16
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    yPos = yPos + 30
    return label
end

local function createToggle(parent, text, isOn, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.Position = UDim2.new(0, 0, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(22, 22, 42)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(210, 210, 235)
    label.TextSize = 12
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 65, 1, -6)
    btn.Position = UDim2.new(1, -72, 0, 3)
    btn.BackgroundColor3 = isOn and Color3.fromRGB(0, 130, 255) or Color3.fromRGB(50, 50, 80)
    btn.Text = isOn and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    yPos = yPos + 38

    btn.MouseButton1Click:Connect(function()
        local newState = not isOn
        isOn = newState
        btn.Text = isOn and "ON" or "OFF"
        btn.BackgroundColor3 = isOn and Color3.fromRGB(0, 130, 255) or Color3.fromRGB(50, 50, 80)
        callback(isOn)
    end)

    return btn
end

local function createColorPicker(parent, text, callback)
    local label = Instance.new("TextLabel", parent)
    label.Size = UDim2.new(1, 0, 0, 22)
    label.Position = UDim2.new(0, 0, 0, yPos)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(180, 180, 215)
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    yPos = yPos + 24

    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.Position = UDim2.new(0, 0, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(22, 22, 42)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local currentColor = Instance.new("Frame", frame)
    currentColor.Size = UDim2.new(0, 30, 1, -8)
    currentColor.Position = UDim2.new(0, 8, 0, 4)
    currentColor.BackgroundColor3 = _G.espColor
    currentColor.BorderSizePixel = 0
    Instance.new("UICorner", currentColor).CornerRadius = UDim.new(0, 6)

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0.8, -10, 1, -6)
    btn.Position = UDim2.new(0.15, 0, 0, 3)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
    btn.Text = colorOptions[1].name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local dropdown = Instance.new("Frame", frame)
    dropdown.Size = UDim2.new(0.8, -10, 0, #colorOptions * 28)
    dropdown.Position = UDim2.new(0.15, 0, 1, 2)
    dropdown.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    dropdown.BorderSizePixel = 0
    dropdown.Visible = false
    Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0, 6)

    local selectedIndex = 1

    for i, opt in ipairs(colorOptions) do
        local optBtn = Instance.new("TextButton", dropdown)
        optBtn.Size = UDim2.new(1, 0, 0, 28)
        optBtn.Position = UDim2.new(0, 0, 0, (i - 1) * 28)
        optBtn.BackgroundColor3 = (i == selectedIndex) and Color3.fromRGB(0, 100, 200) or Color3.fromRGB(25, 25, 50)
        optBtn.Text = opt.name
        optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        optBtn.TextSize = 12
        optBtn.Font = Enum.Font.GothamMedium
        optBtn.BorderSizePixel = 0

        optBtn.MouseButton1Click:Connect(function()
            selectedIndex = i
            _G.espColor = opt.color
            currentColor.BackgroundColor3 = opt.color
            btn.Text = opt.name
            dropdown.Visible = false
            callback(opt.color)
            if _G.espEnabled then updateESP() end
        end)
    end

    btn.MouseButton1Click:Connect(function()
        dropdown.Visible = not dropdown.Visible
    end)

    yPos = yPos + 38
    return btn
end

local function createSlider(parent, text, min, max, default, callback)
    local label = Instance.new("TextLabel", parent)
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, yPos)
    label.BackgroundTransparency = 1
    label.Text = text .. " (" .. default .. ")"
    label.TextColor3 = Color3.fromRGB(180, 180, 215)
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    yPos = yPos + 22

    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 28)
    frame.Position = UDim2.new(0, 0, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(22, 22, 42)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local slider = Instance.new("TextButton", frame)
    slider.Size = UDim2.new(1, -15, 0.7, 0)
    slider.Position = UDim2.new(0, 8, 0, 4)
    slider.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
    slider.BorderSizePixel = 0
    slider.AutoButtonColor = false
    Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 6)

    local fill = Instance.new("Frame", slider)
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 130, 255)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 6)

    local valueLabel = Instance.new("TextLabel", frame)
    valueLabel.Size = UDim2.new(0.15, 0, 1, 0)
    valueLabel.Position = UDim2.new(0.85, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    valueLabel.TextSize = 12
    valueLabel.Font = Enum.Font.GothamBold

    local dragging = false

    slider.MouseButton1Down:Connect(function()
        dragging = true
    end)

    slider.MouseButton1Up:Connect(function()
        dragging = false
    end)

    slider.MouseMoved:Connect(function(x, y)
        if dragging then
            local relativeX = math.clamp((x - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
            local value = math.round(min + (max - min) * relativeX)
            fill.Size = UDim2.new(relativeX, 0, 1, 0)
            valueLabel.Text = tostring(value)
            label.Text = text .. " (" .. value .. ")"
            callback(value)
        end
    end)

    yPos = yPos + 32
    return fill, valueLabel
end

local function createDivider(parent)
    local line = Instance.new("Frame", parent)
    line.Size = UDim2.new(1, -20, 0, 1)
    line.Position = UDim2.new(0, 10, 0, yPos)
    line.BackgroundColor3 = Color3.fromRGB(50, 50, 85)
    line.BorderSizePixel = 0
    yPos = yPos + 10
    return line
end

local function createButton(parent, text, color, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -10, 0, 38)
    btn.Position = UDim2.new(0, 5, 0, yPos)
    btn.BackgroundColor3 = color or Color3.fromRGB(0, 130, 255)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    btn.MouseButton1Click:Connect(callback)
    yPos = yPos + 42
    return btn
end

-- ============================================
-- ВКЛАДКА AUTO
-- ============================================
local autoContent = tabContents[1]
yPos = 5
createHeader(autoContent, "Авто")
local farmToggle = createToggle(autoContent, "Автофарм", _G.autoFarm, function(state)
    _G.autoFarm = state
    if state then startFarm() else stopFarm() end
end)
local flyToggle = createToggle(autoContent, "✈️ Автополет", _G.autoFlyToCave, function(state)
    _G.autoFlyToCave = state
    if state then
        if Player.Character and not isFlyingToCave then
            startFlyToCave()
        end
    else
        stopFlyToCave()
    end
end)
autoContent.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)

-- ============================================
-- ВКЛАДКА ВИЗУАЛЫ
-- ============================================
local espContent = tabContents[2]
yPos = 5
createHeader(espContent, "Настройки ВИЗУАЛОВ")
local espToggle = createToggle(espContent, "Включить ESP", _G.espEnabled, function(state)
    _G.espEnabled = state
    if state then enableESP() else disableESP() end
end)
createDivider(espContent)
createHeader(espContent, "Отображение")
local hitboxToggle = createToggle(espContent, "Хитбокс", _G.showHitbox, function(state)
    _G.showHitbox = state
    if _G.espEnabled then updateESP() end
end)
local namesToggle = createToggle(espContent, "Ники", _G.showNames, function(state)
    _G.showNames = state
    if _G.espEnabled then updateESP() end
end)
local goldToggle = createToggle(espContent, "Золото", _G.showGold, function(state)
    _G.showGold = state
    if _G.espEnabled then updateESP() end
end)
createDivider(espContent)
createHeader(espContent, "Цвет хитбокса")
local colorPicker = createColorPicker(espContent, "Выберите цвет", function(color)
    _G.espColor = color
    if _G.espEnabled then updateESP() end
end)
espContent.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)

-- ============================================
-- ВКЛАДКА НАСТРОЙКИ
-- ============================================
local settingsContent = tabContents[3]
yPos = 5
createHeader(settingsContent, "Настройки движения")
local wsSlider = createSlider(settingsContent, "WalkSpeed", 1, 100, _G.walkSpeed, function(value)
    _G.walkSpeed = value
    local char = Player.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then humanoid.WalkSpeed = value end
    end
end)
local jpSlider = createSlider(settingsContent, "JumpPower", 0, 200, _G.jumpPower, function(value)
    _G.jumpPower = value
    local char = Player.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then humanoid.JumpPower = value end
    end
end)
createDivider(settingsContent)
createHeader(settingsContent, "Настройки гравитации")
local gravSlider = createSlider(settingsContent, "Gravity", 0, 250, _G.gravity, function(value)
    _G.gravity = value
    workspace.Gravity = value
end)
createDivider(settingsContent)
createHeader(settingsContent, "Дополнительно")
local noclipToggle = createToggle(settingsContent, "Noclip", _G.noclipEnabled, function(state)
    _G.noclipEnabled = state
    if state then enableNoclip() else disableNoclip() end
end)
local jumpToggle = createToggle(settingsContent, "Infinite Jump", _G.infiniteJump, function(state)
    _G.infiniteJump = state
end)
local brightToggle = createToggle(settingsContent, "Full Bright", _G.fullBright, function(state)
    _G.fullBright = state
    Lighting.Brightness = state and 2 or 1
    Lighting.Ambient = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(127, 127, 127)
end)
createDivider(settingsContent)
createHeader(settingsContent, "Анти-АФК")
local afkToggle = createToggle(settingsContent, "Анти-АФК (защита от кика)", _G.antiAFK, function(state)
    _G.antiAFK = state
    if state then enableAntiAFK() else disableAntiAFK() end
end)
settingsContent.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)

-- ============================================
-- ВКЛАДКА НАБЛЮДАТЬ
-- ============================================
local spectateContent = tabContents[4]
yPos = 5
createHeader(spectateContent, "👥 Наблюдение за игроками")

local statusText = Instance.new("TextLabel", spectateContent)
statusText.Size = UDim2.new(1, -20, 0, 30)
statusText.Position = UDim2.new(0, 10, 0, yPos)
statusText.BackgroundTransparency = 1
statusText.Text = "Выберите игрока для наблюдения"
statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
statusText.TextSize = 13
statusText.Font = Enum.Font.GothamMedium
statusText.TextXAlignment = Enum.TextXAlignment.Center
yPos = yPos + 35

local playersList = {}

function updatePlayerList()
    for _, btn in ipairs(playersList) do
        btn:Destroy()
    end
    playersList = {}
    
    local players = getPlayerList()
    local tempY = yPos
    
    if #players == 0 then
        local noPlayers = Instance.new("TextLabel", spectateContent)
        noPlayers.Size = UDim2.new(1, -20, 0, 30)
        noPlayers.Position = UDim2.new(0, 10, 0, tempY)
        noPlayers.BackgroundTransparency = 1
        noPlayers.Text = "❌ Нет других игроков на сервере"
        noPlayers.TextColor3 = Color3.fromRGB(200, 200, 200)
        noPlayers.TextSize = 13
        noPlayers.Font = Enum.Font.GothamMedium
        noPlayers.TextXAlignment = Enum.TextXAlignment.Center
        table.insert(playersList, noPlayers)
        return
    end
    
    for i, name in ipairs(players) do
        local btn = Instance.new("TextButton", spectateContent)
        btn.Size = UDim2.new(0.8, 0, 0, 34)
        btn.Position = UDim2.new(0.1, 0, 0, tempY)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 60)
        btn.Text = i .. ". " .. name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        
        btn.MouseButton1Click:Connect(function()
            if isSpectating then
                stopSpectate()
            end
            local success = startSpectate(name)
            if success then
                statusText.Text = "👁️ Наблюдение за: " .. name .. " (F10 - остановить)"
                statusText.TextColor3 = Color3.fromRGB(100, 255, 100)
            else
                statusText.Text = "❌ Не удалось начать наблюдение за " .. name
                statusText.TextColor3 = Color3.fromRGB(255, 100, 100)
            end
        end)
        
        table.insert(playersList, btn)
        tempY = tempY + 38
    end
end

yPos = yPos + 10
local stopSpectateBtn = createButton(spectateContent, "⏹ Остановить наблюдение (F10)", Color3.fromRGB(200, 50, 50), function()
    stopSpectate()
    statusText.Text = "👁️ Наблюдение остановлено"
    statusText.TextColor3 = Color3.fromRGB(255, 200, 100)
end)

local refreshListBtn = createButton(spectateContent, "🔄 Обновить список игроков", Color3.fromRGB(0, 130, 255), function()
    updatePlayerList()
    statusText.Text = "🔄 Список обновлен"
    statusText.TextColor3 = Color3.fromRGB(100, 255, 100)
end)

spectateContent.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)

-- ============================================
-- ВКЛАДКА ПРОФИЛЬ
-- ============================================
local profileContent = tabContents[5]
yPos = 5
createHeader(profileContent, "Ваш профиль")

local profileFrame = Instance.new("Frame", profileContent)
profileFrame.Size = UDim2.new(1, -10, 0, 150)
profileFrame.Position = UDim2.new(0, 5, 0, yPos)
profileFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 45)
profileFrame.BackgroundTransparency = 0.3
profileFrame.BorderSizePixel = 0
Instance.new("UICorner", profileFrame).CornerRadius = UDim.new(0, 10)

local profileText = Instance.new("TextLabel", profileFrame)
profileText.Size = UDim2.new(1, -10, 1, -10)
profileText.Position = UDim2.new(0, 5, 0, 5)
profileText.BackgroundTransparency = 1
profileText.Text = "Загрузка..."
profileText.TextColor3 = Color3.fromRGB(220, 220, 255)
profileText.TextSize = 15
profileText.Font = Enum.Font.GothamMedium
profileText.TextXAlignment = Enum.TextXAlignment.Left
profileText.TextYAlignment = Enum.TextYAlignment.Top

yPos = yPos + 160
createDivider(profileContent)
createHeader(profileContent, "🔄 Действия")

local rejoinBtn = createButton(profileContent, "🔄 Rejoin (перезайти на сервер)", Color3.fromRGB(0, 130, 255), function()
    rejoinGame()
end)

local hopBtn = createButton(profileContent, "🌍 Server Hop (перейти на другой сервер)", Color3.fromRGB(200, 130, 50), function()
    serverHop()
end)

yPos = yPos + 10
profileContent.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)

function updateProfile()
    local gold = getGold(Player)
    local time = getTimePlayed()
    profileText.Text = "👤 Имя: " .. Player.Name .. 
                       "\n💰 Золото: " .. gold .. 
                       "\n⏱️ В игре: " .. time .. 
                       "\n🛠️ Чит: R.E.G ULTIMATE\n📌 Статус: Активен ✅"
end

-- ============================================
-- ВКЛАДКА SOUND
-- ============================================
local soundContent = tabContents[6]
yPos = 5

createHeader(soundContent, "🎵 Музыка")

local statusLabel = Instance.new("TextLabel", soundContent)
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, yPos)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Нажмите кнопку чтобы включить"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 14
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
yPos = yPos + 35

local playBtn = Instance.new("TextButton", soundContent)
playBtn.Size = UDim2.new(0.9, 0, 0, 40)
playBtn.Position = UDim2.new(0.05, 0, 0, yPos)
playBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
playBtn.Text = "🎵 Включить музыку"
playBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
playBtn.TextScaled = true
playBtn.Font = Enum.Font.GothamBold
playBtn.BorderSizePixel = 0
Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0, 8)

playBtn.MouseButton1Click:Connect(function()
    playMusic()
    statusLabel.Text = "🎵 Играет: Parry Gripp"
    statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
end)

yPos = yPos + 45

local stopBtn = Instance.new("TextButton", soundContent)
stopBtn.Size = UDim2.new(0.9, 0, 0, 40)
stopBtn.Position = UDim2.new(0.05, 0, 0, yPos)
stopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
stopBtn.Text = "⏹ Остановить"
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.TextScaled = true
stopBtn.Font = Enum.Font.GothamBold
stopBtn.BorderSizePixel = 0
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 8)

stopBtn.MouseButton1Click:Connect(function()
    stopMusic()
    statusLabel.Text = "⏹ Музыка остановлена"
    statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
end)

yPos = yPos + 45

createDivider(soundContent)
createHeader(soundContent, "🔊 Громкость")

local volSlider = createSlider(soundContent, "Громкость", 0, 100, _G.soundVolume, function(value)
    _G.soundVolume = value
    updateVolume()
end)

soundContent.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)

-- ============================================
-- ЛОГИКА СВЕРТЫВАНИЯ
-- ============================================
Min.MouseButton1Click:Connect(function()
    Frame.Visible = false
    Open.Visible = true
end)

Open.MouseButton1Click:Connect(function()
    Frame.Visible = true
    Open.Visible = false
    updatePlayerList()
end)

Close.MouseButton1Click:Connect(function()
    if _G.espEnabled then disableESP() end
    if _G.autoFarm then stopFarm() end
    if _G.noclipEnabled then disableNoclip() end
    if _G.antiAFK then disableAntiAFK() end
    if isSpectating then stopSpectate() end
    if isFlyingToCave then stopFlyToCave() end
    stopMusic()
    Gui:Destroy()
end)

-- ============================================
-- ESP ФУНКЦИИ
-- ============================================
function enableESP()
    updateESP()
    Players.PlayerAdded:Connect(function() 
        if _G.espEnabled then updateESP() end
    end)
    Players.PlayerRemoving:Connect(function() 
        if _G.espEnabled then updateESP() end
    end)
    task.spawn(function()
        while _G.espEnabled and Gui.Parent do
            updateESP()
            task.wait(0.5)
        end
    end)
end

function disableESP()
    clearESP()
end

function clearESP()
    for _, obj in ipairs(espObjects) do
        obj:Destroy()
    end
    espObjects = {}
end

function updateESP()
    clearESP()
    if not _G.espEnabled then return end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local char = plr.Character
            local rootPart = char:FindFirstChild("HumanoidRootPart")
            if not rootPart then continue end

            if _G.showHitbox then
                local box = Instance.new("BoxHandleAdornment")
                box.Size = Vector3.new(4, 5, 4)
                box.Adornee = rootPart
                box.Color3 = _G.espColor
                box.Transparency = 0.4
                box.ZIndex = 0
                box.AlwaysOnTop = true
                box.Parent = char
                table.insert(espObjects, box)
            end

            local highlight = Instance.new("Highlight")
            highlight.Adornee = char
            highlight.FillColor = _G.espColor
            highlight.FillTransparency = 0.3
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.OutlineTransparency = 0.3
            highlight.Parent = char
            table.insert(espObjects, highlight)

            if _G.showNames or _G.showGold then
                local billboard = Instance.new("BillboardGui")
                billboard.Size = UDim2.new(0, 200, 0, 50)
                billboard.StudsOffset = Vector3.new(0, 3.5, 0)
                billboard.AlwaysOnTop = true
                billboard.Parent = char
                table.insert(espObjects, billboard)

                if _G.showNames then
                    local nameLabel = Instance.new("TextLabel", billboard)
                    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
                    nameLabel.Position = UDim2.new(0, 0, 0, 0)
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.Text = plr.Name
                    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    nameLabel.TextScaled = true
                    nameLabel.Font = Enum.Font.GothamBold
                    nameLabel.TextStrokeTransparency = 0.2
                    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    table.insert(espObjects, nameLabel)
                end

                if _G.showGold then
                    local goldLabel = Instance.new("TextLabel", billboard)
                    goldLabel.Size = UDim2.new(1, 0, 0.5, 0)
                    goldLabel.Position = UDim2.new(0, 0, 0.5, 0)
                    goldLabel.BackgroundTransparency = 1
                    goldLabel.Text = "💰 " .. getGold(plr)
                    goldLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
                    goldLabel.TextScaled = true
                    goldLabel.Font = Enum.Font.GothamBold
                    goldLabel.TextStrokeTransparency = 0.2
                    goldLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    table.insert(espObjects, goldLabel)
                end
            end
        end
    end
end

function toggleESP()
    if _G.espEnabled then disableESP() else enableESP() end
end

-- ============================================
-- NOCLIP
-- ============================================
function enableNoclip()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        if not _G.noclipEnabled then return end
        local char = Player.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
end

function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    local char = Player.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end

function toggleNoclip()
    if _G.noclipEnabled then disableNoclip() else enableNoclip() end
end

-- ============================================
-- АНТИ-АФК
-- ============================================
function enableAntiAFK()
    if antiAFKConnection then return end
    local virtualUser = game:GetService("VirtualUser")
    antiAFKConnection = RunService.Heartbeat:Connect(function()
        if not _G.antiAFK then return end
        virtualUser:CaptureController()
        virtualUser:ClickButton2(Vector2.new(0, 0))
    end)
end

function disableAntiAFK()
    if antiAFKConnection then
        antiAFKConnection:Disconnect()
        antiAFKConnection = nil
    end
end

function toggleAntiAFK()
    if _G.antiAFK then enableAntiAFK() else disableAntiAFK() end
end

-- ============================================
-- АВТОФАРМ ПЕЩЕРЫ 1-10
-- ============================================
local isCaveTeleporting = false
local isCaveWaiting = false

function startFarm()
    if farmConnection then return end
    _G.currentCave = 1
    setGravity(0)
    enableNoclip()
    task.wait(0.5)
    teleportToCavePart(1)

    farmConnection = RunService.Heartbeat:Connect(function()
        if not _G.autoFarm then return end
        if isCaveTeleporting or isCaveWaiting then return end
        
        local char = Player.Character
        if not char then return end
        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end

        isCaveWaiting = true
        
        task.wait(2)
        
