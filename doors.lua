--[[
    ============================================================
    Script Supremo Nativo - Interface Moderna & Animada
    ============================================================
]]

local function applyTeleportQueue()
    if queue_on_teleport then
        pcall(function()
            queue_on_teleport([[
                task.wait(1)
                loadstring(game:HttpGet("https://raw.githubusercontent.com/nrotta59-rgb/blabu/refs/heads/main/doors.lua?v=" .. tick()))()
            ]])
        end)
    end
end
applyTeleportQueue()

if _G.NativeAutomationRunning then
    _G.NativeAutomationRunning = false
    task.wait(0.3)
end
_G.NativeAutomationRunning = true

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
if not player then return end

pcall(function()
    if CoreGui:FindFirstChild("SupremeAutomationUI") then
        CoreGui.SupremeAutomationUI:Destroy()
    end
    if player.PlayerGui:FindFirstChild("SupremeAutomationUI") then
        player.PlayerGui.SupremeAutomationUI:Destroy()
    end
end)

local config = {
    AutoPlayAgain = false,
    AutoShopConfirm = false,
    AutoReset = false,
    AutoResetMinutes = 4,
    AntiAFK = true
}

local settingsFileName = "NativeAutomationConfig.json"

local function saveSettings()
    pcall(function()
        if writefile and HttpService then
            writefile(settingsFileName, HttpService:JSONEncode(config))
        end
    end)
end

local function loadSettings()
    pcall(function()
        if readfile and isfile and isfile(settingsFileName) then
            local fileContent = readfile(settingsFileName)
            local decodedTable = HttpService:JSONDecode(fileContent)
            if type(decodedTable) == "table" then
                for k, v in pairs(decodedTable) do 
                    config[k] = v 
                end
            end
        end
    end)
end
loadSettings()

config.AutoResetMinutes = 4
saveSettings()

-- Criação da Interface Nativa Moderna
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SupremeAutomationUI"
screenGui.ResetOnSpawn = false

pcall(function()
    screenGui.Parent = CoreGui
end)
if not screenGui.Parent then
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 260, 0, 220)
mainFrame.Position = UDim2.new(1, -270, 0, 15)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true

local uiCorner = Instance.new("UICorner", mainFrame)
uiCorner.CornerRadius = UDim.new(0, 10)

local uiStroke = Instance.new("UIStroke", mainFrame)
uiStroke.Color = Color3.fromRGB(50, 50, 65)
uiStroke.Thickness = 1.5

-- Título
local titleLabel = Instance.new("TextLabel", mainFrame)
titleLabel.Size = UDim2.new(1, 0, 0, 35)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "DOORS  |  AUTOMATION"
titleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamBold

local titleLine = Instance.new("Frame", mainFrame)
titleLine.Size = UDim2.new(1, -20, 0, 1)
titleLine.Position = UDim2.new(0, 10, 0, 35)
titleLine.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
titleLine.BorderSizePixel = 0

-- Container Scrolling
local container = Instance.new("ScrollingFrame", mainFrame)
container.Size = UDim2.new(1, -16, 1, -45)
container.Position = UDim2.new(0, 8, 0, 40)
container.BackgroundTransparency = 1
container.CanvasSize = UDim2.new(0, 0, 0, 170)
container.ScrollBarThickness = 2
container.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)

local uiList = Instance.new("UIListLayout", container)
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Padding = UDim.new(0, 6)

-- Estilos para Botões (Cores e Animações)
local COLOR_OFF = Color3.fromRGB(28, 28, 36)
local COLOR_ON = Color3.fromRGB(45, 125, 245)
local TEXT_OFF = Color3.fromRGB(150, 150, 165)
local TEXT_ON = Color3.fromRGB(255, 255, 255)

local function createToggle(name, initialValue, callback)
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, -4, 0, 34)
    btn.BackgroundColor3 = initialValue and COLOR_ON or COLOR_OFF
    btn.TextColor3 = initialValue and TEXT_ON or TEXT_OFF
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamMedium
    btn.AutoButtonColor = false
    
    local statusText = initialValue and "ON" or "OFF"
    btn.Text = "   " .. name .. "  [" .. statusText .. "]"
    btn.TextXAlignment = Enum.TextXAlignment.Left

    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = initialValue and Color3.fromRGB(70, 150, 255) or Color3.fromRGB(40, 40, 50)
    stroke.Thickness = 1

    local active = initialValue

    -- Animações com TweenService
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local function updateVisuals(state)
        local targetBg = state and COLOR_ON or COLOR_OFF
        local targetText = state and TEXT_ON or TEXT_OFF
        local targetStroke = state and Color3.fromRGB(70, 150, 255) or Color3.fromRGB(40, 40, 50)
        
        TweenService:Create(btn, tweenInfo, {BackgroundColor3 = targetBg, TextColor3 = targetText}):Play()
        TweenService:Create(stroke, tweenInfo, {Color = targetStroke}):Play()
    end

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, tweenInfo, {Size = UDim2.new(1, -2, 0, 34)}):Play()
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, tweenInfo, {Size = UDim2.new(1, -4, 0, 34)}):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        active = not active
        local newStatusText = active and "ON" or "OFF"
        btn.Text = "   " .. name .. "  [" .. newStatusText .. "]"
        updateVisuals(active)
        callback(active)
    end)
    
    return btn
end

-- 1. Auto Play Again (Disparo Tríplice + Forçar Eventos de UI)
local isDeadProcessing = false
local function triggerPlayAgain()
    if isDeadProcessing then return end
    isDeadProcessing = true
    
    pcall(function()
        local playerGui = player:WaitForChild("PlayerGui", 5)
        local mainUI = playerGui and playerGui:WaitForChild("MainUI", 5)
        
        if mainUI then
            local deathPanel = mainUI:WaitForChild("DeathPanel", 10)
            local statistics = mainUI:WaitForChild("Statistics", 10)
            
            pcall(function()
                if statistics and statistics:FindFirstChild("Buttons") and statistics.Buttons:FindFirstChild("PlayAgain") then
                    for _, connection in ipairs(getconnections(statistics.Buttons.PlayAgain.MouseButton1Down)) do
                        connection:Fire()
                    end
                end
            end)
        end

        task.wait(1.5)

        local remotesFolder = ReplicatedStorage:WaitForChild("RemotesFolder", 5)
        local playAgainEvent = remotesFolder and remotesFolder:WaitForChild("PlayAgain", 5)

        if playAgainEvent then
            for i = 1, 5 do
                playAgainEvent:FireServer()
                playAgainEvent:FireServer(true)
                task.wait(0.5)
            end
            print("[Automation] Play Again disparado em loop de confirmação!")
        else
            warn("[Automation] RemoteEvent 'PlayAgain' não encontrado.")
        end
    end)
    
    task.wait(2)
    isDeadProcessing = false
end

local function monitorCharacter(character)
    if not character then return end
    local humanoid = character:WaitForChild("Humanoid", 15)
    if not humanoid then return end
    
    humanoid.Died:Connect(function()
        if config.AutoPlayAgain then
            task.spawn(triggerPlayAgain)
        end
    end)
end

if player.Character then 
    task.spawn(function() monitorCharacter(player.Character) end)
end

player.CharacterAdded:Connect(function(newCharacter)
    task.spawn(function() monitorCharacter(newCharacter) end)
end)

createToggle("Auto Play Again", config.AutoPlayAgain, function(val)
    config.AutoPlayAgain = val
    saveSettings()
end)

-- 2. Auto Pre-run Shop Confirm
local cachedShopRemote = nil
local function startShopThread()
    task.spawn(function()
        while _G.NativeAutomationRunning do
            if config.AutoShopConfirm then
                pcall(function()
                    if not cachedShopRemote or not cachedShopRemote.Parent then
                        local remotesFolder = ReplicatedStorage:FindFirstChild("RemotesFolder")
                        if remotesFolder then
                            cachedShopRemote = remotesFolder:FindFirstChild("PreRunShop") or remotesFolder:FindFirstChild("ConfirmShop") or remotesFolder:FindFirstChild("ShopConfirm")
                        end
                    end
                    if cachedShopRemote then
                        cachedShopRemote:FireServer({}, false, {})
                    end
                end)
            end
            task.wait(1)
        end
    end)
end
startShopThread()

createToggle("Auto Shop Confirm", config.AutoShopConfirm, function(val)
    config.AutoShopConfirm = val
    saveSettings()
end)

-- 3. Auto Reset (4 Minutos Exatos com Timer)
local autoResetBtn = nil

autoResetBtn = createToggle("Auto Reset", config.AutoReset, function(val)
    config.AutoReset = val
    if not val and autoResetBtn then
        autoResetBtn.Text = "   Auto Reset  [OFF]"
    end
    saveSettings()
end)

local function startResetThread()
    task.spawn(function()
        local timer = 0
        while _G.NativeAutomationRunning do
            task.wait(1)
            
            if config.AutoReset then
                timer = timer + 1
                local maxSeconds = config.AutoResetMinutes * 60
                local remaining = maxSeconds - timer
                if remaining < 0 then remaining = 0 end
                
                local mins = math.floor(remaining / 60)
                local secs = remaining % 60
                
                if autoResetBtn and config.AutoReset then
                    autoResetBtn.Text = string.format("   Auto Reset  [%02d:%02d]", mins, secs)
                end
                
                if timer >= maxSeconds then
                    timer = 0
                    pcall(function()
                        if player.Character then
                            local hum = player.Character:FindFirstChildOfClass("Humanoid")
                            if hum then
                                hum.Health = 0
                                print("[Automation] Auto Reset acionado.")
                            end
                        end
                    end)
                end
            else
                timer = 0
            end
        end
    end)
end
startResetThread()

-- 4. Anti-AFK
local function startAFKThread()
    task.spawn(function()
        while _G.NativeAutomationRunning do
            if config.AntiAFK then
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0, 0))
                end)
            end
            task.wait(60)
        end
    end)
end
startAFKThread()

createToggle("Anti-AFK", config.AntiAFK, function(val)
    config.AntiAFK = val
    saveSettings()
end)

print("[SupremeAutomation] Interface moderna carregada!")
