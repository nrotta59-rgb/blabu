--[[
    ============================================================
    Script Supremo Nativo - Código Principal Consolidado
    - Auto Play Again (Com busca dinâmica de RemoteEvent)
    - Auto Pre-run Shop Confirm (Com busca dinâmica de RemoteEvent)
    - Auto Reset (3 minutos exatos com temporizador)
    - Painel Nativo Compacto fixado no Canto Superior Direito
    - Salvamento de Configurações em JSON e Anti-Duplicação
    ============================================================
]]

if _G.NativeAutomationRunning then
    _G.NativeAutomationRunning = false
    task.wait(0.2)
end
_G.NativeAutomationRunning = true

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
if not player then return end

-- Limpeza de instâncias duplicadas anteriores
pcall(function()
    if CoreGui:FindFirstChild("SupremeAutomationUI") then
        CoreGui.SupremeAutomationUI:Destroy()
    end
    if player.PlayerGui:FindFirstChild("SupremeAutomationUI") then
        player.PlayerGui.SupremeAutomationUI:Destroy()
    end
end)

-- Configurações e Persistência Local
local config = {
    AutoPlayAgain = false,
    AutoShopConfirm = false,
    AutoReset = false,
    AutoResetMinutes = 3
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
            local decoded = HttpService:JSONDecode(readfile(settingsFileName))
            if type(decoded) == "table" then
                for k, v in pairs(decoded) do config[k] = v end
            end
        end
    end)
end
loadSettings()

-- Criação da Interface Nativa Compacta (Canto Superior Direito)
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
mainFrame.Size = UDim2.new(0, 280, 0, 210)
mainFrame.Position = UDim2.new(1, -290, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true

local uiCorner = Instance.new("UICorner", mainFrame)
uiCorner.CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel", mainFrame)
titleLabel.Size = UDim2.new(1, 0, 0, 35)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Painel Supremo"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 15
titleLabel.Font = Enum.Font.SourceSansBold

local container = Instance.new("ScrollingFrame", mainFrame)
container.Size = UDim2.new(1, -16, 1, -45)
container.Position = UDim2.new(0, 8, 0, 40)
container.BackgroundTransparency = 1
container.CanvasSize = UDim2.new(0, 0, 0, 150)
container.ScrollBarThickness = 3

local uiList = Instance.new("UIListLayout", container)
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Padding = UDim.new(0, 8)

-- Função geradora de botões
local function createToggle(name, initialValue, callback)
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = initialValue and Color3.fromRGB(40, 160, 80) or Color3.fromRGB(45, 45, 45)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.SourceSansSemibold
    
    local statusText = initialValue and "ATIVADO" or "DESATIVADO"
    btn.Text = name .. ": " .. statusText
    
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 6)
    
    local active = initialValue
    btn.MouseButton1Click:Connect(function()
        active = not active
        btn.BackgroundColor3 = active and Color3.fromRGB(40, 160, 80) or Color3.fromRGB(45, 45, 45)
        local newStatusText = active and "ATIVADO" or "DESATIVADO"
        btn.Text = name .. ": " .. newStatusText
        callback(active)
    end)
end

-- Sistema de Busca Dinâmica de RemoteEvents
local function findRemote(keywords)
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local nameLower = string.lower(obj.Name)
            for _, kw in ipairs(keywords) do
                if nameLower:find(string.lower(kw)) then
                    return obj
                end
            end
        end
    end
    return nil
end

-- ==========================================
-- 1. Auto Play Again
-- ==========================================
local isDeadProcessing = false
local function triggerPlayAgain()
    if isDeadProcessing then return end
    isDeadProcessing = true
    
    pcall(function()
        local playAgainEvent = findRemote({"playagain", "restart", "respawn", "again"})
        if playAgainEvent then
            playAgainEvent:FireServer()
            print("[Automation] Play Again disparado via: " .. playAgainEvent.Name)
        else
            warn("[Automation] RemoteEvent de Play Again não encontrado.")
        end
    end)
    
    task.wait(3)
    isDeadProcessing = false
end

local function monitorCharacter(character)
    if not character then return end
    local humanoid = character:WaitForChild("Humanoid", 15)
    if not humanoid then return end
    
    humanoid.Died:Connect(function()
        if config.AutoPlayAgain then
            task.wait(0.15)
            if humanoid and humanoid.Health <= 0 then
                triggerPlayAgain()
            end
        end
    end)
end

if player.Character then monitorCharacter(player.Character) end
player.CharacterAdded:Connect(monitorCharacter)

createToggle("Auto Play Again", config.AutoPlayAgain, function(val)
    config.AutoPlayAgain = val
    saveSettings()
end)

-- ==========================================
-- 2. Auto Pre-run Shop Confirm
-- ==========================================
task.spawn(function()
    while _G.NativeAutomationRunning do
        if config.AutoShopConfirm then
            pcall(function()
                local shopEvent = findRemote({"prerunshop", "shopconfirm", "shop", "buy"})
                if shopEvent then
                    shopEvent:FireServer({}, false, {})
                end
            end)
        end
        task.wait(0.2)
    end
end)

createToggle("Auto Shop Confirm", config.AutoShopConfirm, function(val)
    config.AutoShopConfirm = val
    saveSettings()
end)

-- ==========================================
-- 3. Auto Reset (3 Minutos Exatos)
-- ==========================================
task.spawn(function()
    local timer = 0
    while _G.NativeAutomationRunning do
        task.wait(1)
        if config.AutoReset then
            timer = timer + 1
            if timer >= (config.AutoResetMinutes * 60) then
                timer = 0
                pcall(function()
                    if player.Character and player.Character:FindFirstChild("Humanoid") then
                        player.Character.Humanoid.Health = 0
                        print("[Automation] Auto Reset executado (3 minutos atingidos).")
                    end
                end)
            end
        else
            timer = 0
        end
    end
end)

createToggle("Auto Reset (3 Minutos)", config.AutoReset, function(val)
    config.AutoReset = val
    saveSettings()
end)

print("[SupremeAutomation] Código principal consolidado carregado com sucesso!")
