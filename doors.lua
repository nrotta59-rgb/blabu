--[[
    ============================================================
    Script Supremo Nativo - Busca Resiliente de Remotes
    ============================================================
]]

if queue_on_teleport then
    pcall(function()
        queue_on_teleport([[
            task.wait(1)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/nrotta59-rgb/blabu/refs/heads/main/doors.lua?v=" .. tick()))()
        ]])
    end)
end

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
mainFrame.Size = UDim2.new(0, 280, 0, 250)
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
container.CanvasSize = UDim2.new(0, 0, 0, 190)
container.ScrollBarThickness = 3

local uiList = Instance.new("UIListLayout", container)
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Padding = UDim.new(0, 8)

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
    
    return btn
end

-- Cache de Remotes para evitar novas buscas desnecessárias
local remoteCache = {}

local function findRemote(keywords)
    local cacheKey = table.concat(keywords, "_")
    if remoteCache[cacheKey] and remoteCache[cacheKey].Parent then
        return remoteCache[cacheKey]
    end

    local foundRemote = nil
    local timeout = tick() + 5 -- Tenta por até 5 segundos caso o jogo esteja carregando
    
    while not foundRemote and tick() < timeout and _G.NativeAutomationRunning do
        pcall(function()
            for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
                if obj:IsA("RemoteEvent") then
                    local nameLower = string.lower(obj.Name)
                    for _, kw in ipairs(keywords) do
                        if nameLower:find(string.lower(kw)) then
                            foundRemote = obj
                            remoteCache[cacheKey] = obj
                            return
                        end
                    end
                end
            end
        end)
        if not foundRemote then
            task.wait(0.5)
        end
    end
    
    return foundRemote
end

local lastHeartbeat = {
    ShopLoop = tick(),
    ResetLoop = tick(),
    AFKLoop = tick()
}

-- 1. Auto Play Again (Resiliente)
local isDeadProcessing = false
local function triggerPlayAgain()
    if isDeadProcessing then return end
    isDeadProcessing = true
    
    pcall(function()
        local playAgainEvent = findRemote({"play", "again", "restart", "respawn", "revive", "retry", "continue", "start"})
        if playAgainEvent then
            playAgainEvent:FireServer()
            print("[Automation] Play Again disparado via: " .. playAgainEvent.Name)
        else
            warn("[Automation] RemoteEvent de Play Again não encontrado após tentativa de espera.")
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

-- 2. Auto Pre-run Shop Confirm
local function startShopThread()
    task.spawn(function()
        while _G.NativeAutomationRunning do
            lastHeartbeat.ShopLoop = tick()
            if config.AutoShopConfirm then
                pcall(function()
                    local shopEvent = findRemote({"shop", "buy", "prerun", "confirm", "item"})
                    if shopEvent then
                        shopEvent:FireServer({}, false, {})
                    end
                end)
            end
            task.wait(0.2)
        end
    end)
end
startShopThread()

createToggle("Auto Shop Confirm", config.AutoShopConfirm, function(val)
    config.AutoShopConfirm = val
    saveSettings()
end)

-- 3. Auto Reset (4 Minutos)
local autoResetButton = nil

autoResetButton = createToggle("Auto Reset", config.AutoReset, function(val)
    config.AutoReset = val
    if not val and autoResetButton then
        autoResetButton.Text = "Auto Reset: DESATIVADO"
    end
    saveSettings()
end)

local function startResetThread()
    task.spawn(function()
        local timer = 0
        while _G.NativeAutomationRunning do
            lastHeartbeat.ResetLoop = tick()
            task.wait(1)
            
            if config.AutoReset then
                timer = timer + 1
                local maxSeconds = config.AutoResetMinutes * 60
                local remaining = maxSeconds - timer
                if remaining < 0 then remaining = 0 end
                
                local mins = math.floor(remaining / 60)
                local secs = remaining % 60
                
                if autoResetButton and config.AutoReset then
                    autoResetButton.Text = string.format("Auto Reset: %02d:%02d", mins, secs)
                end
                
                if timer >= maxSeconds then
                    timer = 0
                    pcall(function()
                        if player.Character and player.Character:FindFirstChild("Humanoid") then
                            player.Character.Humanoid.Health = 0
                            print("[Automation] Auto Reset executado.")
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
            lastHeartbeat.AFKLoop = tick()
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

-- Autorrecuperação
task.spawn(function()
    while _G.NativeAutomationRunning do
        task.wait(10)
        local now = tick()
        
        if now - lastHeartbeat.ShopLoop > 5 then
            startShopThread()
        end
        if now - lastHeartbeat.ResetLoop > 5 then
            startResetThread()
        end
        if now - lastHeartbeat.AFKLoop > 120 then
            startAFKThread()
        end
    end
end)

print("[SupremeAutomation] Script carregado com busca resiliente de Remotes!")
